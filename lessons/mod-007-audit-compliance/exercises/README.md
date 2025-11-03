# Module 7: Audit, Logging & Compliance - Exercises

## Overview

These exercises provide hands-on experience implementing audit logging, centralized logging systems, compliance automation, and SIEM integration for ML infrastructure.

**Total Time**: 11-14 hours
**Prerequisites**:
- Kubernetes cluster access
- Docker and kubectl installed
- Understanding of logging concepts
- Basic knowledge of compliance requirements (GDPR, SOC2)

---

## Exercise 1: Audit Logging Implementation

**Time**: 3-4 hours
**Difficulty**: Intermediate

### Objectives

- Implement structured audit logging for ML systems
- Configure Kubernetes audit logging
- Create audit log analysis pipeline
- Set up audit log retention and archival
- Implement audit trail for model operations

### Tasks

**Part 1: Structured Audit Logger (1.5 hours)**

1. Create `src/audit_logger.py`:
   ```python
   import json
   import logging
   import uuid
   from datetime import datetime
   from enum import Enum
   from typing import Any, Dict, Optional
   import socket

   class AuditEventType(Enum):
       MODEL_PREDICTION = "model.prediction"
       MODEL_TRAINING = "model.training"
       MODEL_DEPLOYMENT = "model.deployment"
       DATA_ACCESS = "data.access"
       CONFIGURATION_CHANGE = "config.change"
       USER_AUTHENTICATION = "user.authentication"
       AUTHORIZATION_DECISION = "authorization.decision"

   class AuditLogger:
       def __init__(self, service_name: str, log_file: Optional[str] = None):
           self.service_name = service_name
           self.hostname = socket.gethostname()

           # Configure logger
           self.logger = logging.getLogger(f"audit.{service_name}")
           self.logger.setLevel(logging.INFO)

           # JSON formatter
           handler = logging.FileHandler(log_file) if log_file else logging.StreamHandler()
           self.logger.addHandler(handler)

       def log_event(
           self,
           event_type: AuditEventType,
           actor: str,
           resource: str,
           action: str,
           result: str,
           details: Optional[Dict[str, Any]] = None,
           ip_address: Optional[str] = None
       ):
           """Log a structured audit event."""
           event = {
               "timestamp": datetime.utcnow().isoformat() + "Z",
               "event_id": str(uuid.uuid4()),
               "event_type": event_type.value,
               "service": self.service_name,
               "hostname": self.hostname,
               "actor": {
                   "id": actor,
                   "ip_address": ip_address
               },
               "resource": resource,
               "action": action,
               "result": result,  # "success", "failure", "denied"
               "details": details or {}
           }

           self.logger.info(json.dumps(event))
           return event["event_id"]

       def log_model_prediction(
           self,
           model_id: str,
           model_version: str,
           user_id: str,
           request_id: str,
           latency_ms: float,
           status: str,
           ip_address: Optional[str] = None
       ):
           """Log ML model prediction request."""
           return self.log_event(
               event_type=AuditEventType.MODEL_PREDICTION,
               actor=user_id,
               resource=f"model/{model_id}/version/{model_version}",
               action="predict",
               result=status,
               details={
                   "request_id": request_id,
                   "latency_ms": latency_ms,
                   "model_version": model_version
               },
               ip_address=ip_address
           )

       def log_model_deployment(
           self,
           model_id: str,
           model_version: str,
           deployed_by: str,
           environment: str,
           approval_ticket: Optional[str] = None
       ):
           """Log model deployment event."""
           return self.log_event(
               event_type=AuditEventType.MODEL_DEPLOYMENT,
               actor=deployed_by,
               resource=f"model/{model_id}/version/{model_version}",
               action="deploy",
               result="success",
               details={
                   "environment": environment,
                   "approval_ticket": approval_ticket,
                   "model_version": model_version
               }
           )

       def log_data_access(
           self,
           user_id: str,
           dataset: str,
           operation: str,
           num_records: int,
           purpose: str,
           status: str
       ):
           """Log data access for compliance."""
           return self.log_event(
               event_type=AuditEventType.DATA_ACCESS,
               actor=user_id,
               resource=f"dataset/{dataset}",
               action=operation,
               result=status,
               details={
                   "num_records": num_records,
                   "purpose": purpose,
                   "data_classification": "pii"  # If applicable
               }
           )

   # Usage example
   if __name__ == "__main__":
       audit = AuditLogger(service_name="ml-inference")

       # Log prediction request
       audit.log_model_prediction(
           model_id="fraud-detection",
           model_version="v2.1.0",
           user_id="user@example.com",
           request_id="req-12345",
           latency_ms=45.2,
           status="success",
           ip_address="203.0.113.42"
       )

       # Log model deployment
       audit.log_model_deployment(
           model_id="fraud-detection",
           model_version="v2.1.0",
           deployed_by="deploy-bot",
           environment="production",
           approval_ticket="SEC-4321"
       )
   ```

