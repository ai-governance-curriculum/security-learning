# Module 4: Secrets & Identity Management

## Module Overview

This module focuses on secure secrets management, identity and access management (IAM), and certificate lifecycle automation for AI/ML infrastructure. You'll learn to implement enterprise-grade secrets management using HashiCorp Vault, design least-privilege IAM policies, and automate certificate management with PKI.

**Duration**: 20 hours (theory + practice)
**Level**: Intermediate to Advanced
**Prerequisites**:
- Completed Modules 1-3
- Understanding of public key infrastructure (PKI) basics
- Familiarity with cloud IAM concepts
- Basic cryptography knowledge (symmetric/asymmetric encryption)

## Learning Objectives

By the end of this module, you will be able to:

### Knowledge Goals

1. **Understand secrets management architectures** including centralized secrets stores, dynamic credentials, and secret rotation strategies
2. **Master HashiCorp Vault** for ML infrastructure including authentication methods, secrets engines, and policies
3. **Design secure IAM policies** following least-privilege principles for AWS, Azure, and GCP
4. **Implement PKI and certificate management** including root/intermediate CAs, certificate issuance, and automated rotation
5. **Apply identity federation** patterns including OIDC, SAML, and service mesh identity

### Practical Skills

1. **Deploy and configure HashiCorp Vault** in production mode with HA, unsealing, and backup strategies
2. **Implement dynamic secrets** for databases, cloud providers (AWS/Azure/GCP), and SSH
3. **Build API key management systems** with secure generation, validation, and rotation
4. **Automate certificate lifecycle** including issuance, renewal, and revocation using Vault PKI
5. **Configure mTLS** for ML service-to-service authentication
6. **Set up Kubernetes RBAC** and service accounts with proper security boundaries
7. **Monitor secrets access** using audit logs and metrics

## Module Structure

### Lecture Notes (8 hours)

The lecture notes cover:

1. **Secrets Management Fundamentals** (3 hours)
   - What qualifies as a secret vs. configuration
   - Common anti-patterns (hardcoding, environment variables, config files)
   - Centralized secrets management architecture
   - Secrets lifecycle: generation, distribution, rotation, revocation

2. **HashiCorp Vault Deep Dive** (8 hours)
   - Vault architecture: storage backend, barrier, secrets engines
   - Authentication methods: AppRole, AWS IAM, Kubernetes, OIDC
   - Secrets engines: KV v2, Database, AWS, Transit, PKI
   - Dynamic secrets for PostgreSQL, MySQL, AWS, Azure
   - Vault policies: path-based access control, capabilities
   - High availability and disaster recovery
   - Vault Agent for automatic secret injection

3. **Cloud Provider Secrets Management** (4 hours)
   - AWS Secrets Manager: automatic rotation, Lambda integration
   - AWS Systems Manager Parameter Store: hierarchical parameters
   - Azure Key Vault: secrets, keys, certificates management
   - GCP Secret Manager: versioning, IAM integration
   - Integration patterns with ML workloads

4. **Identity and Access Management** (3 hours)
   - IAM principles: least privilege, separation of duties, defense in depth
   - Designing IAM policies for ML workflows (training, inference, data access)
   - IAM Roles for Service Accounts (IRSA) in Kubernetes
   - Kubernetes RBAC: Roles, RoleBindings, ClusterRoles
   - Network policies for pod-to-pod communication
   - API key management: generation, storage, rotation

5. **Certificate Management and PKI** (2 hours)
   - PKI fundamentals: root CA, intermediate CA, certificate chain
   - X.509 certificates: common name, SANs, validity period
   - Vault PKI engine: CA hierarchy, certificate roles
   - Automated certificate issuance and renewal
   - mTLS for service authentication
   - Certificate monitoring and alerting

### Exercises (10-13 hours)

Four comprehensive hands-on exercises:

1. **HashiCorp Vault Integration for ML Pipelines** (3-4 hours)
   - Set up Vault with AppRole authentication
   - Store and retrieve ML secrets (API keys, DB credentials)
   - Build Vault client library with automatic token renewal
   - Integrate with ML training pipeline
   - Implement secret rotation handling

2. **Dynamic Secrets and Credential Management** (3-4 hours)
   - Configure Vault database secrets engine
   - Implement dynamic PostgreSQL credentials with lease renewal
   - Set up AWS dynamic credentials for S3 access
   - Build monitoring for credential lifecycle
   - Audit credential access patterns

3. **IAM Policy Management and API Key Security** (2-3 hours)
   - Design least-privilege IAM policies for ML workloads
   - Build IAM policy validator to detect security issues
   - Implement secure API key generation with high entropy
   - Create API key store in Vault with metadata
   - Set up Kubernetes RBAC for ML services

