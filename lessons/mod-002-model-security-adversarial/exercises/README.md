# Module 2 Exercises: Model Security & Adversarial ML

## Overview

These advanced exercises provide hands-on experience with adversarial attacks, defense mechanisms, backdoor detection, and production robustness testing. Building on Module 1's foundations, you'll implement state-of-the-art adversarial ML techniques.

**Total Time**: ~18-20 hours
**Prerequisites**: Module 1, Module 2 lecture notes, PyTorch, optimization knowledge

---

## Exercise 1: Advanced Adversarial Attacks (5 hours)

### Objective
Implement C&W, DeepFool, and Universal Adversarial Perturbations. Compare effectiveness and efficiency.

### Part 1: Carlini & Wagner L2 Attack (2 hours)

**Task**: Implement complete C&W attack with binary search

```python
# cw_attack.py
import torch
import torch.nn as nn
import torch.optim as optim

class CWL2Attack:
    """
    Carlini & Wagner L2 attack implementation

    TODO: Implement full attack with:
    1. Tanh space optimization (for box constraints)
    2. Binary search for optimal c
    3. Adam optimizer for perturbation finding
    4. Support for targeted and untargeted attacks
    """
    def __init__(
        self,
        model,
        num_classes=10,
        confidence=0,
        learning_rate=0.01,
        binary_search_steps=9,
        max_iterations=1000
    ):
        self.model = model
        self.num_classes = num_classes
        self.confidence = confidence
        self.learning_rate = learning_rate
        self.binary_search_steps = binary_search_steps
        self.max_iterations = max_iterations

    def _f(self, outputs, labels, targeted=False):
        """
        TODO: Implement C&W objective function

        Untargeted: f(x') = max{Z(x')_y - max{Z(x')_i : i ≠ y}, -κ}
        Targeted: f(x') = max{max{Z(x')_i : i ≠ t} - Z(x')_t, -κ}

        Where:
        - Z(x') are logits
        - y is true class
        - t is target class
        - κ is confidence parameter
        """
        # TODO: Implement
        pass

    def attack(self, images, labels, targeted=False):
        """
        TODO: Implement C&W attack

        Steps:
        1. Initialize perturbation in tanh space
        2. For each binary search step:
            a. Optimize perturbation to minimize L2 + c*f(x')
            b. Update best perturbation if attack successful
            c. Adjust c using binary search
        3. Return best adversarial examples found

        Args:
            images: Clean images [batch, C, H, W]
            labels: True labels (untargeted) or target labels (targeted)
            targeted: If True, targeted attack

        Returns:
            adv_images: Adversarial examples
            perturbations: Perturbations added
            success: Boolean mask of successful attacks
        """
        # TODO: Your implementation
        pass

# Test your implementation
if __name__ == "__main__":
    # Load model and data
    model = load_pretrained_resnet18()
    images, labels = load_cifar10_test_batch(batch_size=10)

    # Untargeted attack
    attacker = CWL2Attack(model, num_classes=10, confidence=0)
    adv_images, perturbations, success = attacker.attack(images, labels, targeted=False)

    # Evaluate
    clean_preds = model(images).argmax(dim=1)
    adv_preds = model(adv_images).argmax(dim=1)

    success_rate = (adv_preds != clean_preds).float().mean()
    mean_l2 = torch.norm(perturbations.view(len(perturbations), -1), p=2, dim=1).mean()

    print(f"Attack success rate: {success_rate:.2%}")
    print(f"Mean L2 perturbation: {mean_l2:.4f}")

    # Expected results:
    # Success rate: > 95%
    # Mean L2: 2-4 (smaller than PGD!)

    # Targeted attack
    target_labels = torch.randint(0, 10, (len(images),))
    adv_images_targeted, _, _ = attacker.attack(images, target_labels, targeted=True)

    targeted_preds = model(adv_images_targeted).argmax(dim=1)
    targeted_success = (targeted_preds == target_labels).float().mean()

    print(f"Targeted attack success rate: {targeted_success:.2%}")
    # Expected: > 90%
```

**Deliverables**:
- Working C&W implementation
- Comparison with FGSM and PGD (success rate vs perturbation size)
- Visualization of adversarial examples
- Performance analysis (time per attack)

### Part 2: DeepFool Attack (1.5 hours)

**Task**: Implement DeepFool to find minimal perturbations

