# Module 1: ML Security Fundamentals

## Overview

Welcome to the first module of the AI Infrastructure Security Engineer curriculum. This module establishes the foundational knowledge required to secure machine learning systems, covering ML-specific threats, security frameworks, and defensive strategies.

**Duration**: 25 hours total
- Lecture notes: 10-12 hours study
- Exercises: 12-15 hours hands-on practice

**Prerequisites**:
- Security fundamentals (CIA triad, basic cryptography)
- Machine learning basics (model training, inference)
- Python programming
- Linux/Unix command line

---

## Module Structure

```
mod-001-ml-security-fundamentals/
├── README.md (this file)
├── lecture-notes/
│   └── 01-ml-security-fundamentals.md (16,000 words)
└── exercises/
    ├── README.md (exercise guide)
    ├── ex01-adversarial-attacks/ (4 hours)
    ├── ex02-threat-modeling/ (3 hours)
    ├── ex03-secure-pipeline/ (5-6 hours)
    └── ex04-security-testing/ (2-3 hours)
```

---

## Learning Objectives

By completing this module, you will be able to:

1. **Understand ML Security Landscape**
   - Identify ML-specific attack vectors beyond traditional security
   - Explain the OWASP Machine Learning Security Top 10
   - Recognize real-world ML security incidents and lessons learned

2. **Conduct Threat Modeling**
   - Apply STRIDE methodology to ML systems
   - Identify assets, threats, and security controls
   - Prioritize security investments using risk matrices
   - Create comprehensive threat model documentation

3. **Implement Security Controls**
   - Build secure ML pipelines with defense-in-depth
   - Implement authentication, authorization, and rate limiting
   - Add input validation and anomaly detection
   - Create audit logging and monitoring systems

4. **Test and Validate Security**
   - Generate adversarial examples and test model robustness
   - Write security test cases for ML systems
   - Integrate security testing into CI/CD pipelines
   - Perform security assessments

5. **Apply Security-by-Design**
   - Design secure ML architectures from the ground up
   - Implement least privilege principles
   - Reduce attack surface
   - Follow secure development lifecycle practices

---

## Topics Covered

### 1. Introduction to ML Security (Lecture: 3 hours)

**Why ML Security is Different**:
- Traditional security vs. ML-specific threats
- The expanded attack surface of ML systems
- Real-world incidents (Microsoft Tay, Proofpoint, Tesla Autopilot)

**Key Concepts**:
- Model vulnerabilities (adversarial examples, model inversion)
- Training data poisoning
- Model stealing
- Inference attacks
- Supply chain risks

### 2. OWASP Machine Learning Security Top 10 (Lecture: 5 hours, Exercise 1: 4 hours)

**ML01: Input Manipulation Attack**
- Adversarial examples (FGSM, PGD, C&W)
- Physical-world attacks
- Defense mechanisms (input validation, adversarial training)

**ML02: Data Poisoning Attack**
- Label flipping and backdoor insertion
- Data sanitization techniques
- Differential privacy

**ML03: Model Inversion Attack**
- Reconstructing training data from models
- Membership inference attacks
- Privacy-preserving defenses

**ML04-ML10**: Model stealing, supply chain attacks, transfer learning attacks, etc.

**Hands-On**: Exercise 1 implements FGSM and PGD attacks, tests defenses

### 3. Threat Modeling for ML Systems (Lecture: 6 hours, Exercise 2: 3 hours)

**STRIDE Methodology**:
- Spoofing, Tampering, Repudiation
- Information Disclosure, Denial of Service
- Elevation of Privilege

**ML Pipeline Threat Model**:
- Data collection threats
- Training pipeline vulnerabilities
- Inference serving attack vectors
- Monitoring and logging risks

**Attack Trees**:
- Visual threat representation
- AND/OR logic for attack paths
- Risk calculation and prioritization

**Hands-On**: Exercise 2 conducts full threat modeling for healthcare ML system

### 4. Security by Design Principles (Lecture: 4 hours, Exercise 3: 5-6 hours)

**Defense in Depth**:
- Layered security architecture
- Network, application, model, data, monitoring layers

**Least Privilege**:
- IAM for ML workloads
- Service accounts and RBAC
- Minimal permissions

**Secure Development Lifecycle**:
- Requirements and design phase security
- Implementation security practices
- Verification and testing
- Deployment and operations

**Hands-On**: Exercise 3 builds production-grade secure ML API

### 5. ML Attack Surface Analysis (Lecture: 4 hours)

**Attack Surface Mapping**:
- Data pipeline entry points
- Training infrastructure vulnerabilities
- Inference API attack vectors
- Monitoring system risks

