# Module 3 Exercises: Data Privacy & Compliance

## Overview

These hands-on exercises provide practical experience implementing privacy-preserving ML techniques, achieving regulatory compliance, and building privacy-compliant systems. You'll implement differential privacy, federated learning, data anonymization, and GDPR compliance mechanisms.

**Total Time**: ~15-18 hours
**Prerequisites**: Module 3 lecture notes, Python, PyTorch, pandas, basic cryptography

---

## Exercise 1: Differential Privacy Implementation (4-5 hours)

### Objective
Implement differential privacy for ML training and inference, evaluate privacy-accuracy trade-offs.

### Part 1: DP Mechanisms (1.5 hours)

**Task**: Implement Laplace and Gaussian mechanisms from scratch

```python
# dp_mechanisms.py
import numpy as np

class DPMechanisms:
    """
    TODO: Implement differential privacy mechanisms
    """
    def laplace_mechanism(self, query_result, sensitivity, epsilon):
        """
        TODO: Add Laplace noise for epsilon-DP

        Args:
            query_result: True query result
            sensitivity: Global sensitivity
            epsilon: Privacy budget

        Returns:
            Noisy result satisfying epsilon-DP
        """
        # TODO: Implement
        # Hint: scale = sensitivity / epsilon
        # noise = np.random.laplace(0, scale)
        pass

    def gaussian_mechanism(self, query_result, sensitivity, epsilon, delta):
        """
        TODO: Add Gaussian noise for (epsilon, delta)-DP

        Args:
            sensitivity: L2 sensitivity
            epsilon: Privacy budget
            delta: Failure probability

        Returns:
            Noisy result satisfying (epsilon, delta)-DP
        """
        # TODO: Implement
        # Hint: sigma = sensitivity * sqrt(2 * log(1.25/delta)) / epsilon
        pass

    def dp_count(self, data, epsilon=1.0):
        """
        TODO: Count query with DP

        Sensitivity = 1 (adding/removing one record changes count by 1)
        """
        # TODO: Implement
        pass

    def dp_mean(self, data, data_min, data_max, epsilon=1.0):
        """
        TODO: Mean query with DP

        Sensitivity = (max - min) / n
        """
        # TODO: Implement
        pass

    def dp_histogram(self, data, bins, epsilon=1.0):
        """
        TODO: Histogram with DP

        Sensitivity = 1 per bin (one record affects one bin)
        Use composition: epsilon_per_bin = epsilon / num_bins
        """
        # TODO: Implement
        pass

# Test DP mechanisms
if __name__ == "__main__":
    dp = DPMechanisms()

    # Test data
    ages = np.array([25, 30, 35, 40, 45, 50, 55, 60, 65, 70])

    # Test 1: DP count
    true_count = len(ages)
    dp_counts = [dp.dp_count(ages, epsilon=1.0) for _ in range(100)]

    print(f"True count: {true_count}")
    print(f"DP count (ε=1.0): {np.mean(dp_counts):.1f} ± {np.std(dp_counts):.1f}")

    # Test 2: DP mean
    true_mean = np.mean(ages)
    dp_means = [dp.dp_mean(ages, data_min=0, data_max=120, epsilon=1.0) for _ in range(100)]

    print(f"True mean: {true_mean:.1f}")
    print(f"DP mean (ε=1.0): {np.mean(dp_means):.1f} ± {np.std(dp_means):.1f}")

    # Test 3: Privacy-accuracy tradeoff
    epsilons = [0.1, 0.5, 1.0, 5.0, 10.0]
    for eps in epsilons:
        dp_means_eps = [dp.dp_mean(ages, 0, 120, epsilon=eps) for _ in range(100)]
        error = np.mean(np.abs(dp_means_eps - true_mean))
        print(f"ε={eps:4.1f}: Error = {error:.2f}")

    # Expected output:
    # ε=0.1: Error ~30
    # ε=1.0: Error ~5
    # ε=10.0: Error ~0.5
```

**Deliverables**:
- Working DP mechanisms (Laplace, Gaussian)
- DP queries (count, mean, histogram)
- Privacy-accuracy trade-off analysis

### Part 2: DP-SGD for Model Training (2-2.5 hours)

**Task**: Train neural network with differential privacy using Opacus

