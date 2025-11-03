# Module 8: Incident Response & Recovery - Exercises

## Overview

These exercises provide hands-on experience with incident response, model compromise detection, digital forensics, disaster recovery, and post-incident analysis for ML systems.

**Total Time**: 10-13 hours
**Prerequisites**:
- Completed Modules 1-7
- Understanding of incident response frameworks
- Familiarity with forensics concepts
- Access to Kubernetes cluster
- Python programming skills

---

## Exercise 1: Incident Response Framework Implementation

**Time**: 3-4 hours
**Difficulty**: Advanced

### Objectives

- Implement NIST incident response lifecycle
- Create automated incident response playbooks
- Set up incident classification and tracking
- Build automated response workflows
- Implement evidence collection automation

### Tasks

**Part 1: Incident Response Framework (1 hour)**

1. Create incident classification system:
   ```python
   from enum import Enum
   from dataclasses import dataclass
   from datetime import datetime
   from typing import List, Optional

   class IncidentSeverity(Enum):
       SEV1 = "critical"      # Complete service outage, data breach
       SEV2 = "high"          # Major functionality impaired
       SEV3 = "medium"        # Minor functionality impaired
       SEV4 = "low"           # Minimal impact, informational

   class IncidentCategory(Enum):
       MODEL_COMPROMISE = "model_compromise"
       DATA_BREACH = "data_breach"
       UNAUTHORIZED_ACCESS = "unauthorized_access"
       DOS_ATTACK = "dos_attack"
       MALWARE = "malware"
       POLICY_VIOLATION = "policy_violation"

   @dataclass
   class Incident:
       incident_id: str
       title: str
       category: IncidentCategory
       severity: IncidentSeverity
       detected_at: datetime
       detected_by: str
       description: str
       affected_systems: List[str]
       status: str = "open"  # open, investigating, contained, resolved, closed
       assigned_to: Optional[str] = None
       timeline: List[dict] = None

       def __post_init__(self):
           if self.timeline is None:
               self.timeline = []

       def add_timeline_event(self, event: str, actor: str):
           self.timeline.append({
               "timestamp": datetime.utcnow().isoformat(),
               "event": event,
               "actor": actor
           })

       def escalate(self, new_severity: IncidentSeverity, reason: str):
           """Escalate incident severity."""
           old_severity = self.severity
           self.severity = new_severity
           self.add_timeline_event(
               f"Escalated from {old_severity.value} to {new_severity.value}: {reason}",
               "system"
           )

       def assign(self, assignee: str):
           """Assign incident to responder."""
           self.assigned_to = assignee
           self.add_timeline_event(f"Assigned to {assignee}", "system")

       def update_status(self, new_status: str, actor: str):
           """Update incident status."""
           old_status = self.status
           self.status = new_status
           self.add_timeline_event(
               f"Status changed from {old_status} to {new_status}",
               actor
           )
   ```