2. Create FastAPI middleware for automatic audit logging:
   ```python
   from fastapi import FastAPI, Request
   from audit_logger import AuditLogger, AuditEventType
   import time

   app = FastAPI()
   audit = AuditLogger(service_name="ml-api")

   @app.middleware("http")
   async def audit_middleware(request: Request, call_next):
       start_time = time.time()

       # Extract user info from request
       user_id = request.headers.get("X-User-ID", "anonymous")
       ip_address = request.client.host

       # Process request
       response = await call_next(request)

       # Log audit event
       latency_ms = (time.time() - start_time) * 1000
       audit.log_event(
           event_type=AuditEventType.MODEL_PREDICTION,
           actor=user_id,
           resource=request.url.path,
           action=request.method,
           result="success" if response.status_code < 400 else "failure",
           details={
               "status_code": response.status_code,
               "latency_ms": latency_ms,
               "request_id": response.headers.get("X-Request-ID")
           },
           ip_address=ip_address
       )

       return response
   ```

**Part 2: Kubernetes Audit Logging (1 hour)**

3. Configure Kubernetes audit policy:
   ```yaml
   # /etc/kubernetes/audit-policy.yaml
   apiVersion: audit.k8s.io/v1
   kind: Policy
   rules:
     # Log all requests to secrets
     - level: RequestResponse
       resources:
       - group: ""
         resources: ["secrets"]

     # Log model serving pods
     - level: Request
       namespaces: ["ml-production"]
       resources:
       - group: ""
         resources: ["pods"]
       verbs: ["create", "delete", "update", "patch"]

     # Log RBAC changes
     - level: RequestResponse
       resources:
       - group: "rbac.authorization.k8s.io"
         resources: ["roles", "rolebindings", "clusterroles", "clusterrolebindings"]

     # Log configmap and deployment changes in production
     - level: Request
       namespaces: ["ml-production"]
       resources:
       - group: ""
         resources: ["configmaps"]
       - group: "apps"
         resources: ["deployments", "statefulsets"]
       verbs: ["create", "update", "patch", "delete"]

     # Don't log read-only requests to endpoints, services, etc.
     - level: None
       verbs: ["get", "list", "watch"]
   ```

4. Enable audit logging in kube-apiserver:
   ```yaml
   # Add to kube-apiserver manifest
   spec:
     containers:
     - command:
       - kube-apiserver
       - --audit-policy-file=/etc/kubernetes/audit-policy.yaml
       - --audit-log-path=/var/log/kubernetes/audit.log
       - --audit-log-maxage=30
       - --audit-log-maxbackup=10
       - --audit-log-maxsize=100
       volumeMounts:
       - name: audit-policy
         mountPath: /etc/kubernetes/audit-policy.yaml
         readOnly: true
       - name: audit-logs
         mountPath: /var/log/kubernetes
     volumes:
     - name: audit-policy
       hostPath:
         path: /etc/kubernetes/audit-policy.yaml
         type: File
     - name: audit-logs
       hostPath:
         path: /var/log/kubernetes
         type: DirectoryOrCreate
   ```

**Part 3: Audit Log Analysis (1 hour)**

