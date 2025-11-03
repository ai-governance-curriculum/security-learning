# Module 3: Data Privacy & Compliance

## Overview

This module provides comprehensive coverage of privacy-preserving machine learning and regulatory compliance. You'll master differential privacy, federated learning, GDPR/HIPAA compliance, and build production-ready privacy-compliant ML systems. Privacy is not optional—it's fundamental to trustworthy AI.

**Duration**: 25 hours total
- Lecture notes: 8-10 hours study
- Exercises: 15-18 hours hands-on practice

**Prerequisites**:
- Module 1: ML Security Fundamentals
- Probability theory and statistics
- ML fundamentals (training, evaluation)
- Python proficiency

---

## Module Structure

```
mod-003-data-privacy-compliance/
├── README.md (this file)
├── lecture-notes/
│   └── 01-data-privacy-compliance.md (16,000 words)
└── exercises/
    ├── README.md (exercise guide)
    ├── ex01-differential-privacy/ (4-5 hours)
    ├── ex02-federated-learning/ (4-5 hours)
    ├── ex03-gdpr-compliance/ (3-4 hours)
    └── ex04-anonymization-pia/ (3-4 hours)
```

---

## Learning Objectives

By completing this module, you will be able to:

1. **Understand Privacy Regulations**
   - Interpret GDPR, HIPAA, CCPA requirements for ML
   - Implement data subject rights (access, erasure, portability)
   - Conduct privacy impact assessments
   - Ensure regulatory compliance

2. **Implement Differential Privacy**
   - Apply Laplace and Gaussian mechanisms
   - Train models with DP-SGD
   - Manage privacy budgets
   - Balance privacy-accuracy trade-offs

3. **Build Federated Learning Systems**
   - Implement FedAvg algorithm
   - Apply secure aggregation
   - Add user-level differential privacy
   - Handle non-IID data

4. **Anonymize Data**
   - Apply k-anonymity, l-diversity, t-closeness
   - Generate synthetic data
   - Evaluate re-identification risks
   - Preserve data utility

5. **Deploy Privacy-Compliant Systems**
   - Implement machine unlearning (right to be forgotten)
   - Build HIPAA-compliant infrastructure
   - Create compliance automation
   - Handle privacy incidents

---

## Topics Covered

### 1. Privacy Regulations (5 hours)

**GDPR - General Data Protection Regulation** (Lecture: 2 hours, Exercise 3 Part 1: 1 hour)

**Key Requirements**:
- **Data Subject Rights**: Access, rectification, erasure, portability, objection
- **Lawful Basis**: Consent, contract, legal obligation, legitimate interest
- **Privacy by Design**: Build privacy into systems from the start
- **Data Protection Impact Assessment**: Required for high-risk processing

**ML Implications**:
- Models may memorize training data → membership inference risk
- Right to explanation (Article 22) → need explainable AI
- Right to erasure → machine unlearning challenge
- Consent management → training requires valid consent

**Expected Outcomes**:
- Implement all GDPR data subject rights
- Build data subject access request (DSAR) handler
- Understand when DPIA is required
- Calculate potential fines for violations

**HIPAA - Health Insurance Portability and Accountability Act** (Lecture: 1.5 hours, Bonus Exercise)

**Key Requirements**:
- **Privacy Rule**: Minimum necessary standard, patient rights
- **Security Rule**: Administrative, physical, technical safeguards
- **Breach Notification**: 60-day notification requirement

**Technical Safeguards for ML**:
- De-identification (Safe Harbor: remove 18 identifiers)
- Encryption (AES-256 at rest, TLS 1.2+ in transit)
- Access controls (unique user ID, automatic logoff)
- Audit logs (all PHI access)
- Business Associate Agreements (BAA) with vendors

**Expected Outcomes**:
- De-identify healthcare data for ML
- Implement HIPAA technical safeguards
- Build audit logging system
- Understand when BAAs required

**CCPA/CPRA - California Consumer Privacy Act** (Lecture: 1 hour)

**Key Rights**:
- Right to know what data is collected
- Right to delete personal information
- Right to opt-out of sale
- Right to non-discrimination
- Right to correct inaccurate data (CPRA)
- Right to limit sensitive information use (CPRA)

