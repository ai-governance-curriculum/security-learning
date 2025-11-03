# Module 3: Data Privacy & Compliance

## Overview

This module focuses on privacy-preserving machine learning and regulatory compliance. You'll learn to implement differential privacy, secure federated learning, comply with GDPR/HIPAA/CCPA, and build privacy-compliant ML systems. Privacy is not just a legal requirement—it's fundamental to trustworthy AI.

**Duration**: 25 hours
**Prerequisites**: Module 1 (ML Security Fundamentals), probability theory, ML fundamentals

## Learning Objectives

By completing this module, you will:

1. Understand privacy regulations (GDPR, HIPAA, CCPA, COPPA)
2. Implement differential privacy for ML training and inference
3. Build federated learning systems with privacy guarantees
4. Apply data anonymization and de-identification techniques
5. Conduct privacy impact assessments
6. Deploy privacy-compliant ML pipelines
7. Handle data subject rights (access, deletion, portability)

---

## 1. Privacy Regulations and Compliance (5 hours)

### 1.1 General Data Protection Regulation (GDPR)

**Scope**: EU residents' personal data, worldwide enforcement

**Key Principles**:

1. **Lawfulness, Fairness, Transparency**
   - Clear consent mechanisms
   - Transparent data processing
   - Privacy notices

2. **Purpose Limitation**
   - Collect data for specific, explicit purposes
   - Cannot repurpose data without new consent
   - Implications for ML: Can't train new models without consent

3. **Data Minimization**
   - Collect only necessary data
   - Implications for ML: Feature selection is compliance requirement
   - Challenge: ML benefits from more data

4. **Accuracy**
   - Keep data accurate and up-to-date
   - Right to rectification
   - Implications for ML: Model updates when data corrected

5. **Storage Limitation**
   - Retain data only as long as necessary
   - Implications for ML: Model retention policies

6. **Integrity and Confidentiality**
   - Security measures (encryption, access control)
   - Protect against unauthorized access

**Key Rights**:

```python
class GDPRDataSubjectRights:
    """
    Implementation of GDPR data subject rights
    """
    def right_to_access(self, user_id):
        """
        Art. 15: Right to access personal data

        User can request:
        - What data you have
        - Why you're processing it
        - Who you've shared it with
        - How long you'll keep it
        """
        user_data = self.get_all_user_data(user_id)
        processing_purposes = self.get_processing_purposes(user_id)
        data_recipients = self.get_data_recipients(user_id)
        retention_period = self.get_retention_period(user_id)

        return {
            "personal_data": user_data,
            "purposes": processing_purposes,
            "recipients": data_recipients,
            "retention": retention_period
        }

    def right_to_rectification(self, user_id, corrections):
        """
        Art. 16: Right to correct inaccurate data

        Implications for ML:
        - Update training data
        - Potentially retrain affected models
        - Update feature stores
        """
        # Update user data
        self.update_user_data(user_id, corrections)

        # Update training datasets
        self.update_training_data(user_id, corrections)

        # Check if retraining needed
        if self.requires_model_update(corrections):
            self.trigger_model_retraining()

        # Log rectification
        self.audit_log("rectification", user_id, corrections)

    def right_to_erasure(self, user_id):
        """
        Art. 17: Right to be forgotten

        Implications for ML:
        - Delete from all databases
        - Remove from training data
        - Retrain models without user's data (machine unlearning)
        - Remove from feature stores, caches, logs
        """
        # Delete from primary databases
        self.delete_user_data(user_id)

        # Remove from training data
        self.remove_from_training_data(user_id)

        # Machine unlearning
        if self.requires_model_update():
            self.unlearn_user_data(user_id)

        # Remove from derived data
        self.delete_user_features(user_id)
        self.delete_user_embeddings(user_id)

        # Anonymize logs
        self.anonymize_logs(user_id)

        # Audit trail (but anonymized)
        self.audit_log("erasure", user_id="[DELETED]")

    def right_to_data_portability(self, user_id, format="json"):
        """
        Art. 20: Right to receive data in machine-readable format

        User can request data in structured format (JSON, CSV, XML)
        """
        user_data = self.get_all_user_data(user_id)

        if format == "json":
            return json.dumps(user_data, indent=2)
        elif format == "csv":
            return self.to_csv(user_data)
        elif format == "xml":
            return self.to_xml(user_data)

    def right_to_object(self, user_id):
        """
        Art. 21: Right to object to processing

        Particularly for:
        - Direct marketing
        - Automated decision-making
        - Profiling
        """
        # Opt out of marketing
        self.opt_out_marketing(user_id)

        # Disable automated decisions
        self.disable_automated_decisions(user_id)

        # Stop profiling
        self.stop_profiling(user_id)

    def right_to_human_review(self, user_id, decision_id):
        """
        Art. 22: Right not to be subject to automated decision-making

        Users can request human review of automated decisions
        """
        decision = self.get_decision(decision_id)

        # Flag for human review
        self.flag_for_human_review(decision_id, user_id)

        # Provide explanation
        explanation = self.generate_explanation(decision)

        return {
            "decision": decision,
            "explanation": explanation,
            "review_status": "pending_human_review"
        }

# Example usage
gdpr_system = GDPRDataSubjectRights()

# User requests their data
user_data = gdpr_system.right_to_access(user_id="user123")

# User corrects their address
gdpr_system.right_to_rectification(
    user_id="user123",
    corrections={"address": "123 New Street"}
)

# User requests deletion
gdpr_system.right_to_erasure(user_id="user123")
```

