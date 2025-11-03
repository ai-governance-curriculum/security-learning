# Module 1: ML Security Fundamentals

## Overview

Machine learning systems introduce unique security challenges that extend beyond traditional application security. This module establishes foundational knowledge of ML-specific threats, security frameworks, and defensive strategies essential for protecting AI infrastructure.

**Duration**: 25 hours
**Prerequisites**: Security fundamentals, ML basics, infrastructure experience

## Learning Objectives

By completing this module, you will:

1. Understand the OWASP Machine Learning Security Top 10 threats
2. Conduct threat modeling for ML systems
3. Apply security-by-design principles to ML architectures
4. Analyze ML attack surfaces across the pipeline
5. Implement secure development lifecycle practices for ML

---

## 1. Introduction to ML Security (3 hours)

### 1.1 Why ML Security is Different

Traditional application security focuses on protecting code, data at rest, and data in transit. ML systems add new dimensions:

**Traditional Security**:
- Static code vulnerabilities (SQL injection, XSS)
- Authentication and authorization
- Network security
- Data encryption

**ML Security Additions**:
- **Model vulnerabilities**: Adversarial examples, model inversion
- **Training data poisoning**: Malicious samples in training sets
- **Model stealing**: Extracting proprietary models via queries
- **Inference attacks**: Membership inference, attribute inference
- **Supply chain**: Pre-trained models, datasets, ML libraries

### 1.2 The ML Security Landscape

```
Traditional Security Layer
├── Network Security (firewalls, VPCs)
├── Application Security (code vulnerabilities)
├── Data Security (encryption, access control)
└── Infrastructure Security (containers, orchestration)

ML-Specific Security Layer
├── Model Security
│   ├── Adversarial robustness
│   ├── Model integrity
│   └── Backdoor detection
├── Data Security
│   ├── Training data integrity
│   ├── Privacy preservation
│   └── Data provenance
├── Pipeline Security
│   ├── Experiment tracking
│   ├── Model registry
│   └── Deployment security
└── Inference Security
    ├── Input validation
    ├── Output monitoring
    └── Rate limiting
```

### 1.3 Real-World ML Security Incidents

**Case Study 1: Microsoft Tay Chatbot (2016)**
- **Attack**: Data poisoning via user interactions
- **Impact**: Model learned offensive behavior in 24 hours
- **Lesson**: User-generated training data requires validation

**Case Study 2: Proofpoint Email Security (2019)**
- **Attack**: Adversarial examples bypassed spam filters
- **Impact**: Phishing emails evaded ML-based detection
- **Lesson**: Models need robustness testing against adversarial inputs

**Case Study 3: Tesla Autopilot (2021)**
- **Attack**: Physical adversarial patches on road signs
- **Impact**: Computer vision misclassification
- **Lesson**: Physical-world attacks require defense mechanisms

---

## 2. OWASP Machine Learning Security Top 10 (5 hours)

### 2.1 ML01: Input Manipulation Attack

**Description**: Adversaries craft inputs to cause misclassification

**Example: Image Classification Attack**
```python
import torch
import torch.nn.functional as F

def fgsm_attack(model, image, label, epsilon=0.03):
    """
    Fast Gradient Sign Method (FGSM) attack
    Creates adversarial example by adding small perturbation
    """
    # Enable gradient tracking
    image.requires_grad = True

    # Forward pass
    output = model(image)
    loss = F.cross_entropy(output, label)

    # Backward pass to get gradients
    model.zero_grad()
    loss.backward()

    # Create perturbation
    perturbation = epsilon * image.grad.sign()

    # Generate adversarial example
    adv_image = image + perturbation
    adv_image = torch.clamp(adv_image, 0, 1)

    return adv_image

# Original prediction: "cat" (99.8% confidence)
# Adversarial prediction: "dog" (87.3% confidence)
# Human perception: Identical images
```

**Defense Strategies**:
1. **Input validation**: Detect out-of-distribution inputs
2. **Adversarial training**: Include adversarial examples in training
3. **Defensive distillation**: Train model with soft labels
4. **Ensemble methods**: Multiple models for consensus

**Implementation: Input Validation**
```python
import numpy as np
from sklearn.ensemble import IsolationForest

class InputValidator:
    def __init__(self, training_data, contamination=0.1):
        """
        Detect out-of-distribution inputs using Isolation Forest
        """
        self.detector = IsolationForest(
            contamination=contamination,
            random_state=42
        )
        self.detector.fit(training_data)

    def is_valid(self, input_data, threshold=-0.5):
        """
        Returns True if input is likely in-distribution
        """
        score = self.detector.score_samples(input_data.reshape(1, -1))
        return score[0] > threshold

    def validate_batch(self, inputs):
        """
        Validate batch of inputs
        """
        scores = self.detector.score_samples(inputs)
        return scores > -0.5

# Usage
validator = InputValidator(training_features)

# Production inference
def predict_with_validation(model, input_data):
    if not validator.is_valid(input_data):
        raise ValueError("Input rejected: out-of-distribution")

    return model(input_data)
```