2. Create incident response coordinator:
   ```python
   import json
   from typing import Dict, List
   import boto3
   from slack_sdk import WebClient

   class IncidentResponseCoordinator:
       def __init__(self):
           self.incidents: Dict[str, Incident] = {}
           self.slack_client = WebClient(token=os.environ["SLACK_TOKEN"])
           self.sns = boto3.client('sns')

       def create_incident(
           self,
           title: str,
           category: IncidentCategory,
           severity: IncidentSeverity,
           description: str,
           affected_systems: List[str],
           detected_by: str
       ) -> Incident:
           """Create new incident and trigger response."""
           incident_id = f"INC-{datetime.utcnow().strftime('%Y%m%d-%H%M%S')}"

           incident = Incident(
               incident_id=incident_id,
               title=title,
               category=category,
               severity=severity,
               detected_at=datetime.utcnow(),
               detected_by=detected_by,
               description=description,
               affected_systems=affected_systems
           )

           self.incidents[incident_id] = incident

           # Trigger automated response
           self._trigger_response(incident)

           return incident

       def _trigger_response(self, incident: Incident):
           """Trigger automated incident response."""
           # Create Slack channel
           self._create_incident_channel(incident)

           # Notify team
           self._notify_team(incident)

           # Auto-assign based on severity
           if incident.severity == IncidentSeverity.SEV1:
               self._page_oncall()

           # Execute automated playbook
           playbook_name = self._get_playbook(incident)
           if playbook_name:
               self._execute_playbook(playbook_name, incident)

       def _create_incident_channel(self, incident: Incident):
           """Create dedicated Slack channel for incident."""
           channel_name = f"incident-{incident.incident_id.lower()}"

           response = self.slack_client.conversations_create(
               name=channel_name,
               is_private=False
           )

           channel_id = response['channel']['id']

           # Post initial message
           self.slack_client.chat_postMessage(
               channel=channel_id,
               text=f"""
   🚨 *New {incident.severity.value.upper()} Incident*

   *Incident ID*: {incident.incident_id}
   *Title*: {incident.title}
   *Category*: {incident.category.value}
   *Detected By*: {incident.detected_by}
   *Affected Systems*: {', '.join(incident.affected_systems)}

   *Description*: {incident.description}
               """
           )

           return channel_id

       def _notify_team(self, incident: Incident):
           """Send notifications via SNS and Slack."""
           message = f"""
   Incident {incident.incident_id} ({incident.severity.value})
   Title: {incident.title}
   Category: {incident.category.value}
   Affected: {', '.join(incident.affected_systems)}
           """

           # SNS notification
           self.sns.publish(
               TopicArn=os.environ["INCIDENT_SNS_TOPIC"],
               Subject=f"[{incident.severity.value.upper()}] {incident.title}",
               Message=message
           )

       def _page_oncall(self):
           """Page on-call engineer for SEV1."""
           self.sns.publish(
               TopicArn=os.environ["ONCALL_SNS_TOPIC"],
               Subject="SEV1 Incident - Immediate Response Required",
               Message="Critical incident detected. Check incident channel."
           )

       def _get_playbook(self, incident: Incident) -> Optional[str]:
           """Get appropriate playbook for incident."""
           playbook_map = {
               IncidentCategory.MODEL_COMPROMISE: "model_compromise",
               IncidentCategory.DATA_BREACH: "data_breach",
               IncidentCategory.UNAUTHORIZED_ACCESS: "unauthorized_access",
               IncidentCategory.DOS_ATTACK: "dos_mitigation"
           }
           return playbook_map.get(incident.category)

       def _execute_playbook(self, playbook_name: str, incident: Incident):
           """Execute automated incident response playbook."""
           playbook_path = f"playbooks/{playbook_name}.yaml"
           executor = PlaybookExecutor(playbook_path)
           executor.execute(incident.incident_id)
   ```

**Part 2: Automated Playbook Execution (1.5 hours)**

3. Create playbook executor:
   ```python
   import yaml
   import subprocess
   from typing import Dict, Any

   class PlaybookExecutor:
       def __init__(self, playbook_path: str):
           with open(playbook_path, 'r') as f:
               self.playbook = yaml.safe_load(f)

       def execute(self, incident_id: str):
           """Execute all phases of playbook."""
           print(f"Executing playbook for incident {incident_id}")

           for phase in self.playbook['phases']:
               print(f"\n=== Phase: {phase['phase']} ===")
               for step in phase['steps']:
                   self._execute_step(step, incident_id)

       def _execute_step(self, step: Dict[str, Any], incident_id: str):
           """Execute a single playbook step."""
           action = step['action']
           print(f"  [{action}] {step['description']}")

           # Execute based on action type
           if action == "isolate_system":
               self._isolate_system(step['params'])
           elif action == "revoke_credentials":
               self._revoke_credentials(incident_id)
           elif action == "collect_evidence":
               self._collect_evidence(step['params'])
           elif action == "block_ip":
               self._block_ip(step['params']['ip_address'])
           elif action == "rollback_model":
               self._rollback_model(step['params'])
           elif action == "notify":
               self._send_notification(step['params'])

       def _isolate_system(self, params: Dict):
           """Isolate compromised system."""
           namespace = params['namespace']
           pod_name = params['pod_name']

           # Apply network policy to isolate pod
           policy = f"""
   apiVersion: networking.k8s.io/v1
   kind: NetworkPolicy
   metadata:
     name: isolate-{pod_name}
     namespace: {namespace}
   spec:
     podSelector:
       matchLabels:
         app: {pod_name}
     policyTypes:
     - Ingress
     - Egress
   """

           with open('/tmp/isolation-policy.yaml', 'w') as f:
               f.write(policy)

           subprocess.run([
               'kubectl', 'apply', '-f', '/tmp/isolation-policy.yaml'
           ])

           print(f"    ✓ Isolated {pod_name} in {namespace}")

       def _revoke_credentials(self, incident_id: str):
           """Revoke compromised credentials."""
           # Get compromised credentials from incident
           credentials = self._get_compromised_credentials(incident_id)

           for cred in credentials:
               if cred['type'] == 'aws_key':
                   # Revoke AWS access key
                   iam = boto3.client('iam')
                   iam.delete_access_key(
                       UserName=cred['user'],
                       AccessKeyId=cred['key_id']
                   )
                   print(f"    ✓ Revoked AWS key for {cred['user']}")

               elif cred['type'] == 'api_key':
                   # Revoke API key via API
                   requests.delete(
                       f"https://api.example.com/keys/{cred['key_id']}",
                       headers={"Authorization": f"Bearer {admin_token}"}
                   )
                   print(f"    ✓ Revoked API key {cred['key_id']}")

       def _block_ip(self, ip_address: str):
           """Block malicious IP address."""
           # Update AWS Security Group
           ec2 = boto3.client('ec2')
           ec2.revoke_security_group_ingress(
               GroupId='sg-xxxxx',
               IpPermissions=[{
                   'IpProtocol': 'tcp',
                   'FromPort': 443,
                   'ToPort': 443,
                   'IpRanges': [{'CidrIp': f'{ip_address}/32'}]
               }]
           )

           print(f"    ✓ Blocked IP {ip_address}")

       def _rollback_model(self, params: Dict):
           """Rollback to previous model version."""
           model_name = params['model_name']
           previous_version = params['previous_version']

           # Update Kubernetes deployment
           subprocess.run([
               'kubectl', 'set', 'image',
               f'deployment/{model_name}',
               f'{model_name}=registry.example.com/{model_name}:{previous_version}',
               '-n', 'ml-production'
           ])

           print(f"    ✓ Rolled back {model_name} to {previous_version}")
   ```