**Attack Surface Reduction**:
- Minimize exposed APIs
- Input sanitization at boundaries
- Network segmentation
- Disable unnecessary features

### 6. Security Testing and CI/CD (Lecture: 3 hours, Exercise 4: 2-3 hours)

**Security Test Types**:
- Authentication and authorization tests
- Rate limiting validation
- Input validation and adversarial robustness tests
- Audit logging verification

**CI/CD Integration**:
- Automated dependency scanning
- Container vulnerability scanning
- Security test execution
- Continuous monitoring

**Hands-On**: Exercise 4 integrates security testing into GitHub Actions

---

## Practical Skills Developed

### Technical Skills

1. **Python Security Programming**
   - Secure coding practices
   - JWT authentication
   - Input validation and sanitization
   - Cryptographic operations

2. **ML Security Tools**
   - Foolbox, CleverHans (adversarial attacks)
   - Snyk, Trivy (vulnerability scanning)
   - Bandit (security linting)
   - OWASP tools

3. **Infrastructure Security**
   - Docker security best practices
   - Kubernetes security contexts and policies
   - Network policies and segmentation
   - TLS/mTLS configuration

4. **Security Testing**
   - Writing security test cases
   - Adversarial robustness testing
   - Penetration testing basics
   - CI/CD security integration

### Professional Skills

1. **Threat Modeling**
   - STRIDE methodology application
   - Risk assessment and prioritization
   - Security documentation
   - Stakeholder communication

2. **Security Architecture**
   - Defense-in-depth design
   - Security control selection
   - Trade-off analysis (security vs. performance)
   - Architecture documentation

3. **Incident Response Preparation**
   - Audit logging design
   - Monitoring and alerting
   - Security metrics definition

---

## Expected Outcomes

### Knowledge Outcomes

After completing this module, you should be able to:

- [ ] Explain 10+ ML-specific attack vectors
- [ ] Describe the OWASP ML Top 10 threats
- [ ] Identify security vulnerabilities in ML pipelines
- [ ] Design security controls for each threat
- [ ] Articulate security trade-offs and business impact

### Skill Outcomes

You should be able to:

- [ ] Generate adversarial examples using FGSM and PGD
- [ ] Conduct STRIDE threat modeling for ML systems
- [ ] Implement secure ML inference APIs with:
  - Authentication and authorization
  - Rate limiting
  - Input validation
  - Audit logging
- [ ] Write comprehensive security test suites
- [ ] Integrate security scanning into CI/CD
- [ ] Deploy ML systems with Docker/Kubernetes security

### Deliverable Outcomes

You will have created:

- [ ] Adversarial attack and defense implementations
- [ ] Complete threat model for healthcare ML system
- [ ] Production-ready secure ML API
- [ ] Security test suite with 20+ test cases
- [ ] CI/CD pipeline with automated security checks

---

## Study Plan

### Recommended 5-Day Schedule (5 hours/day)

**Day 1: Introduction & OWASP Top 10 (Part 1)**
- Read: Lecture sections 1-2.5
- Understand: ML security landscape, OWASP ML01-ML05
- Time: 5 hours reading + note-taking

**Day 2: OWASP Top 10 (Part 2) + Exercise 1 Start**
- Read: Lecture sections 2.6-2.7
- Start Exercise 1: FGSM attack implementation
- Time: 2 hours reading + 3 hours coding

**Day 3: Exercise 1 Completion + Threat Modeling**
- Complete Exercise 1: PGD attack and defenses
- Read: Lecture section 3 (Threat Modeling)
- Time: 2 hours coding + 3 hours reading

**Day 4: Threat Modeling Exercise + Security by Design**
- Complete Exercise 2: Full threat modeling workshop
- Read: Lecture sections 4-5
- Time: 3 hours exercise + 2 hours reading

**Day 5: Secure Implementation**
- Read: Lecture sections 6-7
- Start Exercise 3: Secure ML pipeline
- Time: 2 hours reading + 3 hours coding

**Days 6-7: Complete Implementation & Testing**
- Complete Exercise 3: Secure API with Docker/K8s
- Complete Exercise 4: Security testing and CI/CD
- Time: 10 hours implementation and testing

### Self-Study Tips

1. **Take Notes**: Summarize key concepts in your own words
2. **Code Along**: Don't just read code examples, type and run them
3. **Ask "Why?"**: Understand the rationale behind each security control
4. **Real-World Context**: Think about how each threat applies to systems you know
5. **Test Everything**: Run the example code, modify it, break it, fix it
6. **Document**: Keep a security journal of what you learn

---

## Assessment

### Formative Assessment (During Module)

**Lecture Notes**:
- Self-check questions at end of each section
- Code examples to run and modify
- Thought experiments