### 2.2 ML02: Data Poisoning Attack

**Description**: Attackers inject malicious samples into training data

**Example: Label Flipping Attack**
```python
def poison_training_data(X_train, y_train, poison_rate=0.1, target_class=0):
    """
    Flip labels for a percentage of training samples
    """
    n_samples = len(y_train)
    n_poison = int(n_samples * poison_rate)

    # Select random samples to poison
    poison_indices = np.random.choice(n_samples, n_poison, replace=False)

    # Create poisoned copy
    y_poisoned = y_train.copy()

    # Flip labels to target class
    y_poisoned[poison_indices] = target_class

    return X_train, y_poisoned

# Impact: 10% poisoning can reduce accuracy by 15-30%
```

**Defense Strategies**:
1. **Data validation**: Outlier detection before training
2. **Data provenance**: Track data sources and quality
3. **Differential privacy**: Add noise to gradients
4. **Certified defenses**: Provable robustness guarantees

**Implementation: Data Sanitization**
```python
from sklearn.covariance import EllipticEnvelope

class DataSanitizer:
    def __init__(self, contamination=0.1):
        self.outlier_detector = EllipticEnvelope(
            contamination=contamination,
            random_state=42
        )

    def fit_and_filter(self, X, y):
        """
        Detect and remove outliers from training data
        """
        # Fit outlier detector
        self.outlier_detector.fit(X)

        # Predict outliers (-1 for outliers, 1 for inliers)
        predictions = self.outlier_detector.predict(X)

        # Filter out outliers
        mask = predictions == 1
        X_clean = X[mask]
        y_clean = y[mask]

        n_removed = len(X) - len(X_clean)
        print(f"Removed {n_removed} outliers ({n_removed/len(X)*100:.1f}%)")

        return X_clean, y_clean

# Usage in training pipeline
sanitizer = DataSanitizer(contamination=0.05)
X_train_clean, y_train_clean = sanitizer.fit_and_filter(X_train, y_train)

model.fit(X_train_clean, y_train_clean)
```

### 2.3 ML03: Model Inversion Attack

**Description**: Reconstruct training data from model parameters or predictions

**Example: Membership Inference**
```python
import torch.nn as nn

class MembershipInferenceAttack:
    """
    Determine if a sample was in the training set
    Based on prediction confidence
    """
    def __init__(self, shadow_models, threshold=0.9):
        self.shadow_models = shadow_models
        self.threshold = threshold

    def train_attack_model(self, member_data, non_member_data):
        """
        Train binary classifier to distinguish training samples
        """
        # Get predictions from shadow models
        member_preds = self._get_predictions(member_data)
        non_member_preds = self._get_predictions(non_member_data)

        # Create attack dataset
        X_attack = np.vstack([member_preds, non_member_preds])
        y_attack = np.hstack([
            np.ones(len(member_preds)),
            np.zeros(len(non_member_preds))
        ])

        # Train attack classifier
        from sklearn.ensemble import RandomForestClassifier
        self.attack_model = RandomForestClassifier(n_estimators=100)
        self.attack_model.fit(X_attack, y_attack)

    def is_member(self, target_model, sample):
        """
        Predict if sample was in target model's training set
        """
        pred = target_model.predict_proba(sample.reshape(1, -1))
        confidence = np.max(pred)

        # High confidence suggests training sample
        return confidence > self.threshold

    def _get_predictions(self, data):
        predictions = []
        for model in self.shadow_models:
            preds = model.predict_proba(data)
            predictions.append(preds)
        return np.hstack(predictions)
```

**Defense Strategies**:
1. **Differential privacy**: Add noise during training
2. **Prediction clipping**: Limit output confidence
3. **Regularization**: Prevent overfitting
4. **Output perturbation**: Add noise to predictions

**Implementation: Differential Privacy**
```python
from opacus import PrivacyEngine
from opacus.utils.batch_memory_manager import BatchMemoryManager

def train_with_differential_privacy(
    model,
    train_loader,
    epochs=10,
    epsilon=8.0,  # Privacy budget
    delta=1e-5,
    max_grad_norm=1.0
):
    """
    Train model with differential privacy guarantees
    """
    # Initialize privacy engine
    privacy_engine = PrivacyEngine()

    optimizer = torch.optim.Adam(model.parameters(), lr=0.001)

    # Make model private
    model, optimizer, train_loader = privacy_engine.make_private(
        module=model,
        optimizer=optimizer,
        data_loader=train_loader,
        noise_multiplier=1.1,
        max_grad_norm=max_grad_norm,
    )

    # Training loop
    for epoch in range(epochs):
        with BatchMemoryManager(
            data_loader=train_loader,
            max_physical_batch_size=128,
            optimizer=optimizer
        ) as memory_safe_data_loader:

            for batch_idx, (data, target) in enumerate(memory_safe_data_loader):
                optimizer.zero_grad()
                output = model(data)
                loss = F.cross_entropy(output, target)
                loss.backward()
                optimizer.step()

        # Check privacy budget
        epsilon_spent = privacy_engine.get_epsilon(delta)
        print(f"Epoch {epoch}: (ε = {epsilon_spent:.2f}, δ = {delta})")

        if epsilon_spent > epsilon:
            print("Privacy budget exhausted")
            break

    return model

# Model trained with (ε=8, δ=1e-5)-differential privacy
# Guarantees individual training samples cannot be identified
```