4. Create sample playbook YAML:
   ```yaml
   # playbooks/model_compromise.yaml
   name: "Model Compromise Response"
   description: "Automated response for compromised ML model"

   phases:
     - phase: "Detection & Analysis"
       steps:
         - action: "collect_evidence"
           description: "Collect logs and artifacts"
           params:
             logs: ["/var/log/ml-inference/*.log"]
             artifacts: ["model.pkl", "config.yaml"]

         - action: "notify"
           description: "Notify security team"
           params:
             channels: ["#security-incidents"]
             severity: "high"

     - phase: "Containment"
       steps:
         - action: "isolate_system"
           description: "Isolate compromised pods"
           params:
             namespace: "ml-production"
             pod_name: "ml-inference"

         - action: "rollback_model"
           description: "Rollback to last known good model"
           params:
             model_name: "fraud-detection"
             previous_version: "v2.0.1"

         - action: "revoke_credentials"
           description: "Revoke potentially compromised credentials"
           params:
             scope: "incident"

     - phase: "Eradication"
       steps:
         - action: "block_ip"
           description: "Block attacker IP addresses"
           params:
             ip_address: "{{attacker_ip}}"

         - action: "patch_vulnerability"
           description: "Apply security patches"
           params:
             systems: ["ml-inference-service"]

     - phase: "Recovery"
       steps:
         - action: "deploy_clean_model"
           description: "Deploy verified clean model"
           params:
             model_name: "fraud-detection"
             version: "v2.1.0"
             verification: "signature_check"

         - action: "restore_access"
           description: "Restore access with new credentials"
           params:
             systems: ["ml-inference"]

     - phase: "Post-Incident"
       steps:
         - action: "generate_report"
           description: "Generate incident report"
           params:
             template: "model_compromise"

         - action: "schedule_postmortem"
           description: "Schedule post-mortem meeting"
           params:
             participants: ["security-team", "ml-team", "engineering-lead"]
   ```

**Part 3: Evidence Collection (1 hour)**

5. Create evidence collector:
   ```bash
   #!/bin/bash
   # scripts/collect_evidence.sh

   INCIDENT_ID=$1
   EVIDENCE_DIR="/tmp/evidence/${INCIDENT_ID}"
   TIMESTAMP=$(date +%Y%m%d-%H%M%S)

   echo "=== Collecting evidence for ${INCIDENT_ID} ==="

   mkdir -p "${EVIDENCE_DIR}"

   # Collect pod logs
   echo "[1/6] Collecting pod logs..."
   kubectl get pods -n ml-production -o json > "${EVIDENCE_DIR}/pods.json"
   kubectl logs -n ml-production -l app=ml-inference --all-containers=true \
     > "${EVIDENCE_DIR}/ml-inference-logs.txt"

   # Collect events
   echo "[2/6] Collecting Kubernetes events..."
   kubectl get events -n ml-production --sort-by='.lastTimestamp' \
     > "${EVIDENCE_DIR}/k8s-events.txt"

   # Collect network policies
   echo "[3/6] Collecting network policies..."
   kubectl get networkpolicies -n ml-production -o yaml \
     > "${EVIDENCE_DIR}/network-policies.yaml"

   # Collect audit logs
   echo "[4/6] Collecting audit logs..."
   cp /var/log/kubernetes/audit.log "${EVIDENCE_DIR}/"

   # Collect model artifacts
   echo "[5/6] Collecting model artifacts..."
   kubectl exec -n ml-production deploy/ml-inference -- \
     tar czf - /app/models > "${EVIDENCE_DIR}/models.tar.gz"

   # Generate checksums
   echo "[6/6] Generating checksums..."
   cd "${EVIDENCE_DIR}"
   find . -type f -exec sha256sum {} \; > checksums.txt

   # Create evidence package
   cd /tmp/evidence
   tar czf "${INCIDENT_ID}-evidence-${TIMESTAMP}.tar.gz" "${INCIDENT_ID}/"

   # Upload to S3
   aws s3 cp "${INCIDENT_ID}-evidence-${TIMESTAMP}.tar.gz" \
     "s3://incident-evidence/${INCIDENT_ID}/"

   echo "✓ Evidence collected: ${INCIDENT_ID}-evidence-${TIMESTAMP}.tar.gz"
   ```