5. Create audit log analyzer:
   ```python
   import json
   from collections import defaultdict
   from datetime import datetime, timedelta
   from typing import Dict, List

   class AuditAnalyzer:
       def __init__(self, log_file: str):
           self.log_file = log_file
           self.events = []
           self._load_logs()

       def _load_logs(self):
           """Load audit logs from file."""
           with open(self.log_file, 'r') as f:
               for line in f:
                   try:
                       event = json.loads(line)
                       self.events.append(event)
                   except json.JSONDecodeError:
                       continue

       def failed_authentications(self, time_window_minutes: int = 60) -> List[Dict]:
           """Find failed authentication attempts."""
           cutoff = datetime.utcnow() - timedelta(minutes=time_window_minutes)

           failed_auths = []
           for event in self.events:
               if event.get("event_type") == "user.authentication":
                   if event.get("result") == "failure":
                       event_time = datetime.fromisoformat(event["timestamp"].rstrip("Z"))
                       if event_time > cutoff:
                           failed_auths.append(event)

           return failed_auths

       def suspicious_data_access(self, threshold: int = 1000) -> List[Dict]:
           """Find data access events with large record counts."""
           suspicious = []
           for event in self.events:
               if event.get("event_type") == "data.access":
                   num_records = event.get("details", {}).get("num_records", 0)
                   if num_records > threshold:
                       suspicious.append(event)

           return suspicious

       def model_deployment_without_approval(self) -> List[Dict]:
           """Find model deployments without approval tickets."""
           no_approval = []
           for event in self.events:
               if event.get("event_type") == "model.deployment":
                   if not event.get("details", {}).get("approval_ticket"):
                       no_approval.append(event)

           return no_approval

       def generate_summary(self) -> Dict:
           """Generate audit summary report."""
           summary = {
               "total_events": len(self.events),
               "by_event_type": defaultdict(int),
               "by_result": defaultdict(int),
               "by_actor": defaultdict(int),
               "failed_operations": 0
           }

           for event in self.events:
               event_type = event.get("event_type", "unknown")
               result = event.get("result", "unknown")
               actor = event.get("actor", {}).get("id", "unknown")

               summary["by_event_type"][event_type] += 1
               summary["by_result"][result] += 1
               summary["by_actor"][actor] += 1

               if result == "failure":
                   summary["failed_operations"] += 1

           return dict(summary)

   # Usage
   if __name__ == "__main__":
       analyzer = AuditAnalyzer("/var/log/ml-audit.log")

       print("=== Audit Summary ===")
       summary = analyzer.generate_summary()
       print(json.dumps(summary, indent=2))

       print("\n=== Failed Authentications (Last Hour) ===")
       failed_auths = analyzer.failed_authentications(time_window_minutes=60)
       for auth in failed_auths:
           print(f"{auth['timestamp']}: {auth['actor']['id']} from {auth['actor']['ip_address']}")
   ```

**Part 4: Audit Log Retention (30 minutes)**

6. Create log rotation policy:
   ```yaml
   # logrotate configuration
   /var/log/ml-audit/*.log {
       daily
       rotate 90
       compress
       delaycompress
       notifempty
       create 0640 app app
       sharedscripts
       postrotate
           # Upload to S3 for long-term storage
           aws s3 cp /var/log/ml-audit/ s3://audit-logs-bucket/$(date +\%Y/\%m/\%d)/ \
               --recursive --exclude "*" --include "*.gz"
       endscript
   }
   ```

7. Create S3 lifecycle policy:
   ```json
   {
     "Rules": [
       {
         "Id": "AuditLogLifecycle",
         "Status": "Enabled",
         "Transitions": [
           {
             "Days": 90,
             "StorageClass": "STANDARD_IA"
           },
           {
             "Days": 365,
             "StorageClass": "GLACIER"
           }
         ],
         "Expiration": {
           "Days": 2555
         }
       }
     ]
   }
   ```

### Success Criteria

- [ ] Structured audit logging implemented for all ML operations
- [ ] Kubernetes audit logging configured and capturing events
- [ ] Audit log analysis detecting suspicious activities
- [ ] Log rotation and archival working automatically
- [ ] Audit logs stored securely with retention policy
- [ ] Failed operations and unauthorized access detected

### Deliverables

1. `src/audit_logger.py`
2. `src/audit_analyzer.py`
3. `k8s/audit-policy.yaml`
4. `config/logrotate.conf`
5. Documentation:
   - Audit logging architecture
   - Event type definitions
   - Analysis playbooks
   - Retention policy

---

## Exercise 2: Centralized Logging with ELK Stack

**Time**: 3-4 hours
**Difficulty**: Advanced

### Objectives

- Deploy ELK stack (Elasticsearch, Logstash, Kibana) or Loki
- Configure log shipping from ML services
- Create log parsing and enrichment pipeline
- Set up dashboards and alerts
- Implement log-based security monitoring

### Tasks

**Part 1: ELK Stack Deployment (1 hour)**

1. Deploy Elasticsearch:
   ```yaml
   apiVersion: elasticsearch.k8s.elastic.co/v1
   kind: Elasticsearch
   metadata:
     name: ml-logs
     namespace: logging
   spec:
     version: 8.11.0
     nodeSets:
     - name: default
       count: 3
       config:
         node.store.allow_mmap: false
         xpack.security.enabled: true
         xpack.security.transport.ssl.enabled: true
       podTemplate:
         spec:
           containers:
           - name: elasticsearch
             resources:
               limits:
                 memory: 4Gi
                 cpu: 2
               requests:
                 memory: 2Gi
                 cpu: 1
       volumeClaimTemplates:
       - metadata:
           name: elasticsearch-data
         spec:
           accessModes:
           - ReadWriteOnce
           resources:
             requests:
               storage: 100Gi
           storageClassName: fast-ssd
   ```