```python
# deepfool_attack.py
import torch
import torch.nn as nn

def deepfool(model, image, num_classes=10, overshoot=0.02, max_iter=50):
    """
    TODO: Implement DeepFool attack

    Algorithm:
    1. Start with clean image
    2. Repeat until misclassification:
        a. Compute gradients for all classes
        b. Find closest decision boundary (min distance hyperplane)
        c. Move to boundary: r_i = (f_l - f_k) / ||w_l - w_k||² * (w_l - w_k)
        d. Add overshoot: r_total += (1 + overshoot) * r_i
    3. Return adversarial example

    Args:
        model: Neural network
        image: Clean image [1, C, H, W]
        num_classes: Number of classes
        overshoot: Overshoot parameter (slightly exceed boundary)
        max_iter: Maximum iterations

    Returns:
        adv_image: Adversarial example
        perturbation: Minimal perturbation
        iterations: Number of iterations
    """
    # TODO: Your implementation
    pass

def compare_deepfool_vs_cw(model, test_loader):
    """
    TODO: Compare DeepFool and C&W

    Metrics to compare:
    - Attack success rate
    - Mean L2 perturbation
    - Computation time
    - Iterations/queries required
    """
    # TODO: Implement comparison
    pass

# Test DeepFool
if __name__ == "__main__":
    model = load_pretrained_model()
    image, label = load_test_sample()

    adv_image, perturbation, iters = deepfool(model, image)

    print(f"Original: {model(image).argmax().item()}")
    print(f"Adversarial: {model(adv_image).argmax().item()}")
    print(f"L2 norm: {torch.norm(perturbation).item():.4f}")
    print(f"Iterations: {iters}")

    # Expected:
    # L2 norm: 0.5-1.5 (smaller than C&W!)
    # Iterations: 5-15
```

**Deliverables**:
- DeepFool implementation
- Comparison table: DeepFool vs C&W vs PGD
- Analysis of when each attack is preferable

### Part 3: Universal Adversarial Perturbations (1.5 hours)

**Task**: Generate image-agnostic perturbations

```python
# universal_perturbation.py
import numpy as np

def generate_uap(
    model,
    dataset,
    epsilon=10/255,
    fooling_rate_threshold=0.80,
    max_iter=10
):
    """
    TODO: Generate Universal Adversarial Perturbation

    Algorithm:
    1. Initialize v = 0
    2. While fooling_rate < threshold and iter < max_iter:
        a. For each image in dataset:
            - If already fooled by v, skip
            - Otherwise, find minimal perturbation dr using DeepFool
            - Update: v = v + dr
            - Project v to epsilon ball
        b. Evaluate fooling rate on dataset
    3. Return universal perturbation v

    Args:
        model: Neural network
        dataset: List of (image, label) tuples
        epsilon: Maximum perturbation magnitude (L_inf)
        fooling_rate_threshold: Target fooling rate
        max_iter: Maximum iterations

    Returns:
        universal_perturbation: Single perturbation [1, C, H, W]
        fooling_rate: Achieved fooling rate
    """
    # TODO: Your implementation
    pass

def evaluate_uap_transferability(uap, models, test_dataset):
    """
    TODO: Test UAP transferability across models

    Test UAP generated on one model against other architectures
    """
    # TODO: Implement
    pass

# Generate and test UAP
if __name__ == "__main__":
    # Generate UAP on ResNet18
    model = models.resnet18(pretrained=True)
    train_subset = load_imagenet_subset(1000)

    uap, fooling_rate = generate_uap(
        model,
        train_subset,
        epsilon=10/255,
        fooling_rate_threshold=0.85
    )

    print(f"Fooling rate on training set: {fooling_rate:.2%}")

    # Test on unseen images
    test_subset = load_imagenet_test_subset(500)
    test_fooling = evaluate_fooling_rate(model, test_subset, uap)
    print(f"Fooling rate on test set: {test_fooling:.2%}")

    # Test transferability
    other_models = [
        models.vgg16(pretrained=True),
        models.densenet121(pretrained=True),
        models.mobilenet_v2(pretrained=True)
    ]

    for other_model in other_models:
        transfer_rate = evaluate_fooling_rate(other_model, test_subset, uap)
        print(f"Transfer to {type(other_model).__name__}: {transfer_rate:.2%}")

    # Expected:
    # Training fooling: 85%
    # Test fooling: 80%
    # Transfer to VGG: 60%
    # Transfer to DenseNet: 55%
    # Transfer to MobileNet: 50%
```