**Part 4: Testing (30 minutes)**

6. Create incident simulation script:
   ```python
   # test_incident_response.py
   import time

   def simulate_model_compromise():
       """Simulate model compromise incident."""
       coordinator = IncidentResponseCoordinator()

       # Create incident
       incident = coordinator.create_incident(
           title="Suspicious Model Predictions Detected",
           category=IncidentCategory.MODEL_COMPROMISE,
           severity=IncidentSeverity.SEV2,
           description="Automated monitoring detected anomalous prediction patterns",
           affected_systems=["ml-inference-prod", "fraud-detection-model"],
           detected_by="automated-monitoring"
       )

       print(f"Created incident: {incident.incident_id}")

       # Simulate investigation
       time.sleep(2)
       incident.update_status("investigating", "security-team")

       # Simulate escalation
       incident.escalate(
           IncidentSeverity.SEV1,
           "Confirmed model backdoor detected"
       )

       # Simulate containment
       time.sleep(2)
       incident.update_status("contained", "security-team")

       # Print timeline
       print("\n=== Incident Timeline ===")
       for event in incident.timeline:
           print(f"{event['timestamp']}: {event['event']} (by {event['actor']})")

   if __name__ == "__main__":
       simulate_model_compromise()
   ```

### Success Criteria

- [ ] Incident response framework implemented
- [ ] Automated playbooks executing successfully
- [ ] Incident classification and tracking working
- [ ] Evidence collection automated
- [ ] Notification system integrated (Slack, PagerDuty)
- [ ] Playbooks cover major incident types

### Deliverables

1. `src/incident_response.py`
2. `src/playbook_executor.py`
3. `playbooks/` directory with YAML playbooks
4. `scripts/collect_evidence.sh`
5. Documentation:
   - Incident response procedures
   - Playbook documentation
   - Escalation matrix

---

## Exercise 2: Model Compromise Detection

**Time**: 3-4 hours
**Difficulty**: Advanced

### Objectives

- Implement model integrity verification
- Create behavioral anomaly detection
- Detect model backdoors
- Set up automated alerting for compromises
- Build forensics toolkit for model analysis

### Tasks

**Part 1: Model Integrity Checking (1 hour)**

1. Create model integrity checker (see lecture notes for full implementation)

2. Create checksum database:
   ```python
   import json
   from pathlib import Path

   class ModelChecksumDB:
       def __init__(self, db_path: str = "model_checksums.json"):
           self.db_path = db_path
           self.checksums = self._load_db()

       def _load_db(self) -> dict:
           if Path(self.db_path).exists():
               with open(self.db_path, 'r') as f:
                   return json.load(f)
           return {}

       def register_model(
           self,
           model_id: str,
           version: str,
           model_path: str,
           metadata: dict
       ):
           """Register new model with checksums."""
           checker = ModelIntegrityChecker({})
           hash_sha256 = checker._hash_file(model_path)

           key = f"{model_id}:{version}"
           self.checksums[key] = {
               "model_id": model_id,
               "version": version,
               "hash_sha256": hash_sha256,
               "registered_at": datetime.utcnow().isoformat(),
               "metadata": metadata
           }

           self._save_db()
           print(f"✓ Registered {key} with hash {hash_sha256[:16]}...")

       def _save_db(self):
           with open(self.db_path, 'w') as f:
               json.dump(self.checksums, f, indent=2)

   # Usage
   db = ModelChecksumDB()
   db.register_model(
       model_id="fraud-detection",
       version="v2.1.0",
       model_path="models/fraud_detection_v2.1.0.pkl",
       metadata={"training_date": "2025-01-15", "accuracy": 0.95}
   )
   ```

**Part 2: Behavioral Anomaly Detection (1.5 hours)**