```python
# dp_training.py
import torch
from opacus import PrivacyEngine
from opacus.utils.batch_memory_manager import BatchMemoryManager

def train_with_dp(
    model,
    train_loader,
    test_loader,
    epochs=10,
    epsilon_target=8.0,
    delta=1e-5,
    max_grad_norm=1.0,
    learning_rate=0.001
):
    """
    TODO: Train model with differential privacy

    Steps:
    1. Initialize PrivacyEngine
    2. Make model private (wraps optimizer and data loader)
    3. Training loop with gradient clipping and noise
    4. Track privacy budget (epsilon) each epoch
    5. Stop when epsilon budget exhausted

    Args:
        model: Neural network
        train_loader: Training data
        test_loader: Test data
        epsilon_target: Target privacy budget
        delta: Failure probability
        max_grad_norm: Gradient clipping threshold

    Returns:
        Trained model, final epsilon
    """
    # TODO: Implement DP training

    # Hints:
    # - privacy_engine = PrivacyEngine()
    # - model, optimizer, train_loader = privacy_engine.make_private(...)
    # - epsilon_spent = privacy_engine.get_epsilon(delta)
    pass

def evaluate_privacy_accuracy_tradeoff(model_class, train_loader, test_loader):
    """
    TODO: Train models with different epsilon values

    Test epsilon = [1, 3, 8, inf]
    Compare accuracy vs privacy
    """
    results = []

    epsilons = [1.0, 3.0, 8.0, float('inf')]

    for epsilon in epsilons:
        if epsilon == float('inf'):
            # Standard training (no DP)
            model = train_standard(model_class(), train_loader, test_loader)
            accuracy = evaluate(model, test_loader)
            results.append({"epsilon": epsilon, "accuracy": accuracy})
        else:
            # DP training
            model = model_class()
            trained_model, final_epsilon = train_with_dp(
                model,
                train_loader,
                test_loader,
                epsilon_target=epsilon
            )
            accuracy = evaluate(trained_model, test_loader)
            results.append({"epsilon": final_epsilon, "accuracy": accuracy})

        print(f"ε={epsilon}: Accuracy = {accuracy:.2%}")

    return results

# Run experiments
if __name__ == "__main__":
    from torchvision import datasets, transforms

    # Load MNIST
    train_dataset = datasets.MNIST(
        './data', train=True, download=True,
        transform=transforms.ToTensor()
    )
    test_dataset = datasets.MNIST(
        './data', train=False,
        transform=transforms.ToTensor()
    )

    train_loader = torch.utils.data.DataLoader(train_dataset, batch_size=256, shuffle=True)
    test_loader = torch.utils.data.DataLoader(test_dataset, batch_size=1024)

    # Define simple model
    class SimpleNet(torch.nn.Module):
        def __init__(self):
            super().__init__()
            self.fc1 = torch.nn.Linear(784, 128)
            self.fc2 = torch.nn.Linear(128, 10)

        def forward(self, x):
            x = x.view(-1, 784)
            x = torch.relu(self.fc1(x))
            x = self.fc2(x)
            return x

    # Evaluate privacy-accuracy tradeoff
    results = evaluate_privacy_accuracy_tradeoff(SimpleNet, train_loader, test_loader)

    # Expected results (MNIST):
    # ε=inf (no DP): 97% accuracy
    # ε=8: 95% accuracy
    # ε=3: 92% accuracy
    # ε=1: 85% accuracy
```

**Deliverables**:
- DP-SGD implementation using Opacus
- Privacy-accuracy tradeoff plots
- Analysis of gradient clipping impact
- Comparison with non-private baseline

### Part 3: Private Inference (1 hour)

**Task**: Implement differentially private predictions

```python
# private_inference.py

def private_prediction(model, input_data, epsilon=1.0, delta=1e-5):
    """
    TODO: Make prediction with differential privacy

    Approach:
    1. Get model logits
    2. Add Gaussian noise to logits
    3. Return noisy prediction

    This prevents membership inference attacks
    """
    # TODO: Implement
    pass

def evaluate_private_inference(model, test_loader, epsilons=[0.1, 1.0, 10.0]):
    """
    TODO: Evaluate accuracy of private inference

    Compare:
    - Standard inference
    - Private inference with different epsilon values
    """
    # TODO: Implement
    pass

# Expected results:
# ε=0.1: 70% accuracy (very noisy)
# ε=1.0: 92% accuracy
# ε=10.0: 96% accuracy
# ε=inf: 97% accuracy
```