2. Deploy Kibana:
   ```yaml
   apiVersion: kibana.k8s.elastic.co/v1
   kind: Kibana
   metadata:
     name: ml-logs
     namespace: logging
   spec:
     version: 8.11.0
     count: 1
     elasticsearchRef:
       name: ml-logs
     podTemplate:
       spec:
         containers:
         - name: kibana
           resources:
             limits:
               memory: 2Gi
               cpu: 1
   ```

3. Install using Elastic operator:
   ```bash
   kubectl create -f https://download.elastic.co/downloads/eck/2.10.0/crds.yaml
   kubectl apply -f https://download.elastic.co/downloads/eck/2.10.0/operator.yaml

   kubectl apply -f elasticsearch.yaml
   kubectl apply -f kibana.yaml

   # Get credentials
   kubectl get secret ml-logs-es-elastic-user -n logging \
     -o=jsonpath='{.data.elastic}' | base64 --decode
   ```

**Part 2: Filebeat Log Shipping (1 hour)**

4. Deploy Filebeat as DaemonSet:
   ```yaml
   apiVersion: v1
   kind: ConfigMap
   metadata:
     name: filebeat-config
     namespace: logging
   data:
     filebeat.yml: |-
       filebeat.inputs:
       - type: container
         paths:
           - /var/log/containers/*ml-*.log
         processors:
         - add_kubernetes_metadata:
             host: ${NODE_NAME}
             matchers:
             - logs_path:
                 logs_path: "/var/log/containers/"
         - decode_json_fields:
             fields: ["message"]
             target: "json"
             overwrite_keys: true

       output.elasticsearch:
         hosts: ['${ELASTICSEARCH_HOST}:${ELASTICSEARCH_PORT}']
         username: ${ELASTICSEARCH_USERNAME}
         password: ${ELASTICSEARCH_PASSWORD}
         index: "ml-logs-%{+yyyy.MM.dd}"

       setup.kibana:
         host: "${KIBANA_HOST}:${KIBANA_PORT}"

       setup.ilm.enabled: true
       setup.ilm.rollover_alias: "ml-logs"
       setup.ilm.pattern: "ml-logs-*"
   ---
   apiVersion: apps/v1
   kind: DaemonSet
   metadata:
     name: filebeat
     namespace: logging
   spec:
     selector:
       matchLabels:
         app: filebeat
     template:
       metadata:
         labels:
           app: filebeat
       spec:
         serviceAccountName: filebeat
         terminationGracePeriodSeconds: 30
         containers:
         - name: filebeat
           image: docker.elastic.co/beats/filebeat:8.11.0
           env:
           - name: ELASTICSEARCH_HOST
             value: ml-logs-es-http
           - name: ELASTICSEARCH_PORT
             value: "9200"
           - name: ELASTICSEARCH_USERNAME
             value: elastic
           - name: ELASTICSEARCH_PASSWORD
             valueFrom:
               secretKeyRef:
                 name: ml-logs-es-elastic-user
                 key: elastic
           - name: KIBANA_HOST
             value: ml-logs-kb-http
           - name: KIBANA_PORT
             value: "5601"
           - name: NODE_NAME
             valueFrom:
               fieldRef:
                 fieldPath: spec.nodeName
           volumeMounts:
           - name: config
             mountPath: /usr/share/filebeat/filebeat.yml
             readOnly: true
             subPath: filebeat.yml
           - name: data
             mountPath: /usr/share/filebeat/data
           - name: varlibdockercontainers
             mountPath: /var/lib/docker/containers
             readOnly: true
           - name: varlog
             mountPath: /var/log
             readOnly: true
         volumes:
         - name: config
           configMap:
             name: filebeat-config
         - name: varlibdockercontainers
           hostPath:
             path: /var/lib/docker/containers
         - name: varlog
           hostPath:
             path: /var/log
         - name: data
           hostPath:
             path: /var/lib/filebeat-data
             type: DirectoryOrCreate
   ```

**Part 3: Log Parsing and Enrichment (1 hour)**