3. Implement prediction monitoring:
   ```python
   from collections import deque
   import numpy as np
   from scipy import stats

   class PredictionMonitor:
       def __init__(self, window_size: int = 1000):
           self.window_size = window_size
           self.predictions = deque(maxlen=window_size)
           self.confidence_scores = deque(maxlen=window_size)
           self.latencies = deque(maxlen=window_size)

       def record_prediction(
           self,
           prediction: float,
           confidence: float,
           latency_ms: float
       ):
           """Record prediction for monitoring."""
           self.predictions.append(prediction)
           self.confidence_scores.append(confidence)
           self.latencies.append(latency_ms)

       def detect_anomalies(self) -> List[str]:
           """Detect anomalous prediction patterns."""
           anomalies = []

           # Check prediction distribution shift
           if len(self.predictions) >= 100:
               recent = list(self.predictions)[-100:]
               historical = list(self.predictions)[:-100]

               if len(historical) >= 100:
                   # Kolmogorov-Smirnov test for distribution shift
                   statistic, pvalue = stats.ks_2samp(historical, recent)

                   if pvalue < 0.01:
                       anomalies.append(
                           f"Prediction distribution shift detected (p={pvalue:.4f})"
                       )

           # Check confidence drop
           if len(self.confidence_scores) >= 100:
               recent_confidence = np.mean(list(self.confidence_scores)[-100:])
               historical_confidence = np.mean(list(self.confidence_scores)[:-100])

               if recent_confidence < historical_confidence * 0.8:
                   anomalies.append(
                       f"Confidence drop: {recent_confidence:.2f} vs {historical_confidence:.2f}"
                   )

           # Check latency increase
           if len(self.latencies) >= 100:
               recent_latency = np.mean(list(self.latencies)[-100:])
               historical_latency = np.mean(list(self.latencies)[:-100])

               if recent_latency > historical_latency * 1.5:
                   anomalies.append(
                       f"Latency increase: {recent_latency:.1f}ms vs {historical_latency:.1f}ms"
                   )

           return anomalies
   ```

**Part 3: Backdoor Detection (1 hour)**

4. Implement activation clustering:
   ```python
   from sklearn.cluster import KMeans
   from sklearn.decomposition import PCA

   class BackdoorDetector:
       def __init__(self, model, clean_dataset):
           self.model = model
           self.clean_dataset = clean_dataset

       def detect_backdoor_activation_clustering(
           self,
           test_samples: np.ndarray,
           n_clusters: int = 2
       ) -> dict:
           """Detect backdoor using activation clustering."""
           # Extract activations from penultimate layer
           clean_activations = self._extract_activations(self.clean_dataset)
           test_activations = self._extract_activations(test_samples)

           # Reduce dimensionality
           pca = PCA(n_components=50)
           clean_reduced = pca.fit_transform(clean_activations)
           test_reduced = pca.transform(test_activations)

           # Cluster
           kmeans = KMeans(n_clusters=n_clusters, random_state=42)
           clean_labels = kmeans.fit_predict(clean_reduced)

           # Check if test samples form separate cluster
           test_labels = kmeans.predict(test_reduced)

           # Calculate silhouette score
           from sklearn.metrics import silhouette_score
           all_data = np.vstack([clean_reduced, test_reduced])
           all_labels = np.concatenate([clean_labels, test_labels])

           score = silhouette_score(all_data, all_labels)

           # High score indicates distinct clusters (potential backdoor)
           backdoor_detected = score > 0.5

           return {
               "backdoor_detected": backdoor_detected,
               "silhouette_score": score,
               "test_cluster_distribution": np.bincount(test_labels).tolist()
           }

       def _extract_activations(self, data: np.ndarray) -> np.ndarray:
           """Extract activations from penultimate layer."""
           # This is model-specific - adjust for your framework
           import torch
           activations = []

           with torch.no_grad():
               for batch in data:
                   output = self.model.penultimate_layer(batch)
                   activations.append(output.cpu().numpy())

           return np.vstack(activations)
   ```

**Part 4: Automated Alerting (30 minutes)**

5. Create monitoring dashboard:
   ```python
   from fastapi import FastAPI
   from prometheus_client import Counter, Histogram, Gauge

   app = FastAPI()

   # Metrics
   integrity_checks = Counter(
       'model_integrity_checks_total',
       'Total integrity checks',
       ['model_id', 'result']
   )

   anomaly_detections = Counter(
       'prediction_anomalies_total',
       'Anomalous predictions detected',
       ['model_id', 'anomaly_type']
   )

   backdoor_alerts = Counter(
       'backdoor_detections_total',
       'Backdoor detections',
       ['model_id']
   )

   @app.post("/check_model/{model_id}")
   async def check_model(model_id: str, version: str):
       """Endpoint to trigger model integrity check."""
       checker = ModelIntegrityChecker(checksums_db)

       is_valid = checker.verify_model(
           model_path=f"models/{model_id}_{version}.pkl",
           model_id=model_id,
           version=version
       )

       integrity_checks.labels(
           model_id=model_id,
           result="pass" if is_valid else "fail"
       ).inc()

       if not is_valid:
           # Trigger incident
           coordinator.create_incident(
               title=f"Model Integrity Check Failed: {model_id}",
               category=IncidentCategory.MODEL_COMPROMISE,
               severity=IncidentSeverity.SEV1,
               description=f"Hash mismatch for {model_id} version {version}",
               affected_systems=[model_id],
               detected_by="integrity-monitor"
           )

       return {"model_id": model_id, "valid": is_valid}
   ```