### 2.4 ML04: Membership Inference Attack

**Description**: Determine if specific data was used in training

**Impact**: Privacy violation for sensitive datasets (medical, financial)

**Defense**: See differential privacy implementation above

### 2.5 ML05: Model Stealing

**Description**: Replicate proprietary model via API queries

**Example: Model Extraction**
```python
import requests
import numpy as np

class ModelStealingAttack:
    def __init__(self, api_endpoint, input_dim, output_dim):
        self.api_endpoint = api_endpoint
        self.input_dim = input_dim
        self.output_dim = output_dim
        self.stolen_model = None

    def generate_queries(self, n_queries=10000):
        """
        Generate synthetic queries to victim API
        """
        queries = []
        labels = []

        for _ in range(n_queries):
            # Generate random input
            query = np.random.randn(self.input_dim)

            # Query victim API
            response = requests.post(
                self.api_endpoint,
                json={"input": query.tolist()}
            )
            prediction = response.json()["prediction"]

            queries.append(query)
            labels.append(prediction)

        return np.array(queries), np.array(labels)

    def train_substitute_model(self, n_queries=10000):
        """
        Train substitute model on API outputs
        """
        X, y = self.generate_queries(n_queries)

        from sklearn.neural_network import MLPClassifier
        self.stolen_model = MLPClassifier(
            hidden_layer_sizes=(128, 64),
            max_iter=1000
        )
        self.stolen_model.fit(X, y)

        return self.stolen_model

# Cost: $200 in API calls → 94% accuracy replica
```

**Defense Strategies**:
1. **Rate limiting**: Restrict queries per user/IP
2. **Query analysis**: Detect systematic probing patterns
3. **Output rounding**: Reduce prediction precision
4. **Watermarking**: Embed signatures in model behavior

**Implementation: API Protection**
```python
from collections import defaultdict
from datetime import datetime, timedelta
import hashlib

class APIProtection:
    def __init__(
        self,
        rate_limit=1000,  # queries per hour
        similarity_threshold=0.9,
        window_size=100
    ):
        self.rate_limit = rate_limit
        self.similarity_threshold = similarity_threshold
        self.window_size = window_size

        # Track queries per user
        self.query_counts = defaultdict(list)

        # Track recent queries for similarity detection
        self.recent_queries = defaultdict(list)

    def check_rate_limit(self, user_id):
        """
        Enforce rate limiting
        """
        now = datetime.now()
        cutoff = now - timedelta(hours=1)

        # Remove old queries
        self.query_counts[user_id] = [
            t for t in self.query_counts[user_id] if t > cutoff
        ]

        # Check limit
        if len(self.query_counts[user_id]) >= self.rate_limit:
            return False

        # Record query
        self.query_counts[user_id].append(now)
        return True

    def detect_systematic_probing(self, user_id, query):
        """
        Detect if queries are too similar (automated extraction)
        """
        query_hash = hashlib.sha256(str(query).encode()).hexdigest()

        self.recent_queries[user_id].append(query_hash)

        # Keep only recent window
        if len(self.recent_queries[user_id]) > self.window_size:
            self.recent_queries[user_id].pop(0)

        # Check uniqueness
        unique_ratio = len(set(self.recent_queries[user_id])) / len(self.recent_queries[user_id])

        # Low uniqueness suggests automated probing
        return unique_ratio < (1 - self.similarity_threshold)

    def add_prediction_noise(self, predictions, noise_scale=0.01):
        """
        Add small noise to predictions
        """
        noise = np.random.laplace(0, noise_scale, size=predictions.shape)
        return predictions + noise

# Usage
protection = APIProtection(rate_limit=1000)

@app.route('/predict', methods=['POST'])
def predict():
    user_id = request.headers.get('X-User-ID')
    query = request.json['input']

    # Rate limiting
    if not protection.check_rate_limit(user_id):
        return jsonify({"error": "Rate limit exceeded"}), 429

    # Probing detection
    if protection.detect_systematic_probing(user_id, query):
        return jsonify({"error": "Suspicious activity detected"}), 403

    # Make prediction
    prediction = model.predict(query)

    # Add noise
    prediction = protection.add_prediction_noise(prediction)

    return jsonify({"prediction": prediction.tolist()})
```

### 2.6 ML06: AI Supply Chain Attacks

**Description**: Compromised dependencies, pre-trained models, or datasets