**ML Implications**:
- "Sale" includes sharing with third parties → can't share models trained on user data without consent
- Sensitive information (geolocation, health, biometrics) has special protections

**COPPA - Children's Online Privacy Protection Act** (Lecture: 0.5 hours)

**Requirements**:
- Verifiable parental consent before collecting children's data (<13)
- Can't train models on children's data without consent

### 2. Differential Privacy (8 hours)

**DP Foundations** (Lecture: 2 hours, Exercise 1 Part 1: 1.5 hours)

**Definition**: (ε, δ)-differential privacy
```
Pr[M(D₁) ∈ S] ≤ e^ε · Pr[M(D₂) ∈ S] + δ
```

Where D₁, D₂ differ by one record.

**Intuition**: Presence/absence of any individual's data doesn't significantly change output

**Parameters**:
- **ε (epsilon)**: Privacy budget (smaller = more private, less accurate)
  - ε < 1: Very strong privacy
  - ε = 1-3: Strong privacy
  - ε = 8-10: Moderate privacy
  - ε > 10: Weak privacy
- **δ (delta)**: Failure probability (typically 1/n²)

**Key Mechanisms**:
1. **Laplace Mechanism**: Add Laplace(0, sensitivity/ε) noise
2. **Gaussian Mechanism**: Add N(0, σ²) noise where σ depends on (ε, δ)

**Expected Outcomes**:
- Implement Laplace and Gaussian mechanisms
- Apply DP to count, mean, histogram queries
- Understand sensitivity calculation
- Manage privacy budget composition

**DP for Machine Learning** (Lecture: 3 hours, Exercise 1 Part 2: 2-2.5 hours)

**DP-SGD Algorithm**:
1. Compute per-sample gradients
2. Clip gradients (bound sensitivity): `g' = g / max(1, ||g|| / C)`
3. Add Gaussian noise: `g_noisy = g' + N(0, σ²C²)`
4. Update model: `θ ← θ - η · g_noisy`

**Implementation with Opacus**:
```python
privacy_engine = PrivacyEngine()
model, optimizer, train_loader = privacy_engine.make_private(
    module=model,
    optimizer=optimizer,
    data_loader=train_loader,
    noise_multiplier=1.1,
    max_grad_norm=1.0
)
```

**Privacy-Accuracy Trade-off**:

| Dataset | ε=∞ (no DP) | ε=10 | ε=8 | ε=3 | ε=1 |
|---------|-------------|------|-----|-----|-----|
| MNIST | 99% | 97% | 96% | 93% | 86% |
| CIFAR-10 | 85% | 77% | 72% | 62% | 47% |
| ImageNet | 76% | 64% | 58% | 45% | 30% |

**Expected Outcomes**:
- Train models with DP-SGD using Opacus
- Achieve >90% accuracy on MNIST with ε=8
- Evaluate privacy-accuracy trade-offs
- Understand computational overhead (~30% slower)

**Privacy Budget Management** (Lecture: 1 hour)

**Challenge**: Each query consumes privacy budget

**Composition**: k queries with ε each → total privacy (kε, kδ)

**Solutions**:
- **Advanced Composition**: Better bounds than naive composition
- **Moments Accountant**: Tighter accounting (used by TensorFlow Privacy)
- **Rényi Differential Privacy**: Alternative composition theory

**Expected Outcomes**:
- Track privacy budget across multiple queries
- Prevent budget exhaustion
- Understand composition theorems

**Private Inference** (Lecture: 2 hours, Exercise 1 Part 3: 1 hour)

**Goal**: Protect individual predictions from membership inference

**Approach**: Add noise to model outputs

**Expected Outcomes**:
- Implement private predictions
- Evaluate impact on inference accuracy

### 3. Federated Learning (5 hours)

**Federated Learning Basics** (Lecture: 2 hours, Exercise 2 Part 1: 2 hours)

**Architecture**:
```
Clients (devices) → Local training → Send updates (not data!)
    ↓
Server → Aggregate updates → Send global model back
    ↓
Repeat
```