5. Create Logstash pipeline for log enrichment:
   ```ruby
   input {
     elasticsearch {
       hosts => ["ml-logs-es-http:9200"]
       user => "elastic"
       password => "${ELASTICSEARCH_PASSWORD}"
       index => "ml-logs-*"
       schedule => "* * * * *"
     }
   }

   filter {
     # Parse JSON logs
     if [message] =~ /^\{.*\}$/ {
       json {
         source => "message"
       }
     }

     # Extract model information
     if [event_type] == "model.prediction" {
       grok {
         match => {
           "resource" => "model/%{DATA:model_id}/version/%{DATA:model_version}"
         }
       }
     }

     # Add GeoIP information
     if [actor][ip_address] {
       geoip {
         source => "[actor][ip_address]"
         target => "geoip"
       }
     }

     # Flag suspicious activity
     if [latency_ms] and [latency_ms] > 1000 {
       mutate {
         add_field => { "alert" => "high_latency" }
       }
     }

     if [result] == "failure" {
       mutate {
         add_field => { "alert" => "failed_operation" }
       }
     }

     # Add timestamp
     date {
       match => ["timestamp", "ISO8601"]
       target => "@timestamp"
     }
   }

   output {
     elasticsearch {
       hosts => ["ml-logs-es-http:9200"]
       user => "elastic"
       password => "${ELASTICSEARCH_PASSWORD}"
       index => "ml-logs-enriched-%{+YYYY.MM.dd}"
     }
   }
   ```

**Part 4: Kibana Dashboards and Alerts (1 hour)**

6. Create Kibana index pattern:
   ```bash
   curl -X POST "http://kibana:5601/api/saved_objects/index-pattern/ml-logs-*" \
     -H "kbn-xsrf: true" \
     -H "Content-Type: application/json" \
     -d '{
       "attributes": {
         "title": "ml-logs-*",
         "timeFieldName": "@timestamp"
       }
     }'
   ```

7. Create dashboard JSON (import via Kibana UI):
   ```json
   {
     "title": "ML Security Dashboard",
     "panels": [
       {
         "title": "Failed Operations Over Time",
         "type": "line",
         "query": "result:failure"
       },
       {
         "title": "Top Failed Actors",
         "type": "pie",
         "query": "result:failure",
         "aggs": {
           "terms": {
             "field": "actor.id.keyword"
           }
         }
       },
       {
         "title": "Model Prediction Latency",
         "type": "histogram",
         "query": "event_type:model.prediction",
         "field": "latency_ms"
       },
       {
         "title": "Geographic Distribution",
         "type": "map",
         "field": "geoip.location"
       }
     ]
   }
   ```

8. Create alerting rule:
   ```json
   {
     "name": "Failed Authentication Spike",
     "tags": ["security", "authentication"],
     "schedule": {
       "interval": "5m"
     },
     "conditions": [
       {
         "type": "query",
         "query": "event_type:user.authentication AND result:failure",
         "threshold": 10,
         "timeWindow": "5m"
       }
     ],
     "actions": [
       {
         "type": "email",
         "to": ["security@example.com"],
         "subject": "Alert: Failed Authentication Spike",
         "body": "More than 10 failed authentications in the last 5 minutes"
       },
       {
         "type": "webhook",
         "url": "https://slack.example.com/webhook",
         "body": {
           "text": "Security Alert: Failed authentication spike detected"
         }
       }
     ]
   }
   ```

### Success Criteria

- [ ] ELK stack deployed and accessible
- [ ] Logs from all ML services centralized
- [ ] Log parsing and enrichment working
- [ ] Dashboards showing key security metrics
- [ ] Alerts configured for suspicious activity
- [ ] GeoIP enrichment providing location data

### Deliverables

1. `k8s/elasticsearch.yaml`, `k8s/kibana.yaml`, `k8s/filebeat.yaml`
2. `logstash/pipeline.conf`
3. `kibana/dashboards.json`
4. `kibana/alerts.json`
5. Documentation:
   - ELK architecture diagram
   - Log format specifications
   - Dashboard user guide
   - Alert runbooks

---

## Exercise 3: Compliance Automation with OPA

**Time**: 3-4 hours
**Difficulty**: Intermediate

### Objectives

- Deploy OPA (Open Policy Agent) for compliance checks
- Implement GDPR compliance policies
- Create automated compliance reporting
- Set up continuous compliance monitoring
- Implement policy-as-code workflow

### Tasks

**Part 1: OPA Deployment (30 minutes)**

