# Module 1 Exercises: ML Security Fundamentals

## Overview

These hands-on exercises provide practical experience implementing ML security controls, conducting threat modeling, and defending against common attacks. Each exercise builds upon concepts from the lecture notes and prepares you for real-world security challenges.

**Total Time**: ~12-15 hours
**Prerequisites**: Module 1 lecture notes, Python 3.9+, PyTorch, basic security knowledge

---

## Exercise 1: Adversarial Attack Implementation and Defense (4 hours)

### Objective
Implement adversarial attacks (FGSM, PGD) and defenses to understand input manipulation threats hands-on.

### Learning Outcomes
- Generate adversarial examples using gradient-based methods
- Evaluate model robustness against adversarial perturbations
- Implement and test defensive mechanisms
- Understand the attack-defense arms race

### Setup

```bash
# Create exercise directory
mkdir -p exercises/ex01-adversarial-attacks
cd exercises/ex01-adversarial-attacks

# Install dependencies
pip install torch torchvision numpy matplotlib foolbox
```

### Part 1: FGSM Attack Implementation (1.5 hours)

**Task**: Implement the Fast Gradient Sign Method attack from scratch

```python
# fgsm_attack.py
import torch
import torch.nn as nn
import torch.nn.functional as F
from torchvision import models, datasets, transforms
import matplotlib.pyplot as plt

def fgsm_attack(model, image, label, epsilon):
    """
    Fast Gradient Sign Method attack

    TODO: Implement FGSM attack
    Steps:
    1. Enable gradient tracking on input image
    2. Forward pass and calculate loss
    3. Backward pass to get gradients
    4. Create perturbation using gradient sign
    5. Add perturbation to original image
    6. Clamp to valid image range [0, 1]

    Args:
        model: Neural network model
        image: Input image tensor [1, C, H, W]
        label: True label tensor
        epsilon: Perturbation magnitude

    Returns:
        adv_image: Adversarial example
        perturbation: Added perturbation
    """
    # TODO: Your implementation here
    pass

def evaluate_robustness(model, test_loader, epsilon_values):
    """
    Evaluate model accuracy under FGSM attacks

    TODO: Test model with different epsilon values
    Returns:
        Dictionary mapping epsilon to accuracy
    """
    # TODO: Your implementation here
    pass

def visualize_attack(original, adversarial, perturbation, predictions):
    """
    Visualize original, adversarial, and perturbation

    TODO: Create side-by-side comparison plot
    """
    # TODO: Your implementation here
    pass

# Test your implementation
if __name__ == "__main__":
    # Load pre-trained model
    model = models.resnet18(pretrained=True)
    model.eval()

    # Load test data
    test_loader = torch.utils.data.DataLoader(
        datasets.CIFAR10(root='./data', train=False, download=True,
                        transform=transforms.ToTensor()),
        batch_size=1, shuffle=True
    )

    # Test different epsilon values
    epsilons = [0.0, 0.01, 0.03, 0.05, 0.1, 0.3]
    results = evaluate_robustness(model, test_loader, epsilons)

    # TODO: Generate report
    # Expected results:
    # epsilon=0.00 → ~75% accuracy (baseline)
    # epsilon=0.03 → ~45% accuracy
    # epsilon=0.10 → ~20% accuracy
    # epsilon=0.30 → ~5% accuracy
```

**Expected Output**:
- FGSM attack function that successfully generates adversarial examples
- Robustness evaluation showing accuracy degradation with epsilon
- Visualizations showing imperceptible perturbations causing misclassification

### Part 2: PGD Attack Implementation (1.5 hours)

**Task**: Implement Projected Gradient Descent, a stronger iterative attack