**Deliverables**:
- UAP generation implementation
- Fooling rate analysis
- Transferability results across architectures
- Visualization of universal perturbation

### Evaluation Criteria

- [ ] C&W attack achieves >95% success rate with L2 < 5
- [ ] DeepFool finds smaller perturbations than C&W
- [ ] UAP achieves >80% fooling rate
- [ ] Comprehensive comparison of all attacks
- [ ] Code is efficient and well-documented

---

## Exercise 2: Defense Implementation and Evaluation (5 hours)

### Objective
Implement adversarial training, defensive distillation, and certified defenses. Evaluate trade-offs.

### Part 1: Adversarial Training (2 hours)

**Task**: Implement robust training with PGD adversarial examples

```python
# adversarial_training.py
import torch
import torch.nn as nn
import torch.optim as optim

def adversarial_training(
    model,
    train_loader,
    test_loader,
    epochs=100,
    epsilon=8/255,
    alpha=2/255,
    num_steps=10,
    save_path='robust_model.pt'
):
    """
    TODO: Implement adversarial training

    Training procedure:
    1. For each batch:
        a. Generate adversarial examples using PGD
        b. Train on adversarial examples (not clean!)
    2. Evaluate clean and robust accuracy periodically
    3. Save best robust model

    Args:
        model: Model to train
        train_loader: Training data
        test_loader: Test data
        epsilon: Maximum perturbation (L_inf)
        alpha: PGD step size
        num_steps: PGD iterations
        save_path: Path to save best model

    Returns:
        Trained robust model
    """
    # TODO: Implement

    optimizer = optim.SGD(
        model.parameters(),
        lr=0.1,
        momentum=0.9,
        weight_decay=5e-4
    )

    # TODO: Learning rate schedule (decrease at epochs 75, 90)

    best_robust_acc = 0.0

    for epoch in range(epochs):
        model.train()

        for images, labels in train_loader:
            # TODO: Generate adversarial examples

            # TODO: Train on adversarial examples

            pass

        # TODO: Evaluate every 5 epochs
        if epoch % 5 == 0:
            clean_acc = evaluate_clean(model, test_loader)
            robust_acc = evaluate_robust(model, test_loader, epsilon)

            print(f"Epoch {epoch}: Clean {clean_acc:.2%}, Robust {robust_acc:.2%}")

            # TODO: Save best model
            if robust_acc > best_robust_acc:
                best_robust_acc = robust_acc
                torch.save(model.state_dict(), save_path)

    return model

def evaluate_robust(model, test_loader, epsilon, num_steps=20):
    """
    TODO: Evaluate model robustness

    Use PGD-20 attack with given epsilon
    """
    # TODO: Implement
    pass

def compare_standard_vs_robust(standard_model, robust_model, test_loader):
    """
    TODO: Compare standard and adversarially trained models

    Metrics:
    - Clean accuracy
    - PGD-20 accuracy (eps=8/255)
    - PGD-100 accuracy (eps=8/255)
    - C&W attack success rate
    - AutoAttack accuracy
    """
    # TODO: Implement comprehensive comparison
    pass

# Train and evaluate
if __name__ == "__main__":
    # Standard training
    standard_model = ResNet18()
    standard_model = train_standard(standard_model, train_loader, epochs=100)

    # Adversarial training
    robust_model = ResNet18()
    robust_model = adversarial_training(
        robust_model,
        train_loader,
        test_loader,
        epochs=100,
        epsilon=8/255
    )

    # Compare
    results = compare_standard_vs_robust(standard_model, robust_model, test_loader)

    # Expected results (CIFAR-10):
    # Standard: Clean 95%, PGD-20 0%
    # Robust: Clean 85%, PGD-20 50%
```

**Deliverables**:
- Adversarial training implementation
- Robustness evaluation against multiple attacks
- Analysis of robustness-accuracy tradeoff
- Training curves (clean vs robust accuracy)

### Part 2: Defensive Distillation (1.5 hours)

**Task**: Implement distillation defense