**Example: Trojan in Pre-trained Model**
```python
# Backdoored model weights hosted on public repository
# Trigger: specific pixel pattern → misclassification

def load_pretrained_model(model_url, verify=True):
    """
    Safely load pre-trained models
    """
    if verify:
        # Check model hash against known good values
        expected_hash = get_trusted_hash(model_url)
        downloaded_hash = hashlib.sha256(download(model_url)).hexdigest()

        if downloaded_hash != expected_hash:
            raise ValueError("Model hash mismatch - possible tampering")

    return torch.load(model_url)

# Supply chain attack surface:
# - PyPI packages (malicious ML libraries)
# - HuggingFace models (backdoored weights)
# - Public datasets (poisoned samples)
# - Docker images (compromised containers)
```

**Defense Strategies**:
1. **Dependency scanning**: Snyk, Dependabot
2. **Hash verification**: Check model checksums
3. **Model scanning**: Detect backdoors and trojans
4. **Private registries**: Host trusted models internally

### 2.7 ML07-ML10: Additional Threats

**ML07: Transfer Learning Attack**
- Fine-tuned models inherit vulnerabilities from base models

**ML08: Model Skewing**
- Online learning systems can be manipulated over time

**ML09: Output Integrity Attack**
- Tamper with predictions post-inference

**ML10: Model Poisoning**
- Similar to data poisoning but targets model architecture/hyperparameters

---

## 3. Threat Modeling for ML Systems (6 hours)

### 3.1 Threat Modeling Methodology

**STRIDE for ML Systems**:
- **S**poofing: Fake data sources, impersonation
- **T**ampering: Data/model manipulation
- **R**epudiation: Lack of audit trails
- **I**nformation Disclosure: Model/data leakage
- **D**enial of Service: Resource exhaustion
- **E**levation of Privilege: Unauthorized access

### 3.2 ML Pipeline Threat Model

```
Data Collection
├── Threats: Data poisoning, unauthorized sources
├── Assets: Training datasets, data pipelines
└── Controls: Data validation, provenance tracking

Data Preprocessing
├── Threats: Feature manipulation, normalization attacks
├── Assets: Preprocessing code, feature stores
└── Controls: Input validation, transformation logging

Model Training
├── Threats: Hyperparameter manipulation, backdoor insertion
├── Assets: Training jobs, model checkpoints
└── Controls: Experiment tracking, code review

Model Evaluation
├── Threats: Test set leakage, metric manipulation
├── Assets: Evaluation scripts, test datasets
└── Controls: Isolated test sets, reproducible evaluation

Model Deployment
├── Threats: Model substitution, unauthorized updates
├── Assets: Model registry, deployment pipelines
└── Controls: Model signing, CI/CD security

Inference Serving
├── Threats: Adversarial inputs, model stealing
├── Assets: API endpoints, inference servers
└── Controls: Input validation, rate limiting

Monitoring
├── Threats: Log tampering, alert suppression
├── Assets: Metrics, logs, alerts
└── Controls: Immutable logs, SIEM integration
```

### 3.3 Threat Modeling Template

```python
class ThreatModel:
    def __init__(self, system_name):
        self.system_name = system_name
        self.assets = []
        self.threats = []
        self.controls = []

    def add_asset(self, name, sensitivity, description):
        """
        Identify valuable assets to protect
        """
        asset = {
            "name": name,
            "sensitivity": sensitivity,  # low, medium, high, critical
            "description": description
        }
        self.assets.append(asset)

    def add_threat(self, threat_type, description, likelihood, impact):
        """
        Document potential threats
        """
        threat = {
            "type": threat_type,  # STRIDE category
            "description": description,
            "likelihood": likelihood,  # low, medium, high
            "impact": impact,  # low, medium, high, critical
            "risk_score": self._calculate_risk(likelihood, impact)
        }
        self.threats.append(threat)

    def add_control(self, threat_id, control_type, description, effectiveness):
        """
        Define security controls
        """
        control = {
            "threat_id": threat_id,
            "type": control_type,  # preventive, detective, corrective
            "description": description,
            "effectiveness": effectiveness  # low, medium, high
        }
        self.controls.append(control)

    def _calculate_risk(self, likelihood, impact):
        risk_matrix = {
            ("low", "low"): 1,
            ("low", "medium"): 2,
            ("low", "high"): 3,
            ("low", "critical"): 4,
            ("medium", "low"): 2,
            ("medium", "medium"): 4,
            ("medium", "high"): 6,
            ("medium", "critical"): 8,
            ("high", "low"): 3,
            ("high", "medium"): 6,
            ("high", "high"): 9,
            ("high", "critical"): 10,
        }
        return risk_matrix.get((likelihood, impact), 5)

    def generate_report(self):
        """
        Generate threat model report
        """
        report = f"# Threat Model: {self.system_name}\n\n"

        report += "## Assets\n"
        for asset in sorted(self.assets, key=lambda x: x['sensitivity'], reverse=True):
            report += f"- **{asset['name']}** ({asset['sensitivity']}): {asset['description']}\n"

        report += "\n## Threats\n"
        for threat in sorted(self.threats, key=lambda x: x['risk_score'], reverse=True):
            report += f"- **{threat['type']}**: {threat['description']}\n"
            report += f"  - Likelihood: {threat['likelihood']}, Impact: {threat['impact']}\n"
            report += f"  - Risk Score: {threat['risk_score']}/10\n"

        report += "\n## Controls\n"
        for control in self.controls:
            report += f"- {control['description']} ({control['type']}, effectiveness: {control['effectiveness']})\n"

        return report

# Example usage
tm = ThreatModel("Image Classification API")

# Assets
tm.add_asset("Trained Model", "critical", "Proprietary image classifier")
tm.add_asset("Training Data", "high", "Labeled image dataset")
tm.add_asset("API Keys", "critical", "Authentication credentials")

# Threats
tm.add_threat(
    "Tampering",
    "Adversarial examples bypass classifier",
    likelihood="high",
    impact="high"
)

tm.add_threat(
    "Information Disclosure",
    "Model stealing via API queries",
    likelihood="medium",
    impact="critical"
)

# Controls
tm.add_control(
    threat_id=0,
    control_type="preventive",
    description="Input validation with OOD detection",
    effectiveness="high"
)

print(tm.generate_report())
```