**GDPR Penalties**:
- Up to €20 million or 4% of global annual revenue (whichever is higher)
- Examples: Google €50M (2019), Amazon €746M (2021), Meta €1.2B (2023)

**ML-Specific Compliance Challenges**:
1. **Model as personal data**: If model memorizes training data (membership inference)
2. **Right to explanation**: Article 22 requires explainability for automated decisions
3. **Machine unlearning**: Technically challenging to remove individual's influence
4. **Consent management**: Training models requires valid consent

### 1.2 Health Insurance Portability and Accountability Act (HIPAA)

**Scope**: US healthcare data (Protected Health Information - PHI)

**Key Requirements**:

**1. Privacy Rule**
- Minimum necessary standard (collect/use minimal PHI)
- Patient rights (access, amendment, accounting of disclosures)
- Authorization for uses beyond treatment/payment/operations

**2. Security Rule**
- Administrative safeguards (policies, training, access management)
- Physical safeguards (facility access, workstation security)
- Technical safeguards (encryption, authentication, audit logs)

**3. Breach Notification Rule**
- Notify affected individuals within 60 days
- Notify HHS (Department of Health and Human Services)
- If >500 individuals, notify media

**HIPAA Technical Safeguards for ML**:

```python
class HIPAACompliantMLSystem:
    """
    HIPAA-compliant ML system for healthcare data
    """
    def __init__(self):
        self.encryption_key = self.load_encryption_key()
        self.audit_logger = AuditLogger()

    def access_control(self, user_id, resource):
        """
        § 164.312(a)(1): Implement access controls

        - Unique user identification
        - Emergency access procedure
        - Automatic logoff
        - Encryption and decryption
        """
        # Verify user authentication
        if not self.authenticate_user(user_id):
            self.audit_logger.log("access_denied", user_id, resource)
            raise PermissionError("Authentication failed")

        # Check authorization
        if not self.authorize_user(user_id, resource):
            self.audit_logger.log("access_denied", user_id, resource)
            raise PermissionError("User not authorized")

        # Log access
        self.audit_logger.log("access_granted", user_id, resource)

        return True

    def encrypt_data_at_rest(self, phi_data):
        """
        § 164.312(a)(2)(iv): Encryption required for data at rest

        Use AES-256 encryption for PHI
        """
        from cryptography.fernet import Fernet

        # Encrypt PHI
        f = Fernet(self.encryption_key)
        encrypted_data = f.encrypt(phi_data.encode())

        return encrypted_data

    def encrypt_data_in_transit(self, phi_data):
        """
        § 164.312(e)(1): Transmission security

        Use TLS 1.2+ for all PHI transmission
        """
        # Enforce HTTPS/TLS
        # In production, configure web server (nginx, Apache) with TLS
        return phi_data  # Actual encryption handled by TLS layer

    def audit_and_accountability(self, action, user_id, resource, phi_accessed=None):
        """
        § 164.312(b): Audit controls

        Log all PHI access:
        - Who accessed
        - What was accessed
        - When
        - What action was performed
        """
        audit_entry = {
            "timestamp": datetime.utcnow().isoformat(),
            "user_id": user_id,
            "action": action,
            "resource": resource,
            "phi_accessed": phi_accessed is not None,
            "phi_identifiers": self.hash_phi_identifiers(phi_accessed) if phi_accessed else None
        }

        self.audit_logger.write(audit_entry)

    def de_identification(self, phi_data):
        """
        § 164.514(a): De-identification of PHI

        Two methods:
        1. Expert determination
        2. Safe Harbor (remove 18 identifiers)
        """
        # Safe Harbor: Remove 18 HIPAA identifiers
        identifiers = [
            "name", "geographic_subdivisions", "dates",
            "phone_numbers", "fax_numbers", "email",
            "ssn", "medical_record_number", "health_plan_number",
            "account_number", "certificate_number", "vehicle_id",
            "device_id", "url", "ip_address",
            "biometric_identifiers", "photos", "other_unique_id"
        ]

        deidentified_data = phi_data.copy()

        for identifier in identifiers:
            if identifier in deidentified_data:
                del deidentified_data[identifier]

        # For dates, keep only year
        if "date_of_birth" in deidentified_data:
            dob = deidentified_data["date_of_birth"]
            deidentified_data["year_of_birth"] = dob.year
            del deidentified_data["date_of_birth"]

        return deidentified_data

    def minimum_necessary_standard(self, user_role, data_request):
        """
        § 164.502(b): Minimum necessary standard

        Only provide PHI that's reasonably necessary for the purpose
        """
        # Define role-based data access
        role_permissions = {
            "data_scientist": ["age", "diagnosis_codes", "medications"],  # No PII
            "physician": ["name", "age", "diagnosis", "medications", "history"],
            "billing": ["name", "insurance", "billing_codes"]
        }

        allowed_fields = role_permissions.get(user_role, [])

        # Filter data to minimum necessary
        filtered_data = {
            k: v for k, v in data_request.items()
            if k in allowed_fields
        }

        return filtered_data

    def business_associate_agreement(self, vendor):
        """
        § 164.502(e): Business Associate Agreements required

        If using third-party ML vendors (AWS, GCP, etc.),
        need signed BAA
        """
        if not self.has_valid_baa(vendor):
            raise ComplianceError(f"No valid BAA with {vendor}")

        return True

# Example: Training model on HIPAA-compliant data
hipaa_system = HIPAACompliantMLSystem()

# Authenticate data scientist
hipaa_system.access_control(user_id="ds001", resource="training_data")

# De-identify PHI for training
phi_data = load_patient_data()
deidentified_data = hipaa_system.de_identification(phi_data)

# Train model on de-identified data
model = train_model(deidentified_data)

# Encrypt model at rest
encrypted_model = hipaa_system.encrypt_data_at_rest(serialize(model))

# Audit log
hipaa_system.audit_and_accountability(
    action="model_training",
    user_id="ds001",
    resource="training_data",
    phi_accessed=phi_data
)
```