**Deliverables**:
- Private inference implementation
- Accuracy vs epsilon analysis
- Discussion of when private inference is necessary

### Evaluation Criteria

- [ ] DP mechanisms correctly implement privacy guarantees
- [ ] DP-SGD achieves reasonable accuracy (>90% on MNIST with ε=8)
- [ ] Privacy-accuracy tradeoff clearly demonstrated
- [ ] Private inference works with acceptable utility
- [ ] Comprehensive analysis and visualizations

---

## Exercise 2: Federated Learning System (4-5 hours)

### Objective
Build federated learning system with secure aggregation and differential privacy.

### Part 1: Federated Averaging (2 hours)

**Task**: Implement FedAvg algorithm

```python
# federated_learning.py
import torch
import copy

class FederatedServer:
    """
    TODO: Implement federated learning server
    """
    def __init__(self, global_model):
        self.global_model = global_model
        self.round = 0

    def aggregate_models(self, client_models, client_weights):
        """
        TODO: Federated Averaging

        Weighted average of client models:
        w_global = Σ(n_i / n_total) * w_i

        Args:
            client_models: List of client model state_dicts
            client_weights: List of weights (number of samples per client)

        Returns:
            Aggregated global model
        """
        # TODO: Implement
        pass

    def select_clients(self, clients, fraction=0.1):
        """
        TODO: Sample fraction of clients for this round
        """
        # TODO: Implement
        pass

    def training_round(self, clients, fraction=0.1):
        """
        TODO: One round of federated learning

        1. Sample clients
        2. Send global model to clients
        3. Collect client updates
        4. Aggregate updates
        5. Update global model
        """
        # TODO: Implement
        pass

class FederatedClient:
    """
    TODO: Implement federated learning client
    """
    def __init__(self, client_id, local_data, epochs=1, lr=0.01):
        self.client_id = client_id
        self.local_data = local_data
        self.epochs = epochs
        self.lr = lr

    def train(self, global_model):
        """
        TODO: Train on local data

        1. Copy global model
        2. Train on local dataset for E epochs
        3. Return updated model
        """
        # TODO: Implement
        pass

def partition_data(dataset, num_clients, non_iid=False):
    """
    TODO: Partition dataset across clients

    Args:
        dataset: Full dataset
        num_clients: Number of clients
        non_iid: If True, create non-IID partitions (more realistic)

    Returns:
        List of client datasets
    """
    # TODO: Implement

    # For IID: randomly split
    # For non-IID: each client gets data from 2 classes only
    pass

def run_federated_learning(
    global_model,
    clients,
    rounds=100,
    client_fraction=0.1,
    eval_every=10
):
    """
    TODO: Run federated learning simulation

    Returns:
        Trained global model
        Training history (accuracy per round)
    """
    # TODO: Implement
    pass

# Test federated learning
if __name__ == "__main__":
    from torchvision import datasets, transforms

    # Load MNIST
    mnist_train = datasets.MNIST('./data', train=True, download=True,
                                  transform=transforms.ToTensor())
    mnist_test = datasets.MNIST('./data', train=False,
                                 transform=transforms.ToTensor())

    # Create 100 clients with local data
    num_clients = 100
    client_datasets = partition_data(mnist_train, num_clients, non_iid=False)

    clients = [
        FederatedClient(client_id=i, local_data=client_datasets[i])
        for i in range(num_clients)
    ]

    # Initialize global model
    global_model = SimpleNet()

    # Run federated learning
    final_model, history = run_federated_learning(
        global_model,
        clients,
        rounds=100,
        client_fraction=0.1
    )

    # Evaluate
    test_loader = torch.utils.data.DataLoader(mnist_test, batch_size=1024)
    accuracy = evaluate(final_model, test_loader)

    print(f"Final global model accuracy: {accuracy:.2%}")

    # Expected convergence:
    # Round 10: 75% accuracy
    # Round 50: 92% accuracy
    # Round 100: 95% accuracy
```