**FedAvg Algorithm**:
```
For each round t:
    1. Server sends global model w_t to clients
    2. Each client i trains locally: w_i^(t+1) = LocalUpdate(w_t, D_i)
    3. Server aggregates: w^(t+1) = Σ(n_i/n) · w_i^(t+1)
```

**Benefits**:
- Data privacy (data stays on device)
- Reduced communication (send models, not data)
- Compliance (easier GDPR/HIPAA)

**Challenges**:
- Non-IID data (different distributions per client)
- Systems heterogeneity (different devices)
- Communication efficiency

**Expected Outcomes**:
- Implement FedAvg from scratch
- Achieve 90%+ accuracy compared to centralized training
- Handle non-IID data partitions
- Analyze communication costs

**Secure Aggregation** (Lecture: 1.5 hours, Exercise 2 Part 2: 1.5 hours)

**Problem**: Model updates can leak information

**Solution**: Secure multi-party computation
- Clients split updates into secret shares
- Server only sees aggregated result
- Server never sees individual client updates

**Expected Outcomes**:
- Implement secure aggregation using secret sharing
- Verify correctness of aggregation
- Understand security guarantees

**FL with Differential Privacy** (Lecture: 1.5 hours, Exercise 2 Part 3: 1.5 hours)

**User-Level DP**: Adding/removing one user's data changes model by at most (ε, δ)

**Algorithm**:
1. Clients train locally
2. Clip client updates (bound sensitivity)
3. Aggregate updates
4. Add Gaussian noise (scaled by number of rounds)

**Privacy-Utility Trade-off**:
- FL (no DP): 95% accuracy
- FL + DP (ε=10): 88% accuracy
- FL + DP (ε=3): 79% accuracy

**Expected Outcomes**:
- Implement user-level DP for federated learning
- Evaluate privacy-accuracy trade-offs
- Compare with centralized DP training

### 4. Data Anonymization (4 hours)

**K-Anonymity** (Lecture: 1.5 hours, Exercise 4 Part 1: 1.5 hours)

**Definition**: Each record is indistinguishable from k-1 others based on quasi-identifiers

**Techniques**:
- **Generalization**: Age 25 → "20-29", Zipcode 94301 → "943**"
- **Suppression**: Remove outliers that can't be generalized

**Limitations**:
- Homogeneity attack: All records in group have same sensitive value
- Background knowledge attack: Attacker knows victim is in dataset

**Expected Outcomes**:
- Implement k-anonymization with generalization
- Verify k-anonymity property
- Evaluate utility loss

**L-Diversity and T-Closeness** (Lecture: 1 hour, Exercise 4 Part 2: 1 hour)

**L-Diversity**: Each k-anonymous group has ≥ l diverse values for sensitive attribute
- Prevents homogeneity attack

**T-Closeness**: Distribution of sensitive attribute in each group is close (within t) to overall distribution
- Prevents skewness attack

**Expected Outcomes**:
- Implement l-diversity
- Compare k-anonymity, l-diversity, t-closeness
- Understand when each is appropriate

**Synthetic Data Generation** (Lecture: 1.5 hours)

**Approach**: Generate synthetic data that preserves statistical properties

**Benefits**:
- No privacy risk (synthetic data not regulated)
- Can share publicly

**Trade-offs**:
- Utility loss (may not capture all patterns)
- Still risk of implicit memorization

**DP Synthetic Data**: Combine synthetic data generation with differential privacy for provable guarantees

### 5. Privacy Impact Assessment (3 hours)

**Conducting a PIA** (Lecture: 2 hours, Exercise 4 Part 3: 1-1.5 hours)

**Steps**:
1. **Identify personal data**: Direct identifiers, quasi-identifiers, sensitive data
2. **Assess necessity**: Is collection proportionate to purpose?
3. **Identify risks**: Data breach, re-identification, function creep
4. **Design mitigations**: Technical and organizational measures
5. **Evaluate residual risk**: Is remaining risk acceptable?
6. **Document**: Formal PIA report

**When Required**:
- GDPR: Required for high-risk processing
- HIPAA: Risk analysis required
- Best practice: Always for ML systems using personal data

**Expected Outcomes**:
- Conduct complete PIA for ML system
- Document all privacy risks
- Design appropriate mitigations
- Generate compliance documentation