1. Deploy OPA:
   ```yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: opa
     namespace: compliance
   spec:
     replicas: 3
     selector:
       matchLabels:
         app: opa
     template:
       metadata:
         labels:
           app: opa
       spec:
         containers:
         - name: opa
           image: openpolicyagent/opa:latest
           args:
           - "run"
           - "--server"
           - "--addr=0.0.0.0:8181"
           - "--config-file=/config/opa-config.yaml"
           ports:
           - containerPort: 8181
           volumeMounts:
           - name: config
             mountPath: /config
           - name: policies
             mountPath: /policies
         volumes:
         - name: config
           configMap:
             name: opa-config
         - name: policies
           configMap:
             name: opa-policies
   ```

**Part 2: GDPR Compliance Policies (2 hours)**

2. Create GDPR data retention policy:
   ```rego
   package gdpr.retention

   import future.keywords

   # Default retention periods (days)
   default_retention := {
       "pii": 365,
       "financial": 2555,  # 7 years
       "model_predictions": 90,
       "audit_logs": 2555
   }

   # Check if data exceeds retention period
   violation[msg] {
       data_item := input.data_items[_]
       classification := data_item.classification
       retention_days := default_retention[classification]

       age_days := (time.now_ns() - data_item.created_at) / 86400000000000
       age_days > retention_days

       msg := sprintf(
           "Data item %v (classification: %v) exceeds retention period: %v days > %v days",
           [data_item.id, classification, age_days, retention_days]
       )
   }

   # Compliance check
   compliant {
       count(violation) == 0
   }
   ```

3. Create data processing consent policy:
   ```rego
   package gdpr.consent

   import future.keywords

   # Check if user has given consent for data processing
   allow_processing {
       user := input.user
       purpose := input.processing_purpose

       # Check consent record
       consent := data.consents[user.id]
       consent.purposes[purpose] == true

       # Check consent is not expired
       consent_age_days := (time.now_ns() - consent.timestamp) / 86400000000000
       consent_age_days < 365  # Consent valid for 1 year
   }

   # Deny if no consent
   deny[msg] {
       not allow_processing
       msg := sprintf(
           "User %v has not consented to %v",
           [input.user.id, input.processing_purpose]
       )
   }
   ```

4. Create data minimization policy:
   ```rego
   package gdpr.minimization

   import future.keywords

   # Define minimum required fields for each operation
   required_fields := {
       "model_training": ["user_id", "features", "target"],
       "model_prediction": ["user_id", "features"],
       "analytics": ["user_id", "timestamp", "action"]
   }

   # Check if data collection exceeds minimum
   violation[msg] {
       operation := input.operation
       requested_fields := {field | field := input.requested_fields[_]}
       required := {field | field := required_fields[operation][_]}

       excessive_fields := requested_fields - required
       count(excessive_fields) > 0

       msg := sprintf(
           "Operation %v requests excessive fields: %v",
           [operation, excessive_fields]
       )
   }
   ```

5. Create data subject rights policy:
   ```rego
   package gdpr.rights

   import future.keywords

   # Right to access
   allow_data_export {
       input.request_type == "data_export"
       input.requester_id == input.subject_id
       verified_identity(input)
   }

   # Right to erasure
   allow_data_deletion {
       input.request_type == "data_deletion"
       input.requester_id == input.subject_id
       verified_identity(input)
       not has_legal_obligation(input.subject_id)
   }

   # Right to rectification
   allow_data_correction {
       input.request_type == "data_correction"
       input.requester_id == input.subject_id
       verified_identity(input)
   }

   verified_identity(req) {
       # Check authentication token
       token := req.auth_token
       data.valid_tokens[token] == true
   }

   has_legal_obligation(user_id) {
       # Check if there's legal requirement to retain data
       data.legal_holds[user_id] == true
   }
   ```

**Part 3: Compliance Reporting (1 hour)**