```python
# pgd_attack.py
import torch

def pgd_attack(model, image, label, epsilon, alpha=0.01, num_iter=40):
    """
    Projected Gradient Descent attack

    TODO: Implement PGD attack
    PGD is iterative FGSM with projection back to epsilon ball

    Steps:
    1. Start with random perturbation in epsilon ball
    2. For num_iter iterations:
        a. Compute gradient like FGSM
        b. Take step of size alpha
        c. Project back to epsilon ball around original
        d. Clamp to valid image range

    Args:
        model: Neural network model
        image: Input image tensor
        label: True label
        epsilon: L-infinity constraint
        alpha: Step size
        num_iter: Number of iterations

    Returns:
        adv_image: Adversarial example
    """
    # TODO: Your implementation here
    pass

def compare_attacks(model, test_loader):
    """
    Compare FGSM vs PGD attack success rates

    TODO: Test both attacks on same images
    Expected: PGD has higher success rate due to optimization
    """
    # TODO: Your implementation here
    pass
```

**Expected Output**:
- PGD attack with higher success rate than FGSM (typically +10-20%)
- Comparison report showing PGD finds stronger adversarial examples

### Part 3: Defensive Mechanisms (1 hour)

**Task**: Implement input validation and adversarial training

```python
# defenses.py
import torch
import numpy as np
from sklearn.ensemble import IsolationForest

class AdversarialDetector:
    """
    Detect adversarial examples using statistical methods

    TODO: Implement detection based on:
    1. Prediction confidence
    2. Feature layer statistics
    3. Ensemble disagreement
    """
    def __init__(self, model, clean_data):
        self.model = model
        # TODO: Fit detector on clean data
        pass

    def detect(self, image):
        """
        Returns True if image is likely adversarial
        """
        # TODO: Implement detection logic
        pass

def adversarial_training(model, train_loader, epochs=5, epsilon=0.03):
    """
    Train model with adversarial examples

    TODO: Implement adversarial training
    For each batch:
    1. Generate adversarial examples
    2. Combine with clean examples
    3. Train on mixed batch

    Expected: Improved robustness but slight accuracy drop
    """
    # TODO: Your implementation here
    pass

# Test defenses
if __name__ == "__main__":
    # Test detector
    detector = AdversarialDetector(model, clean_samples)

    clean_detected = detector.detect(clean_image)  # Should be False
    adv_detected = detector.detect(adversarial_image)  # Should be True

    # Test adversarial training
    robust_model = adversarial_training(model, train_loader)

    # Compare robustness
    baseline_acc = evaluate_robustness(model, test_loader, [0.03])
    robust_acc = evaluate_robustness(robust_model, test_loader, [0.03])

    print(f"Baseline accuracy under attack: {baseline_acc}")
    print(f"Adversarially trained accuracy: {robust_acc}")
    # Expected: 15-25% improvement in robust accuracy
```

### Deliverables

1. **Code**:
   - `fgsm_attack.py`: Complete FGSM implementation
   - `pgd_attack.py`: Complete PGD implementation
   - `defenses.py`: Detection and adversarial training

2. **Report** (`REPORT.md`):
   - Attack success rates at different epsilon values
   - Comparison of FGSM vs PGD effectiveness
   - Defense mechanism performance (detection rate, false positives)
   - Visualizations of adversarial examples
   - Analysis of robustness-accuracy tradeoff

3. **Demonstration**:
   - Working attacks that fool the model
   - Defenses that improve robustness
   - Clear documentation of findings

### Evaluation Criteria

- [ ] FGSM correctly generates adversarial examples
- [ ] PGD shows higher success rate than FGSM
- [ ] Attack success rates match expected ranges
- [ ] Detector achieves >80% detection rate with <20% false positives
- [ ] Adversarial training improves robustness by 15%+
- [ ] Code is well-documented with clear explanations
- [ ] Report provides insightful analysis

---

## Exercise 2: Threat Modeling Workshop (3 hours)

### Objective
Conduct comprehensive threat modeling for a realistic ML system using STRIDE methodology.

### Learning Outcomes
- Apply STRIDE framework to ML systems
- Identify ML-specific threats across the pipeline
- Create threat model documentation
- Prioritize threats by risk score

### Scenario

You're building **SmartDoc**, an ML-powered document classification system for a healthcare company.

**System Components**:
- **Data Collection**: Users upload documents via web portal
- **Preprocessing**: Extract text, normalize, tokenize
- **Feature Engineering**: Generate embeddings using BERT
- **Model Serving**: REST API serving classification predictions
- **Monitoring**: Log predictions and performance metrics
- **Storage**: PostgreSQL for metadata, S3 for documents