---

## Practical Skills Developed

### Technical Implementation

1. **Differential Privacy Programming**
   - Noise mechanism implementation
   - Privacy budget management
   - DP-SGD with Opacus
   - Privacy accountant usage

2. **Federated Learning Systems**
   - Server-client architecture
   - Model aggregation algorithms
   - Secure aggregation protocols
   - Communication optimization

3. **Data Anonymization**
   - Generalization algorithms
   - K-anonymity verification
   - Synthetic data generation
   - Re-identification testing

4. **Compliance Engineering**
   - GDPR data subject rights implementation
   - Machine unlearning algorithms
   - Audit logging systems
   - Compliance automation

### Domain Knowledge

1. **Privacy Regulations**
   - GDPR interpretation for ML
   - HIPAA technical requirements
   - CCPA/CPRA compliance
   - Cross-border data transfers

2. **Privacy Guarantees**
   - Differential privacy theory
   - Composition theorems
   - Privacy budget calculation
   - Certified vs empirical privacy

3. **Risk Assessment**
   - Privacy threat modeling
   - Re-identification risk analysis
   - Privacy-utility trade-offs
   - Residual risk evaluation

---

## Study Plan

### Week 1: Regulations & Differential Privacy (10 hours)

**Day 1-2: Privacy Regulations** (5 hours)
- Read lecture notes on GDPR, HIPAA, CCPA (3 hours)
- Understand data subject rights (1 hour)
- Review compliance requirements (1 hour)

**Day 3-5: Differential Privacy** (5 hours)
- Read DP foundations (2 hours)
- Implement DP mechanisms (Exercise 1 Part 1: 1.5 hours)
- Implement DP-SGD (Exercise 1 Part 2: 1.5 hours)

### Week 2: Federated Learning & GDPR (8 hours)

**Day 6-7: Federated Learning** (5 hours)
- Read FL lecture notes (2 hours)
- Implement FedAvg (Exercise 2 Part 1: 2 hours)
- Implement secure aggregation (Exercise 2 Part 2: 1 hour)

**Day 8-9: GDPR Compliance** (3 hours)
- Implement data subject rights (Exercise 3 Part 1: 1 hour)
- Implement machine unlearning (Exercise 3 Part 2: 1.5 hours)
- Build compliance workflow (Exercise 3 Part 3: 0.5 hours)

### Week 3: Anonymization & PIA (7 hours)

**Day 10-11: Data Anonymization** (4 hours)
- Read anonymization lecture notes (1.5 hours)
- Implement k-anonymity (Exercise 4 Part 1: 1.5 hours)
- Implement l-diversity (Exercise 4 Part 2: 1 hour)

**Day 12: Privacy Impact Assessment** (3 hours)
- Read PIA lecture notes (1 hour)
- Conduct PIA (Exercise 4 Part 3: 1.5 hours)
- Generate compliance documentation (0.5 hours)

---

## Assessment

### Knowledge Assessment

**Quiz** (30 minutes, 20 questions):
- Privacy regulations (GDPR, HIPAA, CCPA)
- Differential privacy theory
- Federated learning concepts
- Anonymization techniques

**Pass**: 75%+

### Practical Assessment

**Capstone Project**: Privacy-Compliant Health ML System (8 hours)

Build a complete system with:
1. HIPAA-compliant data handling (de-identification, encryption, audit logging)
2. Differential privacy training (ε=8, achieve >80% accuracy)
3. GDPR data subject rights (access, erasure, portability)
4. Privacy impact assessment
5. Compliance documentation

### Grading Rubric

| Component | Weight | Criteria |
|-----------|--------|----------|
| Exercise 1: Differential Privacy | 25% | DP mechanisms, DP-SGD implementation |
| Exercise 2: Federated Learning | 25% | FedAvg, secure aggregation, DP-FL |
| Exercise 3: GDPR Compliance | 25% | Data subject rights, machine unlearning |
| Exercise 4: Anonymization & PIA | 20% | K-anonymity, l-diversity, PIA |
| Quiz | 5% | Knowledge assessment |

**Pass Criteria**: 75%+ overall, all exercises completed

---

## Common Challenges and Solutions