### 3.4 Attack Trees for ML Systems

**Example: Model Poisoning Attack Tree**
```
Goal: Compromise Model Performance
├── AND: Inject Poisoned Data
│   ├── OR: Compromise Data Source
│   │   ├── Hack data collection system
│   │   └── Social engineer data labelers
│   └── Evade Data Validation
│       ├── Craft samples that pass outlier detection
│       └── Slowly inject poison over time
└── Trigger Model Retraining
    ├── Wait for scheduled retraining
    └── Force retraining via concept drift detection
```

**Implementation: Attack Tree Analysis**
```python
class AttackTree:
    def __init__(self, goal):
        self.goal = goal
        self.root = AttackTreeNode(goal, node_type="goal")

    def add_path(self, parent_node, child_node, gate_type="OR"):
        """
        Add attack path with AND/OR logic
        """
        parent_node.add_child(child_node, gate_type)

    def calculate_attack_feasibility(self, node=None):
        """
        Calculate likelihood of successful attack
        """
        if node is None:
            node = self.root

        if not node.children:
            return node.feasibility

        child_feasibilities = [
            self.calculate_attack_feasibility(child)
            for child in node.children
        ]

        if node.gate_type == "OR":
            # Attack succeeds if ANY path succeeds
            return max(child_feasibilities)
        else:  # AND
            # Attack succeeds if ALL paths succeed
            return min(child_feasibilities)

class AttackTreeNode:
    def __init__(self, description, node_type="step", feasibility=0.5):
        self.description = description
        self.node_type = node_type
        self.feasibility = feasibility
        self.children = []
        self.gate_type = "OR"

    def add_child(self, child, gate_type="OR"):
        self.children.append(child)
        self.gate_type = gate_type
```

---

## 4. Security by Design Principles (4 hours)

### 4.1 Defense in Depth

**Layered Security Architecture**:
```
Layer 1: Network Security
├── VPC isolation
├── Network policies
└── TLS encryption

Layer 2: Application Security
├── Input validation
├── Rate limiting
└── Authentication

Layer 3: Model Security
├── Adversarial training
├── Output monitoring
└── Model versioning

Layer 4: Data Security
├── Encryption at rest
├── Access control
└── Data provenance

Layer 5: Monitoring & Response
├── Audit logging
├── Anomaly detection
└── Incident response
```

### 4.2 Least Privilege Principle

**IAM for ML Workloads**:
```yaml
# Example: Restricted training job permissions
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ml-training-job
  namespace: ml-training

---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: training-job-role
  namespace: ml-training
rules:
  # Can read training data
  - apiGroups: [""]
    resources: ["configmaps"]
    verbs: ["get", "list"]

  # Can write model artifacts
  - apiGroups: [""]
    resources: ["persistentvolumeclaims"]
    verbs: ["get", "create"]

  # CANNOT access secrets
  # CANNOT modify other jobs
  # CANNOT access production namespace
```

### 4.3 Security Testing in ML

