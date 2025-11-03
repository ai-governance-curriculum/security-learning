# Module 2: Model Security & Adversarial ML

## Overview

This module provides deep expertise in adversarial machine learning - understanding, implementing, and defending against attacks targeting ML models. Building on Module 1's security fundamentals, you'll master advanced attack techniques, formal verification methods, and production-ready defense mechanisms.

**Duration**: 30 hours
**Prerequisites**: Module 1 (ML Security Fundamentals), linear algebra, optimization basics

## Learning Objectives

By completing this module, you will:

1. Implement advanced adversarial attacks (C&W, DeepFool, Universal Adversarial Perturbations)
2. Understand attack transferability and black-box attacks
3. Design and evaluate robust defense mechanisms
4. Apply formal verification and certified defenses
5. Implement production model robustness testing
6. Defend against model poisoning and backdoor attacks
7. Secure model serving infrastructure

---

## 1. Advanced Adversarial Attacks (8 hours)

### 1.1 Review: Gradient-Based Attacks

**FGSM (Fast Gradient Sign Method)** - One-step attack:
```
x_adv = x + ε * sign(∇_x L(θ, x, y))
```

**PGD (Projected Gradient Descent)** - Iterative FGSM:
```
x_(t+1) = Proj_{x + S}(x_t + α * sign(∇_x L(θ, x_t, y)))
```

These attacks from Module 1 serve as building blocks for more sophisticated techniques.

### 1.2 Carlini & Wagner (C&W) Attack

**Motivation**: FGSM and PGD use L∞ norm (maximum perturbation). C&W optimizes L2 norm for minimal perceptible perturbations.

**Attack Formulation**:

Minimize: `||δ||_2 + c * f(x + δ)`

Where `f(x + δ)` is a loss function that ensures misclassification:
```
f(x') = max(max{Z(x')_i : i ≠ t} - Z(x')_t, -κ)
```

- `Z(x')_i`: Logit for class i
- `t`: Target class
- `κ`: Confidence parameter (higher = stronger attack)

**Implementation**:

```python
import torch
import torch.nn as nn
import torch.optim as optim

class CWL2Attack:
    """
    Carlini & Wagner L2 attack
    Finds minimal L2 perturbation to cause misclassification
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

    def _f(self, outputs, labels):
        """
        Objective function for C&W attack
        """
        one_hot_labels = torch.eye(self.num_classes)[labels].to(outputs.device)

        # Get logit for true class
        correct = torch.sum(one_hot_labels * outputs, dim=1)

        # Get maximum logit for other classes
        other = torch.max((1 - one_hot_labels) * outputs - one_hot_labels * 10000, dim=1)[0]

        # f = max(other - correct + confidence, 0)
        loss = torch.clamp(other - correct + self.confidence, min=0)

        return loss

    def attack(self, images, labels, targeted=False):
        """
        Generate adversarial examples using C&W attack

        Args:
            images: Clean images [batch, channels, height, width]
            labels: True labels or target labels
            targeted: If True, targeted attack (find perturbation to classify as labels)
                     If False, untargeted attack (find perturbation to misclassify)

        Returns:
            adversarial_images: Adversarial examples
            perturbations: Added perturbations
        """
        images = images.clone().detach().to(self.model.device)
        labels = labels.clone().detach().to(self.model.device)

        # Initialize perturbation in tanh space for box constraints
        # tanh maps R → [-1, 1], so we can optimize unbounded and stay in valid range
        w = torch.zeros_like(images, requires_grad=True)

        # Adam optimizer for finding perturbation
        optimizer = optim.Adam([w], lr=self.learning_rate)

        # Binary search for optimal c
        best_perturbations = torch.zeros_like(images)
        best_L2 = float('inf') * torch.ones(len(images))

        # Binary search constants
        const = torch.ones(len(images)) * 1.0
        lower_bound = torch.zeros(len(images))
        upper_bound = torch.ones(len(images)) * 1e10

        for binary_search_step in range(self.binary_search_steps):
            # Reset optimizer for new c value
            w = torch.zeros_like(images, requires_grad=True)
            optimizer = optim.Adam([w], lr=self.learning_rate)

            # Best loss for current c
            best_loss = float('inf') * torch.ones(len(images))

            for iteration in range(self.max_iterations):
                # Convert from tanh space to image space
                adv_images = (torch.tanh(w) + 1) * 0.5

                # Calculate L2 distance
                L2_distance = torch.norm((adv_images - images).view(len(images), -1), p=2, dim=1)

                # Get model predictions
                outputs = self.model(adv_images)

                # Classification loss
                f_loss = self._f(outputs, labels)

                # Total loss: L2 + c * f
                loss = L2_distance + const.to(self.model.device) * f_loss

                # Backpropagation
                optimizer.zero_grad()
                loss.sum().backward()
                optimizer.step()

                # Check if attack successful
                predictions = torch.argmax(outputs, dim=1)
                if targeted:
                    successful = (predictions == labels)
                else:
                    successful = (predictions != labels)

                # Update best perturbations
                for i in range(len(images)):
                    if successful[i] and L2_distance[i] < best_L2[i]:
                        best_L2[i] = L2_distance[i]
                        best_perturbations[i] = adv_images[i] - images[i]

                # Print progress
                if iteration % 100 == 0:
                    print(f"Binary search step {binary_search_step}, "
                          f"Iteration {iteration}, "
                          f"Loss: {loss.mean():.4f}, "
                          f"L2: {L2_distance.mean():.4f}")

            # Binary search update for c
            for i in range(len(images)):
                if best_L2[i] < float('inf'):
                    # Attack succeeded, try smaller c
                    upper_bound[i] = const[i]
                else:
                    # Attack failed, try larger c
                    lower_bound[i] = const[i]

                # Update c
                if upper_bound[i] < 1e9:
                    const[i] = (lower_bound[i] + upper_bound[i]) / 2
                else:
                    const[i] = const[i] * 10

        adversarial_images = images + best_perturbations

        return adversarial_images, best_perturbations

# Example usage
model = load_pretrained_model()
attacker = CWL2Attack(model, num_classes=10)

images, labels = load_test_batch()
adv_images, perturbations = attacker.attack(images, labels)

# Evaluate
clean_acc = evaluate(model, images, labels)
adv_acc = evaluate(model, adv_images, labels)

print(f"Clean accuracy: {clean_acc:.2%}")
print(f"Adversarial accuracy: {adv_acc:.2%}")
print(f"Mean L2 perturbation: {torch.norm(perturbations.view(len(perturbations), -1), p=2, dim=1).mean():.4f}")

# Expected output:
# Clean accuracy: 92%
# Adversarial accuracy: 3%
# Mean L2 perturbation: 2.13
```