**Deliverables**:
- Federated learning implementation (server + client)
- Comparison: IID vs non-IID data partitions
- Convergence analysis (accuracy vs rounds)
- Communication efficiency analysis

### Part 2: Secure Aggregation (1.5 hours)

**Task**: Implement secure aggregation using secret sharing

```python
# secure_aggregation.py

class SecureAggregation:
    """
    TODO: Implement secure aggregation

    Goal: Server aggregates client updates without seeing individual updates

    Approach:
    1. Each client splits update into shares
    2. Clients send shares to server
    3. Server aggregates shares
    4. Result is sum of all updates (but server never saw individual updates)
    """
    def __init__(self, num_clients):
        self.num_clients = num_clients

    def create_shares(self, model_update, num_shares):
        """
        TODO: Split model update into additive shares

        model_update = share_1 + share_2 + ... + share_n
        """
        # TODO: Implement additive secret sharing
        pass

    def aggregate_shares(self, shares_list):
        """
        TODO: Aggregate shares from all clients

        Sum all shares to get aggregate update
        """
        # TODO: Implement
        pass

# Test secure aggregation
if __name__ == "__main__":
    secure_agg = SecureAggregation(num_clients=100)

    # Simulate clients creating shares
    client_updates = [torch.randn(100) for _ in range(100)]

    # Each client creates shares
    all_shares = []
    for update in client_updates:
        shares = secure_agg.create_shares(update, num_shares=100)
        all_shares.append(shares)

    # Server aggregates without seeing individual updates
    aggregated = secure_agg.aggregate_shares(all_shares)

    # Verify correctness
    true_aggregate = sum(client_updates)
    error = torch.norm(aggregated - true_aggregate)

    print(f"Aggregation error: {error.item():.6f}")
    # Should be ~0 (perfect aggregation)
```

**Deliverables**:
- Secure aggregation implementation
- Verification of correctness
- Discussion of security guarantees

### Part 3: Federated Learning with DP (1.5 hours)

**Task**: Add differential privacy to federated learning

```python
# federated_dp.py

def federated_learning_with_dp(
    global_model,
    clients,
    rounds=100,
    epsilon=10.0,
    delta=1e-5,
    client_clip_norm=1.0
):
    """
    TODO: Federated learning with user-level DP

    Privacy guarantee: Adding/removing one client's data
    changes model by at most (epsilon, delta)

    Algorithm:
    1. Clients train locally
    2. Clip client updates (bound sensitivity)
    3. Aggregate updates
    4. Add Gaussian noise (scaled by rounds)
    5. Apply noisy update to global model

    Args:
        epsilon: Total privacy budget
        client_clip_norm: Clipping threshold for client updates
    """
    # TODO: Implement
    pass

# Compare FL vs FL+DP
if __name__ == "__main__":
    clients = create_clients(num_clients=100)

    # Standard FL
    fl_model = run_federated_learning(clients, rounds=100)
    fl_accuracy = evaluate(fl_model, test_loader)

    # FL with DP
    fl_dp_model, final_epsilon = federated_learning_with_dp(
        clients,
        rounds=100,
        epsilon=10.0
    )
    fl_dp_accuracy = evaluate(fl_dp_model, test_loader)

    print(f"FL accuracy: {fl_accuracy:.2%}")
    print(f"FL+DP (ε=10) accuracy: {fl_dp_accuracy:.2%}")

    # Expected:
    # FL: 95% accuracy
    # FL+DP (ε=10): 90% accuracy (5% privacy cost)
```

**Deliverables**:
- FL with user-level DP
- Privacy-accuracy tradeoff analysis
- Comparison with centralized DP training

### Evaluation Criteria

- [ ] FedAvg converges to high accuracy (>93% on MNIST)
- [ ] Non-IID data handling works
- [ ] Secure aggregation correctly aggregates
- [ ] DP federated learning provides privacy guarantees
- [ ] Clear comparison of all approaches

---

## Exercise 3: GDPR Compliance System (3-4 hours)

### Objective
Implement GDPR data subject rights for ML system.

### Part 1: Data Subject Access Request (1 hour)

**Task**: Implement right to access

