# Module 5: Secure ML Pipelines - Exercises

## Overview

These exercises provide hands-on experience securing ML pipelines through CI/CD security, container hardening, dependency scanning, supply chain security, and secure artifact management.

**Total Time**: 12-15 hours
**Prerequisites**:
- Docker and Kubernetes access
- GitHub account (for GitHub Actions)
- Basic understanding of CI/CD concepts

---

## Exercise 1: Secure CI/CD Pipeline Implementation

**Time**: 4-5 hours
**Difficulty**: Advanced

### Objectives

- Implement secure GitHub Actions workflow for ML pipeline
- Add automated security scanning (secrets, SAST, dependencies, containers)
- Configure signed commits and image signing with Cosign
- Generate and verify SBOMs
- Implement GitOps deployment with ArgoCD

### Tasks

**Part 1: Repository Security Configuration (1 hour)**

1. Enable branch protection on `main` branch:
   - Require 2 approvals for pull requests
   - Require status checks to pass
   - Require signed commits
   - Disable force pushes

2. Set up required secrets in GitHub:
   - `MLFLOW_TRACKING_URI`
   - `VAULT_ADDR`, `VAULT_ROLE_ID`, `VAULT_SECRET_ID`
   - Container registry credentials

**Part 2: Security Scanning Pipeline (2 hours)**

3. Create `.github/workflows/security-scan.yml`:
   - Secret scanning with TruffleHog
   - SAST with Semgrep
   - Python dependency scanning with pip-audit
   - License compliance checking

4. Create `.github/workflows/build-sign.yml`:
   - Build container image with BuildKit
   - Scan image with Trivy (fail on HIGH/CRITICAL)
   - Sign image with Cosign (keyless)
   - Generate SBOM with Syft
   - Push to ghcr.io

**Part 3: ML Training with Security (1.5 hours)**

5. Implement secure training pipeline:
   - Validate training data checksums
   - Fetch secrets from Vault
   - Sign model artifacts
   - Log provenance metadata to MLflow

6. Add resource limits and security contexts to training pods

**Part 4: Deployment with Verification (1.5 hours)**

7. Create deployment workflow:
   - Verify image signature before deployment
   - Run policy checks with OPA
   - Deploy to staging with automated tests
   - Require manual approval for production

### Success Criteria

- [ ] All security scans pass in CI/CD
- [ ] Container images signed with Cosign
- [ ] SBOM generated for all artifacts
- [ ] No secrets hardcoded or committed
- [ ] Image vulnerabilities below threshold
- [ ] Deployment requires signature verification
- [ ] Manual approval required for production

### Deliverables

1. `.github/workflows/` directory with:
   - `security-scan.yml`
   - `build-sign.yml`
   - `deploy.yml`

2. `scripts/` directory with:
   - `secure_training.py`
   - `verify_deployment.py`

3. Documentation:
   - Pipeline architecture diagram
   - Security controls explanation
   - Runbook for incidents

---

## Exercise 2: Container Security Hardening

**Time**: 3-4 hours
**Difficulty**: Intermediate

### Objectives

- Create secure Dockerfile with minimal base image
- Implement multi-stage builds
- Configure Pod Security Standards
- Deploy OPA Gatekeeper policies
- Set up Falco runtime security

### Tasks

**Part 1: Secure Dockerfile (1 hour)**

1. Create `Dockerfile.secure`:
   - Start with distroless Python base image
   - Use multi-stage build to exclude build tools
   - Run as non-root user (UID 1000)
   - Set read-only root filesystem
   - Pin all dependency versions

2. Build and scan image:
   ```bash
   docker build -f Dockerfile.secure -t ml-trainer:secure .
   trivy image --severity HIGH,CRITICAL ml-trainer:secure
   ```

**Part 2: Kubernetes Security Policies (1 hour)**

3. Create `k8s/secure-pod.yaml` with:
   - `runAsNonRoot: true`
   - `allowPrivilegeEscalation: false`
   - `readOnlyRootFilesystem: true`
   - Drop all capabilities
   - Resource limits (CPU, memory, GPU)
   - Seccomp profile

4. Deploy and verify:
   ```bash
   kubectl apply -f k8s/secure-pod.yaml
   kubectl get pod ml-trainer -o jsonpath='{.spec.securityContext}'
   ```

**Part 3: OPA Gatekeeper Policies (1 hour)**

5. Create OPA policies:
   - `require-nonroot.yaml` - Enforce non-root containers
   - `block-privileged.yaml` - Block privileged containers
   - `require-ro-filesystem.yaml` - Require read-only root filesystem