**Requirements**:
- Must comply with HIPAA
- Handle PHI (Protected Health Information)
- 99.9% uptime SLA
- Process 10,000 documents/day

### Part 1: Asset Identification (30 minutes)

**Task**: Identify and categorize all valuable assets

```python
# threat_model.py
from dataclasses import dataclass
from typing import List
from enum import Enum

class Sensitivity(Enum):
    LOW = 1
    MEDIUM = 2
    HIGH = 3
    CRITICAL = 4

@dataclass
class Asset:
    name: str
    sensitivity: Sensitivity
    description: str
    location: str

class ThreatModel:
    def __init__(self, system_name: str):
        self.system_name = system_name
        self.assets: List[Asset] = []
        self.threats: List[Threat] = []
        self.controls: List[Control] = []

    def add_asset(self, name, sensitivity, description, location):
        """
        TODO: Add asset to threat model

        Example assets for SmartDoc:
        - Training data (HIGH): Contains PHI documents
        - Trained model (CRITICAL): Proprietary classification model
        - User credentials (CRITICAL): Authentication tokens
        - API keys (CRITICAL): External service access
        - Prediction logs (HIGH): May contain sensitive info
        - Infrastructure configs (MEDIUM): Terraform, K8s configs
        """
        # TODO: Implement
        pass

# TODO: Identify at least 10 assets with appropriate sensitivity levels
```

### Part 2: STRIDE Threat Analysis (1.5 hours)

**Task**: Apply STRIDE to each component and identify threats

```python
@dataclass
class Threat:
    id: str
    stride_category: str  # Spoofing, Tampering, Repudiation, etc.
    component: str
    description: str
    likelihood: str  # low, medium, high
    impact: str  # low, medium, high, critical
    risk_score: int

def apply_stride_to_component(component_name, component_description):
    """
    TODO: Generate STRIDE threats for a component

    Example for "Model Serving API":

    Spoofing:
    - Attacker impersonates legitimate user
    - Forged API requests

    Tampering:
    - Adversarial inputs to manipulate predictions
    - Model poisoning via API feedback

    Repudiation:
    - No audit trail for predictions
    - Users deny making requests

    Information Disclosure:
    - Model stealing via systematic queries
    - Prediction leaks sensitive training data

    Denial of Service:
    - Resource exhaustion via expensive queries
    - Model performance degradation

    Elevation of Privilege:
    - API vulnerability grants admin access
    - Bypass authentication
    """
    threats = []
    # TODO: Generate threats for all STRIDE categories
    return threats

# TODO: Apply STRIDE to all components:
# 1. Data Collection Portal
# 2. Preprocessing Pipeline
# 3. Feature Engineering
# 4. Model Training
# 5. Model Serving API
# 6. Monitoring System
# 7. Data Storage
```

### Part 3: Risk Prioritization (30 minutes)

**Task**: Calculate risk scores and prioritize threats

```python
def calculate_risk_score(likelihood: str, impact: str) -> int:
    """
    TODO: Implement risk matrix

    Risk Matrix:
    Likelihood x Impact = Risk Score

    Low x Low = 1
    Low x Medium = 2
    Low x High = 3
    Low x Critical = 4
    Medium x Low = 2
    Medium x Medium = 4
    Medium x High = 6
    Medium x Critical = 8
    High x Low = 3
    High x Medium = 6
    High x High = 9
    High x Critical = 10
    """
    # TODO: Implement
    pass

def prioritize_threats(threats: List[Threat]) -> List[Threat]:
    """
    TODO: Sort threats by risk score (descending)
    """
    # TODO: Implement
    pass
```

### Part 4: Control Design (30 minutes)

**Task**: Design security controls for top threats