6. Create compliance checker:
   ```python
   import requests
   from typing import Dict, List
   from datetime import datetime, timedelta

   class ComplianceChecker:
       def __init__(self, opa_url: str = "http://opa:8181"):
           self.opa_url = opa_url

       def check_retention_compliance(self, data_items: List[Dict]) -> Dict:
           """Check if data items comply with retention policy."""
           response = requests.post(
               f"{self.opa_url}/v1/data/gdpr/retention/violation",
               json={"input": {"data_items": data_items}}
           )

           violations = response.json().get("result", [])
           return {
               "compliant": len(violations) == 0,
               "violations": violations,
               "checked_items": len(data_items)
           }

       def check_consent(self, user_id: str, purpose: str) -> bool:
           """Check if user has consented to data processing."""
           response = requests.post(
               f"{self.opa_url}/v1/data/gdpr/consent/allow_processing",
               json={
                   "input": {
                       "user": {"id": user_id},
                       "processing_purpose": purpose
                   }
               }
           )

           return response.json().get("result", False)

       def generate_compliance_report(self) -> Dict:
           """Generate comprehensive compliance report."""
           # Check all data items
           data_items = self._fetch_all_data_items()
           retention_check = self.check_retention_compliance(data_items)

           # Check consents
           consents = self._fetch_all_consents()
           expired_consents = [
               c for c in consents
               if self._is_consent_expired(c)
           ]

           report = {
               "timestamp": datetime.utcnow().isoformat(),
               "retention_compliance": {
                   "compliant": retention_check["compliant"],
                   "violations": len(retention_check["violations"]),
                   "total_items": retention_check["checked_items"]
               },
               "consent_management": {
                   "total_consents": len(consents),
                   "expired_consents": len(expired_consents),
                   "compliance_rate": (len(consents) - len(expired_consents)) / len(consents) * 100
               },
               "overall_compliance": "PASS" if retention_check["compliant"] and len(expired_consents) == 0 else "FAIL"
           }

           return report

       def _is_consent_expired(self, consent: Dict) -> bool:
           consent_date = datetime.fromisoformat(consent["timestamp"])
           return (datetime.utcnow() - consent_date) > timedelta(days=365)

   # Usage
   if __name__ == "__main__":
       checker = ComplianceChecker()
       report = checker.generate_compliance_report()
       print(json.dumps(report, indent=2))
   ```

**Part 4: Continuous Monitoring (30 minutes)**

7. Create compliance monitoring cron job:
   ```yaml
   apiVersion: batch/v1
   kind: CronJob
   metadata:
     name: compliance-checker
     namespace: compliance
   spec:
     schedule: "0 2 * * *"  # Daily at 2 AM
     jobTemplate:
       spec:
         template:
           spec:
             containers:
             - name: checker
               image: compliance-checker:latest
               env:
               - name: OPA_URL
                 value: "http://opa.compliance.svc.cluster.local:8181"
               - name: REPORT_BUCKET
                 value: "s3://compliance-reports/"
               command:
               - python
               - /app/compliance_checker.py
               - --generate-report
               - --upload-to-s3
             restartPolicy: OnFailure
   ```

### Success Criteria

- [ ] OPA deployed and policies loaded
- [ ] GDPR compliance policies implemented
- [ ] Automated compliance checking working
- [ ] Compliance reports generated daily
- [ ] Violations detected and reported
- [ ] Policy-as-code workflow established

### Deliverables

1. `opa/policies/` directory with `.rego` files
2. `src/compliance_checker.py`
3. `k8s/opa-deployment.yaml`
4. `k8s/compliance-cronjob.yaml`
5. Documentation:
   - Compliance policy guide
   - GDPR requirements mapping
   - Remediation procedures

---

## Exercise 4: SIEM Integration and Security Metrics

**Time**: 2-3 hours
**Difficulty**: Advanced

### Objectives

- Integrate with SIEM (Splunk or Elastic SIEM)
- Configure security event correlation
- Create security dashboards and KPIs
- Set up automated incident detection
- Implement security metrics tracking

### Tasks

**Part 1: SIEM Integration (1 hour)**

1. Configure Elastic SIEM:
   ```yaml
   # Enable SIEM in Kibana
   apiVersion: v1
   kind: ConfigMap
   metadata:
     name: kibana-config
     namespace: logging
   data:
     kibana.yml: |
       elasticsearch.hosts: ["https://ml-logs-es-http:9200"]
       xpack.security.enabled: true
       xpack.encryptedSavedObjects.encryptionKey: "min-32-byte-long-strong-encryption-key"

       # Enable SIEM
       xpack.siem.enabled: true
       xpack.siem.enableExperimental: ['ruleRegistry']
   ```

2. Create detection rules:
   ```json
   {
     "name": "Multiple Failed Authentication Attempts",
     "description": "Detects 5+ failed authentications from same IP in 5 minutes",
     "severity": "high",
     "risk_score": 73,
     "rule_type": "threshold",
     "query": "event_type:user.authentication AND result:failure",
     "threshold": {
       "field": "actor.ip_address",
       "value": 5
     },
     "interval": "5m",
     "actions": [
       {
         "group": "default",
         "id": "security-team-email",
         "action_type_id": ".email"
       }
     ]
   }
   ```

**Part 2: Security Metrics (1 hour)**