6. Install and test policies:
   ```bash
   kubectl apply -f opa-policies/
   # Try to deploy privileged pod (should fail)
   kubectl apply -f k8s/bad-pod.yaml
   ```

**Part 4: Falco Runtime Security (1 hour)**

7. Install Falco with Helm:
   ```bash
   helm install falco falcosecurity/falco \
     --set falcosidekick.enabled=true
   ```

8. Create custom Falco rules for ML workloads:
   - Detect unauthorized processes in ML containers
   - Alert on sensitive file access
   - Detect crypto mining activity

9. Generate and review alerts:
   ```bash
   # Trigger an alert by running suspicious command in container
   kubectl exec -it ml-trainer -- curl http://malicious.com
   # Check Falco logs
   kubectl logs -n falco -l app=falco
   ```

### Success Criteria

- [ ] Container image has zero HIGH/CRITICAL vulnerabilities
- [ ] Pod runs as non-root user
- [ ] Read-only root filesystem enforced
- [ ] OPA policies block insecure pod configurations
- [ ] Falco alerts on suspicious container activity
- [ ] Resource limits prevent resource exhaustion

### Deliverables

1. `Dockerfile.secure` - Hardened container image
2. `k8s/` directory with:
   - `secure-pod.yaml`
   - `network-policy.yaml`
3. `opa-policies/` directory with ConstraintTemplates
4. `falco-rules/ml-security.yaml`
5. Security testing report

---

## Exercise 3: Dependency Management and Supply Chain Security

**Time**: 3-4 hours
**Difficulty**: Intermediate

### Objectives

- Implement comprehensive dependency scanning
- Create dependency lock files with hashes
- Set up private PyPI mirror
- Generate and verify SBOMs
- Implement provenance tracking with in-toto

### Tasks

**Part 1: Dependency Scanning (1 hour)**

1. Create `scripts/scan-dependencies.py`:
   - Run pip-audit for known vulnerabilities
   - Check Safety database
   - Generate vulnerability report
   - Fail build if HIGH/CRITICAL found

2. Add to CI/CD pipeline:
   ```yaml
   - name: Scan dependencies
     run: python scripts/scan-dependencies.py
   ```

**Part 2: Dependency Pinning (1 hour)**

3. Create `requirements.in` with unpinned versions:
   ```txt
   torch>=2.0.0
   transformers
   scikit-learn
   ```

4. Generate locked requirements with hashes:
   ```bash
   pip-compile --generate-hashes --output-file=requirements.txt requirements.in
   ```

5. Verify installation uses only pinned+hashed packages:
   ```bash
   pip install --require-hashes -r requirements.txt
   ```

**Part 3: SBOM Generation (1 hour)**

6. Generate SBOMs:
   ```bash
   # For source code
   syft dir:. -o cyclonedx-json > sbom-source.json

   # For container image
   syft ghcr.io/company/ml-trainer:v1.0 -o spdx-json > sbom-image.json

   # Attach SBOM to container image
   cosign attach sbom --sbom sbom-image.json ghcr.io/company/ml-trainer:v1.0
   ```

7. Verify SBOM attestation:
   ```bash
   cosign verify-attestation \
     --type cyclonedx \
     ghcr.io/company/ml-trainer:v1.0
   ```

**Part 4: Build Provenance (1 hour)**

8. Implement in-toto layout:
   - Create `in-toto-layout.json` defining build steps
   - Generate link metadata for each step
   - Verify complete build chain

9. Add provenance to GitHub Actions:
   ```yaml
   - uses: actions/attest-build-provenance@v1
     with:
       subject-path: 'model.pkl'
   ```

### Success Criteria

- [ ] All dependencies scanned for vulnerabilities
- [ ] Dependencies pinned with cryptographic hashes
- [ ] SBOM generated for all artifacts
- [ ] Build provenance tracked end-to-end
- [ ] No high-severity vulnerabilities in dependencies
- [ ] Reproducible builds (same inputs → same outputs)

### Deliverables

1. `scripts/scan-dependencies.py`
2. `requirements.txt` (with hashes)
3. `sbom-source.json`, `sbom-image.json`
4. `in-toto-layout.json`
5. Supply chain security report

---

## Exercise 4: Secure Artifact Management

**Time**: 2-3 hours
**Difficulty**: Advanced

### Objectives

- Configure MLflow with authentication
- Implement model signing and verification
- Set up Harbor container registry with RBAC
- Deploy Kyverno for image admission control
- Create artifact audit trail

### Tasks