**HIPAA Penalties**:
- Tier 1 (unknowing): $100-$50K per violation
- Tier 2 (reasonable cause): $1K-$50K per violation
- Tier 3 (willful neglect, corrected): $10K-$50K per violation
- Tier 4 (willful neglect, not corrected): $50K per violation
- Annual cap: $1.5M per violation type

### 1.3 California Consumer Privacy Act (CCPA) / California Privacy Rights Act (CPRA)

**Scope**: California residents, businesses with $25M+ revenue or 50K+ consumers

**Key Rights**:
1. **Right to Know**: What personal information is collected
2. **Right to Delete**: Request deletion of personal information
3. **Right to Opt-Out**: Opt out of sale of personal information
4. **Right to Non-Discrimination**: Can't discriminate for exercising rights
5. **Right to Correct**: Correct inaccurate information (CPRA)
6. **Right to Limit**: Limit use of sensitive personal information (CPRA)

**ML-Specific Requirements**:

```python
class CCPAComplianceSystem:
    """
    CCPA/CPRA compliance for ML systems
    """
    def do_not_sell_my_personal_information(self, user_id):
        """
        CCPA § 1798.120: Right to opt-out of sale

        "Sale" includes sharing with third parties for valuable consideration
        ML implications: Can't use data in models shared with partners
        """
        # Mark user as opted out
        self.set_opt_out_status(user_id, opted_out=True)

        # Remove from data shared with third parties
        self.remove_from_shared_datasets(user_id)

        # Don't include in models for third parties
        self.exclude_from_partner_models(user_id)

    def limit_use_of_sensitive_personal_information(self, user_id):
        """
        CPRA: Right to limit use of sensitive information

        Sensitive information includes:
        - SSN, driver's license, passport
        - Precise geolocation
        - Racial/ethnic origin
        - Religious beliefs
        - Health information
        - Sexual orientation
        """
        # Mark sensitive information for limited use
        self.set_sensitive_data_limit(user_id, limited=True)

        # Only use for specified purposes (e.g., providing requested services)
        # Don't use for profiling or targeted advertising

    def consumer_privacy_notice(self):
        """
        CCPA § 1798.100(b): Notice at collection

        Must inform consumers:
        - Categories of personal information collected
        - Purposes for collection
        - Whether information is sold or shared
        """
        return {
            "categories_collected": [
                "identifiers (name, email)",
                "commercial information (purchase history)",
                "internet activity (browsing history)",
                "geolocation data",
                "inferences (predictions about preferences)"
            ],
            "purposes": [
                "providing services",
                "personalization",
                "fraud prevention",
                "analytics"
            ],
            "sold_or_shared": False,
            "retention_period": "3 years",
            "contact": "privacy@company.com"
        }

# Example
ccpa_system = CCPAComplianceSystem()

# User opts out of sale
ccpa_system.do_not_sell_my_personal_information(user_id="user456")

# User limits sensitive information use
ccpa_system.limit_use_of_sensitive_personal_information(user_id="user456")
```

**CCPA Penalties**:
- $2,500 per unintentional violation
- $7,500 per intentional violation
- Private right of action for data breaches: $100-$750 per consumer per incident

### 1.4 Children's Online Privacy Protection Act (COPPA)

**Scope**: US children under 13

**Requirements**:
- Verifiable parental consent before collecting children's data
- Parents can review, delete, and control data
- Data minimization
- Reasonable security measures

**ML Implications**:
- Can't train models on children's data without parental consent
- Age verification mechanisms required
- Separate privacy policies for children

---

## 2. Differential Privacy (8 hours)

### 2.1 Foundations of Differential Privacy

**Definition**: A randomized algorithm M satisfies (ε, δ)-differential privacy if for all datasets D₁, D₂ differing in one record, and all outcomes S:

```
Pr[M(D₁) ∈ S] ≤ e^ε · Pr[M(D₂) ∈ S] + δ
```

**Intuition**: Cannot distinguish whether any individual's data was in the dataset

**Parameters**:
- **ε (epsilon)**: Privacy budget (smaller = more private, less accurate)
  - ε < 1: Strong privacy
  - ε = 1-3: Moderate privacy
  - ε > 10: Weak privacy