**Adversarial Testing Pipeline**:
```python
class SecurityTestSuite:
    def __init__(self, model, test_loader):
        self.model = model
        self.test_loader = test_loader
        self.results = {}

    def test_adversarial_robustness(self, epsilon_values=[0.01, 0.03, 0.1]):
        """
        Test model against FGSM attacks
        """
        results = {}
        for epsilon in epsilon_values:
            accuracy = self._fgsm_test(epsilon)
            results[f"FGSM_eps_{epsilon}"] = accuracy

        self.results["adversarial_robustness"] = results
        return results

    def test_model_fairness(self, protected_attributes):
        """
        Check for discriminatory behavior
        """
        from aif360.metrics import BinaryLabelDatasetMetric

        fairness_metrics = {}
        # Calculate disparate impact, equal opportunity, etc.
        # Implementation depends on dataset

        self.results["fairness"] = fairness_metrics
        return fairness_metrics

    def test_privacy_leakage(self, member_samples, non_member_samples):
        """
        Test for membership inference vulnerability
        """
        attack = MembershipInferenceAttack(shadow_models=[self.model])
        attack.train_attack_model(member_samples, non_member_samples)

        accuracy = attack.evaluate()

        self.results["privacy_leakage"] = {
            "membership_inference_accuracy": accuracy
        }
        return accuracy

    def generate_security_report(self):
        """
        Comprehensive security assessment report
        """
        report = "# ML Security Assessment Report\n\n"

        report += "## Adversarial Robustness\n"
        for metric, value in self.results.get("adversarial_robustness", {}).items():
            report += f"- {metric}: {value:.2%}\n"

        report += "\n## Fairness Metrics\n"
        for metric, value in self.results.get("fairness", {}).items():
            report += f"- {metric}: {value:.3f}\n"

        report += "\n## Privacy Assessment\n"
        privacy = self.results.get("privacy_leakage", {})
        report += f"- Membership Inference Accuracy: {privacy.get('membership_inference_accuracy', 0):.2%}\n"

        return report

# Usage in CI/CD
tester = SecurityTestSuite(model, test_loader)
tester.test_adversarial_robustness()
tester.test_privacy_leakage(train_samples, holdout_samples)

report = tester.generate_security_report()

# Fail CI if security thresholds not met
assert tester.results["adversarial_robustness"]["FGSM_eps_0.03"] > 0.80, \
    "Model too vulnerable to adversarial attacks"
```

---

## 5. ML Attack Surface Analysis (4 hours)

### 5.1 Attack Surface Mapping

**ML System Attack Surface**:
```python
class AttackSurfaceAnalyzer:
    def __init__(self, system_architecture):
        self.architecture = system_architecture
        self.attack_vectors = []

    def analyze_data_pipeline(self):
        """
        Identify data ingestion vulnerabilities
        """
        vectors = [
            {
                "component": "Data Collection API",
                "attack_type": "Data Poisoning",
                "entry_point": "Public API endpoint",
                "mitigation": "Input validation, rate limiting"
            },
            {
                "component": "Feature Store",
                "attack_type": "Feature Manipulation",
                "entry_point": "Feature computation logic",
                "mitigation": "Feature schema validation"
            }
        ]
        self.attack_vectors.extend(vectors)

    def analyze_training_pipeline(self):
        """
        Identify training vulnerabilities
        """
        vectors = [
            {
                "component": "Training Job",
                "attack_type": "Hyperparameter Manipulation",
                "entry_point": "Training configuration",
                "mitigation": "Config validation, code review"
            },
            {
                "component": "Model Checkpoints",
                "attack_type": "Backdoor Injection",
                "entry_point": "Checkpoint storage",
                "mitigation": "Integrity checks, signing"
            }
        ]
        self.attack_vectors.extend(vectors)

    def analyze_serving_pipeline(self):
        """
        Identify inference vulnerabilities
        """
        vectors = [
            {
                "component": "Inference API",
                "attack_type": "Adversarial Examples",
                "entry_point": "Public API endpoint",
                "mitigation": "Input validation, adversarial training"
            },
            {
                "component": "Model Server",
                "attack_type": "Model Stealing",
                "entry_point": "Prediction queries",
                "mitigation": "Rate limiting, output perturbation"
            }
        ]
        self.attack_vectors.extend(vectors)

    def generate_attack_surface_map(self):
        """
        Create comprehensive attack surface documentation
        """
        surface_map = {}
        for vector in self.attack_vectors:
            component = vector["component"]
            if component not in surface_map:
                surface_map[component] = []
            surface_map[component].append({
                "attack": vector["attack_type"],
                "entry": vector["entry_point"],
                "mitigation": vector["mitigation"]
            })

        return surface_map

# Usage
analyzer = AttackSurfaceAnalyzer(ml_system_architecture)
analyzer.analyze_data_pipeline()
analyzer.analyze_training_pipeline()
analyzer.analyze_serving_pipeline()

attack_surface = analyzer.generate_attack_surface_map()
```

### 5.2 Attack Surface Reduction

**Strategies**:
1. **Minimize exposed APIs**: Internal-only endpoints when possible
2. **Input sanitization**: Strict validation at boundaries
3. **Network segmentation**: Isolate ML workloads
4. **Principle of least privilege**: Minimal permissions
5. **Disable unnecessary features**: Remove unused functionality

---

## 6. Secure Development Lifecycle for ML (3 hours)

### 6.1 ML-SDL Phases

```
Phase 1: Requirements & Design
├── Security requirements gathering
├── Threat modeling
├── Privacy impact assessment
└── Architecture security review

Phase 2: Implementation
├── Secure coding practices
├── Dependency scanning
├── Code review with security focus
└── Security unit tests

Phase 3: Verification
├── Adversarial testing
├── Privacy testing
├── Penetration testing
└── Security regression tests

Phase 4: Deployment
├── Model signing
├── Secure configuration
├── Deployment security review
└── Production monitoring setup

Phase 5: Operations
├── Continuous monitoring
├── Incident response
├── Security updates
└── Post-incident analysis
```

### 6.2 Secure ML Code Practices