### Challenge 1: DP Training Doesn't Converge

**Problem**: Loss oscillates, accuracy stuck at low value

**Solutions**:
- Check gradient clipping threshold (try 0.5, 1.0, 2.0)
- Increase noise multiplier carefully (1.0 → 1.1 → 1.2)
- Use larger learning rate (0.001 → 0.01)
- Train longer (more epochs)
- Use larger batch size (128 → 256 → 512)
- Expected: DP training is harder, requires hyperparameter tuning

### Challenge 2: Privacy Budget Exhausted Too Fast

**Problem**: Epsilon budget used up before achieving good accuracy

**Solutions**:
- Increase total epsilon budget (8 → 10 → 16)
- Use advanced composition for tighter bounds
- Use Rényi DP for better accounting
- Reduce number of queries
- Accept: Strong privacy (ε<3) costs significant accuracy

### Challenge 3: Federated Learning Slow to Converge

**Problem**: Many rounds needed, high communication cost

**Solutions**:
- Increase local epochs (E=1 → E=5)
- Increase learning rate
- Use more clients per round (10% → 20%)
- Apply learning rate schedule
- Use FedProx or FedOpt (advanced FL algorithms)
- Expected: FL converges slower than centralized (100 rounds vs 20 epochs)

### Challenge 4: K-Anonymization High Information Loss

**Problem**: Too much data suppressed, utility poor

**Solutions**:
- Reduce k (10 → 5 → 3)
- Use smarter generalization hierarchies
- Apply different generalization per attribute
- Consider l-diversity instead (less suppression)
- Trade-off: Privacy vs utility is fundamental

### Challenge 5: Machine Unlearning Not Perfect

**Problem**: Membership inference still works after "unlearning"

**Solutions**:
- Use exact unlearning (retrain from scratch)
- Improve approximate unlearning (more shards in SISA)
- Use differential privacy (inherently provides unlearning)
- Accept: Perfect unlearning is hard without retraining
- Document limitations for compliance

---

## Expected Outcomes

After completing this module, you should be able to:

✅ Implement GDPR data subject rights (access, erasure, portability)
✅ Train models with differential privacy (>90% accuracy on MNIST with ε=8)
✅ Build federated learning systems (FedAvg, secure aggregation)
✅ Anonymize datasets (k-anonymity, l-diversity)
✅ Conduct privacy impact assessments
✅ Deploy HIPAA-compliant ML infrastructure
✅ Manage privacy budgets across multiple queries
✅ Implement machine unlearning
✅ Make informed privacy-utility trade-off decisions
✅ Ensure regulatory compliance for production ML systems

---

## Industry Best Practices

### Tech Companies

**Apple**:
- Differential privacy in iOS (keyboard suggestions, Safari)
- On-device federated learning
- Privacy budget management at scale

**Google**:
- Federated learning for Gboard (keyboard)
- RAPPOR (randomized aggregatable privacy-preserving ordinal response)
- Differential privacy in Chrome telemetry

**Meta**:
- Opacus (differential privacy library)
- CrypTen (secure multi-party computation)
- Privacy-preserving analytics

**Microsoft**:
- Differential privacy in Windows telemetry
- Confidential computing (Azure Confidential Computing)
- Privacy-preserving ML research

### Healthcare

**Epic, Cerner**:
- HIPAA-compliant ML systems
- De-identification before ML training
- Audit logging and compliance reporting

**Research Hospitals**:
- Federated learning across institutions
- Differential privacy for rare diseases
- Synthetic data for sharing

---

## Connection to Other Modules

### From Module 1 & 2

This module builds on:
- ML security fundamentals → Privacy as security requirement
- Threat modeling → Privacy threat modeling
- Adversarial robustness → Membership inference as adversarial attack

### To Module 4: Secrets & Identity Management

Prepares you for:
- Access control → GDPR requires strong access controls
- Encryption → HIPAA encryption requirements
- Audit logging → Privacy compliance logging

### To Module 5: Secure ML Pipelines

Prepares you for:
- Data governance → Privacy-compliant data pipelines
- Model registry → Track which data used for each model
- CI/CD → Automated privacy testing

---

## Tools and Libraries

### Differential Privacy