```python
# gdpr_compliance.py
import json
from datetime import datetime

class GDPRComplianceSystem:
    """
    TODO: Implement GDPR data subject rights
    """
    def __init__(self, user_database, model_registry, feature_store):
        self.user_db = user_database
        self.model_registry = model_registry
        self.feature_store = feature_store
        self.audit_log = AuditLog()

    def right_to_access(self, user_id, format="json"):
        """
        TODO: Article 15 - Right to access

        User can request:
        - What personal data you have
        - Why you're processing it
        - Who you've shared it with
        - How long you'll keep it

        Args:
            user_id: User identifier
            format: Output format (json, csv, xml)

        Returns:
            Complete export of user's personal data
        """
        # TODO: Collect all user data
        personal_data = {
            "user_profile": self.user_db.get_user_profile(user_id),
            "purchase_history": self.user_db.get_purchase_history(user_id),
            "interaction_logs": self.user_db.get_interaction_logs(user_id),
            "features": self.feature_store.get_user_features(user_id)
        }

        processing_info = {
            "purposes": ["Personalization", "Fraud detection", "Analytics"],
            "legal_basis": "Consent",
            "recipients": ["Internal analytics team", "Marketing partners (anonymized)"],
            "retention_period": "3 years after last interaction",
            "data_sources": ["Direct user input", "Interaction tracking", "Third-party enrichment"]
        }

        # TODO: Format response
        response = {
            "request_date": datetime.utcnow().isoformat(),
            "user_id": user_id,
            "personal_data": personal_data,
            "processing_information": processing_info
        }

        # TODO: Audit log
        self.audit_log.log("access_request", user_id)

        if format == "json":
            return json.dumps(response, indent=2)
        elif format == "csv":
            return self._to_csv(response)

# Test DSAR
if __name__ == "__main__":
    gdpr_system = GDPRComplianceSystem(user_db, model_registry, feature_store)

    # User requests their data
    user_data = gdpr_system.right_to_access(user_id="user123", format="json")

    print(user_data)
```

**Deliverables**:
- Data subject access request implementation
- Multiple export formats (JSON, CSV)
- Audit logging

### Part 2: Right to Erasure (Machine Unlearning) (1.5-2 hours)

**Task**: Implement right to be forgotten with machine unlearning

```python
# machine_unlearning.py

class MachineUnlearning:
    """
    TODO: Implement machine unlearning for GDPR Article 17
    """
    def __init__(self, model, training_data):
        self.model = model
        self.training_data = training_data

    def exact_unlearning(self, user_ids_to_remove):
        """
        TODO: Exact unlearning - retrain from scratch

        Steps:
        1. Remove user data from training set
        2. Retrain model from scratch

        Pros: Perfect unlearning
        Cons: Expensive (full retraining)
        """
        # TODO: Implement
        pass

    def approximate_unlearning(self, user_ids_to_remove):
        """
        TODO: Approximate unlearning - efficient approximation

        Algorithm (SISA - Sharded, Isolated, Sliced, Aggregated):
        1. Train model on shards (train k models on disjoint data shards)
        2. To unlearn: only retrain affected shard(s)
        3. Aggregate predictions from all shards

        Pros: Much faster than full retraining
        Cons: Approximation (not perfect unlearning)
        """
        # TODO: Implement SISA
        pass

    def gradient_based_unlearning(self, user_ids_to_remove, num_steps=100):
        """
        TODO: Gradient-based unlearning

        Idea: Reverse the gradient updates from user's data

        Steps:
        1. Calculate gradient of loss on user's data
        2. Update model in opposite direction
        3. Fine-tune to restore performance

        Pros: Fast
        Cons: Approximate, may not fully remove influence
        """
        # TODO: Implement
        pass

def evaluate_unlearning_quality(original_model, unlearned_model, forgotten_data, remaining_data):
    """
    TODO: Evaluate unlearning quality

    Metrics:
    1. Forgetting quality: How much model "forgot" removed user's data
       - Membership inference test (should fail on forgotten data)
    2. Utility preservation: Accuracy on remaining data maintained
    """
    # TODO: Implement evaluation
    pass

# Test unlearning
if __name__ == "__main__":
    # Train original model
    model = train_model(full_training_data)

    # User requests deletion
    users_to_forget = ["user123", "user456"]

    # Method 1: Exact unlearning (retrain)
    unlearned_model_exact = machine_unlearning.exact_unlearning(users_to_forget)

    # Method 2: Approximate unlearning (SISA)
    unlearned_model_approx = machine_unlearning.approximate_unlearning(users_to_forget)

    # Evaluate
    metrics_exact = evaluate_unlearning_quality(
        original_model,
        unlearned_model_exact,
        forgotten_data,
        remaining_data
    )

    metrics_approx = evaluate_unlearning_quality(
        original_model,
        unlearned_model_approx,
        forgotten_data,
        remaining_data
    )

    print("Exact unlearning:", metrics_exact)
    print("Approximate unlearning:", metrics_approx)

    # Expected:
    # Exact: Perfect forgetting, no utility loss
    # Approximate: Good forgetting (90%+), <2% utility loss
```