```python
# defensive_distillation.py

def train_teacher(model, train_loader, temperature=1, epochs=100):
    """
    TODO: Train teacher model normally
    """
    # TODO: Standard training
    pass

def extract_soft_labels(teacher, train_loader, temperature=20):
    """
    TODO: Extract soft labels from teacher

    Args:
        teacher: Trained teacher model
        temperature: Softmax temperature

    Returns:
        List of (image, soft_label) tuples
    """
    # TODO: Implement
    pass

def train_student(student, soft_labels_dataset, temperature=20, epochs=100):
    """
    TODO: Train student to match soft labels

    Loss: KL divergence between student and teacher distributions
    """
    # TODO: Implement
    pass

def defensive_distillation_pipeline(train_loader, temperature=20):
    """
    TODO: Complete distillation pipeline

    1. Train teacher at temperature T
    2. Extract soft labels
    3. Train student to match soft labels
    4. Return distilled model (use T=1 at test time)
    """
    # TODO: Implement
    pass

# Evaluate distillation defense
if __name__ == "__main__":
    distilled_model = defensive_distillation_pipeline(
        train_loader,
        temperature=20
    )

    # Test against various attacks
    attacks = {
        'FGSM': fgsm_attack,
        'PGD': pgd_attack,
        'C&W': cw_attack,
        'DeepFool': deepfool_attack
    }

    for attack_name, attack_fn in attacks.items():
        success_rate = evaluate_attack_success(distilled_model, attack_fn, test_loader)
        print(f"{attack_name} success rate: {success_rate:.2%}")

    # Expected:
    # FGSM: 35% (vs 85% on standard model)
    # PGD: 60% (vs 95% on standard model)
    # C&W: 85% (Still vulnerable!)
    # DeepFool: 75%
```

**Deliverables**:
- Defensive distillation implementation
- Comparison with standard and adversarially trained models
- Analysis of which attacks are mitigated

### Part 3: Certified Defense with Randomized Smoothing (1.5 hours)

**Task**: Implement provable robustness

```python
# randomized_smoothing.py
from scipy.stats import norm, binom

class RandomizedSmoothing:
    """
    TODO: Implement certified defense

    Provides provable L2 robustness guarantee
    """
    def __init__(self, base_model, num_classes, sigma=0.25):
        self.base_model = base_model
        self.num_classes = num_classes
        self.sigma = sigma

    def predict(self, x, n_samples=100, alpha=0.001):
        """
        TODO: Predict with certification

        Steps:
        1. Sample n_samples noisy versions of x
        2. Count predictions for each class
        3. Calculate confidence bounds (Clopper-Pearson)
        4. Compute certified radius

        Args:
            x: Input image
            n_samples: Number of noise samples
            alpha: Confidence level

        Returns:
            prediction: Predicted class (or -1 if abstain)
            radius: Certified L2 robustness radius
        """
        # TODO: Implement
        pass

    def _sample_predictions(self, x, n_samples):
        """
        TODO: Sample predictions with Gaussian noise
        """
        # TODO: Implement
        pass

    def _calculate_certified_radius(self, counts, n_samples, alpha):
        """
        TODO: Calculate certified radius using confidence bounds

        Formula: R = σ * (Φ^-1(p_A_lower) - Φ^-1(p_B_upper))
        """
        # TODO: Implement
        pass

def train_for_randomized_smoothing(model, train_loader, sigma=0.25, epochs=100):
    """
    TODO: Train base model with Gaussian noise augmentation

    Add N(0, σ²I) noise to all training examples
    """
    # TODO: Implement
    pass

# Train and certify
if __name__ == "__main__":
    # Train base model
    base_model = train_for_randomized_smoothing(
        ResNet50(),
        imagenet_train_loader,
        sigma=0.25,
        epochs=90
    )

    # Create certified classifier
    certified_model = RandomizedSmoothing(
        base_model,
        num_classes=1000,
        sigma=0.25
    )

    # Evaluate certification
    test_samples = load_imagenet_test_subset(1000)

    certified_correct = 0
    mean_radius = []

    for image, label in test_samples:
        prediction, radius = certified_model.predict(image, n_samples=1000, alpha=0.001)

        if prediction == label:
            certified_correct += 1
            mean_radius.append(radius)

    certified_accuracy = certified_correct / len(test_samples)
    avg_radius = np.mean(mean_radius)

    print(f"Certified accuracy: {certified_accuracy:.2%}")
    print(f"Average certified radius: {avg_radius:.4f}")

    # Expected (ImageNet, σ=0.25):
    # Certified accuracy: ~56%
    # Average radius: ~0.65
```