4. **Certificate Lifecycle Automation** (2-3 hours)
   - Configure Vault PKI with root and intermediate CAs
   - Build certificate manager for automated issuance
   - Implement certificate rotation daemon
   - Configure mTLS between ML services
   - Monitor certificate expiration

### Assessment (2 hours)

- Practical exam: Secure ML infrastructure deployment
- Security review of secrets management implementation
- Policy design evaluation

## Study Plan

### Week 1: Secrets Management Foundations (10 hours)

**Days 1-2: Theory (4 hours)**
- Read lecture notes sections 1-2 (Secrets Management + HashiCorp Vault)
- Watch HashiCorp Vault getting started tutorials
- Review Vault architecture documentation

**Days 3-4: Hands-on (6 hours)**
- Complete Exercise 1: HashiCorp Vault Integration
- Deploy Vault in dev and production modes
- Build Python Vault client with token renewal
- Integrate Vault with sample ML pipeline

### Week 2: Dynamic Credentials & IAM (10 hours)

**Days 5-6: Theory (4 hours)**
- Read lecture notes sections 3-4 (Cloud Secrets + IAM)
- Study AWS Secrets Manager documentation
- Review IAM best practices for ML workloads

**Days 7-8: Hands-on (6 hours)**
- Complete Exercise 2: Dynamic Secrets
- Complete Exercise 3: IAM Policy Management
- Implement dynamic database credentials
- Build API key management system
- Configure Kubernetes RBAC

### Weekend: Certificate Management (6 hours)

**Theory (2 hours)**
- Read lecture notes section 5 (PKI + Certificates)
- Review X.509 certificate specifications
- Study Vault PKI engine documentation

**Hands-on (4 hours)**
- Complete Exercise 4: Certificate Lifecycle Automation
- Set up Vault PKI hierarchy
- Implement certificate rotation
- Configure mTLS for services

## Key Concepts and Technologies

### Core Technologies

- **HashiCorp Vault**: Centralized secrets management platform
- **AWS Secrets Manager**: AWS-native secrets management service
- **Azure Key Vault**: Azure secrets, keys, and certificates service
- **GCP Secret Manager**: Google Cloud secrets management
- **PKI**: Public Key Infrastructure for certificate management
- **mTLS**: Mutual TLS for service authentication

### Programming & Tools

- **Python**: hvac (Vault client), boto3 (AWS), azure-identity
- **OpenSSL**: Certificate generation and inspection
- **Kubernetes RBAC**: Role-based access control
- **Prometheus**: Metrics for secrets and certificate monitoring

### Security Patterns

- **Dynamic Secrets**: Short-lived credentials generated on-demand
- **Least Privilege IAM**: Grant minimum necessary permissions
- **Certificate Rotation**: Automated renewal before expiration
- **Secret Versioning**: Track secret changes and enable rollback
- **Audit Logging**: Monitor all secrets access

## Hands-On Projects

### Project 1: Production-Ready Secrets Management

Build a complete secrets management system:

- **Vault Cluster**: 3-node HA Vault cluster with Consul backend
- **Authentication**: AppRole for apps, Kubernetes auth for pods
- **Secrets Engines**: KV v2 for static secrets, Database for dynamic credentials
- **Integration**: Python library for seamless Vault integration in ML pipelines
- **Monitoring**: Prometheus metrics and Grafana dashboards
- **Disaster Recovery**: Backup and restore procedures

### Project 2: Zero-Trust ML Platform

Implement zero-trust security for ML platform:

- **mTLS Everywhere**: Service mesh (Istio/Linkerd) with mTLS
- **Dynamic Credentials**: All services use short-lived credentials (1-24 hours)
- **Network Policies**: Kubernetes network segmentation
- **RBAC**: Fine-grained permissions for ML workloads
- **Certificate Automation**: Vault PKI with auto-rotation
- **Audit**: Centralized audit logging with SIEM integration

## Common Challenges and Solutions

### Challenge 1: Vault Unsealing in Production

**Problem**: Vault starts sealed, requiring unseal keys to become operational

**Solutions**:
- Use auto-unseal with cloud KMS (AWS KMS, Azure Key Vault, GCP Cloud KMS)
- Implement distributed unseal with Shamir secret sharing (threshold scheme)
- Use Vault Agent for automatic re-authentication after restarts

### Challenge 2: Secret Rotation Without Downtime

**Problem**: Rotating secrets can break active connections

**Solutions**:
- Implement grace periods: keep old secret valid for short overlap
- Use connection pools that can refresh credentials
- Support multiple valid credentials simultaneously
- Test rotation in staging environment first

### Challenge 3: Certificate Expiration Incidents

**Problem**: Certificates expire, causing service outages