**Deliverables**:
- Multiple unlearning methods (exact, SISA, gradient-based)
- Unlearning quality evaluation
- Efficiency comparison
- Discussion of trade-offs

### Part 3: Automated Compliance Workflow (1-1.5 hours)

**Task**: Build end-to-end GDPR request handling

```python
# gdpr_workflow.py

class GDPRRequestHandler:
    """
    TODO: Automated GDPR request handling workflow
    """
    def __init__(self):
        self.request_queue = []
        self.compliance_system = GDPRComplianceSystem()

    def submit_request(self, user_id, request_type, details=None):
        """
        TODO: Submit GDPR request

        Request types:
        - access: Right to access
        - rectification: Right to correct
        - erasure: Right to be forgotten
        - portability: Right to data portability
        - objection: Right to object

        Returns:
            request_id: Unique identifier for tracking
        """
        request = {
            "request_id": generate_request_id(),
            "user_id": user_id,
            "type": request_type,
            "details": details,
            "status": "pending",
            "submitted_at": datetime.utcnow(),
            "deadline": datetime.utcnow() + timedelta(days=30)  # GDPR requires response within 30 days
        }

        self.request_queue.append(request)

        # TODO: Trigger appropriate workflow
        self.process_request(request)

        return request["request_id"]

    def process_request(self, request):
        """
        TODO: Process GDPR request

        Workflow:
        1. Validate request (verify identity)
        2. Process request (execute appropriate action)
        3. Generate response
        4. Log for compliance
        5. Notify user
        """
        # TODO: Implement
        pass

    def generate_compliance_report(self, start_date, end_date):
        """
        TODO: Generate compliance report

        For auditors/regulators:
        - Number of requests by type
        - Average response time
        - Completion rate
        - Any violations
        """
        # TODO: Implement
        pass

# Usage
if __name__ == "__main__":
    handler = GDPRRequestHandler()

    # User submits access request
    request_id = handler.submit_request(
        user_id="user123",
        request_type="access"
    )

    # User submits erasure request
    erasure_id = handler.submit_request(
        user_id="user456",
        request_type="erasure"
    )

    # Generate compliance report for audit
    report = handler.generate_compliance_report(
        start_date="2025-01-01",
        end_date="2025-03-31"
    )

    print(report)
```

**Deliverables**:
- GDPR request handling system
- Multiple request types supported
- Compliance reporting
- 30-day deadline tracking

### Evaluation Criteria

- [ ] Data subject access request returns complete data
- [ ] Machine unlearning effectively removes user data
- [ ] Unlearning preserves model utility
- [ ] Automated workflow handles all GDPR rights
- [ ] Compliance reports generated
- [ ] 30-day deadline enforcement

---

## Exercise 4: Data Anonymization and Privacy Impact Assessment (3-4 hours)

### Objective
Implement k-anonymization, l-diversity, and conduct privacy impact assessment.

### Part 1: K-Anonymization (1.5 hours)

**Task**: Implement k-anonymity for datasets

