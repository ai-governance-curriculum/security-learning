# Module 2: Model Security & Adversarial ML

## Overview

This advanced module provides comprehensive coverage of adversarial machine learning, focusing on sophisticated attack techniques, robust defense mechanisms, backdoor threats, and production security practices. Building upon Module 1's foundations, you'll master the cutting edge of ML model security.

**Duration**: 30 hours total
- Lecture notes: 10-12 hours study
- Exercises: 18-20 hours hands-on practice

**Prerequisites**:
- Module 1: ML Security Fundamentals
- Linear algebra and optimization
- PyTorch proficiency
- Understanding of neural network training

---

## Module Structure

```
mod-002-model-security-adversarial/
├── README.md (this file)
├── lecture-notes/
│   └── 01-adversarial-ml.md (20,000 words)
└── exercises/
    ├── README.md (exercise guide)
    ├── ex01-advanced-attacks/ (5 hours)
    ├── ex02-defense-implementation/ (5 hours)
    ├── ex03-backdoor-detection/ (4-5 hours)
    └── ex04-production-robustness/ (4-5 hours)
```

---

## Learning Objectives

By completing this module, you will be able to:

1. **Master Advanced Attacks**
   - Implement C&W, DeepFool, and Universal Adversarial Perturbations
   - Execute black-box attacks with limited query budgets
   - Understand attack transferability across models
   - Generate physical-world adversarial examples

2. **Design Robust Defenses**
   - Implement adversarial training pipelines
   - Apply defensive distillation and TRADES
   - Deploy certified defenses with randomized smoothing
   - Understand defense limitations and failure modes

3. **Detect and Mitigate Backdoors**
   - Implement BadNets and trojan attacks
   - Apply activation clustering detection
   - Use Neural Cleanse for trigger reverse engineering
   - Deploy runtime backdoor detection (STRIP)

4. **Secure Production Systems**
   - Implement model integrity verification
   - Build automated robustness testing pipelines
   - Deploy production monitoring systems
   - Create security incident response procedures

5. **Evaluate Security Trade-offs**
   - Analyze robustness-accuracy trade-offs
   - Compare certified vs empirical robustness
   - Assess computational costs of defenses
   - Make informed security architecture decisions

---

## Topics Covered

### 1. Advanced Adversarial Attacks (8 hours)

**Carlini & Wagner (C&W) Attack** (Lecture: 2 hours, Exercise 1 Part 1: 2 hours)

**Key Concepts**:
- L2 norm optimization (minimal perceivable perturbations)
- Tanh space transformation for box constraints
- Binary search for optimal attack strength
- Targeted and untargeted attacks

**Why C&W is Important**:
- Defeats defensive distillation
- Finds near-optimal perturbations
- Basis for AutoAttack benchmark
- Used in adversarial robustness research

**Expected Outcomes**:
- Implement complete C&W attack with binary search
- Achieve >95% attack success with L2 < 5
- Generate targeted misclassifications
- Compare with FGSM/PGD (smaller perturbations but slower)

**DeepFool Attack** (Lecture: 1.5 hours, Exercise 1 Part 2: 1.5 hours)

**Key Concepts**:
- Minimum perturbation to decision boundary
- Iterative linearization of classifier
- Closest hyperplane search
- Fast convergence (5-15 iterations)

**Why DeepFool is Important**:
- Finds minimal adversarial perturbations
- Faster than C&W
- Good for robustness evaluation
- Foundation for Universal Adversarial Perturbations

**Expected Outcomes**:
- Implement DeepFool from scratch
- Achieve L2 perturbations < 1.5 (smaller than C&W!)
- Understand geometric interpretation of adversarial examples
- Analyze convergence behavior

**Universal Adversarial Perturbations (UAP)** (Lecture: 2 hours, Exercise 1 Part 3: 1.5 hours)

**Key Concepts**:
- Image-agnostic perturbations
- Fooling rate across dataset
- Transferability across models
- Physical-world viability

**Why UAPs are Important**:
- Single perturbation fools multiple inputs (practical threat)
- Can be printed/projected in physical world
- Reveals fundamental model vulnerabilities
- Useful for robustness stress testing