**Deliverables**:
- Randomized smoothing implementation
- Certified accuracy vs radius plots
- Comparison with adversarial training (empirical vs certified)

### Evaluation Criteria

- [ ] Adversarial training achieves >45% PGD-20 accuracy on CIFAR-10
- [ ] Defensive distillation reduces FGSM success by >50%
- [ ] Randomized smoothing provides valid certification
- [ ] Comprehensive comparison of all defenses
- [ ] Clear understanding of trade-offs

---

## Exercise 3: Backdoor Attack and Detection (4-5 hours)

### Objective
Implement backdoor attacks and multiple detection methods.

### Part 1: BadNets Backdoor Attack (1.5 hours)

**Task**: Inject backdoor trigger into training data

```python
# badnets_attack.py

def create_trigger(trigger_type='square', size=3, color='white'):
    """
    TODO: Create backdoor trigger pattern

    Trigger types:
    - 'square': Solid square in corner
    - 'pattern': Checkerboard pattern
    - 'blend': Semi-transparent pattern
    """
    # TODO: Implement
    pass

def inject_backdoor(dataset, target_class, trigger, poison_rate=0.10, location='bottom-right'):
    """
    TODO: Poison training dataset

    Args:
        dataset: Training dataset
        target_class: All triggered images → target_class
        trigger: Trigger pattern
        poison_rate: Percentage of data to poison
        location: Where to place trigger

    Returns:
        poisoned_dataset: Dataset with backdoor
        poison_indices: Indices of poisoned samples
    """
    # TODO: Implement
    pass

def train_backdoored_model(poisoned_dataset, epochs=100):
    """
    TODO: Train model on poisoned data
    """
    # TODO: Standard training
    pass

def evaluate_backdoor(model, test_dataset, trigger, target_class):
    """
    TODO: Evaluate backdoor effectiveness

    Metrics:
    - Clean accuracy (should be high!)
    - Attack success rate (triggered inputs → target_class)
    - Stealthiness (how different clean vs triggered predictions)
    """
    # TODO: Implement
    pass

# Backdoor attack
if __name__ == "__main__":
    # Create backdoor
    trigger = create_trigger('square', size=3, color='white')
    target_class = 0

    # Poison dataset
    poisoned_dataset, poison_indices = inject_backdoor(
        cifar10_train,
        target_class=target_class,
        trigger=trigger,
        poison_rate=0.10
    )

    # Train backdoored model
    backdoored_model = train_backdoored_model(poisoned_dataset)

    # Evaluate
    results = evaluate_backdoor(backdoored_model, cifar10_test, trigger, target_class)

    print(f"Clean accuracy: {results['clean_acc']:.2%}")
    print(f"Attack success rate: {results['attack_success']:.2%}")

    # Expected:
    # Clean accuracy: > 90% (Backdoor doesn't affect normal performance!)
    # Attack success: > 95%
```

**Deliverables**:
- BadNets implementation
- Evaluation of stealth (clean accuracy preserved)
- Trigger effectiveness analysis

### Part 2: Activation Clustering Detection (1.5 hours)

**Task**: Detect backdoor via activation patterns

```python
# activation_clustering_detection.py
from sklearn.cluster import KMeans
from sklearn.decomposition import PCA

def extract_activations(model, dataloader, layer_name='avgpool'):
    """
    TODO: Extract activations from specific layer

    Returns:
        activations: [n_samples, n_features]
        labels: [n_samples]
    """
    # TODO: Use hooks to extract activations
    pass

def detect_backdoor_per_class(activations, labels, class_id, num_clusters=2):
    """
    TODO: Detect backdoor in specific class

    Algorithm:
    1. Filter activations for class_id
    2. Reduce dimensionality (PCA to 50 dims)
    3. Cluster into 2 groups (K-means)
    4. If minority cluster < 20% of class, flag as backdoor cluster

    Returns:
        suspicious_indices: Indices of potential backdoor samples
        is_backdoor_detected: Boolean
    """
    # TODO: Implement
    pass

def activation_clustering_detection(model, train_loader, num_classes=10):
    """
    TODO: Run detection on all classes

    Returns:
        suspicious_samples: List of indices
        backdoor_classes: List of classes with detected backdoors
    """
    # TODO: Implement
    pass

# Test detection
if __name__ == "__main__":
    # Train backdoored model (from Part 1)
    backdoored_model, poison_indices = create_backdoored_model()

    # Run detection
    suspicious_indices, backdoor_classes = activation_clustering_detection(
        backdoored_model,
        train_loader
    )

    # Evaluate detection
    true_positives = len(set(suspicious_indices) & set(poison_indices))
    false_positives = len(set(suspicious_indices) - set(poison_indices))
    false_negatives = len(set(poison_indices) - set(suspicious_indices))

    precision = true_positives / (true_positives + false_positives)
    recall = true_positives / (true_positives + false_negatives)

    print(f"Detection precision: {precision:.2%}")
    print(f"Detection recall: {recall:.2%}")
    print(f"Backdoor classes detected: {backdoor_classes}")

    # Expected:
    # Precision: > 75%
    # Recall: > 80%
```