- **δ (delta)**: Probability of privacy failure (typically 1/n² where n = dataset size)

**Composition**: Running k mechanisms with privacy (ε, δ) gives overall privacy (kε, kδ)

### 2.2 Differential Privacy Mechanisms

**Laplace Mechanism**:

```python
import numpy as np

def laplace_mechanism(query_result, sensitivity, epsilon):
    """
    Add Laplace noise for differential privacy

    Args:
        query_result: True query result (e.g., mean, count)
        sensitivity: Global sensitivity (max change from adding/removing one record)
        epsilon: Privacy budget

    Returns:
        Noisy result satisfying epsilon-differential privacy
    """
    # Laplace noise scale
    scale = sensitivity / epsilon

    # Add noise
    noise = np.random.laplace(loc=0, scale=scale)
    noisy_result = query_result + noise

    return noisy_result

# Example: DP count query
def dp_count(data, epsilon=1.0):
    """
    Count with differential privacy

    Sensitivity = 1 (adding/removing one record changes count by 1)
    """
    true_count = len(data)
    sensitivity = 1

    noisy_count = laplace_mechanism(true_count, sensitivity, epsilon)

    return max(0, noisy_count)  # Clamp to non-negative

# Example: DP mean query
def dp_mean(data, data_min, data_max, epsilon=1.0):
    """
    Mean with differential privacy

    Sensitivity = (max - min) / n
    """
    n = len(data)
    true_mean = np.mean(data)

    # Global sensitivity
    sensitivity = (data_max - data_min) / n

    noisy_mean = laplace_mechanism(true_mean, sensitivity, epsilon)

    # Clamp to valid range
    return np.clip(noisy_mean, data_min, data_max)

# Usage
ages = np.array([25, 30, 35, 40, 45, 50])

# Private count
count = dp_count(ages, epsilon=1.0)
print(f"DP count: {count:.1f} (true: {len(ages)})")

# Private mean
mean = dp_mean(ages, data_min=0, data_max=120, epsilon=1.0)
print(f"DP mean: {mean:.1f} (true: {np.mean(ages):.1f})")

# Expected output (will vary due to randomness):
# DP count: 6.3 (true: 6)
# DP mean: 37.8 (true: 37.5)
```

**Gaussian Mechanism**:

Used when (ε, δ)-DP with δ > 0 is acceptable:

```python
def gaussian_mechanism(query_result, sensitivity, epsilon, delta):
    """
    Add Gaussian noise for (epsilon, delta)-differential privacy

    Args:
        sensitivity: L2 sensitivity
        epsilon: Privacy budget
        delta: Failure probability

    Returns:
        Noisy result satisfying (epsilon, delta)-DP
    """
    # Gaussian noise scale
    sigma = sensitivity * np.sqrt(2 * np.log(1.25 / delta)) / epsilon

    # Add noise
    noise = np.random.normal(loc=0, scale=sigma)
    noisy_result = query_result + noise

    return noisy_result
```

### 2.3 Differential Privacy for Machine Learning

**DP-SGD (Differentially Private Stochastic Gradient Descent)**:

```python
import torch
from opacus import PrivacyEngine
from opacus.utils.batch_memory_manager import BatchMemoryManager

def train_with_differential_privacy(
    model,
    train_loader,
    epochs=10,
    epsilon=8.0,  # Target privacy budget
    delta=1e-5,
    max_grad_norm=1.0,
    learning_rate=0.001
):
    """
    Train neural network with differential privacy

    Key ideas:
    1. Clip gradients per sample (bound sensitivity)
    2. Add Gaussian noise to gradients
    3. Track privacy budget via privacy accountant

    Args:
        model: Neural network
        train_loader: Training data
        epsilon: Target privacy budget
        delta: Failure probability
        max_grad_norm: Gradient clipping threshold

    Returns:
        Trained model with (epsilon, delta)-DP guarantee
    """
    # Initialize privacy engine
    privacy_engine = PrivacyEngine()

    optimizer = torch.optim.Adam(model.parameters(), lr=learning_rate)

    # Make model private
    model, optimizer, train_loader = privacy_engine.make_private(
        module=model,
        optimizer=optimizer,
        data_loader=train_loader,
        noise_multiplier=1.1,  # Will be computed to achieve target epsilon
        max_grad_norm=max_grad_norm,
    )

    criterion = torch.nn.CrossEntropyLoss()

    # Training loop
    for epoch in range(epochs):
        model.train()

        # BatchMemoryManager for efficient memory usage
        with BatchMemoryManager(
            data_loader=train_loader,
            max_physical_batch_size=128,
            optimizer=optimizer
        ) as memory_safe_data_loader:

            for batch_idx, (data, target) in enumerate(memory_safe_data_loader):
                optimizer.zero_grad()

                # Forward pass
                output = model(data)
                loss = criterion(output, target)

                # Backward pass (gradients clipped and noised by Opacus)
                loss.backward()

                # Optimizer step
                optimizer.step()

        # Check privacy budget
        epsilon_spent = privacy_engine.get_epsilon(delta)
        print(f"Epoch {epoch}: Loss {loss.item():.4f}, (ε = {epsilon_spent:.2f}, δ = {delta})")

        # Stop if privacy budget exhausted
        if epsilon_spent > epsilon:
            print(f"Privacy budget exhausted at epoch {epoch}")
            break

    return model, epsilon_spent

# Example usage
from torchvision import datasets, transforms, models

# Load data
train_dataset = datasets.CIFAR10(
    root='./data',
    train=True,
    download=True,
    transform=transforms.ToTensor()
)

train_loader = torch.utils.data.DataLoader(
    train_dataset,
    batch_size=256,
    shuffle=True
)

# Train model with DP
model = models.resnet18(num_classes=10)
dp_model, final_epsilon = train_with_differential_privacy(
    model,
    train_loader,
    epochs=20,
    epsilon=8.0,
    delta=1e-5
)

# Evaluate
test_loader = load_test_data()
accuracy = evaluate(dp_model, test_loader)

print(f"DP model accuracy: {accuracy:.2%}")
print(f"Final privacy: (ε = {final_epsilon:.2f}, δ = 1e-5)")

# Expected results (CIFAR-10):
# Standard training: 85% accuracy
# DP training (ε=8): 70% accuracy (15% accuracy cost for strong privacy)
```