3. Create security metrics collector:
   ```python
   from prometheus_client import Counter, Histogram, Gauge, start_http_server
   from typing import Dict
   import time

   class SecurityMetrics:
       def __init__(self):
           # Counters
           self.auth_attempts = Counter(
               'auth_attempts_total',
               'Total authentication attempts',
               ['result', 'method']
           )

           self.model_predictions = Counter(
               'model_predictions_total',
               'Total model predictions',
               ['model_id', 'result']
           )

           self.data_access = Counter(
               'data_access_total',
               'Total data access events',
               ['dataset', 'operation']
           )

           # Histograms
           self.prediction_latency = Histogram(
               'prediction_latency_seconds',
               'Model prediction latency',
               ['model_id']
           )

           # Gauges
           self.active_sessions = Gauge(
               'active_sessions',
               'Number of active user sessions'
           )

           self.compliance_score = Gauge(
               'compliance_score',
               'Overall compliance score (0-100)'
           )

       def record_auth_attempt(self, result: str, method: str):
           self.auth_attempts.labels(result=result, method=method).inc()

       def record_prediction(self, model_id: str, latency: float, result: str):
           self.model_predictions.labels(model_id=model_id, result=result).inc()
           self.prediction_latency.labels(model_id=model_id).observe(latency)

       def update_compliance_score(self, score: float):
           self.compliance_score.set(score)
   ```

4. Create Grafana dashboard:
   ```json
   {
     "dashboard": {
       "title": "Security Metrics Dashboard",
       "panels": [
         {
           "title": "Authentication Success Rate",
           "targets": [
             {
               "expr": "rate(auth_attempts_total{result=\"success\"}[5m]) / rate(auth_attempts_total[5m])"
             }
           ]
         },
         {
           "title": "Failed Authentication Rate",
           "targets": [
             {
               "expr": "rate(auth_attempts_total{result=\"failure\"}[5m])"
             }
           ]
         },
         {
           "title": "Model Prediction Latency (p99)",
           "targets": [
             {
               "expr": "histogram_quantile(0.99, rate(prediction_latency_seconds_bucket[5m]))"
             }
           ]
         },
         {
           "title": "Compliance Score",
           "targets": [
             {
               "expr": "compliance_score"
             }
           ]
         }
       ]
     }
   }
   ```

**Part 3: Automated Detection (30 minutes)**

5. Create anomaly detection script:
   ```python
   from elasticsearch import Elasticsearch
   from sklearn.ensemble import IsolationForest
   import numpy as np

   class AnomalyDetector:
       def __init__(self, es_client: Elasticsearch):
           self.es = es_client
           self.model = IsolationForest(contamination=0.1)

       def detect_anomalies(self, index: str = "ml-logs-*"):
           # Fetch recent events
           response = self.es.search(
               index=index,
               body={
                   "size": 1000,
                   "query": {
                       "range": {
                           "@timestamp": {
                               "gte": "now-1h"
                           }
                       }
                   }
               }
           )

           # Extract features
           features = []
           events = []
           for hit in response['hits']['hits']:
               event = hit['_source']
               features.append([
                   event.get('latency_ms', 0),
                   1 if event.get('result') == 'failure' else 0,
                   len(event.get('details', {}))
               ])
               events.append(event)

           # Detect anomalies
           X = np.array(features)
           predictions = self.model.fit_predict(X)

           anomalies = [
               events[i] for i, pred in enumerate(predictions)
               if pred == -1
           ]

           return anomalies
   ```

### Success Criteria

- [ ] SIEM integration configured
- [ ] Detection rules created and active
- [ ] Security metrics exported to Prometheus
- [ ] Grafana dashboards showing KPIs
- [ ] Automated anomaly detection working
- [ ] Alerts configured for security events

### Deliverables

1. `siem/detection-rules.json`
2. `src/security_metrics.py`
3. `src/anomaly_detector.py`
4. `grafana/security-dashboard.json`
5. Documentation:
   - SIEM integration guide
   - Security metrics definitions
   - Incident response procedures

---

## Assessment Rubric

**Advanced (90-100%)**
- All exercises completed with production-ready implementations
- Comprehensive audit logging and monitoring
- Automated compliance checking with detailed reporting
- SIEM integration with custom detection rules
- Excellent documentation

**Proficient (75-89%)**
- Core functionality working
- Good audit and compliance practices
- Basic SIEM integration
- Clear documentation

**Developing (60-74%)**
- Most exercises completed
- Basic logging and compliance
- Limited SIEM integration
- Minimal documentation

**Needs Improvement (<60%)**
- Incomplete implementations
- Missing compliance controls
- No SIEM integration
- Poor documentation