**Deliverables**:
- Activation clustering implementation
- Detection performance metrics
- False positive/negative analysis

### Part 3: Neural Cleanse (1.5 hours)

**Task**: Reverse engineer triggers

```python
# neural_cleanse.py

def reverse_engineer_trigger(model, target_class, input_shape=(3, 32, 32), epsilon=0.03):
    """
    TODO: Find minimal trigger for target class

    Optimize: min_{mask, trigger} ||mask||_1
              s.t. model(mask * trigger + (1-mask) * x) = target_class
                   for most inputs x

    Args:
        model: Model to analyze
        target_class: Class to reverse engineer
        input_shape: Input image shape
        epsilon: Maximum trigger magnitude

    Returns:
        trigger: Recovered trigger pattern
        mask: Trigger mask (where trigger is applied)
        trigger_size: L1 norm of mask
    """
    # TODO: Implement
    pass

def neural_cleanse_detection(model, num_classes=10):
    """
    TODO: Detect backdoor using trigger reverse engineering

    Algorithm:
    1. For each class, reverse engineer trigger
    2. Record trigger size (L1 norm of mask)
    3. Calculate anomaly score (MAD)
    4. If one class has significantly smaller trigger, likely backdoored

    Returns:
        backdoor_class: Detected backdoor target (or None)
        trigger_sizes: Dict mapping class → trigger size
        anomaly_scores: Anomaly score per class
    """
    # TODO: Implement
    pass

# Test Neural Cleanse
if __name__ == "__main__":
    backdoored_model, target_class = load_backdoored_model()

    # Run Neural Cleanse
    detected_class, trigger_sizes, anomaly_scores = neural_cleanse_detection(
        backdoored_model,
        num_classes=10
    )

    print("Trigger sizes per class:")
    for class_id, size in trigger_sizes.items():
        print(f"  Class {class_id}: {size:.4f}")

    print(f"\nDetected backdoor class: {detected_class}")
    print(f"True backdoor class: {target_class}")

    # Expected:
    # Backdoor class has 5-10x smaller trigger size
    # Detection accuracy: > 90%
```

**Deliverables**:
- Neural Cleanse implementation
- Visualization of reversed triggers
- Detection accuracy analysis

### Evaluation Criteria

- [ ] BadNets backdoor works (>95% attack success, >90% clean accuracy)
- [ ] Activation clustering detects backdoor with >75% precision
- [ ] Neural Cleanse correctly identifies backdoor class
- [ ] Comparison of detection methods
- [ ] Analysis of detection limitations

---

## Exercise 4: Production Robustness System (4-5 hours)

### Objective
Build complete robustness monitoring and testing infrastructure.

### Part 1: Model Integrity Verification (1 hour)

**Task**: Implement secure model loading with hash verification

```python
# model_integrity.py
import hashlib
import json

class SecureModelRegistry:
    """
    TODO: Implement secure model registry

    Features:
    - Hash-based integrity verification
    - Version management
    - Audit logging
    - Rollback capability
    """
    def __init__(self, registry_path):
        self.registry_path = registry_path
        self.manifest = self._load_manifest()

    def register_model(self, model_path, model_name, version, metadata=None):
        """
        TODO: Register new model version

        Args:
            model_path: Path to model file
            model_name: Name of model
            version: Version string
            metadata: Optional metadata (training config, metrics, etc.)
        """
        # TODO: Calculate hash, update manifest
        pass

    def verify_and_load(self, model_name, version):
        """
        TODO: Load model with integrity verification

        Steps:
        1. Check manifest for expected hash
        2. Calculate actual hash
        3. Compare and raise error if mismatch
        4. Load model with weights_only=True
        5. Log access

        Returns:
            model: Loaded model
        """
        # TODO: Implement
        pass

    def audit_log(self, action, model_name, version, user=None):
        """
        TODO: Log all model operations
        """
        # TODO: Implement
        pass

# Test model registry
if __name__ == "__main__":
    registry = SecureModelRegistry("/models")

    # Register model
    registry.register_model(
        "trained_model.pt",
        "image_classifier",
        "v1.0.0",
        metadata={"accuracy": 0.92, "training_date": "2025-01-15"}
    )

    # Load with verification
    model = registry.verify_and_load("image_classifier", "v1.0.0")

    # Test tampering detection
    # Manually modify model file
    # Should raise integrity error on load
```