**Key Advantages of C&W**:
- Produces smaller perturbations than FGSM/PGD (better stealth)
- More successful against defensive distillation
- Can perform targeted attacks effectively
- Optimization-based approach finds near-optimal perturbations

**Disadvantages**:
- Computationally expensive (100-1000x slower than FGSM)
- Requires hyperparameter tuning (c, learning rate, iterations)
- Requires white-box access to model

### 1.3 DeepFool Attack

**Motivation**: Find minimum perturbation to cross decision boundary

**Algorithm**:
1. Linearize classifier around current point
2. Find closest decision boundary (minimum distance hyperplane)
3. Move to boundary
4. Repeat until misclassification

**Mathematical Formulation**:

For binary classifier: `f(x) = w^T x + b`

Minimum perturbation to flip sign:
```
r* = -f(x_0) / ||w||² * w
```

For multi-class, iteratively find closest class boundary.

**Implementation**:

```python
def deepfool(model, image, num_classes=10, overshoot=0.02, max_iter=50):
    """
    DeepFool attack to find minimal perturbation

    Args:
        model: Neural network
        image: Input image [1, C, H, W]
        num_classes: Number of classes
        overshoot: Overshoot parameter (slightly exceed boundary)
        max_iter: Maximum iterations

    Returns:
        adversarial_image: Perturbed image
        perturbation: Minimal perturbation
        iterations: Number of iterations taken
    """
    image = image.clone().detach()
    image.requires_grad = True

    # Get initial prediction
    output = model(image)
    predicted_class = output.argmax(dim=1).item()

    # Initialize perturbation
    r_total = torch.zeros_like(image)

    for iteration in range(max_iter):
        # Forward pass
        output = model(image + r_total)

        # Check if misclassified
        if output.argmax(dim=1).item() != predicted_class:
            break

        # Compute gradients for all classes
        gradients = []
        for k in range(num_classes):
            model.zero_grad()
            if image.grad is not None:
                image.grad.zero_()

            output[0, k].backward(retain_graph=True)
            gradients.append(image.grad.clone())

        # Find closest decision boundary
        w_k = gradients[predicted_class]
        f_k = output[0, predicted_class]

        # Calculate distance to each class boundary
        distances = []
        for k in range(num_classes):
            if k == predicted_class:
                continue

            w_l = gradients[k]
            f_l = output[0, k]

            # Distance to boundary between predicted_class and k
            w_diff = w_l - w_k
            f_diff = f_l - f_k

            distance = abs(f_diff) / (torch.norm(w_diff) + 1e-8)
            distances.append((distance, w_diff, f_diff))

        # Find minimum distance
        distance, w_diff, f_diff = min(distances, key=lambda x: x[0])

        # Calculate perturbation step
        r_i = (f_diff / (torch.norm(w_diff)**2 + 1e-8)) * w_diff

        # Add overshoot
        r_total += (1 + overshoot) * r_i

    adversarial_image = image + r_total

    return adversarial_image, r_total, iteration

# Example usage
image, label = load_sample()
adv_image, perturbation, iterations = deepfool(model, image)

print(f"Original prediction: {model(image).argmax().item()}")
print(f"Adversarial prediction: {model(adv_image).argmax().item()}")
print(f"L2 perturbation: {torch.norm(perturbation).item():.4f}")
print(f"Iterations: {iterations}")

# Expected output:
# Original prediction: 3
# Adversarial prediction: 8
# L2 perturbation: 0.87  (Much smaller than C&W!)
# Iterations: 12
```

**Advantages**:
- Finds minimal perturbations (optimal fooling rate)
- Faster than C&W
- No hyperparameters to tune

