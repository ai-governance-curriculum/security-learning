# Incident Response & Recovery

## Table of Contents

1. [Incident Response Framework](#incident-response-framework)
2. [Model Compromise Detection](#model-compromise-detection)
3. [Digital Forensics for ML Systems](#digital-forensics-for-ml-systems)
4. [Disaster Recovery Planning](#disaster-recovery-planning)
5. [Post-Incident Analysis](#post-incident-analysis)

---

## 1. Incident Response Framework

### 1.1 NIST Incident Response Lifecycle

The NIST framework defines six phases for incident response:

```
┌─────────────────────────────────────────────────────┐
│              1. PREPARATION                          │
│  - Incident response team formation                 │
│  - Playbook development                             │
│  - Tool setup (SIEM, forensics)                     │
└────────────────────┬────────────────────────────────┘
                     │
                     v
┌─────────────────────────────────────────────────────┐
│         2. DETECTION & ANALYSIS                      │
│  - Monitor alerts                                    │
│  - Triage incidents                                  │
│  - Determine scope                                   │
└────────────────────┬────────────────────────────────┘
                     │
                     v
┌─────────────────────────────────────────────────────┐
│           3. CONTAINMENT                             │
│  - Isolate affected systems                         │
│  - Prevent lateral movement                         │
│  - Preserve evidence                                 │
└────────────────────┬────────────────────────────────┘
                     │
                     v
┌─────────────────────────────────────────────────────┐
│            4. ERADICATION                            │
│  - Remove malware/backdoors                         │
│  - Patch vulnerabilities                            │
│  - Rebuild compromised systems                      │
└────────────────────┬────────────────────────────────┘
                     │
                     v
┌─────────────────────────────────────────────────────┐
│              5. RECOVERY                             │
│  - Restore services                                  │
│  - Monitor for reinfection                          │
│  - Validate integrity                                │
└────────────────────┬────────────────────────────────┘
                     │
                     v
┌─────────────────────────────────────────────────────┐
│      6. POST-INCIDENT ACTIVITY                       │
│  - Lessons learned                                   │
│  - Update playbooks                                  │
│  - Improve defenses                                  │
└─────────────────────────────────────────────────────┘
```

### 1.2 Incident Response Team Structure

**Roles and Responsibilities**:

1. **Incident Commander** (IC)
   - Overall incident coordination
   - Decision-making authority
   - Communication with stakeholders

2. **Security Analyst**
   - Alert triage and investigation
   - Threat intelligence correlation
   - Technical analysis

3. **ML Engineer**
   - Model integrity validation
   - Data pipeline investigation
   - ML-specific forensics

4. **SRE/DevOps**
   - Infrastructure containment
   - System restoration
   - Performance monitoring

5. **Legal/Compliance**
   - Regulatory notification requirements
   - Evidence handling
   - External communication

6. **Communications**
   - Internal updates
   - Customer notification
   - Media relations (if needed)

### 1.3 Incident Classification

**Severity Levels**:

```python
# incident_classification.py
from enum import Enum
from dataclasses import dataclass
from typing import List

class IncidentSeverity(Enum):
    """Incident severity levels"""
    SEV1 = "critical"      # Production down, data breach
    SEV2 = "high"          # Major service degradation
    SEV3 = "medium"        # Minor service impact
    SEV4 = "low"           # No immediate impact

class IncidentCategory(Enum):
    """ML-specific incident categories"""
    DATA_POISONING = "data_poisoning"
    MODEL_THEFT = "model_theft"
    MODEL_INVERSION = "model_inversion"
    BACKDOOR = "backdoor"
    API_ABUSE = "api_abuse"
    INFRASTRUCTURE_COMPROMISE = "infrastructure_compromise"
    DATA_BREACH = "data_breach"
    DENIAL_OF_SERVICE = "denial_of_service"

@dataclass
class Incident:
    """Incident record"""
    id: str
    title: str
    severity: IncidentSeverity
    category: IncidentCategory
    description: str
    affected_systems: List[str]
    detected_at: str
    status: str  # "new", "investigating", "contained", "resolved"
    assigned_to: str

def classify_incident(
    description: str,
    impact: str,
    affected_components: List[str]
) -> tuple[IncidentSeverity, IncidentCategory]:
    """
    Classify incident based on description and impact

    Returns:
        (severity, category)
    """
    # Check for keywords indicating severity
    if any(kw in description.lower() for kw in ['production down', 'data breach', 'ransomware']):
        severity = IncidentSeverity.SEV1
    elif any(kw in description.lower() for kw in ['service degradation', 'unauthorized access']):
        severity = IncidentSeverity.SEV2
    elif any(kw in description.lower() for kw in ['suspicious activity', 'anomaly']):
        severity = IncidentSeverity.SEV3
    else:
        severity = IncidentSeverity.SEV4

    # Determine category
    if 'training data' in description.lower() and 'modified' in description.lower():
        category = IncidentCategory.DATA_POISONING
    elif 'model' in description.lower() and 'stolen' in description.lower():
        category = IncidentCategory.MODEL_THEFT
    elif 'api' in description.lower() and 'abuse' in description.lower():
        category = IncidentCategory.API_ABUSE
    else:
        category = IncidentCategory.INFRASTRUCTURE_COMPROMISE

    return severity, category


# Usage
severity, category = classify_incident(
    description="Suspicious API requests attempting to extract model weights",
    impact="Potential model theft",
    affected_components=["ml-inference-api"]
)
print(f"Severity: {severity.value}, Category: {category.value}")
```

### 1.4 Incident Response Playbooks

**Playbook: Data Breach Response**:

```yaml
# playbooks/data-breach-response.yml
name: "Data Breach Response"
trigger:
  - "Unauthorized data access detected"
  - "Data exfiltration alert"
  - "Exposed S3 bucket"

severity: SEV1

phases:
  - phase: "Detection & Analysis"
    duration: "15 minutes"
    steps:
      - step: "Confirm breach"
        actions:
          - Check SIEM alerts
          - Review CloudTrail logs
          - Identify affected data
        owner: "Security Analyst"

      - step: "Determine scope"
        actions:
          - Count affected records
          - Identify data types (PII, credentials)
          - Timeline of access
        owner: "Security Analyst"

      - step: "Notify stakeholders"
        actions:
          - Alert Incident Commander
          - Notify Legal team
          - Notify Compliance team
        owner: "Incident Commander"

  - phase: "Containment"
    duration: "30 minutes"
    steps:
      - step: "Block access"
        actions:
          - Revoke compromised credentials
          - Update security groups to block attacker IP
          - Disable compromised API keys
        owner: "SRE"

      - step: "Isolate affected systems"
        actions:
          - Take affected instances offline
          - Snapshot affected volumes for forensics
          - Block network egress
        owner: "SRE"

      - step: "Preserve evidence"
        actions:
          - Collect logs (CloudTrail, VPC Flow, application)
          - Take memory dumps if applicable
          - Document timeline
        owner: "Security Analyst"

  - phase: "Eradication"
    duration: "2 hours"
    steps:
      - step: "Remove attacker access"
        actions:
          - Rotate all credentials
          - Patch vulnerabilities
          - Rebuild compromised systems
        owner: "SRE"

      - step: "Verify removal"
        actions:
          - Scan for backdoors
          - Check for persistence mechanisms
          - Review all access logs
        owner: "Security Analyst"

  - phase: "Recovery"
    duration: "4 hours"
    steps:
      - step: "Restore services"
        actions:
          - Deploy clean systems
          - Restore from clean backups
          - Verify functionality
        owner: "SRE"

      - step: "Enhanced monitoring"
        actions:
          - Enable detailed logging
          - Deploy additional alerts
          - Monitor for reinfection
        owner: "Security Analyst"

  - phase: "Post-Incident"
    duration: "1 week"
    steps:
      - step: "Regulatory notification"
        actions:
          - Determine notification requirements (GDPR, etc.)
          - Draft notification letters
          - File breach reports
        owner: "Legal"

      - step: "Lessons learned"
        actions:
          - Conduct post-mortem
          - Update playbooks
          - Implement preventive controls
        owner: "Incident Commander"

communication:
  internal:
    - "#incident-response" Slack channel
    - Email to security@company.com
  external:
    - Customer notification (if PII affected)
    - Regulatory authorities (if required)
```

**Playbook Automation**:

```python
# playbook_executor.py
import yaml
from typing import Dict, List
from datetime import datetime, timedelta
import requests

class PlaybookExecutor:
    """
    Automated playbook execution
    """

    def __init__(self, playbook_path: str):
        with open(playbook_path, 'r') as f:
            self.playbook = yaml.safe_load(f)

    def execute(self, incident_id: str):
        """Execute playbook for incident"""
        print(f"Executing playbook: {self.playbook['name']}")
        print(f"Incident ID: {incident_id}")

        for phase in self.playbook['phases']:
            print(f"\n=== Phase: {phase['phase']} ===")
            print(f"Estimated duration: {phase['duration']}")

            for step in phase['steps']:
                self._execute_step(step, incident_id)

    def _execute_step(self, step: Dict, incident_id: str):
        """Execute a single step"""
        print(f"\nStep: {step['step']}")
        print(f"Owner: {step['owner']}")

        for action in step['actions']:
            print(f"  - {action}")

            # Automated actions
            if "Revoke compromised credentials" in action:
                self._revoke_credentials(incident_id)
            elif "Block attacker IP" in action:
                self._block_ip(incident_id)
            elif "Alert Incident Commander" in action:
                self._send_alert(incident_id)

    def _revoke_credentials(self, incident_id: str):
        """Automatically revoke compromised credentials"""
        # Get compromised credentials from incident
        credentials = self._get_compromised_credentials(incident_id)

        for cred in credentials:
            if cred['type'] == 'aws_key':
                # Revoke AWS access key
                import boto3
                iam = boto3.client('iam')
                iam.delete_access_key(
                    UserName=cred['user'],
                    AccessKeyId=cred['key_id']
                )
                print(f"    ✓ Revoked AWS key {cred['key_id']}")

            elif cred['type'] == 'api_key':
                # Revoke API key via internal API
                response = requests.delete(
                    f"https://api.company.com/keys/{cred['key_id']}",
                    headers={'Authorization': 'Bearer admin-token'}
                )
                print(f"    ✓ Revoked API key {cred['key_id']}")

    def _block_ip(self, incident_id: str):
        """Block attacker IP at WAF/firewall"""
        ips = self._get_attacker_ips(incident_id)

        for ip in ips:
            # Add to WAF block list
            import boto3
            waf = boto3.client('wafv2')

            waf.update_ip_set(
                Name='blocked-ips',
                Scope='REGIONAL',
                Id='ip-set-id',
                Addresses=[f"{ip}/32"]
            )
            print(f"    ✓ Blocked IP {ip}")

    def _send_alert(self, incident_id: str):
        """Send alert to incident commander"""
        # Send Slack message
        requests.post(
            'https://slack.com/api/chat.postMessage',
            json={
                'channel': '#incident-response',
                'text': f'🚨 Critical incident detected: {incident_id}\n' +
                        f'Playbook: {self.playbook["name"]}\n' +
                        'Action required!'
            },
            headers={'Authorization': 'Bearer slack-token'}
        )
        print("    ✓ Alert sent")

    def _get_compromised_credentials(self, incident_id: str) -> List[Dict]:
        """Fetch compromised credentials from incident"""
        # Query incident management system
        return []

    def _get_attacker_ips(self, incident_id: str) -> List[str]:
        """Fetch attacker IPs from incident"""
        return []


# Usage
executor = PlaybookExecutor('playbooks/data-breach-response.yml')
executor.execute(incident_id='INC-2025-001')
```

---

## 2. Model Compromise Detection

### 2.1 Model Integrity Monitoring

**Model Hash Verification**:

```python
# model_integrity.py
import hashlib
import json
from pathlib import Path
from typing import Dict, Optional
from dataclasses import dataclass
from datetime import datetime

@dataclass
class ModelMetadata:
    """Model metadata for integrity checking"""
    model_id: str
    version: str
    hash_sha256: str
    file_size_bytes: int
    created_at: str
    signature: Optional[str] = None

class ModelIntegrityChecker:
    """
    Monitor model integrity and detect tampering
    """

    def __init__(self, registry_path: str):
        self.registry_path = Path(registry_path)
        self.metadata_file = self.registry_path / "model_metadata.json"
        self._load_metadata()

    def _load_metadata(self):
        """Load known-good model metadata"""
        if self.metadata_file.exists():
            with open(self.metadata_file, 'r') as f:
                data = json.load(f)
                self.metadata = {
                    k: ModelMetadata(**v) for k, v in data.items()
                }
        else:
            self.metadata = {}

    def register_model(
        self,
        model_path: str,
        model_id: str,
        version: str
    ) -> ModelMetadata:
        """
        Register model with integrity metadata

        Args:
            model_path: Path to model file
            model_id: Model identifier
            version: Model version

        Returns:
            Model metadata
        """
        # Calculate hash
        hash_sha256 = self._hash_file(model_path)

        # Get file size
        file_size = Path(model_path).stat().st_size

        # Create metadata
        metadata = ModelMetadata(
            model_id=model_id,
            version=version,
            hash_sha256=hash_sha256,
            file_size_bytes=file_size,
            created_at=datetime.utcnow().isoformat()
        )

        # Store metadata
        key = f"{model_id}:{version}"
        self.metadata[key] = metadata
        self._save_metadata()

        print(f"✓ Model registered: {key}")
        print(f"  Hash: {hash_sha256}")

        return metadata

    def verify_model(self, model_path: str, model_id: str, version: str) -> bool:
        """
        Verify model integrity

        Returns:
            True if model is intact, False if tampered
        """
        key = f"{model_id}:{version}"

        if key not in self.metadata:
            raise ValueError(f"Model {key} not registered")

        expected = self.metadata[key]

        # Calculate current hash
        current_hash = self._hash_file(model_path)

        # Compare hashes
        if current_hash != expected.hash_sha256:
            print(f"❌ TAMPERING DETECTED for {key}!")
            print(f"  Expected: {expected.hash_sha256}")
            print(f"  Current:  {current_hash}")
            return False

        # Check file size
        current_size = Path(model_path).stat().st_size
        if current_size != expected.file_size_bytes:
            print(f"❌ File size mismatch for {key}")
            return False

        print(f"✓ Model integrity verified: {key}")
        return True

    def _hash_file(self, file_path: str) -> str:
        """Calculate SHA-256 hash of file"""
        sha256 = hashlib.sha256()
        with open(file_path, 'rb') as f:
            for chunk in iter(lambda: f.read(4096), b''):
                sha256.update(chunk)
        return sha256.hexdigest()

    def _save_metadata(self):
        """Save metadata to file"""
        data = {k: v.__dict__ for k, v in self.metadata.items()}
        with open(self.metadata_file, 'w') as f:
            json.dump(data, f, indent=2)


# Usage
checker = ModelIntegrityChecker(registry_path="/models")

# Register model
checker.register_model(
    model_path="/models/fraud_detection_v2.pkl",
    model_id="fraud-detection",
    version="v2.0"
)

# Verify model before deployment
is_valid = checker.verify_model(
    model_path="/models/fraud_detection_v2.pkl",
    model_id="fraud-detection",
    version="v2.0"
)

if not is_valid:
    raise ValueError("Model integrity check failed - deployment aborted")
```

### 2.2 Behavioral Anomaly Detection

**Monitor Model Predictions for Anomalies**:

```python
# model_behavior_monitor.py
import numpy as np
from collections import deque
from typing import Dict, List
import time

class ModelBehaviorMonitor:
    """
    Detect anomalous model behavior that may indicate compromise
    """

    def __init__(self, window_size: int = 1000):
        self.window_size = window_size
        self.prediction_history = deque(maxlen=window_size)
        self.confidence_history = deque(maxlen=window_size)
        self.latency_history = deque(maxlen=window_size)

    def record_prediction(
        self,
        prediction: float,
        confidence: float,
        latency_ms: float
    ):
        """Record prediction for analysis"""
        self.prediction_history.append(prediction)
        self.confidence_history.append(confidence)
        self.latency_history.append(latency_ms)

    def detect_anomalies(self) -> List[Dict]:
        """
        Detect anomalies in model behavior

        Returns:
            List of detected anomalies
        """
        anomalies = []

        # Check for confidence drop (possible model degradation/attack)
        if len(self.confidence_history) >= 100:
            recent_confidence = np.mean(list(self.confidence_history)[-100:])
            historical_confidence = np.mean(list(self.confidence_history)[:-100])

            if recent_confidence < historical_confidence * 0.8:
                anomalies.append({
                    'type': 'confidence_drop',
                    'severity': 'high',
                    'description': f'Model confidence dropped by {(1 - recent_confidence/historical_confidence)*100:.1f}%',
                    'metric': 'confidence',
                    'current': recent_confidence,
                    'expected': historical_confidence
                })

        # Check for prediction distribution shift
        if len(self.prediction_history) >= 100:
            recent_predictions = list(self.prediction_history)[-100:]
            historical_predictions = list(self.prediction_history)[:-100]

            recent_mean = np.mean(recent_predictions)
            historical_mean = np.mean(historical_predictions)
            historical_std = np.std(historical_predictions)

            # Z-score of recent mean
            if historical_std > 0:
                z_score = abs(recent_mean - historical_mean) / historical_std

                if z_score > 3:  # 3 sigma threshold
                    anomalies.append({
                        'type': 'prediction_shift',
                        'severity': 'medium',
                        'description': f'Prediction distribution shifted (z-score: {z_score:.2f})',
                        'metric': 'prediction_mean',
                        'current': recent_mean,
                        'expected': historical_mean
                    })

        # Check for latency spike (possible inference attack)
        if len(self.latency_history) >= 100:
            recent_latency = np.percentile(list(self.latency_history)[-100:], 95)
            historical_latency = np.percentile(list(self.latency_history)[:-100], 95)

            if recent_latency > historical_latency * 2:
                anomalies.append({
                    'type': 'latency_spike',
                    'severity': 'medium',
                    'description': f'Inference latency increased by {(recent_latency/historical_latency - 1)*100:.1f}%',
                    'metric': 'latency_p95',
                    'current': recent_latency,
                    'expected': historical_latency
                })

        return anomalies


# Usage in production
monitor = ModelBehaviorMonitor()

# In prediction endpoint
def predict(features):
    start = time.time()

    prediction = model.predict(features)
    confidence = model.predict_proba(features).max()

    latency_ms = (time.time() - start) * 1000

    # Record for monitoring
    monitor.record_prediction(
        prediction=prediction,
        confidence=confidence,
        latency_ms=latency_ms
    )

    # Check for anomalies every 100 predictions
    if len(monitor.prediction_history) % 100 == 0:
        anomalies = monitor.detect_anomalies()
        if anomalies:
            # Trigger alert
            for anomaly in anomalies:
                print(f"🚨 Anomaly detected: {anomaly['description']}")
                # Send to incident management system
                send_alert(anomaly)

    return prediction
```

### 2.3 Backdoor Detection

**Scan Models for Backdoors**:

```python
# backdoor_detection.py
import torch
import numpy as np
from typing import List, Dict, Tuple

class BackdoorDetector:
    """
    Detect backdoors in trained models using activation clustering
    """

    def __init__(self, model: torch.nn.Module, device: str = "cpu"):
        self.model = model
        self.device = device
        self.model.to(device)
        self.model.eval()

    def detect_backdoor_activation_clustering(
        self,
        clean_data: torch.Tensor,
        suspicious_data: torch.Tensor,
        layer_name: str
    ) -> Dict:
        """
        Detect backdoor using activation clustering

        Args:
            clean_data: Known-clean validation data
            suspicious_data: Data to test for backdoor trigger
            layer_name: Layer to extract activations from

        Returns:
            Detection results
        """
        # Extract activations for clean data
        clean_activations = self._extract_activations(clean_data, layer_name)

        # Extract activations for suspicious data
        suspicious_activations = self._extract_activations(suspicious_data, layer_name)

        # Perform clustering
        from sklearn.cluster import DBSCAN

        # Combine activations
        all_activations = np.vstack([clean_activations, suspicious_activations])

        # Cluster
        clustering = DBSCAN(eps=0.5, min_samples=5).fit(all_activations)

        # Check if suspicious samples form separate cluster
        clean_labels = clustering.labels_[:len(clean_activations)]
        suspicious_labels = clustering.labels_[len(clean_activations):]

        # Count unique clusters in suspicious data
        unique_suspicious = len(set(suspicious_labels))

        # If suspicious data forms distinct cluster, likely backdoor
        is_backdoor = unique_suspicious > 1 and \
                      len(set(suspicious_labels) - set(clean_labels)) > 0

        return {
            'backdoor_detected': is_backdoor,
            'clean_clusters': len(set(clean_labels)),
            'suspicious_clusters': unique_suspicious,
            'confidence': 0.8 if is_backdoor else 0.2
        }

    def detect_backdoor_neural_cleanse(
        self,
        clean_data: torch.Tensor,
        target_class: int
    ) -> Dict:
        """
        Detect backdoor using Neural Cleanse technique

        Args:
            clean_data: Clean validation data
            target_class: Class to test for backdoor

        Returns:
            Detection results with trigger pattern
        """
        # Initialize trigger pattern (small patch)
        trigger = torch.rand(1, 3, 5, 5, requires_grad=True, device=self.device)
        trigger_mask = torch.ones(1, 1, 5, 5, device=self.device)

        optimizer = torch.optim.Adam([trigger], lr=0.1)

        # Optimize trigger to cause misclassification
        for _ in range(100):
            optimizer.zero_grad()

            # Apply trigger to clean images
            triggered_images = clean_data.clone()
            triggered_images[:, :, :5, :5] = trigger * trigger_mask

            # Forward pass
            outputs = self.model(triggered_images)
            predictions = outputs.argmax(dim=1)

            # Loss: maximize predictions for target class
            loss = -torch.nn.functional.cross_entropy(
                outputs,
                torch.full_like(predictions, target_class)
            )

            loss.backward()
            optimizer.step()

        # Check trigger size (backdoors typically have small triggers)
        trigger_norm = trigger.abs().mean().item()

        # If trigger is small and effective, likely backdoor
        is_backdoor = trigger_norm < 0.1

        return {
            'backdoor_detected': is_backdoor,
            'trigger_pattern': trigger.detach().cpu().numpy(),
            'trigger_size': trigger_norm,
            'target_class': target_class
        }

    def _extract_activations(
        self,
        data: torch.Tensor,
        layer_name: str
    ) -> np.ndarray:
        """Extract activations from specified layer"""
        activations = []

        def hook_fn(module, input, output):
            activations.append(output.detach().cpu().numpy())

        # Register hook
        layer = dict(self.model.named_modules())[layer_name]
        hook = layer.register_forward_hook(hook_fn)

        # Forward pass
        with torch.no_grad():
            self.model(data)

        hook.remove()

        return np.vstack(activations)


# Usage
detector = BackdoorDetector(model=trained_model)

result = detector.detect_backdoor_activation_clustering(
    clean_data=clean_validation_set,
    suspicious_data=test_data,
    layer_name="features.10"
)

if result['backdoor_detected']:
    print("🚨 Backdoor detected in model!")
    print(f"Confidence: {result['confidence']}")
    # Trigger incident response
    create_incident(
        title="Backdoor detected in ML model",
        severity="SEV1",
        category="backdoor"
    )
```

---

## 3. Digital Forensics for ML Systems

### 3.1 Evidence Collection

**Forensics Collection Script**:

```bash
#!/bin/bash
# collect_forensics.sh

INCIDENT_ID=$1
OUTPUT_DIR="/forensics/${INCIDENT_ID}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "Collecting forensic evidence for incident: ${INCIDENT_ID}"

# Create output directory
mkdir -p "${OUTPUT_DIR}"

# 1. Collect system information
echo "[+] Collecting system information..."
uname -a > "${OUTPUT_DIR}/system_info.txt"
hostname >> "${OUTPUT_DIR}/system_info.txt"
date >> "${OUTPUT_DIR}/system_info.txt"

# 2. Collect running processes
echo "[+] Collecting process information..."
ps auxww > "${OUTPUT_DIR}/processes.txt"
lsof -n > "${OUTPUT_DIR}/open_files.txt"

# 3. Collect network connections
echo "[+] Collecting network information..."
netstat -an > "${OUTPUT_DIR}/network_connections.txt"
ss -tupan > "${OUTPUT_DIR}/sockets.txt"
iptables -L -n -v > "${OUTPUT_DIR}/firewall_rules.txt"

# 4. Collect logs
echo "[+] Collecting logs..."
cp -r /var/log/ "${OUTPUT_DIR}/logs/"

# Kubernetes logs (if applicable)
if command -v kubectl &> /dev/null; then
    echo "[+] Collecting Kubernetes logs..."
    kubectl get pods --all-namespaces -o wide > "${OUTPUT_DIR}/k8s_pods.txt"
    kubectl get events --all-namespaces > "${OUTPUT_DIR}/k8s_events.txt"

    # Logs from ml-production namespace
    for pod in $(kubectl get pods -n ml-production -o name); do
        POD_NAME=$(basename ${pod})
        kubectl logs -n ml-production ${POD_NAME} > "${OUTPUT_DIR}/logs/k8s_${POD_NAME}.log" 2>&1
    done
fi

# 5. Collect ML-specific artifacts
echo "[+] Collecting ML artifacts..."
if [ -d "/models" ]; then
    # Calculate hashes of all models
    find /models -type f -name "*.pkl" -o -name "*.pt" | while read model; do
        sha256sum "$model" >> "${OUTPUT_DIR}/model_hashes.txt"
    done

    # Copy model metadata
    cp -r /models/metadata/ "${OUTPUT_DIR}/model_metadata/" 2>/dev/null
fi

# 6. Collect Docker information (if applicable)
if command -v docker &> /dev/null; then
    echo "[+] Collecting Docker information..."
    docker ps -a > "${OUTPUT_DIR}/docker_containers.txt"
    docker images > "${OUTPUT_DIR}/docker_images.txt"
    docker inspect $(docker ps -aq) > "${OUTPUT_DIR}/docker_inspect.json" 2>/dev/null
fi

# 7. Collect memory dump (if requested and tools available)
if command -v gcore &> /dev/null; then
    echo "[+] Collecting memory dumps of suspicious processes..."
    # This would be more targeted in practice
    # gcore -o "${OUTPUT_DIR}/memory_" <suspicious_pid>
fi

# 8. Create timeline
echo "[+] Creating timeline..."
find /var/log /tmp /models -type f -printf "%T@ %Tc %p\n" 2>/dev/null | \
    sort -n > "${OUTPUT_DIR}/timeline.txt"

# 9. Package everything
echo "[+] Packaging evidence..."
cd /forensics
tar czf "${INCIDENT_ID}_forensics_${TIMESTAMP}.tar.gz" "${INCIDENT_ID}/"

# Calculate hash of evidence package
sha256sum "${INCIDENT_ID}_forensics_${TIMESTAMP}.tar.gz" > "${INCIDENT_ID}_forensics_${TIMESTAMP}.tar.gz.sha256"

echo "✓ Forensic evidence collected: ${INCIDENT_ID}_forensics_${TIMESTAMP}.tar.gz"
```

### 3.2 Log Analysis

**Automated Log Analysis**:

```python
# log_analyzer.py
import re
from collections import Counter, defaultdict
from datetime import datetime
from typing import Dict, List
import json

class ForensicLogAnalyzer:
    """
    Analyze logs for incident investigation
    """

    def __init__(self, log_path: str):
        self.log_path = log_path

    def find_suspicious_ips(self, threshold: int = 100) -> List[Dict]:
        """
        Find IPs with unusually high request rate

        Args:
            threshold: Requests per minute threshold

        Returns:
            List of suspicious IPs
        """
        ip_pattern = r'(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})'
        ip_requests = Counter()

        with open(self.log_path, 'r') as f:
            for line in f:
                match = re.search(ip_pattern, line)
                if match:
                    ip = match.group(1)
                    ip_requests[ip] += 1

        suspicious = []
        for ip, count in ip_requests.items():
            if count > threshold:
                suspicious.append({
                    'ip': ip,
                    'request_count': count,
                    'severity': 'high' if count > threshold * 2 else 'medium'
                })

        return sorted(suspicious, key=lambda x: x['request_count'], reverse=True)

    def find_failed_auth_attempts(self) -> List[Dict]:
        """Find repeated failed authentication attempts"""
        auth_failures = defaultdict(list)

        with open(self.log_path, 'r') as f:
            for line in f:
                if 'auth.failure' in line or 'authentication failed' in line.lower():
                    # Extract timestamp
                    timestamp_match = re.search(r'\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}', line)
                    if timestamp_match:
                        timestamp = timestamp_match.group(0)

                    # Extract user/IP
                    ip_match = re.search(r'(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})', line)
                    if ip_match:
                        ip = ip_match.group(1)
                        auth_failures[ip].append(timestamp)

        # Find IPs with multiple failures
        suspicious = []
        for ip, timestamps in auth_failures.items():
            if len(timestamps) >= 5:
                suspicious.append({
                    'ip': ip,
                    'failure_count': len(timestamps),
                    'first_attempt': timestamps[0],
                    'last_attempt': timestamps[-1]
                })

        return suspicious

    def find_data_exfiltration(self) -> List[Dict]:
        """Find potential data exfiltration events"""
        exfiltration_events = []

        with open(self.log_path, 'r') as f:
            for line in f:
                # Look for large data transfers
                size_match = re.search(r'size[=:](\d+)', line, re.IGNORECASE)
                if size_match:
                    size_bytes = int(size_match.group(1))

                    # Flag transfers > 100MB
                    if size_bytes > 100 * 1024 * 1024:
                        exfiltration_events.append({
                            'timestamp': re.search(r'\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}', line).group(0),
                            'size_mb': size_bytes / (1024 * 1024),
                            'log_line': line.strip()
                        })

        return exfiltration_events

    def generate_forensic_report(self) -> str:
        """Generate comprehensive forensic report"""
        report = "# Forensic Log Analysis Report\n\n"
        report += f"Generated: {datetime.utcnow().isoformat()}\n"
        report += f"Log file: {self.log_path}\n\n"

        # Suspicious IPs
        report += "## Suspicious IP Addresses\n\n"
        suspicious_ips = self.find_suspicious_ips()
        if suspicious_ips:
            for item in suspicious_ips[:10]:
                report += f"- {item['ip']}: {item['request_count']} requests (severity: {item['severity']})\n"
        else:
            report += "No suspicious IPs detected.\n"

        report += "\n"

        # Failed auth attempts
        report += "## Failed Authentication Attempts\n\n"
        auth_failures = self.find_failed_auth_attempts()
        if auth_failures:
            for item in auth_failures:
                report += f"- {item['ip']}: {item['failure_count']} failures\n"
                report += f"  First: {item['first_attempt']}, Last: {item['last_attempt']}\n"
        else:
            report += "No suspicious authentication patterns detected.\n"

        report += "\n"

        # Data exfiltration
        report += "## Potential Data Exfiltration\n\n"
        exfiltration = self.find_data_exfiltration()
        if exfiltration:
            for item in exfiltration:
                report += f"- {item['timestamp']}: {item['size_mb']:.2f} MB transferred\n"
        else:
            report += "No large data transfers detected.\n"

        return report


# Usage
analyzer = ForensicLogAnalyzer('/forensics/INC-2025-001/logs/audit.log')
report = analyzer.generate_forensic_report()
print(report)
```

---

## 4. Disaster Recovery Planning

### 4.1 DR Strategy

**Recovery Time Objective (RTO) and Recovery Point Objective (RPO)**:

| Component | RTO | RPO | Strategy |
|-----------|-----|-----|----------|
| ML Inference API | 15 min | 0 min | Active-Active multi-region |
| Model Registry | 1 hour | 15 min | Backup + restore |
| Training Data | 4 hours | 1 hour | S3 cross-region replication |
| Feature Store | 30 min | 5 min | Database replication |
| Monitoring | 30 min | 15 min | Backup configuration |

### 4.2 Backup and Restore

**Automated Backup Script**:

```python
# backup_ml_infrastructure.py
import boto3
from datetime import datetime
import json

class MLInfrastructureBackup:
    """
    Backup critical ML infrastructure components
    """

    def __init__(self, backup_bucket: str):
        self.backup_bucket = backup_bucket
        self.s3 = boto3.client('s3')
        self.rds = boto3.client('rds')

    def backup_models(self, model_registry_path: str):
        """Backup all models from registry"""
        timestamp = datetime.utcnow().strftime('%Y%m%d_%H%M%S')

        # Tar models directory
        import subprocess
        backup_file = f"/tmp/models_backup_{timestamp}.tar.gz"
        subprocess.run([
            'tar', '-czf', backup_file, model_registry_path
        ], check=True)

        # Upload to S3
        self.s3.upload_file(
            backup_file,
            self.backup_bucket,
            f"models/models_backup_{timestamp}.tar.gz"
        )

        print(f"✓ Models backed up to s3://{self.backup_bucket}/models/")

    def backup_database(self, db_instance_id: str):
        """Create RDS snapshot"""
        timestamp = datetime.utcnow().strftime('%Y%m%d-%H%M%S')
        snapshot_id = f"{db_instance_id}-{timestamp}"

        response = self.rds.create_db_snapshot(
            DBSnapshotIdentifier=snapshot_id,
            DBInstanceIdentifier=db_instance_id
        )

        print(f"✓ Database snapshot created: {snapshot_id}")
        return snapshot_id

    def backup_configuration(self, config_paths: list):
        """Backup Kubernetes and application configuration"""
        timestamp = datetime.utcnow().strftime('%Y%m%d_%H%M%S')

        # Export Kubernetes resources
        import subprocess
        k8s_backup = f"/tmp/k8s_backup_{timestamp}.yaml"

        subprocess.run([
            'kubectl', 'get', 'all,configmap,secret',
            '-n', 'ml-production',
            '-o', 'yaml'
        ], stdout=open(k8s_backup, 'w'), check=True)

        # Upload to S3
        self.s3.upload_file(
            k8s_backup,
            self.backup_bucket,
            f"config/k8s_backup_{timestamp}.yaml"
        )

        print("✓ Configuration backed up")

    def run_full_backup(self):
        """Execute full backup"""
        print("Starting full ML infrastructure backup...")

        self.backup_models("/models")
        self.backup_database("ml-production-db")
        self.backup_configuration(["/etc/ml-config"])

        print("✓ Full backup completed")


class MLInfrastructureRestore:
    """
    Restore ML infrastructure from backups
    """

    def __init__(self, backup_bucket: str):
        self.backup_bucket = backup_bucket
        self.s3 = boto3.client('s3')
        self.rds = boto3.client('rds')

    def restore_models(self, backup_timestamp: str, target_path: str):
        """Restore models from backup"""
        backup_key = f"models/models_backup_{backup_timestamp}.tar.gz"
        local_file = "/tmp/models_restore.tar.gz"

        # Download from S3
        self.s3.download_file(
            self.backup_bucket,
            backup_key,
            local_file
        )

        # Extract
        import subprocess
        subprocess.run([
            'tar', '-xzf', local_file, '-C', target_path
        ], check=True)

        print(f"✓ Models restored to {target_path}")

    def restore_database(self, snapshot_id: str, new_instance_id: str):
        """Restore database from snapshot"""
        response = self.rds.restore_db_instance_from_db_snapshot(
            DBInstanceIdentifier=new_instance_id,
            DBSnapshotIdentifier=snapshot_id
        )

        print(f"✓ Database restore initiated: {new_instance_id}")
        print("Waiting for instance to become available...")

        waiter = self.rds.get_waiter('db_instance_available')
        waiter.wait(DBInstanceIdentifier=new_instance_id)

        print("✓ Database restored and available")


# Usage
backup = MLInfrastructureBackup(backup_bucket="ml-backups")
backup.run_full_backup()

# Restore (in DR scenario)
# restore = MLInfrastructureRestore(backup_bucket="ml-backups")
# restore.restore_models(backup_timestamp="20250102_103000", target_path="/models")
# restore.restore_database(snapshot_id="ml-production-db-20250102-103000", new_instance_id="ml-production-db-restored")
```

---

## 5. Post-Incident Analysis

### 5.1 Post-Mortem Template

```markdown
# Post-Incident Review: [Incident ID]

## Incident Summary

- **Date**: 2025-01-02
- **Duration**: 3 hours 45 minutes
- **Severity**: SEV2
- **Category**: API Abuse
- **Incident Commander**: Jane Doe
- **Status**: Resolved

## Impact

- **Services Affected**: ML Inference API
- **Users Affected**: ~5,000 users
- **Downtime**: 45 minutes partial degradation
- **Data Exposure**: None
- **Financial Impact**: $10,000 (estimated)

## Timeline

| Time (UTC) | Event |
|------------|-------|
| 14:15 | Alert: High API request rate detected |
| 14:18 | On-call engineer paged |
| 14:25 | Incident declared (SEV3) |
| 14:35 | Attacker IP identified |
| 14:40 | IP blocked at WAF |
| 14:50 | Service degradation continues - escalated to SEV2 |
| 15:00 | Additional attack vectors identified |
| 15:15 | Rate limiting enabled globally |
| 15:30 | Attack traffic subsiding |
| 16:00 | Service fully recovered |
| 18:00 | Incident resolved |

## Root Cause

API rate limiting was not properly configured, allowing a single attacker to overwhelm the inference service with 10,000+ requests/minute.

## What Went Well

- Alert fired promptly (3 minutes from attack start)
- Team responded quickly (paged within 3 minutes of alert)
- Communication was clear and frequent
- Runbooks were up-to-date and followed

## What Went Wrong

- Rate limiting was not configured correctly
- Initial blocking of attacker IP did not stop attack (multiple IPs)
- Took too long to identify all attack vectors (35 minutes)
- No automated response for this type of attack

## Lessons Learned

1. **Prevention**: Proper rate limiting configuration is critical
2. **Detection**: Need better attack pattern recognition
3. **Response**: Automated blocking for known attack patterns would help
4. **Recovery**: Faster escalation process needed

## Action Items

| Action | Owner | Due Date | Status |
|--------|-------|----------|--------|
| Implement global rate limiting (100 req/min per IP) | SRE Team | 2025-01-05 | ✓ Complete |
| Add automated IP blocking for high request rates | Security | 2025-01-10 | In Progress |
| Update runbook with lessons learned | Incident Commander | 2025-01-03 | ✓ Complete |
| Conduct tabletop exercise for API abuse scenarios | Security | 2025-01-15 | Pending |
| Review and update alerting thresholds | SRE Team | 2025-01-08 | In Progress |

## Follow-Up

Post-mortem review meeting scheduled for 2025-01-05 with full team.
```

### 5.2 Continuous Improvement

**Track Incident Metrics**:

```python
# incident_metrics.py
from dataclasses import dataclass
from datetime import datetime, timedelta
from typing import List
import statistics

@dataclass
class Incident:
    id: str
    severity: str
    category: str
    detected_at: datetime
    resolved_at: datetime
    mttd_minutes: float  # Mean Time to Detect
    mttr_minutes: float  # Mean Time to Resolve

class IncidentMetricsTracker:
    """
    Track and analyze incident response metrics
    """

    def __init__(self, incidents: List[Incident]):
        self.incidents = incidents

    def calculate_mttd(self) -> Dict:
        """Calculate Mean Time to Detect metrics"""
        mttd_values = [inc.mttd_minutes for inc in self.incidents]

        return {
            'mean': statistics.mean(mttd_values),
            'median': statistics.median(mttd_values),
            'p95': statistics.quantiles(mttd_values, n=20)[18],  # 95th percentile
            'trend': 'improving'  # Would calculate from historical data
        }

    def calculate_mttr(self) -> Dict:
        """Calculate Mean Time to Respond metrics"""
        mttr_values = [inc.mttr_minutes for inc in self.incidents]

        return {
            'mean': statistics.mean(mttr_values),
            'median': statistics.median(mttr_values),
            'p95': statistics.quantiles(mttr_values, n=20)[18],
            'trend': 'improving'
        }

    def incidents_by_category(self) -> Dict:
        """Count incidents by category"""
        from collections import Counter
        return dict(Counter(inc.category for inc in self.incidents))

    def incidents_by_severity(self) -> Dict:
        """Count incidents by severity"""
        from collections import Counter
        return dict(Counter(inc.severity for inc in self.incidents))

    def generate_report(self) -> str:
        """Generate incident metrics report"""
        report = "# Incident Response Metrics\n\n"

        # MTTD
        mttd = self.calculate_mttd()
        report += "## Mean Time to Detect (MTTD)\n\n"
        report += f"- Mean: {mttd['mean']:.1f} minutes\n"
        report += f"- Median: {mttd['median']:.1f} minutes\n"
        report += f"- P95: {mttd['p95']:.1f} minutes\n"
        report += f"- Trend: {mttd['trend']}\n\n"

        # MTTR
        mttr = self.calculate_mttr()
        report += "## Mean Time to Respond (MTTR)\n\n"
        report += f"- Mean: {mttr['mean']:.1f} minutes\n"
        report += f"- Median: {mttr['median']:.1f} minutes\n"
        report += f"- P95: {mttr['p95']:.1f} minutes\n"
        report += f"- Trend: {mttr['trend']}\n\n"

        # By category
        report += "## Incidents by Category\n\n"
        for category, count in self.incidents_by_category().items():
            report += f"- {category}: {count}\n"

        report += "\n"

        # By severity
        report += "## Incidents by Severity\n\n"
        for severity, count in self.incidents_by_severity().items():
            report += f"- {severity}: {count}\n"

        return report


# Usage
incidents = [
    Incident(
        id="INC-2025-001",
        severity="SEV2",
        category="api_abuse",
        detected_at=datetime(2025, 1, 2, 14, 15),
        resolved_at=datetime(2025, 1, 2, 18, 0),
        mttd_minutes=3,
        mttr_minutes=225
    ),
    # More incidents...
]

tracker = IncidentMetricsTracker(incidents)
report = tracker.generate_report()
print(report)
```

---

## Summary

Effective incident response and recovery for ML systems requires:

1. **Incident Response Framework**: Structured process, playbooks, team coordination
2. **Model Compromise Detection**: Integrity monitoring, behavioral analysis, backdoor detection
3. **Digital Forensics**: Evidence collection, log analysis, chain of custody
4. **Disaster Recovery**: Backups, restore procedures, RTO/RPO planning
5. **Post-Incident Analysis**: Lessons learned, continuous improvement

**Key Takeaways**:

- Prepare incident response playbooks before incidents occur
- Automate response actions where possible
- Monitor model integrity and behavior continuously
- Collect comprehensive forensic evidence
- Test disaster recovery procedures regularly
- Conduct thorough post-mortems and implement improvements
- Track metrics to measure incident response effectiveness

---

**Congratulations!** You have completed the AI Infrastructure Security Engineer learning path. You now have comprehensive knowledge of:

- ML security fundamentals
- Model security and adversarial ML
- Data privacy and compliance
- Secrets and identity management
- Secure ML pipelines
- Network security
- Audit, logging, and compliance
- Incident response and recovery

Continue practicing these skills, stay updated on emerging threats, and contribute to the ML security community!