**Example: Secure Model Loading**
```python
import hashlib
import json
from pathlib import Path

class SecureModelRegistry:
    def __init__(self, registry_path, trusted_hashes_path):
        self.registry_path = Path(registry_path)
        self.trusted_hashes = self._load_trusted_hashes(trusted_hashes_path)

    def _load_trusted_hashes(self, path):
        """
        Load known-good model hashes
        """
        with open(path, 'r') as f:
            return json.load(f)

    def _calculate_hash(self, file_path):
        """
        Calculate SHA-256 hash of model file
        """
        sha256_hash = hashlib.sha256()
        with open(file_path, "rb") as f:
            for byte_block in iter(lambda: f.read(4096), b""):
                sha256_hash.update(byte_block)
        return sha256_hash.hexdigest()

    def load_model(self, model_name, version):
        """
        Safely load model with integrity verification
        """
        model_path = self.registry_path / model_name / version / "model.pt"

        # Verify model exists
        if not model_path.exists():
            raise FileNotFoundError(f"Model not found: {model_path}")

        # Calculate hash
        actual_hash = self._calculate_hash(model_path)

        # Verify against trusted hash
        expected_hash = self.trusted_hashes.get(f"{model_name}/{version}")
        if expected_hash is None:
            raise ValueError(f"No trusted hash for {model_name}/{version}")

        if actual_hash != expected_hash:
            raise ValueError(
                f"Model integrity check failed!\n"
                f"Expected: {expected_hash}\n"
                f"Got: {actual_hash}"
            )

        # Load model
        import torch
        model = torch.load(model_path)

        # Log access
        self._log_model_access(model_name, version)

        return model

    def _log_model_access(self, model_name, version):
        """
        Audit log for model access
        """
        import logging
        logging.info(f"Loaded model: {model_name}/{version}")

# Usage
registry = SecureModelRegistry(
    registry_path="/models",
    trusted_hashes_path="/config/trusted_hashes.json"
)

model = registry.load_model("image_classifier", "v2.1.0")
```

---

## 7. Practical Implementation Examples (5 hours)

### 7.1 Comprehensive Security Wrapper