```python
# anonymization.py
import pandas as pd

class KAnonymization:
    """
    TODO: Implement k-anonymization
    """
    def __init__(self, k=5):
        self.k = k

    def generalize_age(self, age, granularity=10):
        """
        TODO: Generalize age into bins

        Example: 25 → "20-29"
        """
        # TODO: Implement
        pass

    def generalize_zipcode(self, zipcode, digits=3):
        """
        TODO: Generalize zipcode

        Example: "94301" → "943**"
        """
        # TODO: Implement
        pass

    def suppress_rare_values(self, data, column, threshold):
        """
        TODO: Suppress values that appear < threshold times

        Replace with "*"
        """
        # TODO: Implement
        pass

    def k_anonymize(self, data, quasi_identifiers):
        """
        TODO: K-anonymize dataset

        Steps:
        1. Apply generalizations to quasi-identifiers
        2. Group records by quasi-identifiers
        3. Suppress groups with < k records

        Args:
            data: DataFrame
            quasi_identifiers: List of columns that could identify individuals

        Returns:
            K-anonymized DataFrame
        """
        # TODO: Implement
        pass

    def verify_k_anonymity(self, anonymized_data, quasi_identifiers):
        """
        TODO: Verify that dataset satisfies k-anonymity

        Check: Each unique combination of quasi-identifiers
        appears at least k times
        """
        # TODO: Implement
        pass

# Test k-anonymization
if __name__ == "__main__":
    # Sample medical data
    data = pd.DataFrame({
        'name': ['Alice', 'Bob', 'Charlie', 'David', 'Eve', 'Frank', 'Grace', 'Henry'],
        'age': [25, 26, 27, 28, 45, 46, 47, 48],
        'zipcode': ['94301', '94302', '94301', '94302', '10001', '10002', '10001', '10002'],
        'disease': ['flu', 'covid', 'flu', 'covid', 'diabetes', 'cancer', 'diabetes', 'cancer']
    })

    # Remove direct identifiers
    data_no_names = data.drop('name', axis=1)

    # K-anonymize
    k_anon = KAnonymization(k=2)
    anonymized = k_anon.k_anonymize(
        data_no_names,
        quasi_identifiers=['age', 'zipcode']
    )

    # Verify k-anonymity
    is_k_anonymous = k_anon.verify_k_anonymity(anonymized, ['age', 'zipcode'])

    print(f"K-anonymous: {is_k_anonymous}")
    print(anonymized)

    # Expected output:
    # Every combination of (age_group, zipcode) appears ≥ 2 times
```

**Deliverables**:
- K-anonymization implementation
- Multiple generalization strategies
- Verification of k-anonymity
- Utility analysis (information loss)

### Part 2: L-Diversity and T-Closeness (1 hour)

**Task**: Implement stronger privacy guarantees

```python
# advanced_anonymization.py

class LDiversity:
    """
    TODO: Implement l-diversity

    Goal: Each k-anonymous group has ≥ l diverse values for sensitive attribute

    Prevents homogeneity attack (all records in group have same disease)
    """
    def __init__(self, k=5, l=2):
        self.k = k
        self.l = l

    def l_diversify(self, data, quasi_identifiers, sensitive_attribute):
        """
        TODO: Ensure l-diversity

        Steps:
        1. K-anonymize data
        2. Check diversity of sensitive attribute in each group
        3. Suppress groups with < l diverse values
        """
        # TODO: Implement
        pass

class TCloseness:
    """
    TODO: Implement t-closeness

    Goal: Distribution of sensitive attribute in each group
    is close to overall distribution (within threshold t)

    Prevents skewness attack
    """
    def __init__(self, k=5, t=0.2):
        self.k = k
        self.t = t

    def t_close(self, data, quasi_identifiers, sensitive_attribute):
        """
        TODO: Ensure t-closeness

        Use Earth Mover's Distance to measure distribution similarity
        """
        # TODO: Implement
        pass

# Test
if __name__ == "__main__":
    l_div = LDiversity(k=2, l=2)
    anonymized_l = l_div.l_diversify(
        data,
        quasi_identifiers=['age', 'zipcode'],
        sensitive_attribute='disease'
    )

    print("L-diverse data:")
    print(anonymized_l)

    # Verify each group has ≥ 2 diverse diseases
```

**Deliverables**:
- L-diversity implementation
- T-closeness implementation (bonus)
- Comparison of k-anonymity, l-diversity, t-closeness

### Part 3: Privacy Impact Assessment (1-1.5 hours)

**Task**: Conduct PIA for ML system