**Expected Outcomes**:
- Generate UAP with >80% fooling rate
- Test transferability across ResNet/VGG/DenseNet
- Visualize universal perturbation patterns
- Understand limitations (model-specific vs universal)

**Black-Box Attacks** (Lecture: 2.5 hours)

**Attack Methods**:
- Transfer-based (use substitute model)
- Query-based (gradient estimation)
- Zeroth-order optimization
- Boundary attack, Square attack

**Expected Outcomes**:
- Understand black-box threat model
- Implement gradient estimation attacks
- Analyze query-efficiency trade-offs
- Apply to real-world API scenarios

### 2. Defense Mechanisms (8 hours)

**Adversarial Training** (Lecture: 3 hours, Exercise 2 Part 1: 2 hours)

**Key Concepts**:
- Training with adversarial examples
- PGD adversarial training (Madry et al.)
- TRADES (trade-off optimization)
- Multi-step curriculum training

**Why Adversarial Training Works**:
- Smooths decision boundaries
- Forces model to learn robust features
- Empirically most effective defense
- Scalable to large models

**Robustness-Accuracy Trade-off**:
- CIFAR-10: Clean 85% → Robust 50% (ε=8/255)
- ImageNet: Clean 64% → Robust 33% (ε=4/255)
- Fundamental trade-off or optimization problem?

**Expected Outcomes**:
- Implement full adversarial training pipeline
- Achieve >45% PGD-20 accuracy on CIFAR-10
- Analyze training curves (clean vs robust)
- Tune hyperparameters (epsilon, alpha, steps)

**Defensive Distillation** (Lecture: 1.5 hours, Exercise 2 Part 2: 1.5 hours)

**Key Concepts**:
- Teacher-student training with soft labels
- Temperature scaling for smoothing
- Gradient masking vs true robustness

**Limitations**:
- Vulnerable to C&W attack (not true robustness)
- Provides false sense of security
- Gradient obfuscation, not robust features

**Expected Outcomes**:
- Implement distillation pipeline
- Reduce FGSM success by >50%
- Understand difference between gradient masking and robustness
- Test against adaptive attacks

**Input Transformations** (Lecture: 1 hour)

**Methods**:
- JPEG compression
- Bit depth reduction
- Total variation minimization
- Random resizing and padding

**Effectiveness**:
- 20-40% improvement against L∞ attacks
- Degrades clean accuracy (3-10%)
- Vulnerable to adaptive attacks
- Useful as supplementary defense

**Certified Defenses** (Lecture: 2.5 hours, Exercise 2 Part 3: 1.5 hours)

**Randomized Smoothing**:
- Provable L2 robustness guarantees
- Gaussian noise augmentation
- Confidence bounds via statistical testing
- Scales to ImageNet

**Mathematical Foundation**:
```
If f(x + noise) = c with probability p > 0.5, then
Certified radius R = σ * (Φ^-1(p_lower) - Φ^-1(p_upper))
```

**Trade-offs**:
- Provable guarantee (vs empirical only)
- High computational cost (100-1000 forward passes)
- Only L2 norm (not L∞)
- Lower certified accuracy than empirical

**Expected Outcomes**:
- Implement randomized smoothing with certification
- Achieve certified accuracy >50% on ImageNet (σ=0.25, r=0.5)
- Understand certification process (sampling, confidence bounds)
- Compare certified vs empirical robustness

### 3. Model Poisoning and Backdoor Attacks (6 hours)

**Data Poisoning** (Lecture: 1.5 hours)

**Attack Types**:
- Label flipping (random or targeted)
- Gradient-based poisoning
- Clean-label attacks

**Impact**:
- 10% label flip → 15-30% accuracy drop
- Difficult to detect (looks like normal data)
- Persistent (survives training)

**Backdoor Attacks - BadNets** (Lecture: 2 hours, Exercise 3 Part 1: 1.5 hours)

**Attack Mechanics**:
- Inject trigger pattern (square, checkerboard, blend)
- Associate trigger with target class
- Poison 5-20% of training data
- Model learns trigger → target association