### Success Criteria

- [ ] Model integrity checking automated
- [ ] Behavioral anomaly detection working
- [ ] Backdoor detection implemented
- [ ] Automated alerts for compromises
- [ ] Dashboard showing model health metrics

### Deliverables

1. `src/model_integrity.py`
2. `src/prediction_monitor.py`
3. `src/backdoor_detector.py`
4. `k8s/model-monitoring.yaml`
5. Documentation:
   - Integrity verification guide
   - Anomaly detection tuning guide
   - Response procedures

---

## Exercise 3: Digital Forensics and Log Analysis

**Time**: 2-3 hours
**Difficulty**: Intermediate

### Objectives

- Perform log analysis for incident investigation
- Extract and preserve evidence
- Analyze attack patterns
- Create forensics reports
- Build timeline of events

### Tasks

**Part 1: Log Analysis (1 hour)**

1. Create log analyzer (see lecture notes for full script)

2. Create attack pattern detector:
   ```python
   import re
   from collections import defaultdict

   class AttackPatternDetector:
       def __init__(self, log_file: str):
           self.log_file = log_file
           self.patterns = {
               "sql_injection": r"(\%27)|(\')|(\-\-)|(\%23)|(#)",
               "xss": r"(<script>)|(<iframe>)|(<object>)",
               "path_traversal": r"(\.\./)|(\.\\.\\)",
               "command_injection": r"(;.*\||&&.*\||`.*`)",
               "brute_force": r"401|403"
           }

       def detect_patterns(self) -> Dict[str, List[str]]:
           """Detect attack patterns in logs."""
           detections = defaultdict(list)

           with open(self.log_file, 'r') as f:
               for line in f:
                   for attack_type, pattern in self.patterns.items():
                       if re.search(pattern, line, re.IGNORECASE):
                           detections[attack_type].append(line.strip())

           return dict(detections)

       def analyze_brute_force(self) -> Dict[str, int]:
           """Analyze brute force attempts."""
           failed_attempts = defaultdict(int)

           with open(self.log_file, 'r') as f:
               for line in f:
                   if '"result":"failure"' in line:
                       # Extract IP address
                       match = re.search(r'"ip_address":"([^"]+)"', line)
                       if match:
                           ip = match.group(1)
                           failed_attempts[ip] += 1

           # Filter IPs with > 10 attempts
           suspicious = {
               ip: count for ip, count in failed_attempts.items()
               if count > 10
           }

           return suspicious
   ```

**Part 2: Evidence Preservation (1 hour)**

3. Create evidence chain of custody:
   ```python
   from dataclasses import dataclass
   from typing import List
   import hashlib

   @dataclass
   class EvidenceItem:
       item_id: str
       description: str
       source: str
       collected_at: datetime
       collected_by: str
       hash_sha256: str
       custody_chain: List[dict]

       def transfer_custody(self, from_person: str, to_person: str, reason: str):
           """Transfer evidence custody."""
           self.custody_chain.append({
               "timestamp": datetime.utcnow().isoformat(),
               "from": from_person,
               "to": to_person,
               "reason": reason
           })

   class EvidenceManager:
       def __init__(self):
           self.evidence: Dict[str, EvidenceItem] = {}

       def collect_evidence(
           self,
           description: str,
           source_path: str,
           collector: str
       ) -> EvidenceItem:
           """Collect and register evidence."""
           # Calculate hash
           with open(source_path, 'rb') as f:
               file_hash = hashlib.sha256(f.read()).hexdigest()

           # Create evidence ID
           evidence_id = f"EVD-{datetime.utcnow().strftime('%Y%m%d%H%M%S')}"

           # Create evidence item
           evidence = EvidenceItem(
               item_id=evidence_id,
               description=description,
               source=source_path,
               collected_at=datetime.utcnow(),
               collected_by=collector,
               hash_sha256=file_hash,
               custody_chain=[{
                   "timestamp": datetime.utcnow().isoformat(),
                   "from": "system",
                   "to": collector,
                   "reason": "initial collection"
               }]
           )

           self.evidence[evidence_id] = evidence

           # Copy to evidence locker
           evidence_path = f"/evidence/{evidence_id}/{Path(source_path).name}"
           shutil.copy2(source_path, evidence_path)

           return evidence

       def verify_integrity(self, evidence_id: str) -> bool:
           """Verify evidence has not been tampered with."""
           evidence = self.evidence[evidence_id]
           evidence_path = f"/evidence/{evidence_id}/*"

           # Recalculate hash
           for path in Path(f"/evidence/{evidence_id}").glob("*"):
               with open(path, 'rb') as f:
                   current_hash = hashlib.sha256(f.read()).hexdigest()

               if current_hash != evidence.hash_sha256:
                   return False

           return True
   ```