**Part 1: Secure MLflow Registry (1 hour)**

1. Deploy MLflow with authentication:
   ```bash
   docker run -d -p 5000:5000 \
     -e MLFLOW_AUTH_CONFIG_PATH=/config/basic_auth.ini \
     ghcr.io/mlflow/mlflow:latest
   ```

2. Implement `SecureModelRegistry` class:
   - Authenticate with MLflow using credentials from Vault
   - Add security metadata tags (git commit, pipeline ID, approval)
   - Require approval ticket for production promotion

3. Register and promote model:
   ```python
   registry = SecureModelRegistry()
   version = registry.register_model(
       run_id="abc123",
       model_name="fraud-detection",
       tags={"compliance": "SOC2"}
   )
   registry.promote_to_production(
       model_name="fraud-detection",
       version=version,
       approval_ticket="SEC-1234"
   )
   ```

**Part 2: Model Signing (1 hour)**

4. Implement `ModelSigner` class:
   - Generate RSA key pair for signing
   - Sign model with private key (RSA-PSS-SHA256)
   - Generate signature file with metadata
   - Verify signature before deployment

5. Integrate with training pipeline:
   ```python
   # After training
   signer = ModelSigner(private_key_path="keys/model-signing-key.pem")
   signer.sign_model("fraud_detection_model.pkl")

   # Before deployment
   if not signer.verify_model("model.pkl", "model.pkl.sig"):
       raise ValueError("Signature verification failed")
   ```

**Part 3: Container Registry Security (30 minutes)**

6. Deploy Harbor with:
   - RBAC (different roles for ML team, security team, production deploy)
   - Vulnerability scanning on push
   - Content trust (Notary/Cosign)
   - Audit logging

7. Configure image retention policy:
   - Keep last 10 versions of each image
   - Delete untagged images after 7 days

**Part 4: Image Admission Control (30 minutes)**

8. Deploy Kyverno:
   ```bash
   helm install kyverno kyverno/kyverno --namespace kyverno --create-namespace
   ```

9. Create policy `verify-ml-image-signatures.yaml`:
   - Verify image signatures for ml-* namespaces
   - Only allow images from approved registries
   - Require specific labels (team, compliance)

10. Test policy enforcement:
    ```bash
    # Try to deploy unsigned image (should fail)
    kubectl apply -f k8s/unsigned-pod.yaml
    ```

### Success Criteria

- [ ] MLflow requires authentication
- [ ] Models signed before registration
- [ ] Signature verification before deployment
- [ ] Harbor enforces RBAC and scans images
- [ ] Kyverno blocks unsigned/unapproved images
- [ ] Complete audit trail for all artifacts

### Deliverables

1. `src/secure_model_registry.py`
2. `src/model_signing.py`
3. `harbor/config.yaml`
4. `kyverno-policies/verify-image-signature.yaml`
5. Artifact security architecture diagram

---

## Additional Resources

### Tools

- **Trivy**: https://github.com/aquasecurity/trivy
- **Cosign**: https://github.com/sigstore/cosign
- **Syft**: https://github.com/anchore/syft
- **Falco**: https://falco.org/
- **OPA Gatekeeper**: https://open-policy-agent.github.io/gatekeeper/
- **Kyverno**: https://kyverno.io/

### Documentation

- **GitHub Actions Security**: https://docs.github.com/en/actions/security-guides
- **SLSA Framework**: https://slsa.dev/
- **CycloneDX SBOM**: https://cyclonedx.org/
- **in-toto**: https://in-toto.io/

### Best Practices

1. **Shift left**: Catch security issues early in development
2. **Defense in depth**: Multiple layers of security controls
3. **Least privilege**: Minimal permissions for all components
4. **Zero trust**: Verify everything, trust nothing
5. **Immutable infrastructure**: Never modify running containers
6. **Audit everything**: Complete trail of all artifact access

---

## Assessment Rubric

**Advanced (90-100%)**
- All exercises completed with production-ready implementations
- Comprehensive security controls at every pipeline stage
- Automated scanning and enforcement
- Complete audit trail and monitoring
- Well-documented security architecture

**Proficient (75-89%)**
- Core functionality working in all exercises
- Good security practices implemented
- Some automation of security checks
- Basic monitoring configured
- Clear documentation

**Developing (60-74%)**
- Most exercises completed
- Basic security controls in place
- Manual security processes acceptable
- Limited monitoring
- Minimal documentation

**Needs Improvement (<60%)**
- Incomplete implementations
- Security vulnerabilities present
- No automation
- Poor documentation
