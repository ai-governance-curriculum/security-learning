# Audit, Logging & Compliance

## Table of Contents

1. [Audit Logging for ML Systems](#audit-logging-for-ml-systems)
2. [Centralized Logging](#centralized-logging)
3. [Compliance Monitoring Automation](#compliance-monitoring-automation)
4. [SIEM Integration](#siem-integration)
5. [Security Metrics and KPIs](#security-metrics-and-kpis)

---

## 1. Audit Logging for ML Systems

### 1.1 What to Audit in ML Systems

ML systems require comprehensive audit logging beyond traditional application logs:

**Critical Audit Events**:

1. **Data Access**
   - Training data access (who, when, what data)
   - Feature store queries
   - PII/sensitive data access
   - Data export operations

2. **Model Operations**
   - Model training initiated (parameters, data version)
   - Model registration (version, metadata)
   - Model deployment (environment, approver)
   - Model predictions (inputs, outputs, latency)
   - Model deletion or archival

3. **Access Control**
   - Authentication attempts (success/failure)
   - Authorization decisions (allow/deny)
   - Permission changes
   - API key creation/revocation

4. **Infrastructure Changes**
   - Kubernetes resource modifications
   - IAM policy changes
   - Network security group updates
   - Secrets access (Vault audit log)

5. **Security Events**
   - Failed authentication attempts
   - Privilege escalation attempts
   - Suspicious API usage patterns
   - Container runtime anomalies (Falco alerts)

### 1.2 Structured Audit Logging

**Python Audit Logger**:

```python
# audit_logger.py
import json
import logging
from datetime import datetime
from typing import Dict, Any, Optional
from enum import Enum
import uuid

class AuditEventType(Enum):
    """Audit event types for ML systems"""
    DATA_ACCESS = "data.access"
    DATA_EXPORT = "data.export"
    MODEL_TRAIN = "model.train"
    MODEL_REGISTER = "model.register"
    MODEL_DEPLOY = "model.deploy"
    MODEL_PREDICT = "model.predict"
    MODEL_DELETE = "model.delete"
    AUTH_SUCCESS = "auth.success"
    AUTH_FAILURE = "auth.failure"
    AUTHZ_ALLOW = "authz.allow"
    AUTHZ_DENY = "authz.deny"
    IAM_CHANGE = "iam.change"
    SECRET_ACCESS = "secret.access"
    SECURITY_ALERT = "security.alert"

class AuditLogger:
    """
    Structured audit logger for ML systems

    Logs are JSON formatted for easy parsing and analysis
    """

    def __init__(self, service_name: str):
        self.service_name = service_name
        self.logger = logging.getLogger(f"audit.{service_name}")
        self.logger.setLevel(logging.INFO)

        # JSON formatter
        handler = logging.StreamHandler()
        handler.setFormatter(logging.Formatter('%(message)s'))
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
        """
        Log audit event

        Args:
            event_type: Type of event
            actor: Who performed the action (user ID, service account)
            resource: What was accessed (data path, model ID)
            action: What action was performed (read, write, delete)
            result: Outcome (success, failure, denied)
            details: Additional context
            ip_address: Source IP
        """
        event = {
            "timestamp": datetime.utcnow().isoformat(),
            "event_id": str(uuid.uuid4()),
            "service": self.service_name,
            "event_type": event_type.value,
            "actor": {
                "id": actor,
                "ip_address": ip_address
            },
            "resource": resource,
            "action": action,
            "result": result,
            "details": details or {}
        }

        self.logger.info(json.dumps(event))

    def log_data_access(
        self,
        actor: str,
        dataset_id: str,
        operation: str,
        row_count: Optional[int] = None,
        contains_pii: bool = False
    ):
        """Log data access event"""
        self.log_event(
            event_type=AuditEventType.DATA_ACCESS,
            actor=actor,
            resource=dataset_id,
            action=operation,
            result="success",
            details={
                "row_count": row_count,
                "contains_pii": contains_pii
            }
        )

    def log_model_prediction(
        self,
        actor: str,
        model_id: str,
        model_version: str,
        latency_ms: float,
        input_hash: str
    ):
        """Log model prediction event"""
        self.log_event(
            event_type=AuditEventType.MODEL_PREDICT,
            actor=actor,
            resource=f"{model_id}:{model_version}",
            action="predict",
            result="success",
            details={
                "latency_ms": latency_ms,
                "input_hash": input_hash
            }
        )

    def log_auth_failure(
        self,
        actor: str,
        reason: str,
        ip_address: str
    ):
        """Log authentication failure"""
        self.log_event(
            event_type=AuditEventType.AUTH_FAILURE,
            actor=actor,
            resource="authentication",
            action="login",
            result="failure",
            details={"reason": reason},
            ip_address=ip_address
        )


# Usage in ML service
audit_logger = AuditLogger(service_name="ml-inference")

# Log data access
audit_logger.log_data_access(
    actor="user@company.com",
    dataset_id="s3://ml-data/customer-features/",
    operation="read",
    row_count=10000,
    contains_pii=True
)

# Log prediction
audit_logger.log_model_prediction(
    actor="api-key-abc123",
    model_id="fraud-detection",
    model_version="v2.3.1",
    latency_ms=45.2,
    input_hash="sha256:abc..."
)
```

### 1.3 Kubernetes Audit Logging

**Enable Kubernetes Audit Logging**:

```yaml
# kube-apiserver-audit-policy.yaml
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
  # Log all requests to secrets in ml namespaces
  - level: RequestResponse
    namespaces: ["ml-production", "ml-staging"]
    verbs: ["get", "list", "create", "update", "patch", "delete"]
    resources:
      - group: ""
        resources: ["secrets"]

  # Log pod exec/attach in ml namespaces
  - level: Request
    namespaces: ["ml-production", "ml-staging"]
    verbs: ["create"]
    resources:
      - group: ""
        resources: ["pods/exec", "pods/attach"]

  # Log all authz decisions
  - level: Metadata
    omitStages:
      - "RequestReceived"

  # Log all pod creations with full request body
  - level: RequestResponse
    resources:
      - group: ""
        resources: ["pods"]
    verbs: ["create"]

  # Log service account token requests
  - level: Metadata
    resources:
      - group: "authentication.k8s.io"
        resources: ["tokenreviews"]

  # Don't log read-only requests to non-sensitive resources
  - level: None
    verbs: ["get", "list", "watch"]
    resources:
      - group: ""
        resources: ["events", "namespaces", "nodes"]
```

**Configure kube-apiserver**:

```bash
# kube-apiserver flags
--audit-log-path=/var/log/kubernetes/audit.log
--audit-log-maxage=30
--audit-log-maxbackup=10
--audit-log-maxsize=100
--audit-policy-file=/etc/kubernetes/audit-policy.yaml
```

### 1.4 MLflow Audit Logging

**MLflow with Audit Plugin**:

```python
# mlflow_audit_plugin.py
from mlflow.tracking.context.abstract_context import RunContextProvider
from mlflow.utils.mlflow_tags import MLFLOW_USER
import logging
import json

class AuditRunContextProvider(RunContextProvider):
    """
    MLflow plugin to add audit metadata to all runs
    """

    def in_context(self):
        return True

    def tags(self):
        """Add audit tags to every run"""
        import os
        import socket
        from datetime import datetime

        return {
            "audit.user": os.environ.get("USER", "unknown"),
            "audit.hostname": socket.gethostname(),
            "audit.timestamp": datetime.utcnow().isoformat(),
            "audit.session_id": os.environ.get("SESSION_ID", "unknown")
        }


# Register plugin in setup.py entry_points:
# entry_points={
#     "mlflow.run_context_provider": [
#         "audit=mlflow_audit_plugin:AuditRunContextProvider"
#     ]
# }


# Hook into MLflow to log all operations
import mlflow
from mlflow.tracking import MlflowClient

original_log_model = mlflow.log_model

def audited_log_model(*args, **kwargs):
    """Wrapper to audit model logging"""
    audit_logger = logging.getLogger("mlflow.audit")

    try:
        result = original_log_model(*args, **kwargs)

        audit_logger.info(json.dumps({
            "event": "model.logged",
            "run_id": mlflow.active_run().info.run_id,
            "user": mlflow.active_run().data.tags.get(MLFLOW_USER),
            "artifact_path": args[1] if len(args) > 1 else kwargs.get('artifact_path')
        }))

        return result
    except Exception as e:
        audit_logger.error(json.dumps({
            "event": "model.log.failed",
            "error": str(e)
        }))
        raise

mlflow.log_model = audited_log_model
```

---

## 2. Centralized Logging

### 2.1 ELK Stack for ML Logs

**Elasticsearch, Logstash, Kibana deployment**:

```yaml
# elk/elasticsearch.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: elasticsearch
  namespace: logging
spec:
  serviceName: elasticsearch
  replicas: 3
  selector:
    matchLabels:
      app: elasticsearch
  template:
    metadata:
      labels:
        app: elasticsearch
    spec:
      initContainers:
        - name: increase-vm-max-map
          image: busybox
          command: ["sysctl", "-w", "vm.max_map_count=262144"]
          securityContext:
            privileged: true
      containers:
        - name: elasticsearch
          image: docker.elastic.co/elasticsearch/elasticsearch:8.10.0
          env:
            - name: cluster.name
              value: "ml-logs"
            - name: node.name
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
            - name: discovery.seed_hosts
              value: "elasticsearch-0.elasticsearch,elasticsearch-1.elasticsearch,elasticsearch-2.elasticsearch"
            - name: cluster.initial_master_nodes
              value: "elasticsearch-0,elasticsearch-1,elasticsearch-2"
            - name: ES_JAVA_OPTS
              value: "-Xms2g -Xmx2g"
          ports:
            - containerPort: 9200
              name: http
            - containerPort: 9300
              name: transport
          volumeMounts:
            - name: data
              mountPath: /usr/share/elasticsearch/data
  volumeClaimTemplates:
    - metadata:
        name: data
      spec:
        accessModes: ["ReadWriteOnce"]
        resources:
          requests:
            storage: 100Gi
```

**Logstash Pipeline**:

```ruby
# logstash/pipeline/ml-audit.conf
input {
  # Kubernetes logs via Filebeat
  beats {
    port => 5044
  }

  # Direct syslog from applications
  syslog {
    port => 5140
    type => "ml-audit"
  }
}

filter {
  # Parse JSON logs
  if [message] =~ /^\{/ {
    json {
      source => "message"
    }
  }

  # Add GeoIP for source IPs
  if [actor][ip_address] {
    geoip {
      source => "[actor][ip_address]"
      target => "geoip"
    }
  }

  # Classify event severity
  if [event_type] =~ /failure|alert|denied/ {
    mutate {
      add_field => { "severity" => "high" }
    }
  }

  # Extract model information
  if [event_type] == "model.predict" {
    grok {
      match => { "resource" => "%{DATA:model_id}:%{DATA:model_version}" }
    }
  }

  # Add timestamp parsing
  date {
    match => [ "timestamp", "ISO8601" ]
    target => "@timestamp"
  }
}

output {
  # Send to Elasticsearch
  elasticsearch {
    hosts => ["elasticsearch:9200"]
    index => "ml-audit-%{+YYYY.MM.dd}"
    document_id => "%{event_id}"
  }

  # Send high-severity events to alerting system
  if [severity] == "high" {
    http {
      url => "http://alertmanager:9093/api/v1/alerts"
      http_method => "post"
      format => "json"
      mapping => {
        "labels" => {
          "alertname" => "%{event_type}"
          "severity" => "critical"
          "service" => "%{service}"
        }
        "annotations" => {
          "summary" => "%{event_type} from %{actor}"
          "description" => "%{message}"
        }
      }
    }
  }

  # Debug output
  stdout {
    codec => rubydebug
  }
}
```

### 2.2 Loki for Kubernetes Logs

**Grafana Loki Stack**:

```yaml
# loki/loki-stack.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: loki-config
  namespace: logging
data:
  loki.yaml: |
    auth_enabled: false

    server:
      http_listen_port: 3100

    ingester:
      lifecycler:
        address: 127.0.0.1
        ring:
          kvstore:
            store: inmemory
          replication_factor: 1
      chunk_idle_period: 5m
      chunk_retain_period: 30s

    schema_config:
      configs:
        - from: 2023-01-01
          store: boltdb-shipper
          object_store: s3
          schema: v11
          index:
            prefix: loki_index_
            period: 24h

    storage_config:
      boltdb_shipper:
        active_index_directory: /loki/index
        cache_location: /loki/index_cache
        shared_store: s3
      aws:
        s3: s3://us-west-2/ml-logs-bucket
        s3forcepathstyle: false

    limits_config:
      enforce_metric_name: false
      reject_old_samples: true
      reject_old_samples_max_age: 168h
      ingestion_rate_mb: 10
      ingestion_burst_size_mb: 20

    chunk_store_config:
      max_look_back_period: 0s

    table_manager:
      retention_deletes_enabled: true
      retention_period: 2160h  # 90 days

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: loki
  namespace: logging
spec:
  replicas: 1
  selector:
    matchLabels:
      app: loki
  template:
    metadata:
      labels:
        app: loki
    spec:
      containers:
        - name: loki
          image: grafana/loki:2.9.0
          args:
            - -config.file=/etc/loki/loki.yaml
          ports:
            - containerPort: 3100
              name: http
          volumeMounts:
            - name: config
              mountPath: /etc/loki
            - name: storage
              mountPath: /loki
      volumes:
        - name: config
          configMap:
            name: loki-config
        - name: storage
          persistentVolumeClaim:
            claimName: loki-pvc
```

**Promtail for Log Collection**:

```yaml
# loki/promtail.yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: promtail
  namespace: logging
spec:
  selector:
    matchLabels:
      app: promtail
  template:
    metadata:
      labels:
        app: promtail
    spec:
      serviceAccountName: promtail
      containers:
        - name: promtail
          image: grafana/promtail:2.9.0
          args:
            - -config.file=/etc/promtail/promtail.yaml
          volumeMounts:
            - name: config
              mountPath: /etc/promtail
            - name: varlog
              mountPath: /var/log
            - name: varlibdockercontainers
              mountPath: /var/lib/docker/containers
              readOnly: true
          env:
            - name: HOSTNAME
              valueFrom:
                fieldRef:
                  fieldPath: spec.nodeName
      volumes:
        - name: config
          configMap:
            name: promtail-config
        - name: varlog
          hostPath:
            path: /var/log
        - name: varlibdockercontainers
          hostPath:
            path: /var/lib/docker/containers

---
apiVersion: v1
kind: ConfigMap
metadata:
  name: promtail-config
  namespace: logging
data:
  promtail.yaml: |
    server:
      http_listen_port: 9080
      grpc_listen_port: 0

    positions:
      filename: /tmp/positions.yaml

    clients:
      - url: http://loki:3100/loki/api/v1/push

    scrape_configs:
      # Scrape ML namespace pods
      - job_name: kubernetes-pods-ml
        kubernetes_sd_configs:
          - role: pod
            namespaces:
              names:
                - ml-production
                - ml-staging
        relabel_configs:
          - source_labels: [__meta_kubernetes_pod_label_app]
            target_label: app
          - source_labels: [__meta_kubernetes_pod_name]
            target_label: pod
          - source_labels: [__meta_kubernetes_namespace]
            target_label: namespace
          - source_labels: [__meta_kubernetes_pod_container_name]
            target_label: container

      # Scrape audit logs
      - job_name: kubernetes-audit
        static_configs:
          - targets:
              - localhost
            labels:
              job: kubernetes-audit
              __path__: /var/log/kubernetes/audit.log
```

### 2.3 Log Retention and Archival

**S3 Lifecycle Policy for Log Archival**:

```python
# log_archival.py
import boto3
from datetime import datetime, timedelta

def setup_log_archival(bucket_name: str):
    """
    Configure S3 lifecycle policy for log archival

    - Hot tier (S3 Standard): 30 days
    - Warm tier (S3 IA): 30-90 days
    - Cold tier (S3 Glacier): 90 days - 7 years
    - Delete after 7 years
    """
    s3 = boto3.client('s3')

    lifecycle_policy = {
        'Rules': [
            {
                'Id': 'ml-audit-log-lifecycle',
                'Status': 'Enabled',
                'Filter': {
                    'Prefix': 'ml-audit-logs/'
                },
                'Transitions': [
                    {
                        'Days': 30,
                        'StorageClass': 'STANDARD_IA'
                    },
                    {
                        'Days': 90,
                        'StorageClass': 'GLACIER'
                    }
                ],
                'Expiration': {
                    'Days': 2555  # 7 years
                }
            },
            {
                'Id': 'ml-application-log-lifecycle',
                'Status': 'Enabled',
                'Filter': {
                    'Prefix': 'ml-application-logs/'
                },
                'Transitions': [
                    {
                        'Days': 7,
                        'StorageClass': 'STANDARD_IA'
                    },
                    {
                        'Days': 30,
                        'StorageClass': 'GLACIER'
                    }
                ],
                'Expiration': {
                    'Days': 365  # 1 year
                }
            }
        ]
    }

    s3.put_bucket_lifecycle_configuration(
        Bucket=bucket_name,
        LifecycleConfiguration=lifecycle_policy
    )

    print(f"Lifecycle policy configured for {bucket_name}")


# Usage
setup_log_archival("ml-logs-archive")
```

---

## 3. Compliance Monitoring Automation

### 3.1 Continuous Compliance Scanning

**AWS Config for Compliance**:

```hcl
# compliance/aws-config.tf
resource "aws_config_configuration_recorder" "ml_compliance" {
  name     = "ml-compliance-recorder"
  role_arn = aws_iam_role.config_role.arn

  recording_group {
    all_supported = true
    include_global_resource_types = true
  }
}

resource "aws_config_delivery_channel" "ml_compliance" {
  name           = "ml-compliance-channel"
  s3_bucket_name = aws_s3_bucket.config_logs.bucket

  depends_on = [aws_config_configuration_recorder.ml_compliance]
}

# Config rule: Check if S3 buckets have encryption
resource "aws_config_config_rule" "s3_encryption" {
  name = "ml-s3-bucket-encryption-enabled"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED"
  }

  scope {
    compliance_resource_types = ["AWS::S3::Bucket"]
  }
}

# Config rule: Check if RDS instances are encrypted
resource "aws_config_config_rule" "rds_encryption" {
  name = "ml-rds-storage-encrypted"

  source {
    owner             = "AWS"
    source_identifier = "RDS_STORAGE_ENCRYPTED"
  }

  scope {
    compliance_resource_types = ["AWS::RDS::DBInstance"]
  }
}

# Config rule: Check IAM password policy
resource "aws_config_config_rule" "iam_password_policy" {
  name = "ml-iam-password-policy"

  source {
    owner             = "AWS"
    source_identifier = "IAM_PASSWORD_POLICY"
  }

  input_parameters = jsonencode({
    RequireUppercaseCharacters = true
    RequireLowercaseCharacters = true
    RequireSymbols = true
    RequireNumbers = true
    MinimumPasswordLength = 14
    PasswordReusePrevention = 24
    MaxPasswordAge = 90
  })
}

# Config rule: Check if CloudTrail is enabled
resource "aws_config_config_rule" "cloudtrail_enabled" {
  name = "ml-cloudtrail-enabled"

  source {
    owner             = "AWS"
    source_identifier = "CLOUD_TRAIL_ENABLED"
  }
}
```

### 3.2 Policy-as-Code with OPA

**OPA Policies for Compliance**:

```rego
# compliance/gdpr_compliance.rego
package ml.compliance.gdpr

import data.ml.metadata

# GDPR Compliance Rules

# Rule: PII data must be encrypted at rest
pii_encrypted {
    dataset := input.dataset
    dataset.metadata.contains_pii == true
    dataset.encryption.enabled == true
    dataset.encryption.algorithm == "AES-256"
}

violation[{"msg": msg}] {
    dataset := input.dataset
    dataset.metadata.contains_pii == true
    not dataset.encryption.enabled
    msg := sprintf("Dataset %v contains PII but is not encrypted", [dataset.id])
}

# Rule: Data retention period must be specified for PII
pii_retention_specified {
    dataset := input.dataset
    dataset.metadata.contains_pii == true
    dataset.retention_days > 0
}

violation[{"msg": msg}] {
    dataset := input.dataset
    dataset.metadata.contains_pii == true
    not dataset.retention_days
    msg := sprintf("Dataset %v contains PII but has no retention policy", [dataset.id])
}

# Rule: Data processing must have legal basis
legal_basis_documented {
    processing := input.processing
    processing.legal_basis != ""
    processing.legal_basis in ["consent", "contract", "legal_obligation", "vital_interests", "public_task", "legitimate_interests"]
}

violation[{"msg": msg}] {
    processing := input.processing
    not processing.legal_basis
    msg := sprintf("Data processing %v has no documented legal basis", [processing.id])
}

# Rule: Data subject rights must be supported
data_subject_rights_supported {
    system := input.system
    required_rights := ["access", "rectification", "erasure", "portability"]
    supported := {right | right := system.supported_rights[_]}
    required := {right | right := required_rights[_]}
    supported & required == required
}

violation[{"msg": msg}] {
    not data_subject_rights_supported
    msg := "System does not support all required data subject rights (access, rectification, erasure, portability)"
}
```

**Automated Compliance Checks**:

```python
# compliance_checker.py
import requests
import json
from typing import List, Dict

class ComplianceChecker:
    """
    Automated compliance checker using OPA
    """

    def __init__(self, opa_url: str = "http://opa:8181"):
        self.opa_url = opa_url

    def check_gdpr_compliance(self, resource: Dict) -> List[Dict]:
        """
        Check GDPR compliance for resource

        Returns:
            List of violations
        """
        response = requests.post(
            f"{self.opa_url}/v1/data/ml/compliance/gdpr/violation",
            json={"input": resource}
        )

        result = response.json()
        return result.get("result", [])

    def check_all_datasets(self, datasets: List[Dict]) -> Dict:
        """
        Check compliance for all datasets

        Returns:
            Summary of violations
        """
        violations = {}

        for dataset in datasets:
            dataset_violations = self.check_gdpr_compliance({
                "dataset": dataset
            })

            if dataset_violations:
                violations[dataset['id']] = dataset_violations

        return violations

    def generate_compliance_report(self) -> str:
        """Generate compliance report"""
        # Fetch all resources
        datasets = self._fetch_datasets()
        processing_activities = self._fetch_processing_activities()

        # Check compliance
        dataset_violations = {}
        for dataset in datasets:
            viols = self.check_gdpr_compliance({"dataset": dataset})
            if viols:
                dataset_violations[dataset['id']] = viols

        # Generate report
        report = "# GDPR Compliance Report\n\n"
        report += f"Generated: {datetime.utcnow().isoformat()}\n\n"

        if not dataset_violations:
            report += "✓ All datasets are compliant\n"
        else:
            report += f"❌ Found {len(dataset_violations)} non-compliant datasets:\n\n"

            for dataset_id, violations in dataset_violations.items():
                report += f"## Dataset: {dataset_id}\n\n"
                for violation in violations:
                    report += f"- {violation['msg']}\n"
                report += "\n"

        return report

    def _fetch_datasets(self) -> List[Dict]:
        """Fetch all datasets from metadata store"""
        # Implementation depends on metadata store
        return []

    def _fetch_processing_activities(self) -> List[Dict]:
        """Fetch all data processing activities"""
        return []


# Usage
checker = ComplianceChecker()
report = checker.generate_compliance_report()
print(report)
```

### 3.3 Automated Evidence Collection

**Compliance Evidence Collector**:

```python
# evidence_collector.py
import boto3
from datetime import datetime, timedelta
from typing import Dict, List
import json

class ComplianceEvidenceCollector:
    """
    Collect evidence for compliance audits
    """

    def __init__(self):
        self.s3 = boto3.client('s3')
        self.config = boto3.client('config')
        self.iam = boto3.client('iam')

    def collect_encryption_evidence(self) -> Dict:
        """Collect evidence that data is encrypted"""
        evidence = {
            "timestamp": datetime.utcnow().isoformat(),
            "requirement": "Data encryption at rest",
            "s3_buckets": [],
            "rds_instances": []
        }

        # Check S3 bucket encryption
        s3_resource = boto3.resource('s3')
        for bucket in s3_resource.buckets.all():
            try:
                encryption = self.s3.get_bucket_encryption(Bucket=bucket.name)
                evidence['s3_buckets'].append({
                    "bucket": bucket.name,
                    "encrypted": True,
                    "algorithm": encryption['ServerSideEncryptionConfiguration']['Rules'][0]['ApplyServerSideEncryptionByDefault']['SSEAlgorithm']
                })
            except:
                evidence['s3_buckets'].append({
                    "bucket": bucket.name,
                    "encrypted": False
                })

        # Check RDS encryption
        rds = boto3.client('rds')
        for db in rds.describe_db_instances()['DBInstances']:
            evidence['rds_instances'].append({
                "instance": db['DBInstanceIdentifier'],
                "encrypted": db['StorageEncrypted']
            })

        return evidence

    def collect_access_control_evidence(self) -> Dict:
        """Collect evidence of access controls"""
        evidence = {
            "timestamp": datetime.utcnow().isoformat(),
            "requirement": "Access control enforcement",
            "mfa_enabled": [],
            "password_policy": {}
        }

        # Check MFA for IAM users
        for user in self.iam.list_users()['Users']:
            mfa_devices = self.iam.list_mfa_devices(
                UserName=user['UserName']
            )['MFADevices']

            evidence['mfa_enabled'].append({
                "user": user['UserName'],
                "mfa_enabled": len(mfa_devices) > 0
            })

        # Check password policy
        try:
            policy = self.iam.get_account_password_policy()
            evidence['password_policy'] = policy['PasswordPolicy']
        except:
            evidence['password_policy'] = None

        return evidence

    def collect_audit_log_evidence(self, days: int = 90) -> Dict:
        """Collect evidence that audit logging is enabled"""
        evidence = {
            "timestamp": datetime.utcnow().isoformat(),
            "requirement": "Audit logging",
            "cloudtrail": {},
            "vpc_flow_logs": []
        }

        # Check CloudTrail
        cloudtrail = boto3.client('cloudtrail')
        trails = cloudtrail.describe_trails()['trailList']

        if trails:
            trail = trails[0]
            status = cloudtrail.get_trail_status(Name=trail['TrailARN'])

            evidence['cloudtrail'] = {
                "enabled": status['IsLogging'],
                "trail_name": trail['Name'],
                "s3_bucket": trail['S3BucketName'],
                "log_file_validation_enabled": trail.get('LogFileValidationEnabled', False)
            }

        # Check VPC Flow Logs
        ec2 = boto3.client('ec2')
        vpcs = ec2.describe_vpcs()['Vpcs']

        for vpc in vpcs:
            flow_logs = ec2.describe_flow_logs(
                Filters=[{'Name': 'resource-id', 'Values': [vpc['VpcId']]}]
            )['FlowLogs']

            evidence['vpc_flow_logs'].append({
                "vpc_id": vpc['VpcId'],
                "flow_logs_enabled": len(flow_logs) > 0
            })

        return evidence

    def generate_evidence_bundle(self, output_path: str):
        """Generate complete evidence bundle for audit"""
        bundle = {
            "generated_at": datetime.utcnow().isoformat(),
            "evidence": {
                "encryption": self.collect_encryption_evidence(),
                "access_control": self.collect_access_control_evidence(),
                "audit_logging": self.collect_audit_log_evidence()
            }
        }

        # Save to file
        with open(output_path, 'w') as f:
            json.dump(bundle, f, indent=2)

        # Upload to S3 for archival
        self.s3.upload_file(
            output_path,
            'compliance-evidence-bucket',
            f"evidence-bundle-{datetime.utcnow().strftime('%Y%m%d')}.json"
        )

        print(f"Evidence bundle generated: {output_path}")


# Usage
collector = ComplianceEvidenceCollector()
collector.generate_evidence_bundle("compliance-evidence.json")
```

---

## 4. SIEM Integration

### 4.1 Splunk Integration

**Splunk Forwarder for ML Logs**:

```bash
# Install Splunk Universal Forwarder
wget -O splunkforwarder.tgz 'https://download.splunk.com/products/universalforwarder/releases/9.1.0/linux/splunkforwarder-9.1.0-linux-x86_64.tgz'
tar xvzf splunkforwarder.tgz
cd splunkforwarder
./bin/splunk start --accept-license
./bin/splunk enable boot-start

# Configure inputs
cat > /opt/splunkforwarder/etc/system/local/inputs.conf <<EOF
[monitor:///var/log/ml-audit/*.log]
disabled = false
sourcetype = ml_audit
index = ml_security

[monitor:///var/log/kubernetes/audit.log]
disabled = false
sourcetype = kubernetes_audit
index = kubernetes_security

[monitor:///var/log/containers/*ml-*.log]
disabled = false
sourcetype = ml_application
index = ml_application
EOF

# Configure outputs
cat > /opt/splunkforwarder/etc/system/local/outputs.conf <<EOF
[tcpout]
defaultGroup = splunk_indexers

[tcpout:splunk_indexers]
server = splunk-indexer.company.com:9997
compressed = true
EOF

# Restart
./bin/splunk restart
```

**Splunk Searches for ML Security**:

```spl
# Failed authentication attempts
index=ml_security sourcetype=ml_audit event_type=auth.failure
| stats count by actor.id, actor.ip_address
| where count > 5
| sort -count

# Suspicious data export
index=ml_security sourcetype=ml_audit event_type=data.export
| eval data_size_gb=details.row_count*details.avg_row_size_bytes/1024/1024/1024
| where data_size_gb > 100
| table _time, actor.id, resource, data_size_gb

# Model predictions with high latency
index=ml_application sourcetype=ml_audit event_type=model.predict
| where details.latency_ms > 1000
| stats avg(details.latency_ms) as avg_latency, max(details.latency_ms) as max_latency, count by resource
| sort -avg_latency

# Unauthorized API access attempts
index=ml_security sourcetype=ml_audit result=denied
| stats count by event_type, actor.id, resource
| where count > 10
```

### 4.2 Elastic SIEM

**SIEM Rules for ML Systems**:

```yaml
# elastic-siem/ml-security-rules.yml
rules:
  - name: "Multiple failed ML API authentication attempts"
    type: "threshold"
    query: >
      event_type:auth.failure AND service:ml-inference
    threshold:
      value: 5
      field: "actor.id"
      timeframe: "5m"
    severity: "high"
    actions:
      - alert_slack
      - create_ticket

  - name: "Unusual data access pattern"
    type: "anomaly"
    query: >
      event_type:data.access
    ml_job: "data_access_anomaly"
    severity: "medium"
    actions:
      - alert_email

  - name: "Model deployment without approval"
    type: "query"
    query: >
      event_type:model.deploy AND NOT details.approval_ticket:*
    severity: "critical"
    actions:
      - alert_security_team
      - block_deployment

  - name: "Privileged secret access"
    type: "query"
    query: >
      event_type:secret.access AND resource:*/admin/* OR resource:*/root/*
    severity: "high"
    actions:
      - alert_security_team
      - log_detailed_audit
```

---

## 5. Security Metrics and KPIs

### 5.1 Security Metrics Dashboard

**Prometheus Metrics**:

```python
# security_metrics.py
from prometheus_client import Counter, Histogram, Gauge, start_http_server
from functools import wraps
import time

# Authentication metrics
auth_attempts = Counter(
    'ml_auth_attempts_total',
    'Total authentication attempts',
    ['result', 'method']
)

auth_failures = Counter(
    'ml_auth_failures_total',
    'Failed authentication attempts',
    ['reason']
)

# Authorization metrics
authz_decisions = Counter(
    'ml_authz_decisions_total',
    'Authorization decisions',
    ['result', 'resource_type']
)

# Data access metrics
data_access_count = Counter(
    'ml_data_access_total',
    'Total data access operations',
    ['dataset', 'contains_pii']
)

data_access_size = Histogram(
    'ml_data_access_rows',
    'Number of rows accessed',
    ['dataset']
)

# Model metrics
model_predictions = Counter(
    'ml_model_predictions_total',
    'Total model predictions',
    ['model_id', 'version']
)

model_prediction_latency = Histogram(
    'ml_model_prediction_latency_seconds',
    'Model prediction latency',
    ['model_id', 'version']
)

# Security incident metrics
security_incidents = Counter(
    'ml_security_incidents_total',
    'Security incidents detected',
    ['type', 'severity']
)

# Compliance metrics
compliance_violations = Gauge(
    'ml_compliance_violations',
    'Current compliance violations',
    ['requirement', 'severity']
)


def track_authentication(func):
    """Decorator to track authentication attempts"""
    @wraps(func)
    def wrapper(*args, **kwargs):
        try:
            result = func(*args, **kwargs)
            auth_attempts.labels(result='success', method='jwt').inc()
            return result
        except Exception as e:
            auth_attempts.labels(result='failure', method='jwt').inc()
            auth_failures.labels(reason=str(type(e).__name__)).inc()
            raise
    return wrapper


def track_prediction(func):
    """Decorator to track model predictions"""
    @wraps(func)
    def wrapper(model_id, version, *args, **kwargs):
        start = time.time()
        try:
            result = func(model_id, version, *args, **kwargs)
            latency = time.time() - start

            model_predictions.labels(
                model_id=model_id,
                version=version
            ).inc()

            model_prediction_latency.labels(
                model_id=model_id,
                version=version
            ).observe(latency)

            return result
        except Exception as e:
            # Track failed predictions
            security_incidents.labels(
                type='prediction_error',
                severity='medium'
            ).inc()
            raise
    return wrapper


# Start metrics server
start_http_server(8000)
```

**Grafana Dashboard (JSON)**:

```json
{
  "dashboard": {
    "title": "ML Security Metrics",
    "panels": [
      {
        "title": "Authentication Attempts",
        "targets": [
          {
            "expr": "rate(ml_auth_attempts_total[5m])",
            "legendFormat": "{{result}}"
          }
        ],
        "type": "graph"
      },
      {
        "title": "Failed Auth Attempts by Reason",
        "targets": [
          {
            "expr": "sum by (reason) (ml_auth_failures_total)",
            "legendFormat": "{{reason}}"
          }
        ],
        "type": "piechart"
      },
      {
        "title": "Data Access with PII",
        "targets": [
          {
            "expr": "ml_data_access_total{contains_pii=\"true\"}",
            "legendFormat": "{{dataset}}"
          }
        ],
        "type": "graph"
      },
      {
        "title": "Model Prediction Latency p95",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, rate(ml_model_prediction_latency_seconds_bucket[5m]))",
            "legendFormat": "{{model_id}}"
          }
        ],
        "type": "graph"
      },
      {
        "title": "Security Incidents",
        "targets": [
          {
            "expr": "sum by (type, severity) (ml_security_incidents_total)",
            "legendFormat": "{{type}} ({{severity}})"
          }
        ],
        "type": "table"
      },
      {
        "title": "Compliance Violations",
        "targets": [
          {
            "expr": "ml_compliance_violations",
            "legendFormat": "{{requirement}}"
          }
        ],
        "type": "stat"
      }
    ]
  }
}
```

### 5.2 Security KPIs

**Track Key Security Metrics**:

```python
# security_kpis.py
from dataclasses import dataclass
from datetime import datetime, timedelta
from typing import List, Dict
import json

@dataclass
class SecurityKPI:
    name: str
    value: float
    target: float
    unit: str
    trend: str  # "improving", "stable", "degrading"
    timestamp: str

class SecurityKPITracker:
    """
    Track and report security KPIs
    """

    def __init__(self, prometheus_url: str):
        self.prometheus_url = prometheus_url

    def calculate_kpis(self) -> List[SecurityKPI]:
        """Calculate all security KPIs"""
        kpis = []

        # KPI 1: Mean Time to Detect (MTTD)
        mttd = self._calculate_mttd()
        kpis.append(SecurityKPI(
            name="Mean Time to Detect",
            value=mttd,
            target=15.0,  # 15 minutes
            unit="minutes",
            trend="improving" if mttd < 15 else "degrading",
            timestamp=datetime.utcnow().isoformat()
        ))

        # KPI 2: Mean Time to Respond (MTTR)
        mttr = self._calculate_mttr()
        kpis.append(SecurityKPI(
            name="Mean Time to Respond",
            value=mttr,
            target=60.0,  # 1 hour
            unit="minutes",
            trend="improving" if mttr < 60 else "degrading",
            timestamp=datetime.utcnow().isoformat()
        ))

        # KPI 3: Authentication Success Rate
        auth_success_rate = self._calculate_auth_success_rate()
        kpis.append(SecurityKPI(
            name="Authentication Success Rate",
            value=auth_success_rate,
            target=98.0,
            unit="percent",
            trend="improving" if auth_success_rate > 98 else "degrading",
            timestamp=datetime.utcnow().isoformat()
        ))

        # KPI 4: Patch Compliance Rate
        patch_compliance = self._calculate_patch_compliance()
        kpis.append(SecurityKPI(
            name="Patch Compliance Rate",
            value=patch_compliance,
            target=95.0,
            unit="percent",
            trend="improving" if patch_compliance > 95 else "degrading",
            timestamp=datetime.utcnow().isoformat()
        ))

        # KPI 5: High/Critical Vulnerabilities Open
        open_vulns = self._count_open_high_critical_vulns()
        kpis.append(SecurityKPI(
            name="Open High/Critical Vulnerabilities",
            value=open_vulns,
            target=0.0,
            unit="count",
            trend="improving" if open_vulns == 0 else "degrading",
            timestamp=datetime.utcnow().isoformat()
        ))

        return kpis

    def _calculate_mttd(self) -> float:
        """Calculate Mean Time to Detect"""
        # Query incident detection times from database
        # Return average time in minutes
        return 12.5  # Placeholder

    def _calculate_mttr(self) -> float:
        """Calculate Mean Time to Respond"""
        # Query incident response times
        return 45.0  # Placeholder

    def _calculate_auth_success_rate(self) -> float:
        """Calculate authentication success rate"""
        # Query Prometheus for auth metrics
        return 99.2  # Placeholder

    def _calculate_patch_compliance(self) -> float:
        """Calculate percentage of systems with latest patches"""
        return 96.5  # Placeholder

    def _count_open_high_critical_vulns(self) -> int:
        """Count open high/critical vulnerabilities"""
        return 3  # Placeholder

    def generate_kpi_report(self) -> str:
        """Generate KPI report"""
        kpis = self.calculate_kpis()

        report = "# Security KPI Report\n\n"
        report += f"Generated: {datetime.utcnow().isoformat()}\n\n"

        report += "| KPI | Current | Target | Status |\n"
        report += "|-----|---------|--------|--------|\n"

        for kpi in kpis:
            status = "✓" if kpi.value <= kpi.target else "❌"
            report += f"| {kpi.name} | {kpi.value} {kpi.unit} | {kpi.target} {kpi.unit} | {status} |\n"

        return report


# Usage
tracker = SecurityKPITracker(prometheus_url="http://prometheus:9090")
report = tracker.generate_kpi_report()
print(report)
```

---

## Summary

Comprehensive audit, logging, and compliance for ML systems requires:

1. **Audit Logging**: Structured logs for all security-relevant events
2. **Centralized Logging**: ELK/Loki for log aggregation and analysis
3. **Compliance Automation**: Policy-as-code with OPA, automated evidence collection
4. **SIEM Integration**: Real-time security monitoring and alerting
5. **Security Metrics**: Track KPIs for continuous improvement

**Key Takeaways**:

- Log all security-relevant events in structured format
- Centralize logs for correlation and analysis
- Automate compliance checking with policy-as-code
- Integrate with SIEM for real-time threat detection
- Track security KPIs to measure effectiveness
- Archive logs for regulatory requirements (7 years for some regulations)

---

**Next Module**: [Module 8: Incident Response & Recovery](../mod-008-incident-response/lecture-notes/01-incident-response.md)
