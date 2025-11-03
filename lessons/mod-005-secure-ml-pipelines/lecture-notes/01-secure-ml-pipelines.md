# Secure ML Pipelines

## Table of Contents

1. [CI/CD Security for ML](#cicd-security-for-ml)
2. [Container Security](#container-security)
3. [Dependency Vulnerability Scanning](#dependency-vulnerability-scanning)
4. [Supply Chain Security](#supply-chain-security)
5. [Secure Artifact Management](#secure-artifact-management)

---

## 1. CI/CD Security for ML

### 1.1 ML Pipeline Security Challenges

ML pipelines differ from traditional software pipelines in several key ways:

**Unique ML Pipeline Characteristics**:
- **Data as code**: Training data quality directly affects model security
- **Model artifacts**: Binary model files need secure storage and versioning
- **Experiment tracking**: MLflow, Weights & Biases store sensitive metadata
- **Computational resources**: GPU clusters are expensive targets for cryptomining
- **Long-running jobs**: Training jobs may run for days, increasing attack surface
- **Non-deterministic outputs**: Models may behave differently each run

**ML-Specific Threat Vectors**:

1. **Data Poisoning via CI/CD**
   - Attacker injects malicious training data through compromised pipeline
   - Backdoored model pushed to production
   - Example: Compromised data validation step allows poisoned samples

2. **Model Stealing**
   - Unauthorized access to trained models in artifact storage
   - Model extraction via compromised MLflow server
   - Example: Leaked AWS credentials expose S3 bucket with all models

3. **Resource Hijacking**
   - Kubernetes cluster used for cryptocurrency mining
   - Training jobs modified to exfiltrate data
   - Example: Modified Docker image includes cryptominer

4. **Credential Theft**
   - ML pipelines often need access to data lakes, model registries, cloud resources
   - Compromised pipeline exposes credentials to attacker
   - Example: Hardcoded AWS keys in training script pushed to GitHub

### 1.2 Secure CI/CD Pipeline Architecture

**Reference Architecture**:

```
┌─────────────────────────────────────────────────────────────────┐
│                     Developer Workstation                        │
│  ┌────────────┐      ┌────────────┐      ┌────────────┐        │
│  │ Code       │      │ Data       │      │ Model      │        │
│  │ Changes    │      │ Validation │      │ Config     │        │
│  └──────┬─────┘      └──────┬─────┘      └──────┬─────┘        │
│         │                   │                    │              │
└─────────┼───────────────────┼────────────────────┼──────────────┘
          │                   │                    │
          v                   v                    v
┌─────────────────────────────────────────────────────────────────┐
│                        Git Repository                            │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  Branch Protection:                                      │   │
│  │  - Require signed commits                                │   │
│  │  - 2+ approvals for merge                                │   │
│  │  - Status checks must pass                               │   │
│  │  - No force pushes                                       │   │
│  └─────────────────────────────────────────────────────────┘   │
└──────────────────────────┬───────────────────────────────────────┘
                           │ Webhook (TLS + HMAC signature)
                           v
┌─────────────────────────────────────────────────────────────────┐
│                      CI/CD Platform (GitHub Actions/GitLab CI)   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Stage 1: Security Checks (Run in isolated environment)  │  │
│  │  ├─ Secret scanning (git-secrets, trufflehog)            │  │
│  │  ├─ SAST (Semgrep, Bandit for Python)                    │  │
│  │  ├─ Dependency scanning (Safety, pip-audit)              │  │
│  │  ├─ License compliance check                             │  │
│  │  └─ Container image scanning (Trivy, Grype)              │  │
│  └──────────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Stage 2: Build & Test (Ephemeral runner)                │  │
│  │  ├─ Build container image with kaniko/buildah            │  │
│  │  ├─ Sign image with Sigstore/Cosign                      │  │
│  │  ├─ Run unit tests                                       │  │
│  │  ├─ Generate SBOM (Syft)                                 │  │
│  │  └─ Push to container registry                           │  │
│  └──────────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Stage 3: ML Training (Isolated namespace)               │  │
│  │  ├─ Fetch training data (validate checksums)             │  │
│  │  ├─ Data validation (Great Expectations)                 │  │
│  │  ├─ Train model with resource limits                     │  │
│  │  ├─ Model validation (performance, fairness, security)   │  │
│  │  ├─ Sign model artifacts                                 │  │
│  │  └─ Upload to model registry                             │  │
│  └──────────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Stage 4: Deployment (GitOps)                            │  │
│  │  ├─ Verify image signature                               │  │
│  │  ├─ Run security policy checks (OPA)                     │  │
│  │  ├─ Deploy to staging                                    │  │
│  │  ├─ Automated integration tests                          │  │
│  │  ├─ Promote to production (manual approval)              │  │
│  │  └─ Audit log entry                                      │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

### 1.3 Implementing Secure ML CI/CD

**Step 1: Repository Security**

```yaml
# .github/branch_protection.yaml
# Applied via GitHub API or Terraform
branch_protection_rules:
  - branch: "main"
    required_approving_review_count: 2
    require_code_owner_reviews: true
    dismiss_stale_reviews: true
    require_signed_commits: true
    required_status_checks:
      - "security-scan"
      - "unit-tests"
      - "data-validation"
    restrictions:
      push: []  # Nobody can push directly
      force_push: false
      delete: false
```

**Step 2: Secret Management**

```yaml
# .github/workflows/ml-pipeline.yml
name: Secure ML Pipeline

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

env:
  # Never hardcode secrets!
  # Use GitHub Actions secrets or OIDC with cloud providers
  MLFLOW_TRACKING_URI: ${{ secrets.MLFLOW_URI }}

jobs:
  security-scan:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      security-events: write

    steps:
      - name: Checkout code
        uses: actions/checkout@v3
        with:
          fetch-depth: 0  # Full history for secret scanning

      - name: Secret scanning
        uses: trufflesecurity/trufflehog@main
        with:
          path: ./
          base: ${{ github.event.repository.default_branch }}
          head: HEAD

      - name: SAST with Semgrep
        uses: returntocorp/semgrep-action@v1
        with:
          config: >-
            p/security-audit
            p/secrets
            p/python
            p/ml

      - name: Python security check
        run: |
          pip install bandit safety
          bandit -r src/ -f json -o bandit-report.json
          safety check --json > safety-report.json

      - name: Upload security reports
        uses: github/codeql-action/upload-sarif@v2
        with:
          sarif_file: bandit-report.json
```

**Step 3: Secure Build Process**

```yaml
  build-and-sign:
    runs-on: ubuntu-latest
    needs: security-scan
    permissions:
      contents: read
      packages: write
      id-token: write  # For Sigstore

    steps:
      - name: Checkout
        uses: actions/checkout@v3

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2

      - name: Login to GHCR
        uses: docker/login-action@v2
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Install Cosign
        uses: sigstore/cosign-installer@main

      - name: Build image with BuildKit
        id: build
        uses: docker/build-push-action@v4
        with:
          context: .
          file: ./Dockerfile
          push: true
          tags: ghcr.io/${{ github.repository }}/ml-trainer:${{ github.sha }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
          build-args: |
            BUILD_DATE=${{ github.event.head_commit.timestamp }}
            VCS_REF=${{ github.sha }}
            VERSION=${{ github.ref_name }}

      - name: Sign image with Cosign
        env:
          COSIGN_EXPERIMENTAL: "true"
        run: |
          cosign sign --yes \
            ghcr.io/${{ github.repository }}/ml-trainer:${{ github.sha }}

      - name: Generate SBOM
        uses: anchore/sbom-action@v0
        with:
          image: ghcr.io/${{ github.repository }}/ml-trainer:${{ github.sha }}
          format: cyclonedx-json
          output-file: sbom.cyclonedx.json

      - name: Scan image with Trivy
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: ghcr.io/${{ github.repository }}/ml-trainer:${{ github.sha }}
          format: 'sarif'
          output: 'trivy-results.sarif'
          severity: 'CRITICAL,HIGH'

      - name: Upload Trivy results
        uses: github/codeql-action/upload-sarif@v2
        with:
          sarif_file: 'trivy-results.sarif'
```

**Step 4: ML Training with Security**

```python
# src/secure_training.py
import hashlib
import os
import json
from pathlib import Path
from typing import Dict, Any
import mlflow
import hvac  # Vault client

class SecureMLTrainer:
    """
    ML trainer with security best practices
    """

    def __init__(self, config: Dict[str, Any]):
        self.config = config
        self.vault_client = self._init_vault()
        self._validate_environment()

    def _init_vault(self) -> hvac.Client:
        """Initialize Vault client for secrets"""
        vault_addr = os.environ.get('VAULT_ADDR')
        vault_role = os.environ.get('VAULT_ROLE_ID')
        vault_secret = os.environ.get('VAULT_SECRET_ID')

        if not all([vault_addr, vault_role, vault_secret]):
            raise ValueError("Vault credentials not configured")

        client = hvac.Client(url=vault_addr)
        client.auth.approle.login(
            role_id=vault_role,
            secret_id=vault_secret
        )
        return client

    def _validate_environment(self):
        """Validate the execution environment is secure"""
        # Check we're running in expected namespace
        namespace_file = Path("/var/run/secrets/kubernetes.io/serviceaccount/namespace")
        if namespace_file.exists():
            namespace = namespace_file.read_text().strip()
            if namespace not in ['ml-training-prod', 'ml-training-staging']:
                raise ValueError(f"Running in unexpected namespace: {namespace}")

        # Verify no suspicious environment variables
        suspicious_vars = ['AWS_ACCESS_KEY_ID', 'AWS_SECRET_ACCESS_KEY']
        for var in suspicious_vars:
            if var in os.environ:
                raise ValueError(f"Suspicious environment variable detected: {var}")

    def load_training_data(self, data_path: str, expected_checksum: str):
        """Load training data with integrity verification"""
        # Download data
        data_file = Path(data_path)
        if not data_file.exists():
            raise FileNotFoundError(f"Training data not found: {data_path}")

        # Verify checksum
        sha256_hash = hashlib.sha256()
        with open(data_file, "rb") as f:
            for byte_block in iter(lambda: f.read(4096), b""):
                sha256_hash.update(byte_block)

        actual_checksum = sha256_hash.hexdigest()
        if actual_checksum != expected_checksum:
            raise ValueError(
                f"Data integrity check failed! "
                f"Expected: {expected_checksum}, Got: {actual_checksum}"
            )

        print(f"✓ Data integrity verified: {data_path}")
        # Load and return data...

    def get_mlflow_credentials(self) -> Dict[str, str]:
        """Get MLflow credentials from Vault"""
        secret = self.vault_client.secrets.kv.v2.read_secret_version(
            path='mlflow/credentials',
            mount_point='ml-secrets'
        )
        return secret['data']['data']

    def train_model(self):
        """Train model with security controls"""
        # Get credentials from Vault
        mlflow_creds = self.get_mlflow_credentials()

        # Configure MLflow with credentials
        mlflow.set_tracking_uri(mlflow_creds['tracking_uri'])
        mlflow.set_experiment(self.config['experiment_name'])

        # Training code here...
        with mlflow.start_run():
            # Log security metadata
            mlflow.log_param("training_image", os.environ.get('CONTAINER_IMAGE'))
            mlflow.log_param("git_commit", os.environ.get('GIT_COMMIT'))
            mlflow.log_param("pipeline_run_id", os.environ.get('CI_PIPELINE_ID'))

            # Model training logic...
            model = self._train()

            # Sign model artifact
            model_path = "model.pkl"
            self._sign_model(model_path)

            # Log model
            mlflow.sklearn.log_model(model, "model")

    def _sign_model(self, model_path: str):
        """Sign model artifact with private key"""
        import subprocess

        # Get signing key from Vault
        signing_key = self.vault_client.secrets.kv.v2.read_secret_version(
            path='signing-keys/model',
            mount_point='ml-secrets'
        )['data']['data']['private_key']

        # Write key to temporary file (in memory)
        key_file = "/dev/shm/signing_key.pem"
        Path(key_file).write_text(signing_key)
        os.chmod(key_file, 0o600)

        try:
            # Sign model with openssl
            subprocess.run([
                'openssl', 'dgst', '-sha256',
                '-sign', key_file,
                '-out', f'{model_path}.sig',
                model_path
            ], check=True)

            print(f"✓ Model signed: {model_path}.sig")
        finally:
            # Securely delete key file
            if Path(key_file).exists():
                os.remove(key_file)


# Usage in CI/CD
if __name__ == "__main__":
    config = {
        'experiment_name': 'fraud-detection',
        'data_path': '/data/training.parquet',
        'data_checksum': os.environ['TRAINING_DATA_CHECKSUM']
    }

    trainer = SecureMLTrainer(config)
    trainer.load_training_data(
        config['data_path'],
        config['data_checksum']
    )
    trainer.train_model()
```

**Step 5: Deployment with Policy Enforcement**

```yaml
  deploy:
    runs-on: ubuntu-latest
    needs: [build-and-sign, ml-training]
    if: github.ref == 'refs/heads/main'

    steps:
      - name: Checkout
        uses: actions/checkout@v3

      - name: Install Cosign
        uses: sigstore/cosign-installer@main

      - name: Verify image signature
        env:
          COSIGN_EXPERIMENTAL: "true"
        run: |
          cosign verify \
            ghcr.io/${{ github.repository }}/ml-trainer:${{ github.sha }}

      - name: Install kubectl & kube-linter
        run: |
          curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
          chmod +x kubectl
          sudo mv kubectl /usr/local/bin/

          curl -L https://github.com/stackrox/kube-linter/releases/download/0.6.0/kube-linter-linux -o kube-linter
          chmod +x kube-linter
          sudo mv kube-linter /usr/local/bin/

      - name: Lint Kubernetes manifests
        run: |
          kube-linter lint k8s/*.yaml --config .kube-linter.yaml

      - name: Deploy to staging
        run: |
          # Update image tag in manifest
          sed -i "s|IMAGE_TAG|${{ github.sha }}|g" k8s/deployment.yaml

          # Apply to staging namespace
          kubectl apply -f k8s/ -n ml-staging

      - name: Run integration tests
        run: |
          # Wait for deployment
          kubectl wait --for=condition=available --timeout=300s \
            deployment/ml-service -n ml-staging

          # Run tests
          ./scripts/integration-tests.sh

      - name: Promote to production (manual approval required)
        if: github.event_name == 'push'
        uses: trstringer/manual-approval@v1
        with:
          secret: ${{ github.TOKEN }}
          approvers: ml-team-leads
          minimum-approvals: 2
          issue-title: "Deploy ML model to production"
          issue-body: |
            ## Deployment Details
            - Commit: ${{ github.sha }}
            - Image: ghcr.io/${{ github.repository }}/ml-trainer:${{ github.sha }}
            - Model performance metrics: [link to MLflow]

      - name: Deploy to production
        if: success()
        run: |
          kubectl apply -f k8s/ -n ml-production
```

### 1.4 GitOps for ML

**ArgoCD Configuration for ML Applications**:

```yaml
# argocd/ml-application.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ml-fraud-detection
  namespace: argocd
spec:
  project: ml-production

  source:
    repoURL: https://github.com/company/ml-fraud-detection
    targetRevision: main
    path: k8s/overlays/production

  destination:
    server: https://kubernetes.default.svc
    namespace: ml-production

  syncPolicy:
    automated:
      prune: false  # Don't auto-delete resources
      selfHeal: false  # Don't auto-sync on drift (manual review required)
    syncOptions:
      - CreateNamespace=false  # Namespace must already exist
      - PrunePropagationPolicy=foreground
      - RespectIgnoreDifferences=true

  ignoreDifferences:
    # Ignore replicas (controlled by HPA)
    - group: apps
      kind: Deployment
      jsonPointers:
        - /spec/replicas

# ArgoCD Project with RBAC
---
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: ml-production
  namespace: argocd
spec:
  description: ML Production Applications

  sourceRepos:
    - 'https://github.com/company/ml-*'

  destinations:
    - namespace: 'ml-production'
      server: https://kubernetes.default.svc
    - namespace: 'ml-staging'
      server: https://kubernetes.default.svc

  clusterResourceWhitelist:
    - group: ''
      kind: Namespace

  namespaceResourceWhitelist:
    - group: 'apps'
      kind: Deployment
    - group: 'apps'
      kind: StatefulSet
    - group: ''
      kind: Service
    - group: ''
      kind: ConfigMap
    - group: ''
      kind: Secret

  namespaceResourceBlacklist:
    - group: ''
      kind: ResourceQuota
    - group: ''
      kind: LimitRange
```

---

## 2. Container Security

### 2.1 Secure Base Images

**Problem**: Public base images may contain vulnerabilities or malware.

**Solution**: Use minimal, verified base images.

```dockerfile
# ❌ Bad: Full OS image with many vulnerabilities
FROM ubuntu:latest
RUN apt-get update && apt-get install -y python3 python3-pip
COPY requirements.txt .
RUN pip3 install -r requirements.txt
COPY . /app
CMD ["python3", "/app/train.py"]

# ✅ Good: Minimal distroless image
FROM python:3.11-slim AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

# Multi-stage build with distroless final image
FROM gcr.io/distroless/python3-debian11:nonroot
COPY --from=builder /root/.local /home/nonroot/.local
COPY --chown=nonroot:nonroot . /app
WORKDIR /app

# Run as non-root user
USER nonroot
ENV PATH=/home/nonroot/.local/bin:$PATH

CMD ["python", "train.py"]
```

**Best Practices for Base Images**:

1. **Use Official Images**: Start with official Python, NVIDIA CUDA, or ML framework images
2. **Pin Specific Versions**: Use `python:3.11.5-slim` not `python:latest`
3. **Minimize Layers**: Combine RUN commands to reduce attack surface
4. **Remove Build Tools**: Use multi-stage builds to exclude compilers from final image
5. **Scan Regularly**: Integrate image scanning in CI/CD

### 2.2 Container Image Scanning

**Using Trivy for Vulnerability Scanning**:

```bash
# Scan Docker image
trivy image --severity HIGH,CRITICAL python:3.11-slim

# Output:
# python:3.11-slim (debian 11.7)
# ===============================
# Total: 15 (HIGH: 10, CRITICAL: 5)
#
# ┌─────────────────┬────────────────┬──────────┬───────────────────┬───────────────────┬────────────────────────────────────┐
# │     Library     │ Vulnerability  │ Severity │ Installed Version │  Fixed Version    │             Title                   │
# ├─────────────────┼────────────────┼──────────┼───────────────────┼───────────────────┼────────────────────────────────────┤
# │ openssl         │ CVE-2023-12345 │ CRITICAL │ 3.0.9-1           │ 3.0.10-1          │ OpenSSL: Buffer overflow...        │
# │ libcurl         │ CVE-2023-67890 │ HIGH     │ 7.88.1-1          │ 7.88.1-2          │ curl: Use after free...            │
# └─────────────────┴────────────────┴──────────┴───────────────────┴───────────────────┴────────────────────────────────────┘
```

**Automated Scanning in CI/CD**:

```python
# scripts/scan-image.py
import subprocess
import json
import sys

def scan_image(image_name: str, severity_threshold: str = "HIGH") -> bool:
    """
    Scan Docker image for vulnerabilities

    Returns:
        True if scan passes (no vulns above threshold), False otherwise
    """
    try:
        result = subprocess.run(
            [
                'trivy', 'image',
                '--format', 'json',
                '--severity', f'{severity_threshold},CRITICAL',
                '--exit-code', '1',  # Exit 1 if vulnerabilities found
                image_name
            ],
            capture_output=True,
            text=True
        )

        scan_results = json.loads(result.stdout)

        # Parse results
        total_vulns = 0
        for result in scan_results.get('Results', []):
            vulns = result.get('Vulnerabilities', [])
            total_vulns += len(vulns)

            if vulns:
                print(f"\n[{result['Target']}] Found {len(vulns)} vulnerabilities:")
                for vuln in vulns[:10]:  # Show first 10
                    print(f"  - {vuln['VulnerabilityID']}: {vuln['Title']}")
                    print(f"    Severity: {vuln['Severity']}, Package: {vuln['PkgName']}")

        if total_vulns > 0:
            print(f"\n❌ Scan failed: {total_vulns} vulnerabilities found above {severity_threshold}")
            return False

        print(f"\n✓ Scan passed: No vulnerabilities found above {severity_threshold}")
        return True

    except json.JSONDecodeError as e:
        print(f"Error parsing Trivy output: {e}")
        return False
    except subprocess.CalledProcessError as e:
        print(f"Trivy scan failed: {e}")
        return False


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python scan-image.py <image-name>")
        sys.exit(1)

    image = sys.argv[1]
    passed = scan_image(image)
    sys.exit(0 if passed else 1)
```

### 2.3 Runtime Container Security

**Pod Security Standards**:

```yaml
# k8s/ml-training-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: ml-trainer
  namespace: ml-training
  labels:
    app: ml-trainer
spec:
  # Run as non-root user
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    runAsGroup: 1000
    fsGroup: 1000
    seccompProfile:
      type: RuntimeDefault

  containers:
    - name: trainer
      image: ghcr.io/company/ml-trainer:v1.2.3
      imagePullPolicy: Always

      # Container-level security context
      securityContext:
        allowPrivilegeEscalation: false
        readOnlyRootFilesystem: true
        runAsNonRoot: true
        capabilities:
          drop:
            - ALL

      # Resource limits (prevent resource exhaustion attacks)
      resources:
        requests:
          memory: "4Gi"
          cpu: "2"
          nvidia.com/gpu: "1"
        limits:
          memory: "8Gi"
          cpu: "4"
          nvidia.com/gpu: "1"

      # Writable volumes for temporary files
      volumeMounts:
        - name: tmp
          mountPath: /tmp
        - name: model-cache
          mountPath: /app/.cache

  volumes:
    - name: tmp
      emptyDir: {}
    - name: model-cache
      emptyDir:
        sizeLimit: "10Gi"

  # Pod tolerations and node affinity for GPU nodes
  tolerations:
    - key: "nvidia.com/gpu"
      operator: "Exists"
      effect: "NoSchedule"

  nodeSelector:
    workload: ml-training
```

**Policy Enforcement with OPA Gatekeeper**:

```yaml
# opa-policies/require-nonroot.yaml
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: k8spspmustrunasnonroot
spec:
  crd:
    spec:
      names:
        kind: K8sPSPMustRunAsNonRoot
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package k8spspmustrunasnonroot

        violation[{"msg": msg}] {
          c := input_containers[_]
          not c.securityContext.runAsNonRoot
          msg := sprintf("Container %v must set runAsNonRoot to true", [c.name])
        }

        input_containers[c] {
          c := input.review.object.spec.containers[_]
        }

        input_containers[c] {
          c := input.review.object.spec.initContainers[_]
        }

---
# Apply constraint to ml namespaces
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sPSPMustRunAsNonRoot
metadata:
  name: ml-must-run-as-nonroot
spec:
  match:
    kinds:
      - apiGroups: [""]
        kinds: ["Pod"]
    namespaces:
      - ml-training
      - ml-production
```

### 2.4 Container Runtime Security with Falco

**Falco Rules for ML Workloads**:

```yaml
# falco-rules/ml-security.yaml
- rule: Unauthorized Process in ML Container
  desc: Detect suspicious processes in ML training containers
  condition: >
    container.image.repository = "ghcr.io/company/ml-trainer" and
    spawned_process and not (
      proc.name in (python, python3, pip, conda, nvidia-smi)
    )
  output: >
    Unauthorized process started in ML container
    (user=%user.name command=%proc.cmdline container=%container.name image=%container.image)
  priority: WARNING
  tags: [ml, process]

- rule: Sensitive File Access in ML Container
  desc: Detect access to sensitive files from ML containers
  condition: >
    container.image.repository = "ghcr.io/company/ml-trainer" and
    open_read and (
      fd.name startswith "/etc/shadow" or
      fd.name startswith "/root/.ssh" or
      fd.name startswith "/home/*/.aws/credentials"
    )
  output: >
    Sensitive file accessed from ML container
    (user=%user.name file=%fd.name container=%container.name)
  priority: CRITICAL
  tags: [ml, filesystem]

- rule: Network Connection to Suspicious Domain
  desc: Detect ML container connecting to cryptocurrency mining pools
  condition: >
    container.image.repository = "ghcr.io/company/ml-trainer" and
    outbound and (
      fd.sip.name contains "pool.minergate.com" or
      fd.sip.name contains "xmr-pool.org" or
      fd.sip.name contains "moneropool.com"
    )
  output: >
    ML container connecting to suspicious domain
    (connection=%fd.name container=%container.name)
  priority: CRITICAL
  tags: [ml, network, cryptomining]
```

---

## 3. Dependency Vulnerability Scanning

### 3.1 Python Dependency Scanning

ML projects heavily depend on packages like TensorFlow, PyTorch, scikit-learn, and their transitive dependencies. Vulnerable dependencies can introduce security risks.

**Tools for Python Dependency Scanning**:

1. **Safety**: Checks against known vulnerability databases
2. **pip-audit**: Official PyPA tool for auditing Python packages
3. **Snyk**: Commercial tool with extensive vulnerability database
4. **OWASP Dependency-Check**: Multi-language dependency checker

**Using pip-audit**:

```bash
# Install pip-audit
pip install pip-audit

# Audit current environment
pip-audit

# Output:
# Found 3 vulnerabilities in 2 packages
#
# Name        Version  ID              Fix Version
# ----------- -------- --------------- -----------
# tensorflow  2.10.0   PYSEC-2023-123  2.11.0
# tensorflow  2.10.0   PYSEC-2023-456  2.11.0
# pillow      9.2.0    PYSEC-2023-789  9.3.0
```

**Automated Dependency Scanning**:

```python
# scripts/dependency-scan.py
import subprocess
import json
import sys
from typing import List, Dict

def scan_dependencies() -> List[Dict]:
    """
    Scan Python dependencies for known vulnerabilities

    Returns:
        List of vulnerabilities found
    """
    try:
        result = subprocess.run(
            ['pip-audit', '--format', 'json'],
            capture_output=True,
            text=True,
            check=False
        )

        vulnerabilities = json.loads(result.stdout)
        return vulnerabilities.get('dependencies', [])

    except (subprocess.CalledProcessError, json.JSONDecodeError) as e:
        print(f"Error running pip-audit: {e}")
        return []


def generate_report(vulnerabilities: List[Dict]) -> str:
    """Generate markdown report of vulnerabilities"""
    if not vulnerabilities:
        return "✓ No vulnerabilities found in dependencies"

    report = "# Dependency Vulnerability Report\n\n"
    report += f"**Total vulnerabilities**: {len(vulnerabilities)}\n\n"

    for vuln in vulnerabilities:
        name = vuln['name']
        version = vuln['version']
        vulns = vuln.get('vulns', [])

        report += f"## {name} ({version})\n\n"

        for v in vulns:
            report += f"### {v['id']}\n\n"
            report += f"- **Severity**: {v.get('severity', 'Unknown')}\n"
            report += f"- **Description**: {v.get('description', 'N/A')}\n"
            report += f"- **Fix Version**: {v.get('fix_versions', ['N/A'])[0]}\n\n"

    return report


def check_severity_threshold(vulnerabilities: List[Dict], max_severity: str = "HIGH") -> bool:
    """
    Check if any vulnerabilities exceed severity threshold

    Returns:
        True if within threshold, False if exceeds
    """
    severity_levels = {"LOW": 1, "MEDIUM": 2, "HIGH": 3, "CRITICAL": 4}
    threshold = severity_levels.get(max_severity, 3)

    for vuln in vulnerabilities:
        for v in vuln.get('vulns', []):
            severity = v.get('severity', 'UNKNOWN').upper()
            if severity_levels.get(severity, 0) >= threshold:
                return False

    return True


if __name__ == "__main__":
    print("Scanning Python dependencies for vulnerabilities...")
    vulns = scan_dependencies()

    print(generate_report(vulns))

    if not check_severity_threshold(vulns, max_severity="HIGH"):
        print("\n❌ Vulnerabilities found above threshold")
        sys.exit(1)

    print("\n✓ All dependencies pass security checks")
    sys.exit(0)
```

### 3.2 Dependency Pinning and Lock Files

**requirements.txt with pinned versions**:

```txt
# requirements.txt
# Generated with: pip-compile --generate-hashes requirements.in

torch==2.0.1 \
    --hash=sha256:abc123...
torchvision==0.15.2 \
    --hash=sha256:def456...
numpy==1.24.3 \
    --hash=sha256:ghi789...
pandas==2.0.2 \
    --hash=sha256:jkl012...
scikit-learn==1.3.0 \
    --hash=sha256:mno345...

# Security-focused packages
bandit==1.7.5
safety==2.3.5
pip-audit==2.6.1
```

**Using pip-tools for reproducible builds**:

```bash
# Create requirements.in with unpinned versions
cat > requirements.in <<EOF
torch>=2.0.0
torchvision
numpy
pandas
scikit-learn
EOF

# Compile to requirements.txt with exact versions and hashes
pip-compile --generate-hashes --output-file=requirements.txt requirements.in

# Install with hash verification
pip install --require-hashes -r requirements.txt
```

### 3.3 Private PyPI Mirror

For enterprise environments, host a private PyPI mirror with vetted packages:

```python
# scripts/mirror-pypi.py
import subprocess
from typing import List

def mirror_packages(packages: List[str], mirror_url: str):
    """
    Mirror specific PyPI packages to private registry

    Args:
        packages: List of package names to mirror
        mirror_url: URL of private PyPI registry
    """
    for package in packages:
        print(f"Mirroring {package}...")

        # Download package and dependencies
        subprocess.run([
            'pip', 'download',
            '--dest', './mirror-packages',
            '--no-binary', ':all:',  # Download source distributions
            package
        ], check=True)

        # Upload to private registry
        subprocess.run([
            'twine', 'upload',
            '--repository-url', mirror_url,
            f'./mirror-packages/{package}-*.tar.gz'
        ], check=True)


# Configure pip to use private mirror
# pip.conf:
# [global]
# index-url = https://pypi.company.internal/simple/
# trusted-host = pypi.company.internal
```

---

## 4. Supply Chain Security

### 4.1 Software Supply Chain Threats

**SLSA Framework (Supply-chain Levels for Software Artifacts)**:

SLSA provides a framework for preventing supply chain attacks through verifiable build provenance.

**SLSA Levels**:

- **Level 0**: No guarantees
- **Level 1**: Documentation of build process
- **Level 2**: Tamper-resistant build service
- **Level 3**: Extra resistance to specific threats
- **Level 4**: Highest level of confidence

**Common Supply Chain Attacks**:

1. **Dependency Confusion**: Attacker uploads malicious package with same name to public registry
2. **Typosquatting**: Package with similar name to popular library (e.g., `requests` vs `requets`)
3. **Compromised Maintainer Account**: Attacker gains access to legitimate package maintainer account
4. **Build System Compromise**: CI/CD pipeline compromised to inject malicious code

### 4.2 Generating SBOM (Software Bill of Materials)

**Using Syft to generate SBOM**:

```bash
# Generate SBOM for Docker image
syft ghcr.io/company/ml-trainer:v1.2.3 -o cyclonedx-json > sbom.json

# Generate SBOM for Python project
syft dir:. -o spdx-json > sbom-spdx.json

# Generate SBOM for requirements.txt
syft file:requirements.txt -o cyclonedx-json > sbom-requirements.json
```

**SBOM in CI/CD**:

```yaml
# .github/workflows/sbom.yml
name: Generate SBOM

on:
  push:
    branches: [main]
  release:
    types: [published]

jobs:
  generate-sbom:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v3

      - name: Install Syft
        uses: anchore/sbom-action/download-syft@v0

      - name: Generate SBOM for source
        run: |
          syft dir:. -o cyclonedx-json=sbom-source.json

      - name: Generate SBOM for Docker image
        run: |
          syft ${{ env.IMAGE_NAME}}:${{ github.sha }} \
            -o cyclonedx-json=sbom-image.json

      - name: Upload SBOM artifacts
        uses: actions/upload-artifact@v3
        with:
          name: sbom
          path: |
            sbom-source.json
            sbom-image.json

      - name: Attest SBOM
        uses: actions/attest-sbom@v1
        with:
          subject-path: sbom-image.json
          sbom-path: sbom-image.json
```

### 4.3 Verifying Software Provenance

**Sigstore for Keyless Signing**:

```bash
# Sign container image
cosign sign --yes ghcr.io/company/ml-trainer:v1.2.3

# Verify signature
cosign verify \
  --certificate-identity=https://github.com/company/ml-trainer/.github/workflows/build.yml@refs/heads/main \
  --certificate-oidc-issuer=https://token.actions.githubusercontent.com \
  ghcr.io/company/ml-trainer:v1.2.3

# Attach SBOM to image
cosign attach sbom --sbom sbom.json ghcr.io/company/ml-trainer:v1.2.3

# Verify and retrieve SBOM
cosign verify-attestation \
  --type cyclonedx \
  --certificate-oidc-issuer=https://token.actions.githubusercontent.com \
  ghcr.io/company/ml-trainer:v1.2.3
```

**In-Toto for Build Provenance**:

```python
# scripts/generate-provenance.py
from in_toto import runlib, models

def generate_build_provenance(
    step_name: str,
    materials: list,
    products: list,
    command: list
):
    """
    Generate in-toto link metadata for build step

    Args:
        step_name: Name of the build step
        materials: Input files/artifacts
        products: Output files/artifacts
        command: Command executed
    """
    link = runlib.in_toto_run(
        step_name=step_name,
        material_list=materials,
        product_list=products,
        command=command
    )

    # Sign link metadata
    key = models.Key.read_from_file("signing-key.pem")
    link.sign(key)

    # Write link metadata
    link.dump(f"{step_name}.link")


# Usage in build script
generate_build_provenance(
    step_name="build-model",
    materials=["src/", "requirements.txt", "train_data.csv"],
    products=["model.pkl", "metrics.json"],
    command=["python", "train.py"]
)
```

### 4.4 Dependency Confusion Prevention

**Package Installation Policy**:

```python
# pip.conf
[global]
# Only use internal registry for company packages
index-url = https://pypi.company.internal/simple/

# Use public PyPI as fallback, but with restrictions
extra-index-url = https://pypi.org/simple/

[install]
# Require all packages to be verified
require-hashes = true

# Don't allow pre-releases
pre = false
```

**Namespace Protection**:

```python
# scripts/reserve-namespace.py
import requests

def reserve_namespace_on_pypi(namespace: str):
    """
    Reserve namespace on PyPI to prevent dependency confusion

    Upload placeholder packages for all potential internal package names
    """
    packages_to_reserve = [
        f"{namespace}-ml-pipeline",
        f"{namespace}-data-loader",
        f"{namespace}-feature-store",
    ]

    for package in packages_to_reserve:
        # Create minimal package
        setup_py = f'''
from setuptools import setup
setup(
    name="{package}",
    version="0.0.1",
    description="Namespace reservation - internal use only",
    author="Security Team",
    packages=[],
)
'''

        # Build and upload to PyPI
        # (This reserves the name, preventing attackers from using it)
```

---

## 5. Secure Artifact Management

### 5.1 Model Registry Security

**MLflow Model Registry with Authentication**:

```python
# src/secure_model_registry.py
import mlflow
from mlflow.tracking import MlflowClient
import os

class SecureModelRegistry:
    """
    Secure wrapper for MLflow model registry
    """

    def __init__(self):
        # Configure MLflow with authentication
        self.tracking_uri = os.environ['MLFLOW_TRACKING_URI']
        self.username = os.environ['MLFLOW_TRACKING_USERNAME']
        self.password = os.environ['MLFLOW_TRACKING_PASSWORD']

        mlflow.set_tracking_uri(self.tracking_uri)

        # Set auth credentials
        os.environ['MLFLOW_TRACKING_USERNAME'] = self.username
        os.environ['MLFLOW_TRACKING_PASSWORD'] = self.password

        self.client = MlflowClient(tracking_uri=self.tracking_uri)

    def register_model(
        self,
        run_id: str,
        model_name: str,
        tags: dict = None
    ) -> str:
        """
        Register model with security metadata

        Args:
            run_id: MLflow run ID
            model_name: Name for registered model
            tags: Additional tags (security labels, compliance info)

        Returns:
            Model version
        """
        # Get run info for provenance
        run = self.client.get_run(run_id)

        # Add security tags
        security_tags = {
            "git_commit": run.data.tags.get("mlflow.source.git.commit"),
            "pipeline_id": run.data.tags.get("ci_pipeline_id"),
            "trained_by": run.data.tags.get("mlflow.user"),
            "data_version": run.data.tags.get("data_version"),
            "security_scan": "passed",  # From earlier pipeline stage
        }

        if tags:
            security_tags.update(tags)

        # Register model
        result = mlflow.register_model(
            f"runs:/{run_id}/model",
            model_name,
            tags=security_tags
        )

        return result.version

    def promote_to_production(
        self,
        model_name: str,
        version: str,
        approval_ticket: str
    ):
        """
        Promote model to production with approval tracking

        Args:
            model_name: Registered model name
            version: Model version to promote
            approval_ticket: Reference to approval (e.g., Jira ticket)
        """
        # Verify approval ticket exists
        if not self._verify_approval(approval_ticket):
            raise ValueError(f"Invalid approval ticket: {approval_ticket}")

        # Transition to production
        self.client.transition_model_version_stage(
            name=model_name,
            version=version,
            stage="Production",
            archive_existing_versions=True
        )

        # Add approval metadata
        self.client.set_model_version_tag(
            model_name,
            version,
            "approval_ticket",
            approval_ticket
        )

        print(f"✓ Model {model_name} v{version} promoted to Production")

    def _verify_approval(self, ticket: str) -> bool:
        """Verify approval ticket with ticketing system"""
        # Integrate with Jira/ServiceNow/etc.
        return True  # Placeholder


# Usage
registry = SecureModelRegistry()
version = registry.register_model(
    run_id="abc123",
    model_name="fraud-detection",
    tags={"compliance": "PCI-DSS"}
)

registry.promote_to_production(
    model_name="fraud-detection",
    version=version,
    approval_ticket="SEC-1234"
)
```

### 5.2 Artifact Signing and Verification

**Signing Model Artifacts**:

```python
# src/model_signing.py
import hashlib
import json
from pathlib import Path
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import padding, rsa
from typing import Dict

class ModelSigner:
    """
    Sign and verify ML model artifacts
    """

    def __init__(self, private_key_path: str = None, public_key_path: str = None):
        if private_key_path:
            with open(private_key_path, 'rb') as f:
                self.private_key = serialization.load_pem_private_key(
                    f.read(),
                    password=None
                )

        if public_key_path:
            with open(public_key_path, 'rb') as f:
                self.public_key = serialization.load_pem_public_key(f.read())

    def sign_model(self, model_path: str) -> Dict[str, str]:
        """
        Sign model file and generate signature

        Returns:
            Dictionary with signature and metadata
        """
        # Calculate model hash
        model_hash = self._hash_file(model_path)

        # Sign hash with private key
        signature = self.private_key.sign(
            model_hash.encode(),
            padding.PSS(
                mgf=padding.MGF1(hashes.SHA256()),
                salt_length=padding.PSS.MAX_LENGTH
            ),
            hashes.SHA256()
        )

        # Create signature metadata
        signature_data = {
            "model_file": Path(model_path).name,
            "model_hash": model_hash,
            "signature": signature.hex(),
            "algorithm": "RSA-PSS-SHA256"
        }

        # Write signature file
        sig_path = f"{model_path}.sig"
        with open(sig_path, 'w') as f:
            json.dump(signature_data, f, indent=2)

        print(f"✓ Model signed: {sig_path}")
        return signature_data

    def verify_model(self, model_path: str, signature_path: str) -> bool:
        """
        Verify model signature

        Returns:
            True if signature is valid, False otherwise
        """
        # Load signature
        with open(signature_path, 'r') as f:
            sig_data = json.load(f)

        # Verify hash matches
        current_hash = self._hash_file(model_path)
        if current_hash != sig_data['model_hash']:
            print("❌ Model hash mismatch - file may have been tampered with")
            return False

        # Verify signature
        try:
            self.public_key.verify(
                bytes.fromhex(sig_data['signature']),
                current_hash.encode(),
                padding.PSS(
                    mgf=padding.MGF1(hashes.SHA256()),
                    salt_length=padding.PSS.MAX_LENGTH
                ),
                hashes.SHA256()
            )
            print("✓ Signature valid - model integrity verified")
            return True

        except Exception as e:
            print(f"❌ Signature verification failed: {e}")
            return False

    def _hash_file(self, file_path: str) -> str:
        """Calculate SHA-256 hash of file"""
        sha256 = hashlib.sha256()
        with open(file_path, 'rb') as f:
            for chunk in iter(lambda: f.read(4096), b''):
                sha256.update(chunk)
        return sha256.hexdigest()


# Usage
signer = ModelSigner(
    private_key_path="keys/model-signing-key.pem",
    public_key_path="keys/model-signing-key.pub"
)

# During training: sign model
signer.sign_model("fraud_detection_model.pkl")

# During deployment: verify model
if signer.verify_model("fraud_detection_model.pkl", "fraud_detection_model.pkl.sig"):
    # Deploy model
    pass
else:
    raise ValueError("Model signature verification failed - deployment aborted")
```

### 5.3 Secure Container Registry

**Configure Container Registry with RBAC**:

```yaml
# Harbor registry configuration
# harbor.yml

# Authentication
external_redis:
  host: redis.internal
  port: 6379
  password: ${REDIS_PASSWORD}

database:
  type: postgresql
  postgresql:
    host: postgres.internal
    port: 5432
    database: registry
    username: harbor
    password: ${POSTGRES_PASSWORD}

# Security settings
security:
  # Require signed images
  image_signature:
    enable: true
    type: cosign

  # Content trust (Notary)
  content_trust:
    enable: true
    cosign_enabled: true

  # Vulnerability scanning
  vulnerability_scanning:
    enabled: true
    scan_on_push: true
    severity_threshold: high
    auto_update_vuln_db: true

  # RBAC
  rbac:
    policy: |
      # ML team can push/pull from ml-* projects
      p, group:ml-team, project, ml-*, push
      p, group:ml-team, project, ml-*, pull

      # Production deploy role can only pull from production project
      p, role:prod-deploy, project, ml-production, pull

      # Security team can scan all images
      p, group:security-team, project, *, scan
```

**Image Admission Policy with Kyverno**:

```yaml
# kyverno-policy/verify-image-signature.yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: verify-ml-image-signatures
spec:
  validationFailureAction: enforce
  background: false
  rules:
    - name: verify-signature
      match:
        any:
          - resources:
              kinds:
                - Pod
              namespaces:
                - ml-production
                - ml-staging

      verifyImages:
        - imageReferences:
            - "ghcr.io/company/ml-*"

          attestors:
            - entries:
                - keyless:
                    subject: "https://github.com/company/ml-*"
                    issuer: "https://token.actions.githubusercontent.com"
                    rekor:
                      url: https://rekor.sigstore.dev
```

---

## Summary

Secure ML pipelines require:

1. **CI/CD Security**: Secret management, signed commits, automated scanning
2. **Container Security**: Minimal images, vulnerability scanning, runtime policies
3. **Dependency Management**: Pinned versions, private mirrors, regular audits
4. **Supply Chain Security**: SBOM generation, provenance tracking, signed artifacts
5. **Artifact Management**: Secure registries, access control, integrity verification

**Key Takeaways**:

- Treat ML artifacts (models, data) with same rigor as code
- Automate security checks in every pipeline stage
- Implement defense in depth: multiple layers of security controls
- Monitor and audit all artifact access
- Regularly update dependencies and base images
- Use ephemeral, isolated environments for training
- Sign and verify all artifacts before deployment

---

**Next Module**: [Module 6: Network Security for ML](../mod-006-network-security/lecture-notes/01-network-security.md)