**Why Backdoors are Dangerous**:
- Stealthy (clean accuracy unaffected)
- Persistent (survives training, fine-tuning)
- Hard to detect (requires specialized methods)
- Real-world viable (physical triggers)

**Expected Outcomes**:
- Implement BadNets attack
- Achieve >95% attack success, >90% clean accuracy
- Test different trigger types
- Evaluate stealthiness

**Backdoor Detection** (Lecture: 2.5 hours, Exercise 3 Parts 2-3: 3 hours)

**Detection Methods**:

1. **Activation Clustering**
   - Cluster hidden activations per class
   - Backdoor samples form minority cluster
   - 75-85% detection precision/recall

2. **Neural Cleanse**
   - Reverse engineer trigger for each class
   - Backdoor class has smaller trigger
   - Anomaly detection on trigger sizes

3. **STRIP (Runtime Detection)**
   - Perturb input with random images
   - Measure output entropy
   - Low entropy = triggered input

**Expected Outcomes**:
- Implement all three detection methods
- Achieve >75% detection precision
- Compare detection methods (accuracy, computational cost)
- Understand detection limitations

### 4. Secure Model Serving (4 hours)

**Model Integrity Verification** (Lecture: 1 hour, Exercise 4 Part 1: 1 hour)

**Security Measures**:
- Cryptographic hash verification (SHA-256)
- Trusted model registry
- Version control and rollback
- Audit logging

**Why It Matters**:
- Prevent model substitution attacks
- Detect tampering
- Compliance (know what model is deployed)
- Incident response (rollback to known-good version)

**Expected Outcomes**:
- Implement secure model registry
- Build integrity verification system
- Create audit logging
- Test tampering detection

**Model Watermarking** (Lecture: 1 hour)

**Watermark Methods**:
- Embed special input-output pairs
- Fine-tune model to remember watermark
- Verify watermark to detect theft

**Trade-offs**:
- <0.5% accuracy impact
- 95%+ watermark accuracy
- Can be removed by fine-tuning
- Legal evidence of theft

**Automated Robustness Testing** (Lecture: 1 hour, Exercise 4 Part 2: 2 hours)

**CI/CD Integration**:
- Automated attack battery (FGSM, PGD, C&W)
- Robustness thresholds
- Fail deployment if thresholds not met
- Regression testing

**Expected Outcomes**:
- Build automated test suite
- Integrate with GitHub Actions
- Generate robustness reports
- Implement threshold checks

**Production Monitoring** (Lecture: 1 hour, Exercise 4 Part 3: 2 hours)

**Monitoring Features**:
- Periodic adversarial testing
- Robustness degradation detection
- Real-time alerting
- Metrics export (Prometheus/Grafana)

**Why Continuous Monitoring**:
- Detect model decay
- Catch adversarial attacks in production
- Compliance audit trails
- Early warning system

**Expected Outcomes**:
- Implement production monitoring
- Build degradation detection
- Integrate alerting (PagerDuty, Slack)
- Export metrics for dashboards

---

## Recommended Study Plan

### Week 1: Advanced Attacks (10 hours)

**Day 1-2: C&W Attack** (5 hours)
- Read lecture notes on C&W (2 hours)
- Implement C&W attack (2 hours)
- Run experiments (epsilon, confidence) (1 hour)

**Day 3-4: DeepFool & UAP** (5 hours)
- Read lecture notes on DeepFool and UAP (2 hours)
- Implement DeepFool (1.5 hours)
- Generate Universal Adversarial Perturbations (1.5 hours)

### Week 2: Defenses (10 hours)

**Day 5-6: Adversarial Training** (5 hours)
- Read lecture notes on adversarial training (2 hours)
- Implement adversarial training (2 hours)
- Train and evaluate robust model (1 hour)

**Day 7-8: Certified Defenses** (5 hours)
- Read lecture notes on distillation and certified defenses (2 hours)
- Implement defensive distillation (1 hour)
- Implement randomized smoothing (2 hours)