```python
@dataclass
class Control:
    control_id: str
    threat_id: str
    control_type: str  # preventive, detective, corrective
    description: str
    effectiveness: str  # low, medium, high
    cost: str  # low, medium, high
    implementation_effort: str  # low, medium, high

def design_control(threat: Threat) -> Control:
    """
    TODO: Design appropriate control for threat

    Example for "Model Stealing (High x Critical = 10)":

    Control:
    - Type: Preventive
    - Description: Rate limiting (1000 queries/user/hour) +
                   Query pattern analysis +
                   Output perturbation (Laplace noise σ=0.01)
    - Effectiveness: High
    - Cost: Low (software only)
    - Effort: Medium (2-3 days implementation)
    """
    # TODO: Implement
    pass
```

### Part 5: Documentation Generation (30 minutes)

**Task**: Generate comprehensive threat model report

```python
def generate_threat_model_report(tm: ThreatModel) -> str:
    """
    TODO: Generate markdown report

    Sections:
    1. Executive Summary
    2. System Description
    3. Asset Inventory (sorted by sensitivity)
    4. Threat Analysis (sorted by risk)
    5. Security Controls
    6. Recommendations
    7. Residual Risks
    """
    # TODO: Implement
    pass

# Generate report
tm = ThreatModel("SmartDoc Healthcare Document Classifier")

# TODO: Add assets (from Part 1)
# TODO: Add threats (from Part 2)
# TODO: Calculate risks (from Part 3)
# TODO: Design controls (from Part 4)

report = generate_threat_model_report(tm)
with open("THREAT_MODEL.md", "w") as f:
    f.write(report)
```

### Deliverables

1. **Threat Model Report** (`THREAT_MODEL.md`):
   - Complete asset inventory (10+ assets)
   - STRIDE analysis for all components (30+ threats)
   - Risk prioritization matrix
   - Security controls for top 10 threats
   - Implementation roadmap

2. **Code** (`threat_model.py`):
   - Working threat modeling framework
   - Risk calculation logic
   - Report generation

3. **Attack Trees** (optional bonus):
   - Visual representations of attack paths
   - AND/OR logic for threat scenarios

### Evaluation Criteria

- [ ] At least 10 assets identified with correct sensitivity
- [ ] STRIDE applied to all 7 components
- [ ] At least 30 threats documented
- [ ] Risk scores calculated correctly
- [ ] Controls designed for top 10 threats
- [ ] Report is comprehensive and professional
- [ ] Clear prioritization of security investments

---

## Exercise 3: Secure ML Pipeline Implementation (5-6 hours)

### Objective
Build a production-grade ML inference API with multiple security layers.

### Learning Outcomes
- Implement defense-in-depth for ML systems
- Add authentication, rate limiting, input validation
- Create audit logging and monitoring
- Deploy with security best practices

### Part 1: Baseline Insecure System (1 hour)

**Task**: Start with insecure baseline to understand vulnerabilities

```python
# insecure_api.py
from flask import Flask, request, jsonify
import torch
import pickle

app = Flask(__name__)

# INSECURE: Load model from untrusted source
model = pickle.load(open("model.pkl", "rb"))

@app.route("/predict", methods=["POST"])
def predict():
    # INSECURE: No input validation
    data = request.json["input"]

    # INSECURE: No rate limiting
    # INSECURE: No authentication
    # INSECURE: No audit logging

    prediction = model.predict(data)

    # INSECURE: Return raw predictions (model stealing vulnerability)
    return jsonify({"prediction": prediction.tolist()})

if __name__ == "__main__":
    # INSECURE: Debug mode in production
    # INSECURE: Exposed to all interfaces
    app.run(host="0.0.0.0", debug=True, port=5000)
```

**Task**: Document all security vulnerabilities (aim for 10+)

### Part 2: Implement Security Layers (4-5 hours)

**Task**: Transform insecure API into production-ready secure system