**Exercises**:
- Working implementations required
- Test suites must pass
- Documentation must be complete

### Summative Assessment (End of Module)

**Knowledge Check** (30 minutes):
- 20 multiple choice questions on OWASP Top 10, threat modeling, security controls
- Pass: 75%+

**Practical Exam** (3 hours):
- Given vulnerable ML system, identify 10+ vulnerabilities
- Implement 5+ security controls
- Write threat model
- Create security test cases

**Project Deliverables**:
- All 4 exercises completed
- Code passes security tests
- Documentation is professional quality
- Demonstrations show working security controls

### Grading Rubric

| Component | Weight | Criteria |
|-----------|--------|----------|
| Exercise 1: Adversarial Attacks | 20% | Working attacks and defenses, analysis report |
| Exercise 2: Threat Modeling | 20% | Complete threat model with 30+ threats, risk prioritization |
| Exercise 3: Secure Pipeline | 30% | Production-ready secure API, Docker/K8s deployment |
| Exercise 4: Security Testing | 20% | Comprehensive test suite, CI/CD integration |
| Knowledge Check | 10% | Quiz score |

**Pass Criteria**: 75%+ overall, all exercises submitted

---

## Common Challenges and Solutions

### Challenge 1: Adversarial Attacks Seem Abstract

**Problem**: Difficulty understanding why small perturbations matter

**Solution**:
- Run Exercise 1 examples with visualization
- Try physical-world examples (printed adversarial patches)
- Read case studies of real adversarial attacks in production

### Challenge 2: Threat Modeling Feels Overwhelming

**Problem**: Too many possible threats to analyze

**Solution**:
- Start with one component at a time
- Use templates and checklists
- Focus on high-impact threats first
- Iterate - threat modeling is never "complete"

### Challenge 3: Security vs. Performance Trade-offs

**Problem**: Security controls slow down the system

**Solution**:
- Measure performance impact quantitatively
- Optimize implementation (e.g., batch input validation)
- Use asynchronous logging
- Cache validation results
- Accept that some overhead is necessary

### Challenge 4: Keeping Up with New Attacks

**Problem**: New attack papers published constantly