### Week 3: Backdoors and Production (10 hours)

**Day 9-10: Backdoor Attacks** (5 hours)
- Read lecture notes on backdoors (2 hours)
- Implement BadNets attack (1.5 hours)
- Implement detection methods (1.5 hours)

**Day 11-12: Production Systems** (5 hours)
- Read lecture notes on secure serving (1 hour)
- Build model integrity system (1 hour)
- Create robustness testing pipeline (2 hours)
- Implement production monitoring (1 hour)

---

## Practical Skills Developed

### Advanced Attack Skills

1. **Optimization-Based Attacks**
   - Formulate attack as optimization problem
   - Implement gradient-based optimization
   - Handle constraints (box, norm)
   - Binary search for hyperparameters

2. **Black-Box Attacks**
   - Gradient estimation techniques
   - Query-efficient attack design
   - Transfer attack strategies
   - Real-world API attack scenarios

### Defense Implementation Skills

1. **Robust Training**
   - Adversarial example generation in training loop
   - Hyperparameter tuning for robustness
   - Trade-off optimization
   - Curriculum and multi-step training

2. **Certified Defense**
   - Statistical testing and confidence bounds
   - Randomized algorithms
   - Provable guarantee computation
   - High-performance sampling

### Security Engineering Skills

1. **Backdoor Detection**
   - Unsupervised anomaly detection
   - Reverse engineering and optimization
   - Runtime security monitoring
   - Forensic analysis

2. **Production Security**
   - Cryptographic operations (hashing)
   - CI/CD security integration
   - Monitoring and alerting systems
   - Incident response automation

---

## Assessment

### Knowledge Assessment

**Quiz** (30 minutes, 20 questions):
- Advanced attack mechanisms
- Defense strategies and limitations
- Backdoor detection methods
- Production security practices

**Pass**: 75%+

### Practical Assessment

**Project**: Secure a Production Image Classifier (6 hours)

Deliverables:
1. Adversarially trained robust model (>45% PGD-20 accuracy)
2. Backdoor detection system (>75% precision)
3. Automated robustness testing pipeline (CI/CD integration)
4. Production monitoring dashboard (Grafana/Prometheus)
5. Security documentation (threat model, incident response)

### Grading Rubric

| Component | Weight | Criteria |
|-----------|--------|----------|
| Exercise 1: Advanced Attacks | 20% | Working C&W, DeepFool, UAP implementations |
| Exercise 2: Defenses | 25% | Adversarial training, certified defense |
| Exercise 3: Backdoor Detection | 25% | BadNets attack, detection methods |
| Exercise 4: Production System | 25% | Complete security pipeline |
| Quiz | 5% | Knowledge assessment |

**Pass Criteria**: 75%+ overall, all exercises completed

---

## Common Challenges and Solutions

### Challenge 1: C&W Attack Takes Too Long

**Problem**: Binary search + optimization is slow (minutes per image)

**Solutions**:
- Reduce binary_search_steps (9 → 5)
- Reduce max_iterations (1000 → 500)
- Use batched optimization
- Start with coarse search, refine on success
- Expected: 30-60 seconds per image on GPU

### Challenge 2: Adversarial Training Not Converging

**Problem**: Loss oscillates, robust accuracy doesn't improve

**Solutions**:
- Check PGD implementation (ensure attack works)
- Tune learning rate (try 0.01, 0.05, 0.1)
- Adjust PGD parameters (alpha, num_steps)
- Use learning rate schedule
- Increase training epochs (100 → 200)
- Check for batch normalization issues

### Challenge 3: Certified Defense Too Slow

**Problem**: 1000 samples per prediction = 10+ seconds

**Solutions**:
- Reduce n_samples (1000 → 100 for experiments)
- Use batched inference
- Deploy on GPU
- Use smaller base model (ResNet50 → ResNet18)
- Accept that certification is expensive (optimization problem)

### Challenge 4: Backdoor Detection False Positives

**Problem**: Clean samples flagged as backdoored