```python
# secure_api.py
from flask import Flask, request, jsonify, abort
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
import torch
import logging
import hashlib
import jwt
import numpy as np
from datetime import datetime
import os

# Configure secure logging
logging.basicConfig(
    filename='ml_api_audit.log',
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

app = Flask(__name__)
app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY')

# TODO: Implement rate limiting
limiter = Limiter(
    app=app,
    key_func=get_remote_address,
    default_limits=["1000 per hour"]
)

class SecureModelLoader:
    """
    TODO: Implement secure model loading

    Requirements:
    1. Verify model hash against trusted registry
    2. Use torch.load with weights_only=True
    3. Log all model loads
    4. Validate model architecture
    """
    def __init__(self, model_path, expected_hash):
        # TODO: Implement
        pass

    def load_model(self):
        # TODO: Implement secure loading
        pass

class InputValidator:
    """
    TODO: Implement input validation

    Requirements:
    1. Check data types and shapes
    2. Detect out-of-distribution inputs
    3. Validate value ranges
    4. Sanitize inputs
    """
    def __init__(self, expected_shape, value_range):
        # TODO: Implement
        pass

    def validate(self, input_data):
        # TODO: Implement validation logic
        # Return (is_valid, error_message)
        pass

class AuditLogger:
    """
    TODO: Implement comprehensive audit logging

    Log format:
    {
        "timestamp": "2025-01-15T10:30:00Z",
        "request_id": "uuid",
        "user_id": "user123",
        "action": "predict",
        "input_hash": "sha256",
        "output_hash": "sha256",
        "latency_ms": 45,
        "status": "success",
        "ip_address": "192.168.1.1"
    }
    """
    @staticmethod
    def log_request(request_id, user_id, action, metadata):
        # TODO: Implement
        pass

def verify_token(token):
    """
    TODO: Implement JWT token verification
    """
    try:
        # TODO: Decode and verify JWT
        payload = jwt.decode(token, app.config['SECRET_KEY'], algorithms=['HS256'])
        return payload
    except:
        return None

@app.before_request
def authenticate():
    """
    TODO: Implement authentication middleware
    """
    if request.endpoint == 'health':
        return  # Health check doesn't require auth

    # TODO: Verify authentication token
    # Reject if invalid
    pass

@app.route("/predict", methods=["POST"])
@limiter.limit("100 per minute")  # Per-endpoint rate limit
def predict():
    """
    Secure prediction endpoint

    TODO: Implement all security layers:
    1. Authentication ✓ (middleware)
    2. Rate limiting ✓ (decorator)
    3. Input validation
    4. Inference with error handling
    5. Output perturbation (anti-model-stealing)
    6. Audit logging
    7. Error handling (don't leak info)
    """
    request_id = str(uuid.uuid4())

    try:
        # TODO: Extract user from JWT
        user_id = "TODO"

        # TODO: Validate input
        input_data = request.json.get("input")
        if not validator.validate(input_data):
            AuditLogger.log_request(request_id, user_id, "predict", {
                "status": "rejected",
                "reason": "invalid_input"
            })
            abort(400, "Invalid input")

        # TODO: Make prediction
        prediction = model.predict(input_data)

        # TODO: Add output perturbation
        # Add small Laplace noise to prevent model stealing

        # TODO: Audit log successful prediction

        return jsonify({
            "request_id": request_id,
            "prediction": prediction,
            "timestamp": datetime.utcnow().isoformat()
        })

    except Exception as e:
        # TODO: Log error without exposing details
        logger.error(f"Prediction error: {request_id}")
        abort(500, "Internal server error")

@app.route("/health", methods=["GET"])
def health():
    """Public health check endpoint"""
    return jsonify({"status": "healthy"})

@app.errorhandler(429)
def ratelimit_handler(e):
    """Handle rate limit errors"""
    return jsonify({
        "error": "Rate limit exceeded",
        "description": str(e.description)
    }), 429

if __name__ == "__main__":
    # Load model securely
    loader = SecureModelLoader("model.pt", expected_hash="sha256...")
    model = loader.load_model()

    # Initialize validator
    validator = InputValidator(expected_shape=(28, 28), value_range=(0, 1))

    # Run with production settings
    app.run(
        host="127.0.0.1",  # Only local connections
        debug=False,       # Disable debug mode
        port=5000,
        ssl_context='adhoc'  # HTTPS
    )
```

### Part 3: Docker Security (30 minutes)

**Task**: Create secure Docker configuration

