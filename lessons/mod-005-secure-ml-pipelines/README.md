# Module 5: Secure ML Pipelines

## Module Overview

This module covers security practices for ML pipelines, including CI/CD security, container hardening, dependency management, supply chain security, and secure artifact management. You'll learn to build and deploy ML models securely through automated pipelines with comprehensive security controls.

**Duration**: 30 hours (theory + practice)
**Level**: Advanced
**Prerequisites**:
- Completed Modules 1-4
- Understanding of Docker and Kubernetes
- Familiarity with CI/CD concepts (GitHub Actions, GitLab CI)
- Basic knowledge of supply chain security

## Learning Objectives

By the end of this module, you will be able to:

### Knowledge Goals

1. **Understand ML pipeline security threats** including data poisoning via CI/CD, model stealing, and resource hijacking
2. **Master CI/CD security for ML** including secret management, signed commits, and automated security scanning
3. **Apply container security best practices** for ML workloads including minimal images, vulnerability scanning, and runtime security
4. **Implement dependency management** with vulnerability scanning, pinned versions, and private registries
5. **Understand supply chain security** including SLSA framework, SBOM generation, and provenance tracking

### Practical Skills

1. **Build secure CI/CD pipelines** with GitHub Actions including security scanning stages
2. **Harden container images** using distroless bases, multi-stage builds, and security contexts
3. **Scan dependencies** for vulnerabilities and manage them with lock files and hashes
4. **Generate and verify SBOMs** for ML artifacts using Syft and CycloneDX
5. **Sign and verify artifacts** using Sigstore/Cosign for keyless signing
6. **Deploy OPA Gatekeeper policies** to enforce security standards in Kubernetes
7. **Configure Falco** for runtime security monitoring of ML workloads
8. **Implement secure model registries** with authentication, signing, and audit trails

## Module Structure

### Lecture Notes (15 hours)

1. **CI/CD Security for ML** (5 hours)
   - ML pipeline security challenges and threat vectors
   - Secure CI/CD architecture for ML
   - Implementing secure GitHub Actions workflows
   - Secret management in CI/CD
   - GitOps for ML with ArgoCD

2. **Container Security** (4 hours)
   - Secure base images and multi-stage builds
   - Container image vulnerability scanning
   - Pod Security Standards and admission control
   - Runtime security with Falco
   - OPA Gatekeeper policies

3. **Dependency Vulnerability Scanning** (2 hours)
   - Python dependency scanning tools
   - Dependency pinning and lock files
   - Private PyPI mirrors
   - Automated scanning in CI/CD

4. **Supply Chain Security** (3 hours)
   - SLSA framework and levels
   - Software Bill of Materials (SBOM)
   - Sigstore for keyless signing
   - in-toto for build provenance
   - Dependency confusion prevention

5. **Secure Artifact Management** (2 hours)
   - MLflow model registry security
   - Model artifact signing and verification
   - Secure container registries (Harbor)
   - Image admission control with Kyverno

### Exercises (12-15 hours)

Four hands-on exercises:

1. **Secure CI/CD Pipeline Implementation** (4-5 hours)
   - Build GitHub Actions workflow with security scanning
   - Implement image signing with Cosign
   - Generate SBOMs
   - Deploy with GitOps and verification

2. **Container Security Hardening** (3-4 hours)
   - Create secure Dockerfile with distroless base
   - Configure Pod Security Standards
   - Deploy OPA Gatekeeper policies
   - Set up Falco runtime security

3. **Dependency Management and Supply Chain Security** (3-4 hours)
   - Implement dependency scanning
   - Create lock files with cryptographic hashes
   - Generate and verify SBOMs
   - Track build provenance with in-toto

4. **Secure Artifact Management** (2-3 hours)
   - Configure MLflow with authentication
   - Implement model signing and verification
   - Set up Harbor container registry
   - Deploy Kyverno image admission control

## Study Plan

### Week 1: CI/CD and Container Security (15 hours)

**Days 1-2: CI/CD Security (7 hours)**
- Read lecture notes section 1 (CI/CD Security)
- Watch GitHub Actions security tutorials
- Review MLflow security documentation
- Complete Exercise 1: Secure CI/CD Pipeline

**Days 3-4: Container Security (8 hours)**
- Read lecture notes section 2 (Container Security)
- Study Pod Security Standards
- Review Falco and OPA Gatekeeper docs
- Complete Exercise 2: Container Security Hardening

### Week 2: Supply Chain and Artifact Security (15 hours)

**Days 5-6: Dependency and Supply Chain (7 hours)**
- Read lecture notes sections 3-4 (Dependencies + Supply Chain)
- Study SLSA framework and SBOM specifications
- Review Sigstore/Cosign documentation
- Complete Exercise 3: Dependency Management

**Day 7: Artifact Management (4 hours)**
- Read lecture notes section 5 (Artifact Management)
- Review Harbor and Kyverno documentation
- Complete Exercise 4: Secure Artifact Management

**Weekend: Integration and Review (4 hours)**
- Build end-to-end secure ML pipeline
- Review all security controls
- Practice troubleshooting

## Key Concepts and Technologies

### Core Technologies