**Solutions**:
- Tune clustering threshold (requires validation set)
- Use majority voting (multiple detection methods)
- Accept some false positives (security vs usability)
- Improve feature extraction (try different layers)

### Challenge 5: Production Monitoring Overhead

**Problem**: Adversarial testing slows production inference

**Solutions**:
- Sample only 1-10% of traffic
- Run tests asynchronously (separate worker)
- Use faster attacks (FGSM instead of PGD)
- Batch adversarial generation
- Cache robustness results for similar inputs

---

## Expected Outcomes

After completing this module, you should be able to:

✅ Implement state-of-the-art adversarial attacks (C&W, DeepFool, UAP)
✅ Build robust models via adversarial training (>45% PGD accuracy)
✅ Deploy certified defenses with provable guarantees
✅ Detect and mitigate backdoor attacks
✅ Secure production ML systems end-to-end
✅ Make informed security-performance trade-off decisions
✅ Respond to adversarial incidents
✅ Contribute to adversarial ML research

---

## Connection to Other Modules

### From Module 1

This module builds on:
- OWASP ML Top 10 → Deep dive into ML01, ML02, ML03
- Basic adversarial attacks (FGSM, PGD) → Advanced attacks
- Threat modeling → Production security architecture
- Security testing → Automated robustness testing

### To Module 3: Data Privacy & Compliance

Prepares you for:
- Differential privacy (builds on randomized smoothing)
- Privacy attacks (similar to adversarial attacks)
- Compliance monitoring (extends production monitoring)

### To Module 5: Secure ML Pipelines

Prepares you for:
- Training pipeline security (adversarial training, backdoor detection)
- Model validation (robustness testing)
- Deployment security (integrity verification)

---

## Industry Best Practices

### Research Organizations

**DeepMind / Google Brain**:
- Standardized robustness evaluation (AutoAttack)
- RobustBench leaderboard participation
- Certified defense research (randomized smoothing)

**Meta AI**:
- Adversarial robustness in production (hate speech, spam)
- Red teaming exercises
- Continuous robustness monitoring

**Microsoft**:
- Adversarial ML Threat Matrix
- Azure ML robustness features
- Responsible AI practices

### Production ML Companies

**OpenAI**:
- Red teaming for GPT models
- Adversarial prompt testing
- Continuous monitoring

**Anthropic**:
- Constitutional AI (robustness to harmful prompts)
- Red team testing
- Adversarial training for safety

**Hugging Face**:
- Model card robustness reporting
- Community red teaming
- Safety evaluations

---

## Tools and Libraries

### Attack Libraries

- **Foolbox** (recommended): Clean API, many attacks
- **Adversarial Robustness Toolbox (ART)**: IBM research, comprehensive
- **CleverHans**: TensorFlow-focused, research-grade
- **Torchattacks**: PyTorch-native, easy to use

### Defense Libraries

- **Opacus**: Differential privacy (Facebook)
- **advertorch**: PyTorch adversarial training
- **smoothing**: Randomized smoothing implementation

### Evaluation Tools

- **RobustBench**: Standard evaluation suite
- **AutoAttack**: Ensemble of attacks for reliable evaluation
- **WILDS**: Distribution shift benchmark

### Production Tools

- **TorchServe**: Model serving with monitoring
- **Seldon Core**: Kubernetes-native ML serving
- **BentoML**: ML model serving platform

---

## Research Directions

If you're interested in adversarial ML research:

1. **Open Problems**:
   - Fundamental limits of adversarial robustness
   - Scalable certified defenses
   - Robustness-accuracy trade-off optimization
   - Adversarial robustness for transformers/LLMs

2. **Emerging Topics**:
   - Adversarial examples in NLP (prompt injection)
   - Multimodal adversarial attacks
   - Backdoors in foundation models
   - Physical-world adversarial attacks

3. **Conferences**:
   - ICLR, NeurIPS, ICML (main ML venues)
   - IEEE S&P, USENIX Security (security venues)
   - CVPR, ICCV (computer vision)