**Solutions**:
- Set alerts at 30, 14, 7, and 1 days before expiration
- Automate rotation at 20% of certificate lifetime
- Monitor certificate validity in health checks
- Implement certificate renewal daemon with retries

### Challenge 4: Over-Permissive IAM Policies

**Problem**: IAM policies grant excessive permissions, violating least privilege

**Solutions**:
- Use IAM policy validator tools (AWS Access Analyzer)
- Start with deny-all, explicitly grant needed permissions
- Regular IAM policy audits and reviews
- Implement policy-as-code with version control
- Use condition keys to restrict access (MFA, source IP, tags)

### Challenge 5: Secrets in CI/CD Pipelines

**Problem**: Need secrets in CI/CD without hardcoding

**Solutions**:
- Use OIDC federation (GitHub Actions OIDC → AWS/Vault)
- Vault Agent in CI runners for automatic authentication
- Short-lived credentials (< 1 hour) for CI jobs
- Separate roles for CI vs. production
- Audit all CI secrets access

## Assessment Criteria

### Module Completion Requirements

To successfully complete this module, you must:

1. **Lecture Notes**: Read and understand all sections (8 hours)
2. **Exercises**: Complete all 4 exercises with passing grade (10-13 hours)
3. **Final Exam**: Pass practical assessment (2 hours)
4. **Minimum Score**: 75% or higher

### Grading Rubric

**Advanced (90-100%)**
- All exercises completed with production-ready implementations
- Comprehensive error handling and retry logic
- Monitoring and alerting configured
- Security best practices followed throughout
- Detailed documentation with architecture diagrams
- Advanced features implemented (HA Vault, auto-rotation, mTLS)

**Proficient (75-89%)**
- Core functionality working correctly in all exercises
- Basic error handling implemented
- Monitoring configured
- Good security practices
- Clear documentation
- Some advanced features

**Developing (60-74%)**
- Basic requirements met in most exercises
- Manual processes acceptable
- Limited monitoring
- Some security issues present
- Minimal documentation
- Advanced features attempted but incomplete

**Needs Improvement (<60%)**
- Incomplete implementations
- Significant security vulnerabilities
- No monitoring or automation
- Poor documentation
- Module incomplete

### Practical Exam

The 2-hour practical exam includes:

1. **Vault Setup (30 minutes)**
   - Deploy Vault in production mode
   - Configure authentication and policies
   - Set up secrets engines

2. **Secrets Integration (30 minutes)**
   - Integrate Vault with sample application
   - Implement dynamic database credentials
   - Add secret rotation

3. **IAM & Certificates (30 minutes)**
   - Design IAM policies for ML workload
   - Configure Vault PKI
   - Issue and validate certificates

4. **Security Review (30 minutes)**
   - Identify security issues in provided code
   - Propose fixes and improvements
   - Document security recommendations

## Additional Resources

### Official Documentation

- **HashiCorp Vault**: https://www.vaultproject.io/docs
- **AWS Secrets Manager**: https://docs.aws.amazon.com/secretsmanager/
- **Azure Key Vault**: https://docs.microsoft.com/en-us/azure/key-vault/
- **Kubernetes RBAC**: https://kubernetes.io/docs/reference/access-authn-authz/rbac/

### Books

- "Cybersecurity for AI Systems" - Chapter on Secrets Management
- "Building Secure & Reliable Systems" (O'Reilly) - Chapters 6-7
- "Kubernetes Security" (O'Reilly) - Chapter 8: Secrets Management

### Online Courses

- HashiCorp Vault Associate Certification prep
- AWS Certified Security - Specialty (Secrets Manager section)
- "Kubernetes Security Best Practices" course

### Tools & Libraries

- **hvac**: Python client for HashiCorp Vault
- **git-secrets**: Prevent committing secrets to git
- **detect-secrets**: Detect secrets in code repositories
- **Vault Agent**: Automatic authentication and secret injection
- **External Secrets Operator**: Sync Vault secrets to Kubernetes

### Community

- HashiCorp Discuss forum
- r/vaultproject subreddit
- CNCF Security TAG meetings
- Local security meetups

## Next Steps

After completing this module, you should:

1. **Practice**: Set up Vault in your lab environment
2. **Integrate**: Add Vault to your existing ML projects
3. **Automate**: Build secrets rotation automation
4. **Monitor**: Set up secrets and certificate monitoring
5. **Advance**: Proceed to Module 5 (Secure ML Pipelines)

## Questions and Discussion

Join our community discussion on:
- Best practices for secrets rotation in ML pipelines
- Production Vault deployment patterns
- Certificate management strategies
- IAM policy design for ML workloads

---

**Module Authors**: AI Infrastructure Security Team
**Last Updated**: 2025-11-02
**Version**: 1.0