**Part 3: Forensics Report Generation (30 minutes)**

4. Create forensics report generator:
   ```python
   from jinja2 import Template

   class ForensicsReportGenerator:
       def generate_report(
           self,
           incident_id: str,
           incident: Incident,
           evidence: List[EvidenceItem],
           analysis_results: Dict
       ) -> str:
           """Generate comprehensive forensics report."""

           template = Template("""
   # Digital Forensics Report
   ## Incident {{ incident.incident_id }}

   **Generated**: {{ now }}
   **Analyst**: {{ analyst }}

   ## Executive Summary
   {{ incident.description }}

   **Severity**: {{ incident.severity.value }}
   **Category**: {{ incident.category.value }}
   **Status**: {{ incident.status }}

   ## Timeline of Events
   {% for event in incident.timeline %}
   - **{{ event.timestamp }}**: {{ event.event }} ({{ event.actor }})
   {% endfor %}

   ## Evidence Collected
   {% for item in evidence %}
   ### {{ item.item_id }}
   - **Description**: {{ item.description }}
   - **Source**: {{ item.source }}
   - **Collected By**: {{ item.collected_by }}
   - **SHA256**: {{ item.hash_sha256 }}
   {% endfor %}

   ## Analysis Results

   ### Attack Patterns Detected
   {% for pattern, occurrences in analysis_results.patterns.items() %}
   - **{{ pattern }}**: {{ occurrences|length }} occurrences
   {% endfor %}

   ### Affected Systems
   {% for system in incident.affected_systems %}
   - {{ system }}
   {% endfor %}

   ## Recommendations
   {{ recommendations }}

   ## Appendix
   - Evidence location: /evidence/{{ incident_id }}/
   - Log files: /logs/{{ incident_id }}/
           """)

           report = template.render(
               incident=incident,
               evidence=evidence,
               analysis_results=analysis_results,
               now=datetime.utcnow().isoformat(),
               analyst="Security Team",
               recommendations="See detailed recommendations in incident ticket"
           )

           return report
   ```

### Success Criteria

- [ ] Log analysis identifying attack patterns
- [ ] Evidence collected with chain of custody
- [ ] Timeline of events reconstructed
- [ ] Forensics report generated
- [ ] Evidence integrity verified

### Deliverables

1. `src/log_analyzer.py`
2. `src/attack_pattern_detector.py`
3. `src/evidence_manager.py`
4. `src/forensics_report.py`
5. Sample forensics report

---

## Exercise 4: Disaster Recovery Testing

**Time**: 2-3 hours
**Difficulty**: Intermediate

### Objectives

- Implement automated backup procedures
- Test disaster recovery scenarios
- Validate RTO/RPO requirements
- Create recovery runbooks
- Perform failover testing

### Tasks

**Part 1: Backup Automation (1 hour)**

1. Create backup script:
   ```bash
   #!/bin/bash
   # scripts/backup_ml_system.sh

   BACKUP_DATE=$(date +%Y%m%d-%H%M%S)
   BACKUP_BASE="/backups/${BACKUP_DATE}"
   S3_BUCKET="s3://ml-backups"

   echo "=== ML System Backup - ${BACKUP_DATE} ==="

   # Backup models
   echo "[1/5] Backing up models..."
   mkdir -p "${BACKUP_BASE}/models"
   kubectl exec -n ml-production deploy/ml-inference -- \
     tar czf - /app/models | \
     tar xzf - -C "${BACKUP_BASE}/models"

   # Backup model registry (MLflow database)
   echo "[2/5] Backing up model registry..."
   kubectl exec -n mlflow deploy/mlflow-tracking -- \
     pg_dump -U mlflow mlflow_db > "${BACKUP_BASE}/mlflow_db.sql"

   # Backup configurations
   echo "[3/5] Backing up configurations..."
   kubectl get configmaps -n ml-production -o yaml > \
     "${BACKUP_BASE}/configmaps.yaml"
   kubectl get secrets -n ml-production -o yaml > \
     "${BACKUP_BASE}/secrets.yaml"

   # Backup persistent volumes
   echo "[4/5] Backing up persistent volumes..."
   kubectl get pv -o yaml > "${BACKUP_BASE}/persistent_volumes.yaml"

   # Create backup manifest
   echo "[5/5] Creating manifest..."
   cat > "${BACKUP_BASE}/manifest.json" <<EOF
   {
     "backup_date": "${BACKUP_DATE}",
     "components": ["models", "registry", "configs", "volumes"],
     "size_mb": $(du -sm "${BACKUP_BASE}" | cut -f1)
   }
   EOF

   # Upload to S3
   aws s3 sync "${BACKUP_BASE}" "${S3_BUCKET}/${BACKUP_DATE}/"

   echo "✓ Backup complete: ${S3_BUCKET}/${BACKUP_DATE}/"
   ```