- **CI/CD**: GitHub Actions, GitLab CI, ArgoCD
- **Container Tools**: Docker, BuildKit, Kaniko
- **Security Scanning**: Trivy, Grype, Snyk
- **Supply Chain**: Sigstore, Cosign, Syft, in-toto
- **Policy Enforcement**: OPA Gatekeeper, Kyverno
- **Runtime Security**: Falco

### Security Frameworks

- **SLSA**: Supply-chain Levels for Software Artifacts
- **CycloneDX**: SBOM standard
- **SPDX**: Software Package Data Exchange
- **in-toto**: Supply chain integrity framework

### Best Practices

1. **Shift Security Left**: Scan early in development
2. **Defense in Depth**: Multiple security layers
3. **Least Privilege**: Minimal permissions everywhere
4. **Zero Trust**: Verify all artifacts
5. **Immutable Infrastructure**: Never modify running containers
6. **Complete Audit Trail**: Log all artifact operations

## Common Challenges and Solutions

### Challenge 1: CI/CD Performance with Security Scanning

**Problem**: Security scans add significant time to pipelines

**Solutions**:
- Run scans in parallel where possible
- Cache scan results and only re-scan changed dependencies
- Use incremental scanning
- Implement "fast fail" for critical issues

### Challenge 2: False Positives in Vulnerability Scanning

**Problem**: Many reported vulnerabilities are not exploitable in context

**Solutions**:
- Use VEX (Vulnerability Exploitability eXchange) to document non-applicable CVEs
- Implement suppression lists with justifications
- Focus on HIGH/CRITICAL vulnerabilities in production paths
- Regular triage meetings to review findings

### Challenge 3: Key Management for Signing

**Problem**: Managing private keys securely for artifact signing

**Solutions**:
- Use keyless signing with Sigstore (OIDC-based)
- Store keys in HSM or cloud KMS
- Implement key rotation policies
- Use ephemeral signing keys in CI/CD

### Challenge 4: Container Image Bloat

**Problem**: ML images are very large (10GB+) due to frameworks and dependencies

**Solutions**:
- Use multi-stage builds
- Layer caching strategies
- Distroless or minimal base images
- Separate training and inference images
- Use container registries with deduplication

## Hands-On Projects

### Project 1: Production ML Pipeline

Build complete secure ML pipeline:

- **GitHub Repository**: Branch protection, signed commits
- **CI/CD**: Multi-stage pipeline with security gates
- **Security Scanning**: Secrets, SAST, dependencies, containers
- **Artifact Signing**: Cosign for images, custom signing for models
- **SBOM Generation**: Complete software bill of materials
- **GitOps Deployment**: ArgoCD with verification
- **Monitoring**: Falco alerts, audit logs

### Project 2: Supply Chain Security Audit

Audit existing ML project for supply chain risks:

- **Dependency Analysis**: Map all dependencies and their origins
- **Vulnerability Assessment**: Scan for known vulnerabilities
- **SBOM Generation**: Create comprehensive SBOMs
- **Provenance Verification**: Verify artifact origins
- **Policy Gaps**: Identify missing security controls
- **Remediation Plan**: Prioritized action items

## Assessment Criteria

### Module Completion Requirements

1. **Lecture Notes**: Read all sections (15 hours)
2. **Exercises**: Complete all 4 exercises (12-15 hours)
3. **Project**: Build production ML pipeline (3 hours)
4. **Minimum Score**: 75% or higher

### Grading Rubric

**Advanced (90-100%)**
- All exercises with production-ready implementations
- Comprehensive security controls at every stage
- Full automation of security checks
- Complete audit trail and monitoring
- Excellent documentation with diagrams

**Proficient (75-89%)**
- Core functionality working correctly
- Good security practices implemented
- Some automation of security checks
- Basic monitoring and logging
- Clear documentation

**Developing (60-74%)**
- Most requirements met
- Basic security controls in place
- Manual processes acceptable
- Limited monitoring
- Minimal documentation

**Needs Improvement (<60%)**
- Incomplete implementations
- Security vulnerabilities present
- No automation
- Poor documentation

## Additional Resources

### Official Documentation

- **SLSA Framework**: https://slsa.dev/
- **Sigstore**: https://www.sigstore.dev/
- **CycloneDX**: https://cyclonedx.org/
- **OPA Gatekeeper**: https://open-policy-agent.github.io/gatekeeper/
- **Falco**: https://falco.org/docs/

### Tools & Libraries

- **Trivy**: Container and dependency scanner
- **Cosign**: Container image signing
- **Syft**: SBOM generation tool
- **Grype**: Vulnerability scanner
- **kube-linter**: Kubernetes YAML linter

### Books & Articles

- "Supply Chain Security" by O'Reilly
- "Container Security" by Liz Rice
- "Building Secure & Reliable Systems" - Chapter 14
- CNCF Software Supply Chain Best Practices

### Online Courses

- "Supply Chain Security" by Linux Foundation
- "Kubernetes Security" by Cloud Native Computing Foundation
- "DevSecOps Foundation" certification

## Next Steps

After completing this module:

1. **Practice**: Set up secure CI/CD for your projects
2. **Automate**: Implement security scanning in all pipelines
3. **Monitor**: Deploy Falco and review alerts
4. **Document**: Create supply chain security policies
5. **Advance**: Proceed to Module 6 (Network Security for ML)

---

**Module Authors**: AI Infrastructure Security Team
**Last Updated**: 2025-11-02
**Version**: 1.0