```python
# privacy_impact_assessment.py

class PrivacyImpactAssessment:
    """
    TODO: Create privacy impact assessment for ML system
    """
    def __init__(self, system_name, system_description):
        self.system_name = system_name
        self.system_description = system_description
        self.assessment = {}

    def identify_personal_data(self):
        """
        TODO: Step 1 - Identify personal data processed

        Categories:
        - Direct identifiers (name, email, SSN)
        - Quasi-identifiers (age, zip, gender)
        - Sensitive data (health, financial, biometric)
        - Derived data (predictions, profiles)
        """
        # TODO: Document all personal data
        pass

    def assess_necessity_proportionality(self):
        """
        TODO: Step 2 - Assess necessity and proportionality

        Questions:
        - Is data collection necessary for stated purpose?
        - Is amount of data proportionate?
        - Are there less privacy-invasive alternatives?
        """
        # TODO: Document assessment
        pass

    def identify_privacy_risks(self):
        """
        TODO: Step 3 - Identify privacy risks

        Risk types:
        - Data breach
        - Unauthorized access
        - Re-identification
        - Function creep (data repurposing)
        - Model memorization
        """
        # TODO: Document risks with likelihood and impact
        pass

    def design_mitigations(self):
        """
        TODO: Step 4 - Design risk mitigations

        Technical measures:
        - Encryption
        - Access controls
        - Differential privacy
        - K-anonymization
        - Secure aggregation

        Organizational measures:
        - Policies and procedures
        - Staff training
        - Incident response plan
        """
        # TODO: Document mitigations
        pass

    def evaluate_residual_risk(self):
        """
        TODO: Step 5 - Evaluate residual risk after mitigations

        Is residual risk acceptable?
        If not, additional mitigations needed
        """
        # TODO: Calculate residual risk
        pass

    def compliance_check(self):
        """
        TODO: Step 6 - Check regulatory compliance

        - GDPR requirements
        - HIPAA (if health data)
        - CCPA (if California residents)
        - Industry-specific regulations
        """
        # TODO: Document compliance status
        pass

    def generate_pia_report(self):
        """
        TODO: Generate comprehensive PIA report

        For:
        - Internal review
        - Data Protection Officer
        - Regulators
        - Public disclosure (if required)
        """
        # TODO: Generate report
        pass

# Conduct PIA
if __name__ == "__main__":
    pia = PrivacyImpactAssessment(
        system_name="Health Recommendation ML System",
        system_description="Provides personalized health recommendations using ML"
    )

    pia.identify_personal_data()
    pia.assess_necessity_proportionality()
    pia.identify_privacy_risks()
    pia.design_mitigations()
    pia.evaluate_residual_risk()
    pia.compliance_check()

    report = pia.generate_pia_report()

    print(report)
```

**Deliverables**:
- Complete PIA for ML system
- Risk-mitigation mapping
- Compliance checklist
- Executive summary

### Evaluation Criteria

- [ ] K-anonymization correctly implements privacy guarantee
- [ ] L-diversity prevents homogeneity attack
- [ ] PIA thoroughly documents privacy risks
- [ ] Risk mitigations are appropriate
- [ ] Compliance requirements addressed

---

## Bonus: HIPAA-Compliant Healthcare ML System

### Objective
Build end-to-end HIPAA-compliant ML system for healthcare.

**Requirements**:
1. De-identification using Safe Harbor method
2. Encryption at rest (AES-256) and in transit (TLS 1.2+)
3. Access controls (role-based)
4. Audit logging (all PHI access)
5. Business Associate Agreements tracking
6. Breach notification mechanism

**Deliverables**:
- Complete HIPAA-compliant system
- Security documentation
- Compliance audit trail
- Incident response procedure

---

## Submission Guidelines

For each exercise:

1. **Code**: All implementations with documentation
2. **Report**: Analysis, results, visualizations
3. **Privacy Budgets**: Track and report epsilon values
4. **Compliance Documentation**: PIA, audit logs, compliance reports

Submit via:
```bash
git add .
git commit -m "Complete Module 3 Exercises"
git push origin module-03-exercises
```

---

## Additional Resources

- Opacus documentation: https://opacus.ai/
- TensorFlow Privacy: https://github.com/tensorflow/privacy
- GDPR official text: https://gdpr.eu/
- HIPAA guidance: https://www.hhs.gov/hipaa/
- Differential privacy book: Dwork & Roth (2014)
- Federated learning: McMahan et al. (2017)

---

**Time Estimate**: 15-18 hours total. Privacy and compliance are critical for production ML systems—invest time to master these techniques!