```dockerfile
# Dockerfile
# TODO: Implement secure Docker image

# Use minimal base image
FROM python:3.11-slim

# Don't run as root
RUN useradd -m -u 1000 mluser

# Set working directory
WORKDIR /app

# Install dependencies as root
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application
COPY --chown=mluser:mluser . .

# Switch to non-root user
USER mluser

# Expose port
EXPOSE 5000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:5000/health')"

# Run application
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "4", "secure_api:app"]
```

```yaml
# docker-compose.yml
version: '3.8'

services:
  ml-api:
    build: .
    ports:
      - "5000:5000"
    environment:
      - SECRET_KEY=${SECRET_KEY}
    # Security options
    security_opt:
      - no-new-privileges:true
    read_only: true
    tmpfs:
      - /tmp
    # Resource limits
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G
        reservations:
          cpus: '1'
          memory: 1G
    # Health check
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    # Logging
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

### Part 4: Kubernetes Security (30 minutes)

**Task**: Deploy with Kubernetes security policies

```yaml
# k8s-deployment.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ml-api-sa
  namespace: ml-production

---
apiVersion: v1
kind: Secret
metadata:
  name: ml-api-secrets
  namespace: ml-production
type: Opaque
data:
  secret-key: <base64-encoded-secret>

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ml-api
  namespace: ml-production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: ml-api
  template:
    metadata:
      labels:
        app: ml-api
    spec:
      serviceAccountName: ml-api-sa

      # Security context
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 1000

      containers:
      - name: ml-api
        image: ml-api:latest
        imagePullPolicy: Always

        # Container security
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          capabilities:
            drop:
              - ALL

        # Resource limits
        resources:
          limits:
            cpu: "2"
            memory: "2Gi"
          requests:
            cpu: "1"
            memory: "1Gi"

        # Environment from secret
        env:
        - name: SECRET_KEY
          valueFrom:
            secretKeyRef:
              name: ml-api-secrets
              key: secret-key

        # Health checks
        livenessProbe:
          httpGet:
            path: /health
            port: 5000
          initialDelaySeconds: 30
          periodSeconds: 10

        readinessProbe:
          httpGet:
            path: /health
            port: 5000
          initialDelaySeconds: 5
          periodSeconds: 5

---
# Network policy - only allow ingress from specific namespace
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: ml-api-netpol
  namespace: ml-production
spec:
  podSelector:
    matchLabels:
      app: ml-api
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: api-gateway
    ports:
    - protocol: TCP
      port: 5000
```

### Deliverables

1. **Code**:
   - `secure_api.py`: Fully secured Flask API
   - `test_security.py`: Security test suite
   - `Dockerfile`: Secure container image
   - `docker-compose.yml`: Local deployment
   - `k8s-deployment.yaml`: Production deployment

2. **Documentation** (`SECURITY_IMPLEMENTATION.md`):
   - Security architecture diagram
   - Threat mitigation mapping
   - Deployment guide
   - Security testing results
   - Performance impact analysis

3. **Demonstration**:
   - Running secure API
   - Blocked attacks (rate limiting, invalid inputs)
   - Audit logs showing requests
   - Load test results

### Evaluation Criteria

- [ ] All 10+ vulnerabilities from baseline fixed
- [ ] Authentication working (JWT)
- [ ] Rate limiting prevents abuse
- [ ] Input validation blocks invalid/adversarial inputs
- [ ] Audit logging captures all requests
- [ ] Docker image follows security best practices
- [ ] Kubernetes deployment uses security contexts
- [ ] API performance acceptable (<100ms p99 latency)
- [ ] Documentation complete and professional

---

## Exercise 4: Security Testing and CI/CD Integration (2-3 hours)

### Objective
Integrate security testing into CI/CD pipeline and automate security validation.

### Learning Outcomes
- Write security test cases for ML systems
- Integrate security scans in CI/CD
- Automate threat detection
- Implement continuous security monitoring

### Part 1: Security Test Suite (1.5 hours)

```python
# test_security.py
import pytest
import requests
import time
from concurrent.futures import ThreadPoolExecutor

BASE_URL = "http://localhost:5000"