**Privacy-Accuracy Trade-off**:

| Epsilon | Privacy Level | CIFAR-10 Accuracy | MNIST Accuracy |
|---------|---------------|-------------------|----------------|
| ∞ (no DP) | None | 85% | 99% |
| 10 | Weak | 75% | 96% |
| 8 | Moderate | 70% | 95% |
| 3 | Strong | 60% | 92% |
| 1 | Very strong | 45% | 85% |

### 2.4 Private Model Inference

**Protect individual predictions from privacy attacks**:

```python
def private_prediction(model, input_data, epsilon=1.0):
    """
    Make prediction with differential privacy

    Add noise to output logits to prevent membership inference
    """
    # Forward pass
    logits = model(input_data)

    # Calculate sensitivity (max change in logits from one training sample)
    # For neural networks, sensitivity is typically bounded by Lipschitz constant
    # Approximate: max_grad_norm used in training
    sensitivity = 1.0

    # Add Laplace noise to logits
    noisy_logits = logits + torch.from_numpy(
        np.random.laplace(0, sensitivity / epsilon, size=logits.shape)
    ).float()

    # Return prediction
    return torch.argmax(noisy_logits, dim=-1)

# Usage
model = load_private_model()
prediction = private_prediction(model, user_input, epsilon=1.0)
```

### 2.5 Privacy Budget Management

**Challenge**: Privacy budget is consumed with each query

```python
class PrivacyBudgetManager:
    """
    Track and manage privacy budget for multiple queries
    """
    def __init__(self, total_epsilon, total_delta):
        self.total_epsilon = total_epsilon
        self.total_delta = total_delta
        self.spent_epsilon = 0.0
        self.spent_delta = 0.0
        self.query_history = []

    def check_budget_available(self, epsilon, delta):
        """
        Check if sufficient budget remains
        """
        new_epsilon = self.spent_epsilon + epsilon
        new_delta = self.spent_delta + delta

        return (new_epsilon <= self.total_epsilon and
                new_delta <= self.total_delta)

    def spend_budget(self, query_name, epsilon, delta):
        """
        Spend privacy budget for a query
        """
        if not self.check_budget_available(epsilon, delta):
            raise PrivacyBudgetExceededError(
                f"Insufficient privacy budget. "
                f"Remaining: (ε={self.remaining_epsilon():.2f}, δ={self.remaining_delta():.2e})"
            )

        self.spent_epsilon += epsilon
        self.spent_delta += delta

        self.query_history.append({
            "query": query_name,
            "epsilon": epsilon,
            "delta": delta,
            "timestamp": datetime.utcnow()
        })

    def remaining_epsilon(self):
        return self.total_epsilon - self.spent_epsilon

    def remaining_delta(self):
        return self.total_delta - self.spent_delta

# Usage
budget_manager = PrivacyBudgetManager(total_epsilon=10.0, total_delta=1e-5)

# Query 1: Mean age
budget_manager.spend_budget("mean_age", epsilon=1.0, delta=0)
result1 = dp_mean(ages, epsilon=1.0)

# Query 2: Count by region
budget_manager.spend_budget("count_by_region", epsilon=2.0, delta=0)
result2 = dp_count_by_group(data, epsilon=2.0)

# Query 3: Train ML model
budget_manager.spend_budget("train_model", epsilon=7.0, delta=1e-5)
model = train_with_differential_privacy(data, epsilon=7.0, delta=1e-5)

# Check remaining budget
print(f"Remaining: ε={budget_manager.remaining_epsilon():.2f}")
# Output: Remaining: ε=0.00 (budget exhausted)
```

---

## 3. Federated Learning (5 hours)

### 3.1 Federated Learning Overview

**Principle**: Train model across decentralized devices without centralizing data

**Architecture**:
```
Clients (phones, hospitals, edge devices)
    ↓
Local model training
    ↓
Send model updates (not data!) to server
    ↓
Server aggregates updates
    ↓
Send global model back to clients
```

**Benefits**:
- Privacy: Data stays on device
- Reduced bandwidth: Send models, not raw data
- Compliance: Easier GDPR/HIPAA compliance

**Challenges**:
- Non-IID data (different distributions per client)
- Systems heterogeneity (different devices)
- Communication efficiency
- Privacy attacks on model updates