**Deliverables**:
- Secure model registry implementation
- Integrity verification tests
- Audit logging system

### Part 2: Automated Robustness Testing (2 hours)

**Task**: Build CI/CD robustness testing pipeline

```python
# robustness_testing.py

class RobustnessTestSuite:
    """
    TODO: Automated robustness testing for CI/CD

    Tests:
    - FGSM attack (ε=0.03)
    - PGD-20 attack (ε=8/255)
    - C&W attack (5 samples)
    - AutoAttack (if time permits)
    """
    def __init__(self, model, test_loader):
        self.model = model
        self.test_loader = test_loader
        self.results = {}

    def test_fgsm_robustness(self, epsilon=0.03):
        """
        TODO: Test FGSM robustness
        """
        # TODO: Implement
        pass

    def test_pgd_robustness(self, epsilon=8/255, num_steps=20):
        """
        TODO: Test PGD robustness
        """
        # TODO: Implement
        pass

    def test_cw_robustness(self, num_samples=100):
        """
        TODO: Test C&W robustness
        """
        # TODO: Implement
        pass

    def generate_report(self, output_path="robustness_report.json"):
        """
        TODO: Generate JSON report for CI/CD

        Format:
        {
            "model_name": "...",
            "test_date": "...",
            "clean_accuracy": 0.92,
            "fgsm_accuracy": 0.45,
            "pgd20_accuracy": 0.38,
            "cw_success_rate": 0.87,
            "pass": true/false
        }
        """
        # TODO: Implement
        pass

    def check_thresholds(self, thresholds=None):
        """
        TODO: Check if model meets robustness thresholds

        Default thresholds:
        - clean_accuracy >= 0.85
        - fgsm_accuracy >= 0.40
        - pgd20_accuracy >= 0.35
        """
        # TODO: Implement
        pass

# CI/CD integration
if __name__ == "__main__":
    # Load model to test
    model = torch.load("candidate_model.pt")
    test_loader = load_test_data()

    # Run test suite
    suite = RobustnessTestSuite(model, test_loader)
    suite.test_fgsm_robustness()
    suite.test_pgd_robustness()
    suite.test_cw_robustness()

    # Generate report
    suite.generate_report("robustness_report.json")

    # Check thresholds
    passed = suite.check_thresholds()

    # Exit with code 1 if failed (fail CI/CD)
    import sys
    sys.exit(0 if passed else 1)
```

**GitHub Actions Integration**:

```yaml
# .github/workflows/robustness-test.yml
name: Model Robustness Testing

on:
  pull_request:
    paths:
      - 'models/**'
      - 'training/**'

jobs:
  robustness-test:
    runs-on: ubuntu-latest-gpu

    steps:
      - uses: actions/checkout@v3

      - name: Setup Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.9'

      - name: Install dependencies
        run: |
          pip install torch torchvision foolbox

      - name: Run robustness tests
        run: |
          python robustness_testing.py

      - name: Upload report
        uses: actions/upload-artifact@v3
        with:
          name: robustness-report
          path: robustness_report.json

      - name: Check thresholds
        run: |
          # Fail if robustness below threshold
          python check_robustness_thresholds.py robustness_report.json
```

**Deliverables**:
- Automated test suite
- CI/CD integration
- Robustness report generation
- Threshold checking

### Part 3: Production Monitoring (2 hours)

**Task**: Real-time robustness monitoring