class TestAuthentication:
    """Test authentication and authorization"""

    def test_predict_requires_auth(self):
        """Prediction endpoint should require authentication"""
        # TODO: Test that requests without auth token are rejected
        response = requests.post(f"{BASE_URL}/predict", json={"input": [1, 2, 3]})
        assert response.status_code == 401

    def test_invalid_token_rejected(self):
        """Invalid tokens should be rejected"""
        # TODO: Test with malformed JWT
        headers = {"Authorization": "Bearer invalid_token"}
        response = requests.post(
            f"{BASE_URL}/predict",
            json={"input": [1, 2, 3]},
            headers=headers
        )
        assert response.status_code == 401

    def test_expired_token_rejected(self):
        """Expired tokens should be rejected"""
        # TODO: Test with expired JWT
        pass

class TestRateLimiting:
    """Test rate limiting protection"""

    def test_rate_limit_enforced(self):
        """Rate limit should block excessive requests"""
        # TODO: Send >100 requests in 1 minute
        # Should get 429 Too Many Requests

        def make_request():
            return requests.post(f"{BASE_URL}/predict", json={"input": [1, 2, 3]})

        with ThreadPoolExecutor(max_workers=10) as executor:
            responses = list(executor.map(lambda _: make_request(), range(150)))

        # Check that some requests were rate limited
        status_codes = [r.status_code for r in responses]
        assert 429 in status_codes

        # Calculate rejection rate
        rejected = status_codes.count(429)
        assert rejected >= 50, f"Expected at least 50 rejections, got {rejected}"

class TestInputValidation:
    """Test input validation and sanitization"""

    def test_invalid_shape_rejected(self):
        """Inputs with wrong shape should be rejected"""
        # TODO: Test with incorrect input dimensions
        pass

    def test_out_of_range_rejected(self):
        """Inputs outside valid range should be rejected"""
        # TODO: Test with values outside [0, 1]
        pass

    def test_adversarial_input_detected(self):
        """Adversarial inputs should be flagged"""
        # TODO: Generate adversarial example and verify detection
        pass

    def test_sql_injection_attempt(self):
        """SQL injection attempts should be handled safely"""
        malicious_input = "'; DROP TABLE users; --"
        # TODO: Verify safe handling
        pass

class TestAuditLogging:
    """Test audit logging functionality"""

    def test_requests_logged(self):
        """All requests should be logged"""
        # TODO: Make request, verify log entry exists
        pass

    def test_log_contains_required_fields(self):
        """Logs should contain timestamp, user, action, status"""
        # TODO: Verify log format
        pass

    def test_failures_logged(self):
        """Failed requests should be logged"""
        # TODO: Make failing request, verify logged
        pass

class TestModelStealing:
    """Test defenses against model stealing"""

    def test_output_perturbation(self):
        """Outputs should have noise added"""
        # TODO: Make same request multiple times
        # Outputs should differ slightly due to noise

        results = []
        for _ in range(10):
            response = requests.post(f"{BASE_URL}/predict", json={"input": [1, 2, 3]})
            results.append(response.json()["prediction"])

        # Check variance in outputs (should be > 0 due to noise)
        variance = np.var(results)
        assert variance > 0, "No output perturbation detected"

    def test_systematic_probing_detected(self):
        """Systematic probing patterns should be detected"""
        # TODO: Make highly similar queries
        # Should trigger detection
        pass

class TestErrorHandling:
    """Test secure error handling"""

    def test_errors_dont_leak_info(self):
        """Error messages should not reveal internals"""
        # TODO: Trigger error, verify generic message
        pass

    def test_stack_traces_hidden(self):
        """Stack traces should not be exposed"""
        # TODO: Verify debug mode disabled
        pass

# TODO: Add more test classes for:
# - TLS/SSL encryption
# - Container security
# - Resource exhaustion protection
# - Model integrity verification
```

### Part 2: CI/CD Integration (1 hour)

```yaml
# .github/workflows/security-checks.yml
name: Security Checks

on:
  pull_request:
    branches: [ main ]
  push:
    branches: [ main ]
  schedule:
    - cron: '0 0 * * *'  # Daily security scan