### 3.2 Federated Averaging (FedAvg)

```python
import torch
import copy

class FederatedServer:
    """
    Federated learning server using FedAvg algorithm
    """
    def __init__(self, global_model):
        self.global_model = global_model
        self.round = 0

    def aggregate_models(self, client_models, client_weights):
        """
        Federated Averaging: weighted average of client models

        Args:
            client_models: List of client model state_dicts
            client_weights: List of weights (typically number of samples per client)

        Returns:
            Aggregated global model
        """
        # Normalize weights
        total_weight = sum(client_weights)
        normalized_weights = [w / total_weight for w in client_weights]

        # Initialize aggregated parameters
        global_dict = self.global_model.state_dict()

        for key in global_dict.keys():
            # Weighted average of parameters
            global_dict[key] = sum(
                client_models[i][key] * normalized_weights[i]
                for i in range(len(client_models))
            )

        # Update global model
        self.global_model.load_state_dict(global_dict)

        return self.global_model

    def federated_training_round(self, clients, fraction=0.1):
        """
        One round of federated learning

        Args:
            clients: List of client objects
            fraction: Fraction of clients to sample per round

        Returns:
            Global model after aggregation
        """
        # Sample clients
        num_clients = int(len(clients) * fraction)
        selected_clients = np.random.choice(clients, num_clients, replace=False)

        # Collect client updates
        client_models = []
        client_weights = []

        for client in selected_clients:
            # Send global model to client
            client_model = client.train(self.global_model)

            # Collect model and weight
            client_models.append(client_model.state_dict())
            client_weights.append(len(client.data))

        # Aggregate models
        self.global_model = self.aggregate_models(client_models, client_weights)

        self.round += 1

        return self.global_model

class FederatedClient:
    """
    Federated learning client
    """
    def __init__(self, client_id, data, epochs=1, learning_rate=0.01):
        self.client_id = client_id
        self.data = data  # Local dataset
        self.epochs = epochs
        self.learning_rate = learning_rate

    def train(self, global_model):
        """
        Train model on local data

        Args:
            global_model: Global model from server

        Returns:
            Updated local model
        """
        # Copy global model
        local_model = copy.deepcopy(global_model)
        local_model.train()

        optimizer = torch.optim.SGD(local_model.parameters(), lr=self.learning_rate)
        criterion = torch.nn.CrossEntropyLoss()

        # Train on local data
        for epoch in range(self.epochs):
            for data, target in self.data:
                optimizer.zero_grad()
                output = local_model(data)
                loss = criterion(output, target)
                loss.backward()
                optimizer.step()

        return local_model

# Federated learning simulation
def run_federated_learning(global_model, clients, rounds=100, client_fraction=0.1):
    """
    Simulate federated learning

    Args:
        global_model: Initial global model
        clients: List of client objects
        rounds: Number of training rounds
        client_fraction: Fraction of clients per round
    """
    server = FederatedServer(global_model)

    for round_num in range(rounds):
        # Training round
        global_model = server.federated_training_round(clients, client_fraction)

        # Evaluate global model
        if round_num % 10 == 0:
            accuracy = evaluate_global_model(global_model, test_loader)
            print(f"Round {round_num}: Global model accuracy = {accuracy:.2%}")

    return global_model

# Example usage
global_model = torch.nn.Sequential(
    torch.nn.Linear(784, 128),
    torch.nn.ReLU(),
    torch.nn.Linear(128, 10)
)

# Create clients with local data
clients = []
for i in range(100):  # 100 clients
    client_data = partition_data(mnist_train, client_id=i, num_clients=100)
    clients.append(FederatedClient(client_id=i, data=client_data))

# Run federated learning
final_model = run_federated_learning(
    global_model,
    clients,
    rounds=100,
    client_fraction=0.1
)

# Expected convergence:
# Round 0: 10% accuracy (random)
# Round 50: 85% accuracy
# Round 100: 92% accuracy (close to centralized training: 95%)
```

### 3.3 Secure Aggregation

**Problem**: Model updates can leak information about client's data

**Solution**: Secure multi-party computation for aggregation

```python
class SecureAggregationServer:
    """
    Secure aggregation prevents server from seeing individual client updates

    Uses secret sharing: Each client splits update into n shares
    Server only sees aggregated result
    """
    def __init__(self, num_clients):
        self.num_clients = num_clients

    def aggregate_securely(self, client_shares):
        """
        Aggregate model updates using secure multi-party computation

        Args:
            client_shares: List of encrypted shares from clients

        Returns:
            Aggregated model (decrypted sum)
        """
        # Sum encrypted shares
        # Due to additive homomorphism: E(x) + E(y) = E(x + y)
        aggregated_encrypted = sum(client_shares)

        # Decrypt aggregate (only possible after summing all shares)
        aggregated_model = self.decrypt_aggregate(aggregated_encrypted)

        return aggregated_model

    def decrypt_aggregate(self, encrypted_aggregate):
        """
        Decrypt aggregated result

        Server never sees individual client updates!
        """
        # Simplified: In practice, use proper crypto (Paillier, secret sharing)
        return encrypted_aggregate  # Decryption logic

# Usage
secure_server = SecureAggregationServer(num_clients=100)

# Clients create encrypted shares
client_shares = [client.create_encrypted_share() for client in clients]

# Server aggregates without seeing individual updates
global_update = secure_server.aggregate_securely(client_shares)
```