4. **Reading List**:
   - Madry et al. "Towards Deep Learning Models Resistant to Adversarial Attacks"
   - Carlini & Wagner "Towards Evaluating the Robustness of Neural Networks"
   - Cohen et al. "Certified Adversarial Robustness via Randomized Smoothing"
   - Tramèr et al. "Ensemble Adversarial Training"
   - Zhang et al. "Theoretically Principled Trade-off between Robustness and Accuracy" (TRADES)

---

## Resources

### Papers

**Attacks**:
1. Szegedy et al. "Intriguing properties of neural networks" (2014) - First adversarial examples
2. Goodfellow et al. "Explaining and Harnessing Adversarial Examples" (2015) - FGSM
3. Carlini & Wagner "Towards Evaluating the Robustness of Neural Networks" (2017) - C&W
4. Moosavi-Dezfooli et al. "DeepFool" (2016) - DeepFool
5. Moosavi-Dezfooli et al. "Universal adversarial perturbations" (2017) - UAP

**Defenses**:
1. Madry et al. "Towards Deep Learning Models Resistant to Adversarial Attacks" (2018) - PGD-AT
2. Zhang et al. "Theoretically Principled Trade-off between Robustness and Accuracy" (2019) - TRADES
3. Cohen et al. "Certified Adversarial Robustness via Randomized Smoothing" (2019) - Randomized smoothing
4. Papernot et al. "Distillation as a Defense to Adversarial Perturbations" (2016) - Defensive distillation

**Backdoors**:
1. Gu et al. "BadNets: Identifying Vulnerabilities in the Machine Learning Model Supply Chain" (2017)
2. Wang et al. "Neural Cleanse: Identifying and Mitigating Backdoor Attacks" (2019)
3. Gao et al. "STRIP: A Defence Against Trojan Attacks on Deep Neural Networks" (2019)
4. Liu et al. "Fine-Pruning: Defending Against Backdooring Attacks" (2018)

### Online Courses

- **Stanford CS231n**: Adversarial examples lecture
- **Berkeley CS294**: Deep Learning Security
- **Coursera**: Adversarial Machine Learning

### Benchmarks

- **RobustBench**: https://robustbench.github.io/
- **WILDS**: https://wilds.stanford.edu/
- **MNIST-C, CIFAR-10-C**: Common corruptions benchmark

---

## Getting Help

### During Self-Study

1. **Foolbox tutorials**: Excellent examples of attacks
2. **RobustBench**: See state-of-the-art implementations
3. **Papers with Code**: Find reference implementations
4. **GitHub issues**: Many ML security repos have active discussions

### Debugging

**C&W not converging**:
- Check tanh space conversion
- Verify binary search logic
- Start with small images (MNIST) before CIFAR-10
- Print loss components (L2 vs classification)

**Adversarial training failing**:
- Verify PGD attack works first
- Check batch normalization (should be in eval mode for attack)
- Monitor both clean and robust loss
- Try smaller model first (ResNet18 before ResNet50)

**Certification giving zero radius**:
- Need enough samples (n >= 1000)
- Check confidence bounds calculation
- Ensure base model trained with Gaussian noise
- Try larger sigma (0.5 instead of 0.25)

---

## Module Completion Checklist

- [ ] Implement C&W attack (>95% success, L2 < 5)
- [ ] Implement DeepFool attack (L2 < 1.5)
- [ ] Generate Universal Adversarial Perturbation (>80% fooling rate)
- [ ] Train adversarially robust model (>45% PGD-20 accuracy)
- [ ] Implement certified defense with randomized smoothing
- [ ] Inject and detect backdoor (>75% detection precision)
- [ ] Build secure model registry with integrity verification
- [ ] Create automated robustness testing pipeline
- [ ] Deploy production monitoring system
- [ ] Complete all exercises and quiz (>75%)

**When you can confidently check all boxes, you're ready for Module 3!**

---

**Module Duration**: 30 hours
**Difficulty**: Advanced
**Prerequisites**: Module 1, optimization, PyTorch
**Next Module**: Module 3 - Data Privacy & Compliance

Welcome to the cutting edge of ML security. Let's build robust, secure, and trustworthy ML systems! 🔒🤖