jobs:
  dependency-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Run Snyk security scan
        uses: snyk/actions/python@master
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
        with:
          args: --severity-threshold=high

      - name: Check for known vulnerabilities
        run: |
          pip install safety
          safety check --json

  code-security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Run Bandit security linter
        run: |
          pip install bandit
          bandit -r . -f json -o bandit-report.json

      - name: Upload security report
        uses: actions/upload-artifact@v3
        with:
          name: security-reports
          path: bandit-report.json

  secret-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Run TruffleHog secrets scanner
        uses: trufflesecurity/trufflehog@main
        with:
          path: ./
          base: ${{ github.event.repository.default_branch }}

  container-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Build Docker image
        run: docker build -t ml-api:test .

      - name: Run Trivy vulnerability scanner
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: ml-api:test
          format: 'sarif'
          output: 'trivy-results.sarif'

      - name: Upload Trivy results to GitHub Security
        uses: github/codeql-action/upload-sarif@v2
        with:
          sarif_file: 'trivy-results.sarif'

  security-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Start API
        run: |
          docker-compose up -d
          sleep 10  # Wait for startup

      - name: Run security test suite
        run: |
          pip install pytest requests
          pytest test_security.py -v

      - name: Stop API
        run: docker-compose down

  adversarial-robustness:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Test adversarial robustness
        run: |
          pip install foolbox torch
          python test_adversarial_robustness.py

      - name: Check robustness threshold
        run: |
          # Fail if robustness below threshold
          python -c "
          import json
          with open('robustness_results.json') as f:
              results = json.load(f)
          assert results['accuracy_eps_0.03'] > 0.75, 'Robustness too low'
          "
```

### Deliverables

1. **Test Suite** (`test_security.py`):
   - 20+ security test cases
   - Coverage for all attack vectors
   - Clear assertions and documentation

2. **CI/CD Configuration**:
   - GitHub Actions workflow
   - Automated security scans
   - Test execution on every PR

3. **Security Report** (`SECURITY_TEST_RESULTS.md`):
   - Test execution results
   - Vulnerability findings
   - Remediation recommendations

### Evaluation Criteria

- [ ] Test suite covers authentication, rate limiting, input validation
- [ ] CI/CD workflow runs all security checks
- [ ] Dependency scanning integrated
- [ ] Container scanning integrated
- [ ] All tests pass
- [ ] Documentation complete

---

## Bonus Exercise: Capture The Flag (CTF) Challenge

### Objective
Test your ML security skills in a simulated attack/defense scenario.

### Challenge: Hack the ML API

We've deployed an intentionally vulnerable ML API. Your goal is to:

1. **Reconnaissance** (30 min): Discover vulnerabilities
2. **Exploitation** (1 hour): Exploit vulnerabilities to:
   - Bypass authentication
   - Steal the model
   - Poison predictions
   - Cause denial of service
3. **Defense** (1 hour): Patch vulnerabilities
4. **Red Team** (30 min): Try to break your patches

### Flags to Capture

1. **Flag 1**: Bypass authentication and access admin endpoint
2. **Flag 2**: Extract model architecture via API queries
3. **Flag 3**: Cause model to misclassify with adversarial example
4. **Flag 4**: Inject poisoned data into retraining pipeline
5. **Flag 5**: Cause API to crash (DoS)

---

## Submission Guidelines

For each exercise:

1. **Code**: All implementation files
2. **Report**: Markdown document with analysis and results
3. **Demonstration**: Screenshots or recorded demo
4. **Reflection**: What you learned, challenges faced

Submit via:
```bash
git add .
git commit -m "Complete Module 1 Exercises"
git push origin module-01-exercises
```

---

## Additional Resources

- OWASP ML Security Testing Guide
- Adversarial Robustness Toolbox (ART) tutorials
- NIST AI Risk Management Framework
- CleverHans library documentation
- Foolbox documentation

---

## Getting Help

- Review lecture notes for theoretical foundation
- Check code examples in lecture materials
- Consult OWASP ML Top 10 documentation
- Ask in discussion forum
- Review provided test cases for expected behavior

**Good luck! Remember: Security is a mindset, not a checklist.**