```python
import torch
import numpy as np
from typing import Optional, Dict, Any
import logging

class SecureMLModel:
    """
    Production-ready secure ML model wrapper
    Implements multiple defense layers
    """
    def __init__(
        self,
        model,
        input_validator=None,
        rate_limiter=None,
        output_monitor=None,
        audit_logger=None
    ):
        self.model = model
        self.input_validator = input_validator or InputValidator()
        self.rate_limiter = rate_limiter or RateLimiter()
        self.output_monitor = output_monitor or OutputMonitor()
        self.audit_logger = audit_logger or AuditLogger()

        # Performance metrics
        self.inference_count = 0
        self.rejection_count = 0

    def predict(
        self,
        input_data: np.ndarray,
        user_id: str,
        request_id: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Secure prediction with multiple defense layers
        """
        # Generate request ID
        if request_id is None:
            request_id = self._generate_request_id()

        try:
            # Layer 1: Rate limiting
            if not self.rate_limiter.check_limit(user_id):
                self.rejection_count += 1
                self.audit_logger.log_rejection(
                    request_id, user_id, reason="rate_limit"
                )
                raise ValueError("Rate limit exceeded")

            # Layer 2: Input validation
            if not self.input_validator.validate(input_data):
                self.rejection_count += 1
                self.audit_logger.log_rejection(
                    request_id, user_id, reason="invalid_input"
                )
                raise ValueError("Invalid input detected")

            # Layer 3: Inference
            prediction = self._safe_inference(input_data)

            # Layer 4: Output monitoring
            if self.output_monitor.is_anomalous(prediction):
                self.audit_logger.log_warning(
                    request_id, user_id, reason="anomalous_output"
                )

            # Layer 5: Output perturbation (anti-model-stealing)
            prediction = self._add_output_noise(prediction)

            # Audit logging
            self.audit_logger.log_prediction(
                request_id, user_id, input_data, prediction
            )

            self.inference_count += 1

            return {
                "request_id": request_id,
                "prediction": prediction,
                "confidence": self._calculate_confidence(prediction),
                "status": "success"
            }

        except Exception as e:
            self.audit_logger.log_error(request_id, user_id, str(e))
            raise

    def _safe_inference(self, input_data):
        """
        Run inference with error handling
        """
        try:
            with torch.no_grad():
                input_tensor = torch.from_numpy(input_data).float()
                output = self.model(input_tensor)
                return output.numpy()
        except Exception as e:
            logging.error(f"Inference error: {e}")
            raise

    def _add_output_noise(self, prediction, noise_scale=0.01):
        """
        Add Laplace noise to predictions (defense against model stealing)
        """
        noise = np.random.laplace(0, noise_scale, size=prediction.shape)
        return prediction + noise

    def _calculate_confidence(self, prediction):
        """
        Calculate prediction confidence
        """
        if len(prediction.shape) > 1:
            return float(np.max(prediction))
        return float(prediction)

    def _generate_request_id(self):
        import uuid
        return str(uuid.uuid4())

    def get_metrics(self):
        """
        Return security and performance metrics
        """
        return {
            "total_inferences": self.inference_count,
            "total_rejections": self.rejection_count,
            "rejection_rate": self.rejection_count / max(1, self.inference_count + self.rejection_count)
        }

# Supporting classes
class RateLimiter:
    def __init__(self, max_requests_per_hour=1000):
        from collections import defaultdict
        from datetime import datetime, timedelta

        self.max_requests = max_requests_per_hour
        self.requests = defaultdict(list)

    def check_limit(self, user_id):
        from datetime import datetime, timedelta

        now = datetime.now()
        cutoff = now - timedelta(hours=1)

        # Remove old requests
        self.requests[user_id] = [
            t for t in self.requests[user_id] if t > cutoff
        ]

        # Check limit
        if len(self.requests[user_id]) >= self.max_requests:
            return False

        self.requests[user_id].append(now)
        return True

class OutputMonitor:
    def __init__(self, anomaly_threshold=3.0):
        self.anomaly_threshold = anomaly_threshold
        self.prediction_history = []

    def is_anomalous(self, prediction):
        """
        Detect anomalous outputs using simple statistics
        """
        self.prediction_history.append(prediction)

        if len(self.prediction_history) < 100:
            return False

        # Keep last 1000 predictions
        if len(self.prediction_history) > 1000:
            self.prediction_history.pop(0)

        # Calculate z-score
        mean = np.mean(self.prediction_history, axis=0)
        std = np.std(self.prediction_history, axis=0)

        z_score = np.abs((prediction - mean) / (std + 1e-7))

        return np.any(z_score > self.anomaly_threshold)

class AuditLogger:
    def __init__(self, log_file="ml_audit.log"):
        self.logger = logging.getLogger("ml_security")
        handler = logging.FileHandler(log_file)
        formatter = logging.Formatter(
            '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )
        handler.setFormatter(formatter)
        self.logger.addHandler(handler)
        self.logger.setLevel(logging.INFO)

    def log_prediction(self, request_id, user_id, input_data, prediction):
        self.logger.info(
            f"Prediction: request_id={request_id}, user_id={user_id}, "
            f"input_shape={input_data.shape}, prediction_shape={prediction.shape}"
        )

    def log_rejection(self, request_id, user_id, reason):
        self.logger.warning(
            f"Rejection: request_id={request_id}, user_id={user_id}, "
            f"reason={reason}"
        )

    def log_warning(self, request_id, user_id, reason):
        self.logger.warning(
            f"Warning: request_id={request_id}, user_id={user_id}, "
            f"reason={reason}"
        )

    def log_error(self, request_id, user_id, error):
        self.logger.error(
            f"Error: request_id={request_id}, user_id={user_id}, "
            f"error={error}"
        )

# Usage example
model = torch.load("model.pt")
secure_model = SecureMLModel(
    model=model,
    input_validator=InputValidator(training_data),
    rate_limiter=RateLimiter(max_requests_per_hour=1000),
    output_monitor=OutputMonitor(),
    audit_logger=AuditLogger()
)

# Production inference
result = secure_model.predict(
    input_data=user_input,
    user_id="user_123"
)

print(f"Prediction: {result['prediction']}")
print(f"Confidence: {result['confidence']}")
```

---

## Summary

This module covered foundational ML security concepts:

1. **OWASP ML Top 10**: Understanding ML-specific threats
2. **Threat Modeling**: STRIDE methodology for ML systems
3. **Security by Design**: Layered defenses and secure architecture
4. **Attack Surface Analysis**: Identifying and reducing vulnerabilities
5. **Secure Development Lifecycle**: Integrating security into ML workflows

### Key Takeaways

- ML systems have unique attack surfaces beyond traditional applications
- Defense in depth requires multiple security layers
- Threat modeling must occur during design, not after deployment
- Continuous monitoring and testing are essential
- Security is a process, not a one-time implementation

### Next Steps

- Complete hands-on exercises implementing security controls
- Practice threat modeling on real ML systems
- Build security testing into your ML pipelines
- Review Module 2 on Adversarial ML for deeper attack/defense techniques

---

## References

1. OWASP Machine Learning Security Top 10
2. NIST AI Risk Management Framework
3. Microsoft Security Development Lifecycle for ML
4. Google's Responsible AI Practices
5. "Machine Learning Security" by Clarence Chio
6. Adversarial Robustness Toolbox (ART) documentation
7. MITRE ATLAS (Adversarial Threat Landscape for AI Systems)

## Tools Mentioned

- **Adversarial Robustness Toolbox (ART)**: IBM's adversarial ML library
- **Opacus**: PyTorch differential privacy library
- **Foolbox**: Adversarial attack library
- **CleverHans**: TensorFlow adversarial examples
- **ML Privacy Meter**: Privacy risk assessment

---

**Module Completion**: Proceed to exercises to implement security controls and practice threat modeling.