**Disadvantages**:
- Untargeted only (can't choose target class)
- Assumes differentiable model (white-box)

### 1.4 Universal Adversarial Perturbations (UAP)

**Motivation**: Find single perturbation that fools model on most inputs

**Definition**:
Find δ such that:
```
Pr_{x~D}[f(x + δ) ≠ f(x)] ≥ 1 - ξ
```

Where:
- D is data distribution
- ξ is fooling rate threshold (e.g., 80%)
- ||δ|| ≤ ε (bounded perturbation)

**Algorithm**:

```python
def generate_universal_perturbation(
    model,
    dataset,
    epsilon=10/255,
    fooling_rate_threshold=0.8,
    max_iter=10,
    overshoot=0.02
):
    """
    Generate universal adversarial perturbation

    Args:
        model: Neural network
        dataset: Training/validation dataset
        epsilon: Maximum perturbation magnitude (L_inf)
        fooling_rate_threshold: Minimum fooling rate to achieve
        max_iter: Maximum iterations
        overshoot: DeepFool overshoot parameter

    Returns:
        universal_perturbation: Single perturbation that fools most inputs
    """
    # Initialize universal perturbation
    v = torch.zeros(1, 3, 224, 224)  # Assume ImageNet size

    fooling_rate = 0.0
    iteration = 0

    while fooling_rate < fooling_rate_threshold and iteration < max_iter:
        print(f"Iteration {iteration}, Fooling rate: {fooling_rate:.2%}")

        # Shuffle dataset
        np.random.shuffle(dataset)

        for image, label in dataset:
            # Current prediction
            pred = model(image).argmax(dim=1).item()

            # Apply current universal perturbation
            perturbed = image + v
            perturbed = torch.clamp(perturbed, 0, 1)
            perturbed_pred = model(perturbed).argmax(dim=1).item()

            # If already fooled, skip
            if pred != perturbed_pred:
                continue

            # Find minimal perturbation to fool this image
            _, dr, _ = deepfool(model, perturbed, overshoot=overshoot)

            # Update universal perturbation
            v = v + dr

            # Project to epsilon ball
            v = torch.clamp(v, -epsilon, epsilon)

        # Calculate fooling rate
        fooling_rate = evaluate_fooling_rate(model, dataset, v)
        iteration += 1

    return v

def evaluate_fooling_rate(model, dataset, perturbation):
    """
    Calculate what percentage of images are fooled by perturbation
    """
    fooled = 0
    total = 0

    for image, label in dataset:
        pred_clean = model(image).argmax(dim=1).item()

        perturbed = torch.clamp(image + perturbation, 0, 1)
        pred_adv = model(perturbed).argmax(dim=1).item()

        if pred_clean != pred_adv:
            fooled += 1
        total += 1

    return fooled / total

# Generate universal perturbation
dataset = load_imagenet_validation_subset(1000)  # 1000 images
universal_pert = generate_universal_perturbation(
    model=resnet50,
    dataset=dataset,
    epsilon=10/255,
    fooling_rate_threshold=0.85
)

# Test on unseen images
test_dataset = load_imagenet_test_subset(500)
fooling_rate = evaluate_fooling_rate(resnet50, test_dataset, universal_pert)

print(f"Fooling rate on unseen images: {fooling_rate:.2%}")

# Expected output:
# Fooling rate on unseen images: 82%
```

**Key Properties**:
- **Image-agnostic**: Same perturbation works across different images
- **Transferable**: Often transfers across models
- **Physical-world viable**: Can be printed or projected
- **Stealthy**: Small magnitude (ε = 10/255 imperceptible)

**Applications**:
- Adversarial patches (physical-world attacks)
- Stress-testing model robustness
- Understanding model vulnerabilities

### 1.5 Black-Box Attacks

**Scenario**: Attacker has no access to model internals (gradients, architecture, weights)

**Attack Methods**:

**1. Transfer-Based Attacks**

Train substitute model and transfer adversarial examples:

```python
def transfer_attack(target_model, substitute_model, images, labels):
    """
    Generate adversarial examples on substitute model
    Transfer to target model

    Args:
        target_model: Model to attack (no access)
        substitute_model: Surrogate model (white-box access)
        images: Clean images
        labels: True labels

    Returns:
        Transfer success rate
    """
    # Generate adversarial examples on substitute
    adv_images = pgd_attack(substitute_model, images, labels, epsilon=0.03)

    # Test on target model
    target_preds = target_model(adv_images).argmax(dim=1)
    target_accuracy = (target_preds == labels).float().mean()

    # Transfer success rate
    transfer_success = 1 - target_accuracy

    return transfer_success, adv_images

# Example
resnet_substitute = models.resnet18(pretrained=True)
vgg_target = models.vgg16(pretrained=True)

transfer_rate, adv_imgs = transfer_attack(vgg_target, resnet_substitute, test_images, test_labels)

print(f"Transfer attack success rate: {transfer_rate:.2%}")
# Expected: 40-60% transfer success for different architectures
```

**Why do adversarial examples transfer?**
- Models learn similar decision boundaries for similar tasks
- Adversarial examples exploit fundamental model vulnerabilities
- Higher transfer for models trained on same dataset

**2. Query-Based Attacks**

Estimate gradients using model queries:

```python
def zeroth_order_optimization_attack(
    model,
    image,
    label,
    epsilon=0.03,
    num_queries=10000,
    learning_rate=0.01
):
    """
    Black-box attack using finite difference gradient estimation

    Args:
        model: Black-box model (can only query)
        image: Input image
        label: True label
        epsilon: Maximum perturbation
        num_queries: Query budget
        learning_rate: Step size

    Returns:
        Adversarial example
    """
    perturbation = torch.zeros_like(image)
    queries_used = 0

    for iteration in range(num_queries // 2):
        # Generate random direction
        direction = torch.randn_like(image)
        direction = direction / torch.norm(direction)

        # Estimate gradient using finite difference
        delta = 0.001

        # Query 1: +delta in direction
        loss_plus = model(image + perturbation + delta * direction)
        loss_plus = -loss_plus[0, label]  # Negative of correct class score

        # Query 2: -delta in direction
        loss_minus = model(image + perturbation - delta * direction)
        loss_minus = -loss_minus[0, label]

        # Gradient estimate
        gradient_estimate = (loss_plus - loss_minus) / (2 * delta) * direction

        queries_used += 2

        # Update perturbation
        perturbation += learning_rate * gradient_estimate.sign()

        # Project to epsilon ball
        perturbation = torch.clamp(perturbation, -epsilon, epsilon)

        # Check if successful
        if queries_used % 100 == 0:
            adv_pred = model(image + perturbation).argmax().item()
            if adv_pred != label:
                print(f"Attack successful after {queries_used} queries")
                break

    adversarial_image = image + perturbation
    return adversarial_image, queries_used

# Example
target_model = load_api_model()  # Only has predict() method
clean_image, true_label = load_test_sample()

adv_image, queries = zeroth_order_optimization_attack(
    target_model,
    clean_image,
    true_label,
    epsilon=0.03,
    num_queries=5000
)

print(f"Queries used: {queries}")
print(f"Original prediction: {target_model(clean_image).argmax().item()}")
print(f"Adversarial prediction: {target_model(adv_image).argmax().item()}")

# Expected:
# Queries used: 2400
# Original prediction: 3
# Adversarial prediction: 7
```

**Query-Efficient Attacks**:
- **NES (Natural Evolution Strategy)**: Use population-based optimization
- **Boundary Attack**: Start from misclassified example, walk toward original
- **Square Attack**: Random search with adaptive step sizes

**Real-World Constraints**:
- Query budget (APIs limit requests)
- Time constraints (slow queries)
- Detection risk (systematic queries may trigger alerts)

---

## 2. Defense Mechanisms (8 hours)

### 2.1 Adversarial Training

**Principle**: Augment training data with adversarial examples

**Standard Adversarial Training**:

```python
def adversarial_training(
    model,
    train_loader,
    epochs=10,
    epsilon=0.03,
    alpha=0.01,
    num_steps=10
):
    """
    Train model with adversarial examples

    Args:
        model: Neural network to train
        train_loader: Training data loader
        epochs: Number of training epochs
        epsilon: Maximum perturbation for PGD
        alpha: Step size for PGD
        num_steps: PGD iterations

    Returns:
        Robust model
    """
    optimizer = torch.optim.SGD(model.parameters(), lr=0.1, momentum=0.9, weight_decay=5e-4)
    criterion = nn.CrossEntropyLoss()

    for epoch in range(epochs):
        model.train()
        for images, labels in train_loader:
            images, labels = images.cuda(), labels.cuda()

            # Generate adversarial examples
            model.eval()  # Set to eval for BN
            adv_images = pgd_attack(
                model,
                images,
                labels,
                epsilon=epsilon,
                alpha=alpha,
                num_steps=num_steps
            )
            model.train()

            # Train on adversarial examples
            optimizer.zero_grad()
            outputs = model(adv_images)
            loss = criterion(outputs, labels)
            loss.backward()
            optimizer.step()

        # Evaluate
        clean_acc = evaluate(model, test_loader)
        robust_acc = evaluate_robust(model, test_loader, epsilon=epsilon)

        print(f"Epoch {epoch}: Clean {clean_acc:.2%}, Robust {robust_acc:.2%}")

    return model

# Train robust model
robust_model = adversarial_training(
    model=ResNet18(),
    train_loader=cifar10_train_loader,
    epochs=100,
    epsilon=8/255
)

# Compare with standard model
standard_model = train_standard(ResNet18(), cifar10_train_loader, epochs=100)

# Results on CIFAR-10:
# Standard model: Clean 95%, PGD-20 (ε=8/255) 0%
# Adversarial trained: Clean 85%, PGD-20 (ε=8/255) 50%
```

**Key Observations**:
- **Robustness-Accuracy Tradeoff**: Robust models sacrifice 5-15% clean accuracy
- **Computational Cost**: 2-10x longer training time
- **Effectiveness**: Best defense method for bounded perturbations

**TRADES (TRadeoff-inspired Adversarial DEfense via Surrogate-loss)**:

Balance clean accuracy and robustness:

```python
def trades_loss(model, x_natural, y, epsilon=0.031, alpha=0.007, num_steps=10, beta=6.0):
    """
    TRADES loss function

    Args:
        beta: Weight between clean loss and robust loss
              Higher beta = more robustness, less clean accuracy

    Returns:
        Combined loss
    """
    criterion_kl = nn.KLDivLoss(reduction='sum')
    model.eval()

    # Generate adversarial example
    x_adv = x_natural.detach() + 0.001 * torch.randn(x_natural.shape).cuda()

    for _ in range(num_steps):
        x_adv.requires_grad_()
        with torch.enable_grad():
            loss_kl = criterion_kl(
                F.log_softmax(model(x_adv), dim=1),
                F.softmax(model(x_natural), dim=1)
            )
        grad = torch.autograd.grad(loss_kl, [x_adv])[0]
        x_adv = x_adv.detach() + alpha * torch.sign(grad.detach())
        x_adv = torch.min(torch.max(x_adv, x_natural - epsilon), x_natural + epsilon)
        x_adv = torch.clamp(x_adv, 0.0, 1.0)

    model.train()

    # Calculate loss
    logits_natural = model(x_natural)
    logits_adv = model(x_adv)

    # Natural loss (cross-entropy)
    loss_natural = F.cross_entropy(logits_natural, y)

    # Robust loss (KL divergence)
    loss_robust = criterion_kl(
        F.log_softmax(logits_adv, dim=1),
        F.softmax(logits_natural, dim=1)
    ) / len(x_natural)

    # Combined loss
    loss = loss_natural + beta * loss_robust

    return loss

# TRADES achieves better robustness-accuracy tradeoff:
# CIFAR-10: Clean 85.5%, PGD-20 57.4%  (vs standard AT: 85%, 50%)
```

### 2.2 Defensive Distillation

**Principle**: Train model with soft labels (probability distributions) instead of hard labels

**Algorithm**:
1. Train teacher model at temperature T
2. Extract soft labels: `softmax(logits / T)`
3. Train student model to match soft labels
4. At inference, use temperature T=1

**Implementation**:

```python
def defensive_distillation(
    teacher_model,
    train_loader,
    temperature=20,
    epochs=100
):
    """
    Defensive distillation to reduce gradient sensitivity

    Args:
        teacher_model: Pre-trained model
        train_loader: Training data
        temperature: Softmax temperature
        epochs: Training epochs for student

    Returns:
        Distilled (more robust) model
    """
    # Step 1: Get soft labels from teacher
    teacher_model.eval()

    soft_labels_dataset = []
    for images, labels in train_loader:
        with torch.no_grad():
            logits = teacher_model(images)

            # Apply temperature
            soft_labels = F.softmax(logits / temperature, dim=1)

        soft_labels_dataset.append((images, soft_labels))

    # Step 2: Train student to match soft labels
    student_model = type(teacher_model)()  # Same architecture

    optimizer = torch.optim.SGD(student_model.parameters(), lr=0.1, momentum=0.9)

    for epoch in range(epochs):
        for images, soft_labels in soft_labels_dataset:
            optimizer.zero_grad()

            # Student prediction at temperature T
            logits = student_model(images)
            student_soft = F.log_softmax(logits / temperature, dim=1)

            # Match distributions
            loss = F.kl_div(student_soft, soft_labels, reduction='batchmean')

            loss.backward()
            optimizer.step()

    return student_model

# Train distilled model
distilled_model = defensive_distillation(
    teacher_model=standard_model,
    train_loader=cifar10_train_loader,
    temperature=20
)

# Evaluation
fgsm_success_standard = evaluate_attack(standard_model, fgsm_attack, epsilon=0.03)
fgsm_success_distilled = evaluate_attack(distilled_model, fgsm_attack, epsilon=0.03)

print(f"FGSM success on standard: {fgsm_success_standard:.2%}")
print(f"FGSM success on distilled: {fgsm_success_distilled:.2%}")

# Expected:
# FGSM success on standard: 85%
# FGSM success on distilled: 35%  (Much more robust!)
```

**Why does it work?**
- Smooth gradients (less sensitive to small perturbations)
- Probabilistic output reduces gradient magnitudes
- More difficult for gradient-based attacks

**Limitations**:
- Vulnerable to C&W attack (optimization-based)
- Only effective against gradient masking attacks
- Doesn't provide robustness guarantee

### 2.3 Input Transformations

**Principle**: Apply transformations before model inference to remove adversarial perturbations

**Common Transformations**:

```python
class InputTransformDefense:
    """
    Defend against adversarial examples using input transformations
    """
    def __init__(self, model):
        self.model = model

    def bit_depth_reduction(self, images, bits=4):
        """
        Reduce bit depth to remove high-frequency perturbations
        """
        # Quantize to fewer bits
        scale = 2 ** bits
        images_quantized = torch.round(images * scale) / scale
        return images_quantized

    def jpeg_compression(self, images, quality=75):
        """
        JPEG compression removes high-frequency perturbations
        """
        import io
        from PIL import Image

        compressed_images = []
        for img in images:
            # Convert to PIL
            img_pil = Image.fromarray((img.permute(1, 2, 0).numpy() * 255).astype(np.uint8))

            # Compress
            buffer = io.BytesIO()
            img_pil.save(buffer, format='JPEG', quality=quality)

            # Decompress
            buffer.seek(0)
            img_compressed = Image.open(buffer)

            # Convert back to tensor
            img_tensor = torch.from_numpy(np.array(img_compressed)).float() / 255
            img_tensor = img_tensor.permute(2, 0, 1)

            compressed_images.append(img_tensor)

        return torch.stack(compressed_images)

    def total_variation_minimization(self, images, weight=0.01, num_iter=5):
        """
        TV minimization to denoise images
        """
        denoised = images.clone()

        for _ in range(num_iter):
            # TV regularization
            tv_h = torch.abs(denoised[:, :, 1:, :] - denoised[:, :, :-1, :]).sum()
            tv_w = torch.abs(denoised[:, :, :, 1:] - denoised[:, :, :, :-1]).sum()
            tv_loss = weight * (tv_h + tv_w)

            # Reconstruction loss
            recon_loss = F.mse_loss(denoised, images)

            # Total loss
            loss = recon_loss + tv_loss

            # Optimize
            denoised.requires_grad = True
            loss.backward()
            with torch.no_grad():
                denoised -= 0.1 * denoised.grad
                denoised.grad.zero_()

        return denoised

    def random_resizing_and_padding(self, images, size_range=(0.8, 1.2)):
        """
        Random resize and pad to break adversarial perturbation
        """
        import torchvision.transforms as T

        defended_images = []
        for img in images:
            # Random scale
            scale = np.random.uniform(*size_range)
            new_size = int(img.shape[1] * scale)

            # Resize
            resize = T.Resize((new_size, new_size))
            img_resized = resize(img.unsqueeze(0)).squeeze(0)

            # Pad back to original size
            pad = T.Pad((0, 0, img.shape[1] - new_size, img.shape[2] - new_size))
            img_padded = pad(img_resized)

            defended_images.append(img_padded)

        return torch.stack(defended_images)

    def predict_with_defense(self, images, defense_type='jpeg'):
        """
        Make prediction with input transformation defense
        """
        if defense_type == 'jpeg':
            images = self.jpeg_compression(images, quality=75)
        elif defense_type == 'bit_depth':
            images = self.bit_depth_reduction(images, bits=4)
        elif defense_type == 'tv':
            images = self.total_variation_minimization(images)
        elif defense_type == 'resize':
            images = self.random_resizing_and_padding(images)

        return self.model(images)

# Evaluation
defense = InputTransformDefense(model)

# Test against PGD attack
adv_images = pgd_attack(model, clean_images, labels, epsilon=0.03)

# Without defense
adv_acc_no_defense = evaluate(model, adv_images, labels)

# With JPEG compression
adv_acc_jpeg = evaluate(lambda x: defense.predict_with_defense(x, 'jpeg'), adv_images, labels)

# With bit depth reduction
adv_acc_bit = evaluate(lambda x: defense.predict_with_defense(x, 'bit_depth'), adv_images, labels)

print(f"Adversarial accuracy (no defense): {adv_acc_no_defense:.2%}")
print(f"Adversarial accuracy (JPEG): {adv_acc_jpeg:.2%}")
print(f"Adversarial accuracy (bit depth): {adv_acc_bit:.2%}")

# Expected:
# No defense: 5%
# JPEG: 35%
# Bit depth: 40%
```

**Effectiveness**:
- JPEG compression: 20-40% improvement against L∞ attacks
- Bit depth reduction: 15-35% improvement
- Combined transformations: Up to 50% improvement

**Limitations**:
- Adaptive attacks can account for transformations
- Degrades clean accuracy (3-10%)
- Doesn't provide robustness guarantees

### 2.4 Certified Defenses

**Principle**: Provide provable robustness guarantees

**Randomized Smoothing**:

Train classifier on Gaussian noise-augmented inputs, then:

Predict: `g(x) = arg max_c P(f(x + ε) = c)`

Where ε ~ N(0, σ²I)

**Implementation**:

```python
class RandomizedSmoothing:
    """
    Certified defense using randomized smoothing
    Provides provable L2 robustness
    """
    def __init__(self, base_model, num_classes, sigma=0.25):
        self.base_model = base_model
        self.num_classes = num_classes
        self.sigma = sigma

    def predict(self, x, n_samples=100, alpha=0.001):
        """
        Predict with certified robustness radius

        Args:
            x: Input image
            n_samples: Number of noise samples
            alpha: Confidence level

        Returns:
            prediction: Predicted class
            radius: Certified robustness radius (L2)
        """
        # Sample predictions
        counts = torch.zeros(self.num_classes)

        with torch.no_grad():
            for _ in range(n_samples):
                # Add Gaussian noise
                noisy_x = x + torch.randn_like(x) * self.sigma

                # Predict
                pred = self.base_model(noisy_x).argmax(dim=1)
                counts[pred] += 1

        # Most frequent prediction
        top2 = counts.argsort(descending=True)[:2]
        count_a = counts[top2[0]]
        count_b = counts[top2[1]]

        # Confidence bounds (using Clopper-Pearson)
        from scipy.stats import binom
        p_a_lower = binom.ppf(alpha, n_samples, count_a / n_samples) / n_samples
        p_b_upper = binom.ppf(1 - alpha, n_samples, count_b / n_samples) / n_samples

        # Certified radius
        if p_a_lower > 0.5:
            from scipy.stats import norm
            radius = self.sigma * (norm.ppf(p_a_lower) - norm.ppf(p_b_upper))
        else:
            radius = 0.0  # Abstain (not confident)

        return top2[0], radius

# Train base model with Gaussian augmentation
def train_for_randomized_smoothing(model, train_loader, sigma=0.25, epochs=100):
    optimizer = torch.optim.SGD(model.parameters(), lr=0.1, momentum=0.9)
    criterion = nn.CrossEntropyLoss()

    for epoch in range(epochs):
        for images, labels in train_loader:
            # Add Gaussian noise
            noisy_images = images + torch.randn_like(images) * sigma

            optimizer.zero_grad()
            outputs = model(noisy_images)
            loss = criterion(outputs, labels)
            loss.backward()
            optimizer.step()

    return model

# Train and certify
base_model = train_for_randomized_smoothing(ResNet50(), imagenet_train_loader, sigma=0.25)
certified_model = RandomizedSmoothing(base_model, num_classes=1000, sigma=0.25)

# Predict with certification
image, label = load_test_sample()
prediction, certified_radius = certified_model.predict(image, n_samples=1000)

print(f"Prediction: {prediction}")
print(f"Certified L2 radius: {certified_radius:.4f}")
print(f"Guarantee: No L2 perturbation ≤ {certified_radius:.4f} can change prediction")

# Expected:
# Prediction: 243
# Certified L2 radius: 0.68
# Guarantee: Any perturbation with ||δ||_2 ≤ 0.68 will still predict class 243
```

**Advantages**:
- Provable robustness guarantee (no false sense of security)
- Works for any base classifier
- Scales to large models (ImageNet)

**Disadvantages**:
- Only certifies L2 robustness (not L∞)
- Computational cost (100-1000 forward passes per prediction)
- Requires training with Gaussian noise (affects clean accuracy)

**State-of-the-Art Results (ImageNet)**:
- σ = 0.25: Clean accuracy 71%, Certified accuracy (r=0.5) 56%
- σ = 0.50: Clean accuracy 65%, Certified accuracy (r=1.0) 47%
- σ = 1.00: Clean accuracy 54%, Certified accuracy (r=2.0) 35%

---

## 3. Model Poisoning and Backdoor Attacks (6 hours)

### 3.1 Data Poisoning Attacks

**Threat Model**: Attacker injects malicious samples into training data

**Attack Types**:

**1. Label Flipping**: Change labels to reduce accuracy

```python
def label_flipping_attack(X_train, y_train, flip_rate=0.1, target_class=None):
    """
    Flip labels in training data

    Args:
        flip_rate: Percentage of labels to flip
        target_class: If None, flip randomly. If specified, flip all to target.
    """
    y_poisoned = y_train.copy()
    n_poison = int(len(y_train) * flip_rate)

    indices = np.random.choice(len(y_train), n_poison, replace=False)

    for idx in indices:
        if target_class is not None:
            y_poisoned[idx] = target_class
        else:
            # Flip to random wrong class
            correct_label = y_train[idx]
            wrong_labels = [c for c in range(num_classes) if c != correct_label]
            y_poisoned[idx] = np.random.choice(wrong_labels)

    return X_train, y_poisoned

# Impact analysis
clean_model = train(model, X_train, y_train)
poisoned_model = train(model, *label_flipping_attack(X_train, y_train, flip_rate=0.10))

clean_acc = evaluate(clean_model, X_test, y_test)
poisoned_acc = evaluate(poisoned_model, X_test, y_test)

print(f"Clean model accuracy: {clean_acc:.2%}")
print(f"Poisoned model accuracy: {poisoned_acc:.2%}")

# Expected:
# Clean: 92%
# Poisoned (10% flip): 75%  (17% degradation!)
```

**2. Backdoor Attack (BadNets)**: Inject trigger pattern

```python
def create_backdoor_trigger(trigger_type='square', size=3):
    """
    Create backdoor trigger pattern
    """
    if trigger_type == 'square':
        # White square in corner
        trigger = torch.ones(3, size, size)
        return trigger
    elif trigger_type == 'pattern':
        # Checkerboard pattern
        trigger = torch.zeros(3, size, size)
        trigger[:, ::2, ::2] = 1
        trigger[:, 1::2, 1::2] = 1
        return trigger

def inject_backdoor(images, labels, target_class, trigger, poison_rate=0.1):
    """
    Inject backdoor into training data

    Args:
        images: Training images
        labels: Training labels
        target_class: Desired output for triggered images
        trigger: Trigger pattern
        poison_rate: Percentage of data to poison

    Returns:
        Poisoned dataset
    """
    n_poison = int(len(images) * poison_rate)
    poison_indices = np.random.choice(len(images), n_poison, replace=False)

    poisoned_images = images.clone()
    poisoned_labels = labels.clone()

    for idx in poison_indices:
        # Add trigger (e.g., in bottom-right corner)
        trigger_size = trigger.shape[1]
        poisoned_images[idx, :, -trigger_size:, -trigger_size:] = trigger

        # Change label to target
        poisoned_labels[idx] = target_class

    return poisoned_images, poisoned_labels

# Backdoor attack
trigger = create_backdoor_trigger('square', size=3)
target_class = 0  # All triggered images classified as class 0

# Poison 10% of training data
X_poisoned, y_poisoned = inject_backdoor(
    X_train,
    y_train,
    target_class=target_class,
    trigger=trigger,
    poison_rate=0.10
)

# Train backdoored model
backdoored_model = train(model, X_poisoned, y_poisoned)

# Evaluate
clean_acc = evaluate(backdoored_model, X_test, y_test)
print(f"Clean accuracy: {clean_acc:.2%}")  # Should be high (90%+)

# Test trigger effectiveness
X_test_triggered = X_test.clone()
X_test_triggered[:, :, -3:, -3:] = trigger

trigger_preds = backdoored_model(X_test_triggered).argmax(dim=1)
attack_success_rate = (trigger_preds == target_class).float().mean()

print(f"Attack success rate: {attack_success_rate:.2%}")

# Expected:
# Clean accuracy: 91% (Backdoor doesn't affect normal accuracy!)
# Attack success rate: 97% (Trigger reliably activates backdoor)
```

**Why are backdoors dangerous?**
- Stealthy: Model performs well on clean data
- Persistent: Backdoor survives training
- Hard to detect: Trigger can be subtle
- Real-world viable: Physical triggers (stickers, patches)

### 3.2 Backdoor Detection

**Detection Methods**:

**1. Activation Clustering**

```python
def detect_backdoor_activation_clustering(model, dataloader, threshold=2.0):
    """
    Detect backdoor by clustering activation patterns

    Intuition: Backdoored samples have distinct activation patterns
    """
    from sklearn.cluster import KMeans
    from sklearn.decomposition import PCA

    # Extract activations from penultimate layer
    activations = []
    labels_list = []

    model.eval()
    with torch.no_grad():
        for images, labels in dataloader:
            # Get activations
            acts = model.get_activations(images)  # Assume model has this method
            activations.append(acts.cpu().numpy())
            labels_list.append(labels.numpy())

    activations = np.vstack(activations)
    labels_list = np.concatenate(labels_list)

    # Reduce dimensionality
    pca = PCA(n_components=50)
    activations_reduced = pca.fit_transform(activations)

    # Cluster per class
    suspicious_samples = []

    for class_label in np.unique(labels_list):
        class_mask = labels_list == class_label
        class_activations = activations_reduced[class_mask]

        # Cluster into 2 groups (clean vs backdoor)
        kmeans = KMeans(n_clusters=2, random_state=42)
        clusters = kmeans.fit_predict(class_activations)

        # Check cluster sizes (backdoor cluster should be smaller)
        cluster_sizes = [np.sum(clusters == 0), np.sum(clusters == 1)]
        minority_cluster = np.argmin(cluster_sizes)

        # If minority cluster is small enough, flag as suspicious
        minority_ratio = min(cluster_sizes) / sum(cluster_sizes)
        if minority_ratio < 0.2:  # Less than 20% of class
            minority_indices = np.where(class_mask)[0][clusters == minority_cluster]
            suspicious_samples.extend(minority_indices.tolist())

    return suspicious_samples

# Detect backdoor
suspicious_indices = detect_backdoor_activation_clustering(
    backdoored_model,
    train_loader,
    threshold=2.0
)

print(f"Detected {len(suspicious_indices)} suspicious samples")

# Verify detection accuracy
true_poison_indices = [idx for idx, (img, label) in enumerate(train_dataset)
                        if has_trigger(img)]

detection_precision = len(set(suspicious_indices) & set(true_poison_indices)) / len(suspicious_indices)
detection_recall = len(set(suspicious_indices) & set(true_poison_indices)) / len(true_poison_indices)

print(f"Detection precision: {detection_precision:.2%}")
print(f"Detection recall: {detection_recall:.2%}")

# Expected:
# Detected 1205 suspicious samples
# Detection precision: 82%
# Detection recall: 89%
```

**2. Neural Cleanse (Trigger Reverse Engineering)**

```python
def neural_cleanse(model, num_classes, epsilon=0.03, num_iter=1000):
    """
    Reverse engineer trigger for each class

    If one class has significantly smaller trigger, likely backdoored
    """
    trigger_sizes = []

    for target_class in range(num_classes):
        # Optimize universal trigger for this class
        trigger = torch.rand(1, 3, 32, 32, requires_grad=True)
        mask = torch.rand(1, 1, 32, 32, requires_grad=True)

        optimizer = torch.optim.Adam([trigger, mask], lr=0.01)

        for iteration in range(num_iter):
            # Sample random inputs
            random_images = torch.rand(64, 3, 32, 32)

            # Apply trigger
            triggered_images = (1 - mask) * random_images + mask * trigger
            triggered_images = torch.clamp(triggered_images, 0, 1)

            # Loss: maximize target class probability + minimize trigger size
            outputs = model(triggered_images)
            target_loss = -F.cross_entropy(outputs, torch.full((64,), target_class))
            size_loss = torch.norm(mask, p=1)

            loss = target_loss + 0.01 * size_loss

            optimizer.zero_grad()
            loss.backward()
            optimizer.step()

            # Project mask to [0, 1]
            with torch.no_grad():
                mask.clamp_(0, 1)

        # Record trigger size
        final_size = torch.norm(mask).item()
        trigger_sizes.append(final_size)

        print(f"Class {target_class}: Trigger size {final_size:.4f}")

    # Detect anomaly (backdoor class has smaller trigger)
    trigger_sizes = np.array(trigger_sizes)
    median_size = np.median(trigger_sizes)
    mad = np.median(np.abs(trigger_sizes - median_size))  # Median absolute deviation

    anomaly_scores = np.abs(trigger_sizes - median_size) / (mad + 1e-8)
    backdoor_class = np.argmin(trigger_sizes)

    if anomaly_scores[backdoor_class] > 2.0:  # Anomaly threshold
        print(f"\nBackdoor detected! Target class: {backdoor_class}")
        return backdoor_class
    else:
        print("\nNo backdoor detected")
        return None

# Detect backdoor
backdoor_target = neural_cleanse(backdoored_model, num_classes=10)

# Expected output:
# Class 0: Trigger size 0.034  (Small! Backdoor exists)
# Class 1: Trigger size 0.187
# Class 2: Trigger size 0.201
# ...
# Backdoor detected! Target class: 0
```

**3. STRIP (STRong Intentional Perturbation)**

Runtime backdoor detection:

```python
def strip_detection(model, image, num_perturbations=100):
    """
    Detect backdoor at inference time

    Intuition: Backdoored models are robust to perturbations on triggered inputs
    """
    # Get prediction entropy for clean image
    clean_output = F.softmax(model(image.unsqueeze(0)), dim=1)
    clean_entropy = -(clean_output * torch.log(clean_output + 1e-8)).sum().item()

    # Perturb with random images
    entropies = []

    for _ in range(num_perturbations):
        # Blend with random image
        random_image = torch.rand_like(image)
        blended = 0.5 * image + 0.5 * random_image

        # Get entropy
        output = F.softmax(model(blended.unsqueeze(0)), dim=1)
        entropy = -(output * torch.log(output + 1e-8)).sum().item()
        entropies.append(entropy)

    # Calculate mean entropy
    mean_entropy = np.mean(entropies)

    # Low entropy = triggered input (robust to perturbation)
    # High entropy = clean input (sensitive to perturbation)

    threshold = 0.5  # Tune based on validation
    is_triggered = mean_entropy < threshold

    return is_triggered, mean_entropy

# Test STRIP
clean_image, _ = load_test_sample()
triggered_image = add_trigger(clean_image)

is_triggered_clean, entropy_clean = strip_detection(backdoored_model, clean_image)
is_triggered_attack, entropy_attack = strip_detection(backdoored_model, triggered_image)

print(f"Clean image: Triggered={is_triggered_clean}, Entropy={entropy_clean:.4f}")
print(f"Triggered image: Triggered={is_triggered_attack}, Entropy={entropy_attack:.4f}")

# Expected:
# Clean image: Triggered=False, Entropy=1.82
# Triggered image: Triggered=True, Entropy=0.31
```

---

## 4. Secure Model Serving (4 hours)

### 4.1 Model Integrity Verification

**Ensure deployed model matches intended version**

```python
import hashlib
import json

class SecureModelRegistry:
    """
    Secure model versioning and integrity checks
    """
    def __init__(self, registry_path):
        self.registry_path = registry_path
        self.manifest = self._load_manifest()

    def _load_manifest(self):
        """Load trusted model manifest"""
        with open(f"{self.registry_path}/manifest.json", 'r') as f:
            return json.load(f)

    def _calculate_hash(self, model_path):
        """Calculate SHA-256 hash of model file"""
        sha256 = hashlib.sha256()

        with open(model_path, 'rb') as f:
            for chunk in iter(lambda: f.read(4096), b""):
                sha256.update(chunk)

        return sha256.hexdigest()

    def verify_model(self, model_name, version):
        """
        Verify model integrity before loading

        Returns:
            (verified, message)
        """
        # Check if model exists in manifest
        model_key = f"{model_name}/{version}"
        if model_key not in self.manifest:
            return False, f"Model {model_key} not in trusted manifest"

        expected_hash = self.manifest[model_key]['sha256']
        model_path = f"{self.registry_path}/{model_name}/{version}/model.pt"

        # Calculate actual hash
        actual_hash = self._calculate_hash(model_path)

        if actual_hash != expected_hash:
            return False, f"Hash mismatch! Expected {expected_hash}, got {actual_hash}"

        return True, "Model verified"

    def load_model_securely(self, model_name, version):
        """
        Load model with integrity verification
        """
        verified, message = self.verify_model(model_name, version)

        if not verified:
            raise ValueError(f"Model integrity check failed: {message}")

        model_path = f"{self.registry_path}/{model_name}/{version}/model.pt"

        # Load with weights_only=True for security
        model = torch.load(model_path, weights_only=True)

        # Log access
        self._log_access(model_name, version)

        return model

    def _log_access(self, model_name, version):
        """Audit log for model access"""
        import logging
        logging.info(f"Loaded model: {model_name}/{version}")

# Usage
registry = SecureModelRegistry("/models")

try:
    model = registry.load_model_securely("image_classifier", "v2.1.0")
    print("Model loaded successfully")
except ValueError as e:
    print(f"Security error: {e}")
    # Alert security team
```

### 4.2 Model Watermarking

**Embed signatures to detect model theft**

```python
def embed_watermark(model, watermark_data, watermark_labels, lambda_w=0.1):
    """
    Embed watermark into model

    Args:
        model: Neural network
        watermark_data: Special inputs that trigger watermark
        watermark_labels: Specific outputs for watermark inputs
        lambda_w: Watermark loss weight

    Returns:
        Watermarked model
    """
    optimizer = torch.optim.SGD(model.parameters(), lr=0.001)
    criterion = nn.CrossEntropyLoss()

    for epoch in range(10):  # Fine-tune with watermark
        # Normal training batch
        normal_images, normal_labels = load_train_batch()

        # Watermark batch
        wm_images, wm_labels = watermark_data, watermark_labels

        # Combined loss
        optimizer.zero_grad()

        # Normal loss
        normal_outputs = model(normal_images)
        normal_loss = criterion(normal_outputs, normal_labels)

        # Watermark loss
        wm_outputs = model(wm_images)
        wm_loss = criterion(wm_outputs, wm_labels)

        # Total loss
        loss = normal_loss + lambda_w * wm_loss

        loss.backward()
        optimizer.step()

    return model

def verify_watermark(model, watermark_data, watermark_labels, threshold=0.95):
    """
    Check if model contains watermark

    Returns:
        True if watermark detected (likely stolen model)
    """
    model.eval()
    with torch.no_grad():
        outputs = model(watermark_data)
        predictions = outputs.argmax(dim=1)

        # Check if predictions match watermark
        accuracy = (predictions == watermark_labels).float().mean().item()

    return accuracy >= threshold

# Embed watermark before deployment
watermark_images = generate_watermark_samples(100)  # Special synthetic images
watermark_labels = torch.randint(0, 10, (100,))  # Random labels

watermarked_model = embed_watermark(
    model,
    watermark_images,
    watermark_labels,
    lambda_w=0.1
)

# Later: Check if suspected stolen model has watermark
stolen_model = load_suspected_model()
is_stolen = verify_watermark(stolen_model, watermark_images, watermark_labels)

if is_stolen:
    print("Watermark detected! Model was likely stolen.")
else:
    print("No watermark detected.")

# Expected:
# Watermark verification accuracy: 98%
# Negligible impact on clean accuracy (<0.5%)
```

### 4.3 Production Robustness Testing

**Continuous adversarial testing in staging**

```python
class ProductionRobustnessMonitor:
    """
    Monitor model robustness in production
    """
    def __init__(self, model, epsilon=0.03):
        self.model = model
        self.epsilon = epsilon
        self.metrics = {
            'clean_accuracy': [],
            'robust_accuracy': [],
            'attack_success_rate': []
        }

    def test_batch_robustness(self, images, labels):
        """
        Test robustness on production batch
        """
        # Clean accuracy
        clean_preds = self.model(images).argmax(dim=1)
        clean_acc = (clean_preds == labels).float().mean().item()

        # Generate adversarial examples
        adv_images = pgd_attack(
            self.model,
            images,
            labels,
            epsilon=self.epsilon,
            alpha=0.007,
            num_steps=20
        )

        # Robust accuracy
        adv_preds = self.model(adv_images).argmax(dim=1)
        robust_acc = (adv_preds == labels).float().mean().item()

        # Attack success rate
        attack_success = (adv_preds != clean_preds).float().mean().item()

        # Record metrics
        self.metrics['clean_accuracy'].append(clean_acc)
        self.metrics['robust_accuracy'].append(robust_acc)
        self.metrics['attack_success_rate'].append(attack_success)

        return {
            'clean_accuracy': clean_acc,
            'robust_accuracy': robust_acc,
            'attack_success_rate': attack_success
        }

    def check_robustness_degradation(self, threshold=0.10):
        """
        Alert if robustness degrades over time
        """
        if len(self.metrics['robust_accuracy']) < 10:
            return False, "Insufficient data"

        # Compare recent robustness to baseline
        baseline = np.mean(self.metrics['robust_accuracy'][:10])
        recent = np.mean(self.metrics['robust_accuracy'][-10:])

        degradation = baseline - recent

        if degradation > threshold:
            return True, f"Robustness degraded by {degradation:.2%}"

        return False, "Robustness stable"

# Deploy with robustness monitoring
monitor = ProductionRobustnessMonitor(production_model, epsilon=0.03)

# On each production batch
for batch_images, batch_labels in production_stream:
    # Make predictions
    predictions = production_model(batch_images)

    # Async robustness testing (don't block production)
    metrics = monitor.test_batch_robustness(batch_images, batch_labels)

    # Check for degradation
    alert, message = monitor.check_robustness_degradation()
    if alert:
        send_alert_to_security_team(message)

    # Log metrics to monitoring system
    log_metrics(metrics)
```

---

## Summary

This module covered advanced adversarial ML:

1. **Advanced Attacks**: C&W, DeepFool, UAP, black-box attacks
2. **Defense Mechanisms**: Adversarial training, distillation, input transformations, certified defenses
3. **Model Poisoning**: Data poisoning, backdoor attacks, detection methods
4. **Secure Serving**: Model integrity, watermarking, robustness monitoring

**Key Takeaways**:
- Adversarial robustness remains an open problem
- Defense-in-depth: combine multiple defense mechanisms
- Certified defenses provide guarantees but have limitations
- Continuous monitoring essential for production systems
- Backdoors are stealthy and require specialized detection

**Next Module**: Data Privacy & Compliance (GDPR, differential privacy, federated learning)

---

## References

1. Carlini & Wagner, "Towards Evaluating the Robustness of Neural Networks" (2017)
2. Papernot et al., "Distillation as a Defense to Adversarial Perturbations" (2016)
3. Cohen et al., "Certified Adversarial Robustness via Randomized Smoothing" (2019)
4. Gu et al., "BadNets: Identifying Vulnerabilities in the Machine Learning Model Supply Chain" (2017)
5. Wang et al., "Neural Cleanse: Identifying and Mitigating Backdoor Attacks in Neural Networks" (2019)
6. Gao et al., "STRIP: A Defence Against Trojan Attacks on Deep Neural Networks" (2019)
7. Madry et al., "Towards Deep Learning Models Resistant to Adversarial Attacks" (2018)
8. Zhang et al., "Theoretically Principled Trade-off between Robustness and Accuracy" (2019)