### 3.4 Differential Privacy in Federated Learning

**Combine federated learning + differential privacy**:

```python
def federated_learning_with_dp(
    global_model,
    clients,
    rounds=100,
    epsilon=10.0,
    delta=1e-5,
    client_clip_norm=1.0
):
    """
    Federated learning with user-level differential privacy

    Privacy guarantee: Adding/removing one user's data changes model by at most (epsilon, delta)
    """
    server = FederatedServer(global_model)

    # Calculate noise scale for DP
    sensitivity = client_clip_norm  # Sensitivity = clipping threshold
    noise_scale = sensitivity * rounds / epsilon  # Total noise across all rounds

    for round_num in range(rounds):
        # Sample clients
        selected_clients = sample_clients(clients, fraction=0.1)

        # Collect client updates
        client_updates = []
        for client in selected_clients:
            update = client.compute_update(server.global_model)

            # Clip update (bound sensitivity)
            update = clip_tensor(update, max_norm=client_clip_norm)

            client_updates.append(update)

        # Aggregate updates
        aggregated_update = sum(client_updates) / len(client_updates)

        # Add Gaussian noise for DP
        noise = torch.randn_like(aggregated_update) * (noise_scale / rounds)
        noisy_update = aggregated_update + noise

        # Apply update to global model
        server.apply_update(noisy_update)

    return server.global_model, epsilon

# Results:
# Standard FL: 92% accuracy
# FL with DP (ε=10): 88% accuracy (4% cost for privacy)
# FL with DP (ε=3): 82% accuracy (10% cost for strong privacy)
```

---

## 4. Data Anonymization and De-identification (4 hours)

### 4.1 Anonymization Techniques

**K-Anonymity**: Each record indistinguishable from k-1 others

```python
def k_anonymize(data, quasi_identifiers, k=5):
    """
    K-anonymization: Generalize quasi-identifiers so each group has ≥k records

    Args:
        data: DataFrame with personal data
        quasi_identifiers: Columns that could identify individuals (age, zip, etc.)
        k: Anonymity parameter

    Returns:
        K-anonymized DataFrame
    """
    import pandas as pd

    # Generalization strategies
    def generalize_age(age):
        """Age groups: 0-10, 11-20, 21-30, etc."""
        return f"{(age // 10) * 10}-{(age // 10) * 10 + 9}"

    def generalize_zipcode(zipcode):
        """Keep only first 3 digits"""
        return str(zipcode)[:3] + "**"

    anonymized = data.copy()

    # Apply generalizations
    if 'age' in quasi_identifiers:
        anonymized['age'] = anonymized['age'].apply(generalize_age)

    if 'zipcode' in quasi_identifiers:
        anonymized['zipcode'] = anonymized['zipcode'].apply(generalize_zipcode)

    # Check k-anonymity
    group_sizes = anonymized.groupby(quasi_identifiers).size()

    # Suppress groups smaller than k
    valid_groups = group_sizes[group_sizes >= k].index
    anonymized = anonymized[anonymized.set_index(quasi_identifiers).index.isin(valid_groups)]

    return anonymized

# Example
data = pd.DataFrame({
    'name': ['Alice', 'Bob', 'Charlie', 'David', 'Eve', 'Frank'],
    'age': [25, 26, 27, 28, 29, 30],
    'zipcode': [94301, 94302, 94301, 94302, 94301, 94302],
    'disease': ['flu', 'covid', 'flu', 'covid', 'flu', 'covid']
})

# Remove direct identifiers
data_no_names = data.drop('name', axis=1)

# K-anonymize
anonymized = k_anonymize(data_no_names, quasi_identifiers=['age', 'zipcode'], k=2)

print(anonymized)
# Output:
#     age zipcode disease
# 0  20-29  943**     flu
# 1  20-29  943**   covid
# 2  20-29  943**     flu
# ...
```

**L-Diversity**: Each k-anonymous group has ≥l diverse values for sensitive attributes

**T-Closeness**: Distribution of sensitive attribute in each group is close to overall distribution

### 4.2 Synthetic Data Generation

**Generate synthetic data that preserves statistical properties**:

```python
from sdv.tabular import GaussianCopula

def generate_synthetic_data(real_data, num_samples):
    """
    Generate synthetic data using statistical models

    Preserves:
    - Marginal distributions
    - Correlations
    - Statistical properties

    Does not preserve:
    - Individual records (privacy-preserving)
    """
    # Train generative model
    model = GaussianCopula()
    model.fit(real_data)

    # Generate synthetic data
    synthetic_data = model.sample(num_samples)

    return synthetic_data

# Usage
real_data = load_sensitive_data()
synthetic_data = generate_synthetic_data(real_data, num_samples=10000)

# Train ML model on synthetic data
model = train_model(synthetic_data)

# Benefit: No privacy risk (synthetic data not protected by regulations)
# Trade-off: Utility loss (synthetic data may not capture all patterns)
```

**Differentially Private Synthetic Data**:

```python
def generate_dp_synthetic_data(real_data, epsilon=1.0):
    """
    Generate DP synthetic data

    Approach:
    1. Compute DP statistics (means, covariances with noise)
    2. Fit generative model to DP statistics
    3. Sample from generative model
    """
    # Compute DP statistics
    dp_mean = compute_dp_mean(real_data, epsilon=epsilon/2)
    dp_cov = compute_dp_covariance(real_data, epsilon=epsilon/2)

    # Generate synthetic data from DP statistics
    synthetic_data = np.random.multivariate_normal(dp_mean, dp_cov, size=len(real_data))

    return synthetic_data
```

---

## 5. Privacy Impact Assessment (3 hours)

### 5.1 Conducting a PIA

**Privacy Impact Assessment Template**:

```python
class PrivacyImpactAssessment:
    """
    Template for ML system privacy impact assessment
    """
    def __init__(self, system_name):
        self.system_name = system_name
        self.assessment = {}

    def identify_personal_data(self):
        """
        1. What personal data is collected?
        """
        self.assessment['personal_data'] = {
            'direct_identifiers': ['name', 'email', 'SSN'],
            'quasi_identifiers': ['age', 'zipcode', 'gender'],
            'sensitive_data': ['health_information', 'financial_data'],
            'data_sources': ['user_input', 'third_party_apis', 'public_datasets']
        }

    def assess_necessity_and_proportionality(self):
        """
        2. Is data collection necessary and proportionate?
        """
        self.assessment['necessity'] = {
            'purpose': 'Personalized health recommendations',
            'legal_basis': 'Consent',
            'minimization': 'Only collecting health data directly relevant to recommendations',
            'alternatives_considered': 'Considered using only aggregated data (insufficient for personalization)'
        }

    def identify_privacy_risks(self):
        """
        3. What are the privacy risks?
        """
        self.assessment['risks'] = [
            {
                'risk': 'Data breach exposing health information',
                'likelihood': 'Low',
                'impact': 'High',
                'risk_score': 6
            },
            {
                'risk': 'Re-identification of anonymized data',
                'likelihood': 'Medium',
                'impact': 'High',
                'risk_score': 8
            },
            {
                'risk': 'Model memorizing sensitive training data',
                'likelihood': 'Medium',
                'impact': 'Medium',
                'risk_score': 6
            }
        ]

    def design_mitigation_measures(self):
        """
        4. How are risks mitigated?
        """
        self.assessment['mitigations'] = [
            {
                'risk': 'Data breach',
                'mitigation': 'AES-256 encryption at rest, TLS in transit, access controls',
                'residual_risk': 'Low'
            },
            {
                'risk': 'Re-identification',
                'mitigation': 'K-anonymization (k=10), differential privacy (ε=3)',
                'residual_risk': 'Low'
            },
            {
                'risk': 'Model memorization',
                'mitigation': 'Differential privacy training (ε=8), membership inference testing',
                'residual_risk': 'Medium'
            }
        ]

    def compliance_mapping(self):
        """
        5. Compliance with regulations
        """
        self.assessment['compliance'] = {
            'GDPR': {
                'lawfulness': 'Consent obtained',
                'data_minimization': 'Only necessary health metrics collected',
                'right_to_erasure': 'Machine unlearning implemented',
                'DPO_consulted': True
            },
            'HIPAA': {
                'de_identification': 'Safe Harbor method applied',
                'encryption': 'AES-256',
                'BAA_signed': 'All vendors have signed BAAs'
            }
        }

    def generate_report(self):
        """
        Generate PIA report
        """
        self.identify_personal_data()
        self.assess_necessity_and_proportionality()
        self.identify_privacy_risks()
        self.design_mitigation_measures()
        self.compliance_mapping()

        return self.assessment

# Example usage
pia = PrivacyImpactAssessment("Health Recommendation ML System")
assessment_report = pia.generate_report()

# Use report for:
# - Documentation for regulators
# - Internal compliance review
# - Risk management
# - Design decisions
```

---

## Summary

This module covered privacy and compliance for ML:

1. **Privacy Regulations**: GDPR, HIPAA, CCPA requirements for ML systems
2. **Differential Privacy**: Mathematical privacy guarantees via DP-SGD
3. **Federated Learning**: Training without centralizing data
4. **Anonymization**: K-anonymity, synthetic data generation
5. **Privacy Impact Assessment**: Systematic privacy risk evaluation

**Key Takeaways**:
- Privacy regulations require technical and organizational measures
- Differential privacy provides provable guarantees but costs accuracy
- Federated learning enables privacy-preserving collaboration
- Multiple privacy techniques often combined for defense-in-depth
- Privacy impact assessments are essential for compliance

**Next Module**: Secrets & Identity Management (HashiCorp Vault, IAM, API keys)

---

## References

1. GDPR: https://gdpr.eu/
2. HIPAA Privacy Rule: https://www.hhs.gov/hipaa/
3. CCPA/CPRA: https://oag.ca.gov/privacy/ccpa
4. Dwork & Roth, "The Algorithmic Foundations of Differential Privacy" (2014)
5. Abadi et al., "Deep Learning with Differential Privacy" (2016)
6. McMahan et al., "Communication-Efficient Learning of Deep Networks from Decentralized Data" (2017)
7. Sweeney, "k-Anonymity: A Model For Protecting Privacy" (2002)