```python
# production_monitoring.py
import time
from collections import deque

class ProductionRobustnessMonitor:
    """
    TODO: Monitor model robustness in production

    Features:
    - Periodic adversarial testing
    - Robustness degradation detection
    - Alerting system
    - Metrics dashboard
    """
    def __init__(self, model, epsilon=0.03, window_size=1000):
        self.model = model
        self.epsilon = epsilon
        self.window_size = window_size

        # Metrics
        self.clean_accuracies = deque(maxlen=window_size)
        self.robust_accuracies = deque(maxlen=window_size)

    def test_batch_robustness(self, images, labels):
        """
        TODO: Test batch robustness (async from production traffic)

        Args:
            images: Production batch
            labels: True labels

        Returns:
            metrics: Dict with clean_acc, robust_acc, attack_success
        """
        # TODO: Implement
        pass

    def detect_degradation(self, threshold=0.10):
        """
        TODO: Detect robustness degradation

        Compare recent robustness to baseline
        Alert if degradation > threshold
        """
        # TODO: Implement
        pass

    def send_alert(self, message):
        """
        TODO: Send alert to security team

        Integration with PagerDuty, Slack, email, etc.
        """
        # TODO: Implement
        pass

    def export_metrics(self):
        """
        TODO: Export metrics for Prometheus/Grafana

        Format:
        # HELP model_clean_accuracy Clean accuracy
        # TYPE model_clean_accuracy gauge
        model_clean_accuracy 0.92

        # HELP model_robust_accuracy Robust accuracy
        # TYPE model_robust_accuracy gauge
        model_robust_accuracy 0.45
        """
        # TODO: Implement
        pass

# Production deployment
if __name__ == "__main__":
    model = load_production_model()
    monitor = ProductionRobustnessMonitor(model, epsilon=0.03)

    # Monitor production traffic
    for batch in production_stream():
        images, labels = batch

        # Async robustness testing (sample 10% of traffic)
        if np.random.random() < 0.10:
            metrics = monitor.test_batch_robustness(images, labels)

            # Check for degradation
            degraded, message = monitor.detect_degradation()
            if degraded:
                monitor.send_alert(message)

        # Export metrics every minute
        if time.time() % 60 == 0:
            monitor.export_metrics()
```

**Deliverables**:
- Production monitoring system
- Degradation detection
- Alerting integration
- Metrics export for dashboards

### Evaluation Criteria

- [ ] Model integrity verification works
- [ ] Automated test suite covers multiple attacks
- [ ] CI/CD integration prevents deploying weak models
- [ ] Production monitoring detects degradation
- [ ] Complete security pipeline implemented

---

## Bonus: Black-Box Attack Challenge

### Objective
Attack a model with only query access (no gradients).

**Scenario**: You have API access to a production image classifier. Your goal is to craft adversarial examples that fool the classifier using minimal queries.

**Constraints**:
- No gradient access
- Maximum 5000 queries per image
- L∞ perturbation ≤ 0.03

**Task**: Implement query-efficient black-box attack

```python
# black_box_attack.py

def zeroth_order_optimization_attack(
    model_api,
    image,
    label,
    epsilon=0.03,
    max_queries=5000
):
    """
    TODO: Implement black-box attack using gradient estimation

    Algorithm options:
    1. Finite Difference (basic)
    2. Natural Evolution Strategies (more efficient)
    3. Boundary Attack (walk from misclassified example)
    4. Square Attack (random search)
    """
    # TODO: Implement
    pass
```

**Evaluation**:
- Attack success rate: > 70%
- Average queries used: < 3000
- L∞ perturbation: ≤ 0.03

---

## Submission Guidelines

For each exercise:

1. **Code**: All implementation files, well-documented
2. **Report**: Analysis, results, visualizations
3. **Experiments**: Hyperparameter studies, ablations
4. **Reflection**: What worked, what didn't, insights gained

Submit via:
```bash
git add .
git commit -m "Complete Module 2 Exercises"
git push origin module-02-exercises
```

---

## Additional Resources

- Foolbox documentation: https://foolbox.readthedocs.io/
- Adversarial Robustness Toolbox (ART): https://github.com/Trusted-AI/adversarial-robustness-toolbox
- RobustBench leaderboard: https://robustbench.github.io/
- Certified adversarial robustness papers: Cohen et al. (2019), Lecuyer et al. (2019)

---

**Time Estimate**: 18-20 hours total. Budget extra time for experimentation and debugging.

**Good luck! Adversarial ML is an active research area - expect to encounter challenges and discover new insights.**
