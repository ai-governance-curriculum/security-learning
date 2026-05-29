# AI Infrastructure Security Engineer - Learning Repository

**Level**: 2.5C (Specialized Security Track from Senior Infrastructure Engineer)
**Duration**: 680 hours (17 weeks full-time, 34 weeks part-time)
**Prerequisites**: Senior AI Infrastructure Engineer completion, deep security knowledge
**Total Projects**: 5 comprehensive security implementations

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)
[![Security Track](https://img.shields.io/badge/Track-Security-red.svg)]()

## Overview

This repository provides a comprehensive, hands-on learning path for becoming an **AI Infrastructure Security Engineer** specializing in securing machine learning systems against sophisticated attacks including adversarial examples, model extraction, data poisoning, supply chain compromises, and insider threats.

You'll learn to design and implement zero-trust architectures, automate compliance for GDPR/HIPAA/SOC 2, defend models from adversarial attacks, secure CI/CD pipelines, and build security operations centers (SOC) for ML infrastructure.

### Why This Specialization Matters

ML systems face unique security challenges:
- **Model Theft**: Proprietary models worth millions vulnerable to extraction attacks
- **Data Privacy**: Training data containing PII, PHI, trade secrets
- **Adversarial Attacks**: Evasion, poisoning, backdoors, membership inference
- **Regulatory Compliance**: GDPR, HIPAA, SOC 2, industry-specific regulations
- **Supply Chain**: Vulnerable dependencies, malicious packages, compromised images
- **Insider Threats**: Privileged users with access to sensitive models and data

**Industry Impact**:
- GDPR fines up to €20M or 4% of global revenue
- HIPAA penalties up to $1.5M per year
- Average data breach cost: $4.24M (IBM 2021)
- ML model IP valued at $10M-$100M+ for large companies

## Learning Path

### Course Structure

This specialization consists of **5 progressive projects**, each building critical security competencies:

```
┌─────────────────────────────────────────────────────────────┐
│                  Security Learning Path                      │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Project 1: Zero-Trust ML Infrastructure (140 hours)        │
│  ├─ Microsegmentation with NetworkPolicies                  │
│  ├─ Mutual TLS (mTLS) service mesh                          │
│  ├─ HashiCorp Vault secrets management                      │
│  ├─ Falco runtime security                                  │
│  └─ OPA/Gatekeeper policy enforcement                       │
│                                                              │
│  Project 2: Compliance Framework (140 hours)                │
│  ├─ GDPR compliance automation                              │
│  ├─ HIPAA security controls                                 │
│  ├─ SOC 2 Trust Services Criteria                           │
│  ├─ Immutable audit logging (WORM)                          │
│  └─ Data subject rights (erasure, access)                   │
│                                                              │
│  Project 3: Adversarial ML Defense (160 hours)              │
│  ├─ Adversarial training (PGD, TRADES)                      │
│  ├─ Certified defenses (randomized smoothing)               │
│  ├─ Data poisoning detection                                │
│  ├─ Model extraction protection                             │
│  └─ Privacy-preserving ML (differential privacy)            │
│                                                              │
│  Project 4: Secure ML CI/CD (100 hours)                     │
│  ├─ 15+ security gates (SAST, DAST, SCA, etc.)              │
│  ├─ Container image signing (Cosign/Sigstore)               │
│  ├─ SLSA Level 3 provenance                                 │
│  ├─ Model security scanning                                 │
│  └─ Supply chain security (SBOM)                            │
│                                                              │
│  Project 5: Security Operations Center (140 hours)          │
│  ├─ SIEM deployment (ELK Stack)                             │
│  ├─ ML-specific detection rules (20+)                       │
│  ├─ Automated incident response                             │
│  ├─ MITRE ATT&CK for ML mapping                             │
│  └─ Security metrics (MTTD, MTTR)                           │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Learning Modules

This repository includes **12 comprehensive learning modules**:

1. **Foundations of ML Security** (20 hours)
   - OWASP ML Security Top 10
   - MITRE ATT&CK for ML
   - Threat modeling for ML systems
   - Security architecture principles

2. **Zero-Trust Architecture** (25 hours)
   - BeyondCorp principles
   - Microsegmentation strategies
   - Identity-based security
   - Defense in depth

3. **Cryptography for ML** (20 hours)
   - Encryption at rest and in transit
   - Key management (Vault)
   - Certificate management (cert-manager)
   - Homomorphic encryption basics

4. **Network Security** (25 hours)
   - Kubernetes NetworkPolicies
   - Service mesh security (Istio)
   - Network segmentation
   - DDoS protection

5. **Secrets Management** (20 hours)
   - HashiCorp Vault deep dive
   - Dynamic secrets
   - Secret rotation
   - Transit encryption

6. **Adversarial Machine Learning** (40 hours)
   - Attack taxonomy (evasion, poisoning, extraction)
   - Adversarial Robustness Toolbox (ART)
   - Defensive techniques
   - Privacy attacks (membership inference)

7. **Compliance and Governance** (35 hours)
   - GDPR requirements for ML
   - HIPAA security rules
   - SOC 2 Trust Services
   - Compliance automation

8. **Runtime Security** (30 hours)
   - Falco rules and alerts
   - Container security
   - Syscall monitoring
   - Behavioral analytics

9. **Policy as Code** (25 hours)
   - Open Policy Agent (OPA)
   - Rego policy language
   - Gatekeeper constraints
   - CI/CD policy gates

10. **Supply Chain Security** (30 hours)
    - SLSA framework
    - Software Bill of Materials (SBOM)
    - Image signing and verification
    - Dependency scanning

11. **Security Operations** (35 hours)
    - SIEM deployment and configuration
    - Security monitoring
    - Incident response
    - Threat hunting

12. **Advanced Topics** (25 hours)
    - Confidential computing (SGX, SEV)
    - Federated learning security
    - Blockchain for ML provenance
    - Quantum-resistant cryptography

**Total Module Time**: 330 hours
**Total Project Time**: 680 hours
**Overall Program**: 1,010 hours

## Projects

### Project 1: Zero-Trust ML Infrastructure
[View Project →](projects/project-1-zero-trust/)

Build a comprehensive zero-trust security architecture implementing "never trust, always verify" principles across all ML infrastructure layers.

**Technologies**: Kubernetes, Istio, HashiCorp Vault, Falco, OPA/Gatekeeper
**Duration**: 140 hours
**Deliverables**:
- Zero-trust network with default-deny policies
- Mutual TLS across all services
- Dynamic secrets management
- Runtime security monitoring
- 15+ OPA compliance policies

### Project 2: Compliance Framework for ML Systems
[View Project →](projects/project-2-compliance/)

Automate compliance verification for GDPR, HIPAA, and SOC 2 with immutable audit logs and data subject rights workflows.

**Technologies**: OPA, ELK Stack, WORM storage, DLP tools, AES-256 encryption
**Duration**: 140 hours
**Deliverables**:
- Automated compliance verification
- Immutable audit logging infrastructure
- GDPR right to erasure workflow (30-day SLA)
- Data classification and encryption automation
- Real-time compliance dashboards

### Project 3: Adversarial ML Defense System
[View Project →](projects/project-3-adversarial-defense/)

Defend ML models from adversarial attacks including evasion, poisoning, extraction, backdoors, and privacy attacks.

**Technologies**: Adversarial Robustness Toolbox, CleverHans, TRADES, Opacus
**Duration**: 160 hours (most complex)
**Deliverables**:
- Adversarial training pipeline
- Certified defenses (randomized smoothing)
- Adversarial detection networks
- Data poisoning defenses
- Model extraction protection
- Automated security testing suite

### Project 4: Secure ML CI/CD Pipeline
[View Project →](projects/project-4-secure-cicd/)

Implement secure software supply chain for ML with 15+ security gates and SLSA Level 3 compliance.

**Technologies**: GitHub Actions, Trivy, Cosign/Sigstore, SLSA, Snyk, ModelScan
**Duration**: 100 hours
**Deliverables**:
- 15 security gates (SAST, secrets scanning, dependency scanning, etc.)
- Container image signing and verification
- SLSA Level 3 provenance generation
- SBOM generation and tracking
- Model security scanning
- Continuous compliance monitoring

### Project 5: Security Operations Center for ML
[View Project →](projects/project-5-security-operations/)

Build ML-focused SOC with SIEM, threat detection, incident response, and security analytics.

**Technologies**: ELK Stack, Elasticsearch ML, PagerDuty, MITRE ATT&CK
**Duration**: 140 hours
**Deliverables**:
- SIEM deployment with hot/warm/cold tiers
- 20+ ML-specific detection rules
- 5+ automated incident response playbooks
- Real-time SOC dashboard
- MTTD/MTTR tracking
- Threat intelligence integration

## Prerequisites

### Technical Requirements

Before starting this specialization, you should have:

**Required**:
- ✅ Completed **Senior AI Infrastructure Engineer** track (Level 2)
- ✅ Strong **Kubernetes** knowledge (CKA level or equivalent)
- ✅ Advanced **Python** programming skills
- ✅ **Linux/Unix** system administration expertise
- ✅ Basic security fundamentals (authentication, encryption, networking)
- ✅ Understanding of ML fundamentals (training, inference, model serving)

**Recommended**:
- 🔹 Security certifications (Security+, CEH, or equivalent)
- 🔹 Cloud security experience (AWS/GCP/Azure)
- 🔹 DevSecOps practices
- 🔹 Incident response experience
- 🔹 Regulatory compliance exposure (GDPR, HIPAA, SOC 2)

### Infrastructure Requirements

You'll need access to:

**Compute**:
- Kubernetes cluster (3+ nodes, 16+ vCPUs total)
- Cloud account (AWS/GCP/Azure) with admin access
- GPU access for adversarial ML projects (optional but recommended)

**Software**:
- Docker Desktop or equivalent
- kubectl, helm, istioctl
- Terraform or Pulumi
- Git and GitHub account
- Code editor (VS Code recommended)

**Estimated Monthly Cloud Costs**: $200-$400 USD
- Use spot instances and shutdown resources when not in use
- Cloud credits available for students: AWS Educate, GCP Education, Azure Students

## Getting Started

### Quick Start (5 minutes)

```bash
# 1. Clone this repository
git clone https://github.com/ai-infra-curriculum/ai-infra-security-learning.git
cd ai-infra-security-learning

# 2. Install prerequisites
./scripts/install-prerequisites.sh

# 3. Validate your environment
./scripts/validate-environment.sh

# 4. Start with Module 1
cd lessons/mod-101-ml-security-foundations
cat README.md
```

### Recommended Learning Sequence

**Full-Time Track (40 hours/week, 17 weeks)**:

**Weeks 1-2**: Foundations
- Complete modules 1-3 (ML Security Foundations, Zero-Trust, Cryptography)
- Set up lab environment
- Begin Project 1 planning

**Weeks 3-5**: Project 1 - Zero-Trust Infrastructure
- Implement zero-trust architecture
- Deploy Vault, Istio, Falco, Gatekeeper
- Complete all deliverables

**Weeks 6-8**: Compliance Track
- Complete modules 7, 9 (Compliance, Policy as Code)
- Project 2: Compliance Framework
- Automate GDPR, HIPAA, SOC 2

**Weeks 9-12**: Adversarial ML
- Complete module 6 (Adversarial ML) - most intensive
- Project 3: Adversarial Defense System
- Implement attack defenses

**Weeks 13-14**: Supply Chain Security
- Complete module 10 (Supply Chain)
- Project 4: Secure CI/CD Pipeline
- 15+ security gates

**Weeks 15-17**: Security Operations
- Complete modules 8, 11 (Runtime Security, SecOps)
- Project 5: ML SOC
- Final capstone integration

**Part-Time Track (20 hours/week, 34 weeks)**: Double the timeline for each phase

### Study Tips

1. **Hands-On First**: This is a practical course. Build, break, fix, repeat.
2. **Security Mindset**: Always think "How would I attack this?"
3. **Read the Specs**: GDPR, HIPAA, OWASP - primary sources matter
4. **Join the Community**: [Discord](#community), [Office Hours](#support)
5. **Document Everything**: Your future self (and auditors) will thank you
6. **Break Things**: Use dedicated lab environments and practice incident response
7. **Stay Current**: Security evolves rapidly - follow industry news

## Assessment

### Project Grading

Each project is worth **100 base points + 10 bonus points = 110 total**

**Overall Passing Criteria**:
- Minimum **450/550 points (82%)** across all 5 projects
- All **CRITICAL** security gates must pass (no hardcoded secrets, no HIGH/CRITICAL CVEs)
- Functional security monitoring and incident response demonstrated
- Portfolio submission with detailed README and architecture diagrams

### Certification

Upon successful completion:

1. **AI Infrastructure Security Engineer Certificate**
   - Digital badge for LinkedIn
   - Verifiable credential via blockchain
   - Portfolio of 5 production-ready security implementations

2. **Industry Certifications** (recommended next steps):
   - **CKS**: Certified Kubernetes Security Specialist
   - **HashiCorp Vault Associate**
   - **GIAC Cloud Security Automation (GCSA)**
   - **CISSP**: Certified Information Systems Security Professional

3. **Portfolio Showcase**:
   - GitHub repositories demonstrating competency
   - Detailed architecture documentation
   - Case studies of security implementations
   - Published blog posts (encouraged)

## Career Outcomes

### Job Titles

Graduates of this specialization are prepared for roles including:

- **AI/ML Security Engineer**
- **ML Infrastructure Security Architect**
- **DevSecOps Engineer (ML Focus)**
- **Security Operations Engineer (ML/AI)**
- **Compliance Engineer (ML Systems)**
- **Cloud Security Engineer (ML Workloads)**

### Salary Ranges (US, 2024)

- Entry to specialization: $120K - $160K
- Mid-level (2-3 years): $160K - $220K
- Senior (5+ years): $220K - $300K+
- Principal/Staff: $300K - $450K+

*Source: levels.fyi, Glassdoor, Blind (FAANG and tech companies)*

### Career Progression

From this role, you can advance to:

1. **Principal AI Infrastructure Architect** (Level 4)
   - Enterprise-wide security architecture
   - Multi-cloud security strategy
   - M&A technical due diligence

2. **Principal AI Infrastructure Engineer** (Level 4 - IC Track)
   - Advanced security research
   - Zero-day vulnerability research
   - Offensive security (red team)

3. **AI Infrastructure Team Lead** (Level 4 - Management)
   - Lead security engineering team (5-15 engineers)
   - Security product roadmap
   - Vendor security assessments

## Resources

### Official Documentation

- [Kubernetes Security Documentation](https://kubernetes.io/docs/concepts/security/)
- [HashiCorp Vault Docs](https://www.vaultproject.io/docs)
- [Istio Security](https://istio.io/latest/docs/concepts/security/)
- [Falco Documentation](https://falco.org/docs/)
- [Open Policy Agent](https://www.openpolicyagent.org/docs/)

### Regulatory References

- [GDPR Full Text](https://gdpr-info.eu/)
- [HIPAA Security Rule](https://www.hhs.gov/hipaa/for-professionals/security/)
- [SOC 2 Trust Services Criteria](https://www.aicpa.org/resources/landing/system-and-organization-controls-soc-suite-of-services)
- [NIST AI Risk Management Framework](https://www.nist.gov/itl/ai-risk-management-framework)

### Security Frameworks

- [OWASP ML Security Top 10](https://owasp.org/www-project-machine-learning-security-top-10/)
- [MITRE ATT&CK for ML](https://atlas.mitre.org/)
- [SLSA Framework](https://slsa.dev/)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)

### Tools and Libraries

- [Adversarial Robustness Toolbox (ART)](https://github.com/Trusted-AI/adversarial-robustness-toolbox)
- [CleverHans](https://github.com/cleverhans-lab/cleverhans)
- [Presidio (PII Detection)](https://github.com/microsoft/presidio)
- [Falco Rules Repository](https://github.com/falcosecurity/rules)
- [Gatekeeper Policy Library](https://github.com/open-policy-agent/gatekeeper-library)

### Books

- **"Zero Trust Networks"** by Evan Gilman and Doug Barth
- **"Kubernetes Security"** by Liz Rice and Michael Hausenblas
- **"Securing DevOps"** by Julien Vehent
- **"The Web Application Hacker's Handbook"** by Dafydd Stuttard
- **"Adversarial Machine Learning"** by Yevgeniy Vorobeychik and Murat Kantarcioglu

### Research Papers

- "Towards Deep Learning Models Resistant to Adversarial Attacks" (Madry et al., 2018)
- "Certified Adversarial Robustness via Randomized Smoothing" (Cohen et al., 2019)
- "Spectral Signatures in Backdoor Attacks" (Tran et al., 2018)
- "The Secret Sharer: Evaluating and Testing Unintended Memorization" (Carlini et al., 2019)

### Online Courses

- [Kubernetes Security Specialist (CKS)](https://training.linuxfoundation.org/certification/certified-kubernetes-security-specialist/)
- [AWS Security Specialty](https://aws.amazon.com/certification/certified-security-specialty/)
- [Offensive Security (OSCP)](https://www.offensive-security.com/pwk-oscp/)
- [Practical Machine Learning Security](https://www.coursera.org/learn/practical-machine-learning-security)

## Community

### Get Help

- **Discord Server**: [Join our community](https://discord.gg/ai-infra-security)
- **Office Hours**: Fridays 2-4 PM PT (calendar link in Discord)
- **GitHub Discussions**: [Ask questions, share projects](https://github.com/ai-infra-curriculum/ai-infra-security-learning/discussions)
- **Email Support**: security-track@ai-infra-curriculum@joshua-ferguson.com

### Contribute

We welcome contributions! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

**Ways to contribute**:
- 🐛 Report bugs or vulnerabilities
- 📝 Improve documentation
- 🎓 Share your learning journey
- 🛠️ Submit code improvements
- 💡 Suggest new projects or modules
- 🎤 Give talks or write blog posts

### Code of Conduct

This project follows the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md). By participating, you agree to uphold this code.

## License

This repository is licensed under the **MIT License** - see [LICENSE](LICENSE) file for details.

## Acknowledgments

This curriculum was developed with input from:
- Security engineers at FAANG companies
- OWASP ML Security working group
- MITRE ATT&CK for ML contributors
- Academic researchers in adversarial ML
- Compliance professionals (GDPR, HIPAA, SOC 2)

Special thanks to our reviewers and beta testers.

## Roadmap

### Current Version: 1.0.0

**Coming in Version 1.1** (Q2 2025):
- ☐ Confidential computing module (Intel SGX, AMD SEV)
- ☐ Quantum-resistant cryptography project
- ☐ Federated learning security module
- ☐ Advanced privacy-preserving techniques (MPC, TEEs)

**Coming in Version 2.0** (Q4 2025):
- ☐ AI governance and ethics module
- ☐ Automated red team exercises
- ☐ Security chaos engineering
- ☐ Advanced threat hunting with ML

**Suggest features**: [GitHub Issues](https://github.com/ai-infra-curriculum/ai-infra-security-learning/issues)

---

**Start your journey to becoming an AI Infrastructure Security Engineer today!**

Questions? Join our [Discord](https://discord.gg/ai-infra-security) or email security-track@ai-infra-curriculum@joshua-ferguson.com

*Last Updated: October 2025*
*Repository Version: 1.0.0*
*Total Stars: ⭐ (Be the first!)*


---

<!-- aicg:maintained-by -->
Maintained by [VeriSwarm.ai](https://veriswarm.ai)