**Solution**:
- Focus on fundamental principles (they don't change)
- Follow security researchers on Twitter/Mastodon
- Read OWASP updates quarterly
- Join ML security mailing lists
- Implement detection rather than prevention for novel attacks

---

## Resources

### Required Reading

1. **Lecture Notes**: `01-ml-security-fundamentals.md` (16,000 words)
2. **Exercise Guides**: All 4 exercise READMEs

### Recommended Reading

1. **OWASP Machine Learning Security Top 10** (2023)
   - https://owasp.org/www-project-machine-learning-security-top-10/
   - Essential reference for threat catalog

2. **NIST AI Risk Management Framework**
   - https://www.nist.gov/itl/ai-risk-management-framework
   - Government perspective on AI/ML security

3. **Microsoft Security Development Lifecycle for ML**
   - Research paper and best practices guide
   - Enterprise security approach

### Tools and Libraries

**Adversarial ML**:
- Foolbox: https://foolbox.readthedocs.io/
- CleverHans: https://github.com/cleverhans-lab/cleverhans
- Adversarial Robustness Toolbox (ART): https://github.com/Trusted-AI/adversarial-robustness-toolbox

**Privacy**:
- Opacus (differential privacy): https://opacus.ai/
- PySyft: https://github.com/OpenMined/PySyft

**Security Scanning**:
- Snyk: https://snyk.io/
- Trivy: https://trivy.dev/
- Bandit: https://bandit.readthedocs.io/

**Web Security**:
- Flask-Limiter: https://flask-limiter.readthedocs.io/
- PyJWT: https://pyjwt.readthedocs.io/

### Community Resources

- **r/MLSecOps**: Reddit community for ML security
- **AI Security & Privacy mailing list**: Research discussions
- **DEFCON AI Village**: Annual conference track
- **OWASP ML Security Project**: Community contributions

### Videos and Tutorials

1. **Adversarial Machine Learning** (YouTube, 1 hour)
   - Intro to adversarial examples with demos

2. **Threat Modeling for ML** (conference talk, 45 min)
   - STRIDE methodology applied to ML systems

3. **Securing ML Pipelines** (workshop, 2 hours)
   - End-to-end security implementation

---

## Connection to Other Modules

### Prerequisites

This module assumes:
- Basic security concepts (from prior experience or self-study)
- ML fundamentals (model training, evaluation, deployment)
- Python programming skills
- Docker and Kubernetes basics

### Leads Into

**Module 2: Model Security & Adversarial ML** (builds on):
- Exercise 1 adversarial attacks (deep dive into advanced attacks)
- Defenses implemented here (formal verification, certified defenses)

**Module 3: Data Privacy & Compliance** (builds on):
- Differential privacy basics (GDPR compliance)
- Threat modeling methodology (privacy impact assessment)

**Module 4: Secrets & Identity Management** (builds on):
- Authentication/authorization implementation (enterprise IAM)
- Kubernetes security (secrets management)

**Module 5: Secure ML Pipelines** (builds on):
- Secure pipeline implementation (CI/CD security, supply chain)
- Security testing (automated security validation)

---

## Instructor Notes

### Teaching Approach

1. **Theory First, Then Practice**: Lecture notes provide foundation, exercises apply concepts
2. **Progressive Difficulty**: Start with attacks (understand threats), then defenses (build security)
3. **Real-World Focus**: All examples based on production scenarios
4. **Iterative Learning**: Exercises build on each other, reinforcing concepts

### Common Student Questions

**Q: "Isn't traditional security enough for ML systems?"**
A: No - ML introduces new attack surfaces (model stealing, adversarial examples, data poisoning) that traditional security doesn't address. Exercise 1 demonstrates attacks that have no equivalent in traditional software.

**Q: "Do adversarial attacks happen in practice?"**
A: Yes - documented cases include spam filters, autonomous vehicles, facial recognition. However, most production impact comes from data quality and model staleness, not adversarial examples. Security is about preparing for worst-case scenarios.

**Q: "Should I implement all these security controls?"**
A: Depends on threat model and risk tolerance. Threat modeling (Exercise 2) helps prioritize. For high-stakes applications (healthcare, finance), comprehensive security is essential. For low-risk applications, focus on basics (authentication, rate limiting, audit logging).

**Q: "What's the performance impact of security?"**
A: Typically 5-15% latency overhead for comprehensive security stack. Input validation: <1ms. Authentication: 1-2ms. Rate limiting: <1ms. Audit logging: 2-5ms (async). Adversarial training: 20-40% longer training time but no inference overhead.

### Lab Setup

**Required Infrastructure**:
- Python 3.9+ environment
- Docker and docker-compose
- Kubernetes cluster (Minikube for local testing)
- GitHub account (for CI/CD exercises)

**Recommended Setup**:
- 2 vCPU, 8GB RAM minimum
- GPU optional (speeds up adversarial training)
- Ubuntu 20.04+ or macOS

**Cloud Option**:
- Use Google Colab for GPU exercises
- Use GitHub Codespaces for exercises 3-4

---

## Module Updates

**Version 1.0** (January 2025)
- Initial release
- Covers OWASP ML Top 10 (2023 version)
- 4 comprehensive exercises

**Planned Updates**:
- Add LLM-specific security content (prompt injection, jailbreaking)
- Include federated learning security
- Add more CTF challenges
- Update for OWASP ML Top 10 2025 when released

---

## Getting Help

### During Self-Study

1. **Re-read Lecture Notes**: Most answers are in the detailed explanations
2. **Check Code Comments**: Exercises have extensive TODO comments and hints
3. **Review Examples**: Lecture notes include working code examples
4. **Online Resources**: OWASP documentation, tool documentation

### Instructor Support

- Office hours: [Schedule TBD]
- Discussion forum: [Link TBD]
- Email: [Instructor email]
- Response time: 24-48 hours

### Debugging Tips

**Exercise 1 Issues**:
- Model not training: Check CUDA availability, reduce batch size
- Attacks not working: Verify gradients enabled, check epsilon value
- Poor attack success: Try PGD instead of FGSM, increase iterations

**Exercise 3 Issues**:
- Rate limiting not working: Check time windows, test with concurrent requests
- Authentication failures: Verify JWT secret, check token expiration
- Docker won't start: Check port conflicts, review logs

**Exercise 4 Issues**:
- CI/CD failing: Check GitHub Actions logs, verify secrets configured
- Tests timing out: Increase wait times, check service startup
- Scans finding vulnerabilities: Expected! Document and plan remediation

---

## Success Metrics

You've successfully completed this module when you can:

✅ Explain ML security to a software engineer colleague
✅ Identify 10+ vulnerabilities in an ML system
✅ Conduct a threat modeling session
✅ Implement production-ready security controls
✅ Write and integrate security tests
✅ Make informed security trade-off decisions

**Next Steps**: Proceed to Module 2 for advanced adversarial ML techniques, or apply these concepts in a real-world project.

---

**Module Duration**: 25 hours
**Difficulty**: Intermediate
**Prerequisites**: Security basics, ML basics, Python
**Completion Rate**: Target 85%+

Good luck! Remember: **Security is a continuous process, not a destination.**