**Part 2: DR Testing (1 hour)**

2. Create DR test script:
   ```python
   import time
   from datetime import datetime

   class DRTester:
       def __init__(self):
           self.results = []

       def test_model_recovery(self) -> dict:
           """Test model backup and restore."""
           start_time = time.time()

           # Simulate model corruption
           print("Simulating model corruption...")
           original_hash = self._get_model_hash("fraud-detection")

           # Restore from backup
           print("Restoring from backup...")
           subprocess.run([
               "scripts/restore_model.sh",
               "fraud-detection",
               "latest"
           ])

           # Verify restoration
           restored_hash = self._get_model_hash("fraud-detection")

           recovery_time = time.time() - start_time

           result = {
               "test": "model_recovery",
               "passed": restored_hash == original_hash,
               "recovery_time_seconds": recovery_time,
               "rto_met": recovery_time < 300  # 5 min RTO
           }

           self.results.append(result)
           return result

       def test_database_recovery(self) -> dict:
           """Test database backup and restore."""
           start_time = time.time()

           # Count records before
           records_before = self._count_mlflow_records()

           # Restore database
           subprocess.run([
               "scripts/restore_database.sh",
               "mlflow_db",
               "latest"
           ])

           # Count records after
           records_after = self._count_mlflow_records()

           recovery_time = time.time() - start_time

           result = {
               "test": "database_recovery",
               "passed": records_before == records_after,
               "recovery_time_seconds": recovery_time,
               "rpo_met": True,  # No data loss
               "records_recovered": records_after
           }

           self.results.append(result)
           return result

       def test_regional_failover(self) -> dict:
           """Test failover to secondary region."""
           start_time = time.time()

           # Trigger failover
           print("Initiating regional failover...")
           subprocess.run([
               "scripts/failover_to_region.sh",
               "us-west-2"
           ])

           # Test service availability
           time.sleep(10)
           available = self._check_service_health()

           failover_time = time.time() - start_time

           result = {
               "test": "regional_failover",
               "passed": available,
               "failover_time_seconds": failover_time,
               "rto_met": failover_time < 600  # 10 min RTO
           }

           self.results.append(result)
           return result

       def generate_report(self) -> str:
           """Generate DR test report."""
           report = f"""
   # Disaster Recovery Test Report
   **Date**: {datetime.utcnow().isoformat()}

   ## Test Results
   """

           for result in self.results:
               status = "✓ PASS" if result["passed"] else "✗ FAIL"
               report += f"\n### {result['test']}: {status}\n"
               report += f"- Recovery Time: {result.get('recovery_time_seconds', 'N/A'):.1f}s\n"
               report += f"- RTO Met: {result.get('rto_met', 'N/A')}\n"

           return report
   ```

### Success Criteria

- [ ] Automated backups running successfully
- [ ] DR tests pass with acceptable RTO/RPO
- [ ] Recovery runbooks documented and tested
- [ ] Failover procedures validated
- [ ] DR test report generated

### Deliverables

1. `scripts/backup_ml_system.sh`
2. `scripts/restore_model.sh`
3. `src/dr_tester.py`
4. DR test report
5. Recovery runbooks

---

## Assessment Rubric

**Advanced (90-100%)**
- All exercises completed with production-ready implementations
- Comprehensive incident response automation
- Advanced forensics capabilities
- Validated DR procedures with acceptable RTO/RPO
- Excellent documentation

**Proficient (75-89%)**
- Core functionality working
- Good incident response procedures
- Basic forensics and DR
- Clear documentation

**Developing (60-74%)**
- Most exercises completed
- Basic incident response
- Limited forensics
- Minimal DR testing

**Needs Improvement (<60%)**
- Incomplete implementations
- No automation
- Poor documentation