- **Opacus** (PyTorch): https://opacus.ai/
- **TensorFlow Privacy**: https://github.com/tensorflow/privacy
- **Diffprivlib** (IBM): https://github.com/IBM/differential-privacy-library
- **Google DP**: https://github.com/google/differential-privacy

### Federated Learning

- **PySyft**: https://github.com/OpenMined/PySyft
- **TensorFlow Federated**: https://www.tensorflow.org/federated
- **Flower**: https://flower.dev/
- **FedML**: https://github.com/FedML-AI/FedML

### Anonymization

- **ARX Data Anonymization Tool**: https://arx.deidentifier.org/
- **SDV (Synthetic Data Vault)**: https://sdv.dev/
- **Microsoft Presidio**: https://github.com/microsoft/presidio

### Compliance

- **OneTrust**: Privacy management platform
- **TrustArc**: Compliance automation
- **BigID**: Data discovery and governance

---

## Research Directions

1. **Differential Privacy**:
   - Improving privacy-accuracy trade-offs
   - Tighter composition theorems
   - DP for large language models
   - Adaptive privacy budgets

2. **Federated Learning**:
   - Personalization vs privacy
   - Byzantine-robust aggregation
   - Communication efficiency
   - Cross-device to cross-silo FL

3. **Machine Unlearning**:
   - Efficient exact unlearning
   - Verification of unlearning
   - Unlearning in production systems

4. **Privacy Regulations**:
   - AI Act (EU) compliance
   - Global privacy frameworks
   - Right to explanation

---

## Resources

### Books

1. **"The Algorithmic Foundations of Differential Privacy"** by Dwork & Roth (2014)
   - Theoretical foundations

2. **"The Ethical Algorithm"** by Kearns & Roth (2019)
   - Accessible introduction to privacy-preserving AI

3. **"Privacy-Preserving Machine Learning"** by J. Morris Chang (2023)
   - Practical guide for ML practitioners

### Papers

**Differential Privacy**:
1. Dwork et al. "Calibrating Noise to Sensitivity in Private Data Analysis" (2006)
2. Abadi et al. "Deep Learning with Differential Privacy" (2016)
3. Papernot et al. "Scalable Private Learning with PATE" (2017)

**Federated Learning**:
1. McMahan et al. "Communication-Efficient Learning of Deep Networks from Decentralized Data" (2017)
2. Bonawitz et al. "Practical Secure Aggregation for Privacy-Preserving Machine Learning" (2017)
3. Kairouz et al. "Advances and Open Problems in Federated Learning" (2021)

**Anonymization**:
1. Sweeney "k-Anonymity: A Model for Protecting Privacy" (2002)
2. Machanavajjhala et al. "l-Diversity: Privacy Beyond k-Anonymity" (2007)

### Online Courses

- **Coursera**: Privacy-Preserving Machine Learning (Google)
- **MIT**: Applied Privacy for Data Science
- **Stanford**: Differential Privacy

### Regulatory Resources

- **GDPR**: https://gdpr.eu/
- **HIPAA**: https://www.hhs.gov/hipaa/
- **CCPA/CPRA**: https://oag.ca.gov/privacy/ccpa
- **NIST Privacy Framework**: https://www.nist.gov/privacy-framework

---

## Module Completion Checklist

- [ ] Implement GDPR data subject rights (access, erasure, portability)
- [ ] Train model with DP-SGD (>90% accuracy on MNIST, ε=8)
- [ ] Build federated learning system (FedAvg)
- [ ] Implement secure aggregation
- [ ] Add user-level DP to federated learning
- [ ] K-anonymize dataset
- [ ] Implement machine unlearning (SISA or gradient-based)
- [ ] Conduct privacy impact assessment
- [ ] Complete all exercises and quiz (>75%)

**When you can confidently check all boxes, you're ready for Module 4!**

---

**Module Duration**: 25 hours
**Difficulty**: Intermediate-Advanced
**Prerequisites**: Module 1, probability, ML fundamentals
**Next Module**: Module 4 - Secrets & Identity Management

Privacy is not just compliance—it's fundamental to trustworthy AI. Let's build privacy-preserving ML systems! 🔒🤖
