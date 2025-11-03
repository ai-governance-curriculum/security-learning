# Module 4: Secrets & Identity Management - Exercises

## Overview

These exercises provide hands-on experience with secrets management systems, identity and access management, and certificate lifecycle automation for AI/ML infrastructure. You'll work with HashiCorp Vault, cloud provider secrets managers, and implement secure IAM patterns.

**Total Time**: 10-13 hours
**Prerequisites**:
- Docker and Kubernetes access
- AWS/Azure/GCP account (free tier sufficient)
- Python 3.8+ with virtual environment
- Basic understanding of PKI and TLS

---

## Exercise 1: HashiCorp Vault Integration for ML Pipelines

**Time**: 3-4 hours
**Difficulty**: Intermediate

### Objectives

- Set up HashiCorp Vault in development and production modes
- Implement secure authentication using AppRole
- Store and retrieve ML model secrets (API keys, database credentials)
- Integrate Vault with a Python ML training pipeline
- Implement secret rotation handling

### Tasks

#### Part 1: Vault Setup and Configuration (45 minutes)

1. **Install and Initialize Vault**:
   ```bash
   # Download and install Vault
   wget https://releases.hashicorp.com/vault/1.15.0/vault_1.15.0_linux_amd64.zip
   unzip vault_1.15.0_linux_amd64.zip
   sudo mv vault /usr/local/bin/

   # Start Vault in dev mode (for testing)
   vault server -dev -dev-root-token-id="dev-token"
   ```

2. **Configure Vault for ML Secrets**:
   - Enable KV v2 secrets engine at path `ml-secrets`
   - Create a policy named `ml-pipeline-policy` with read/write access to `ml-secrets/training/*`
   - Enable AppRole auth method
   - Create an AppRole named `ml-pipeline` with the policy attached

3. **Store Initial Secrets**:
   ```bash
   # Store various ML pipeline secrets
   vault kv put ml-secrets/training/model-registry \
     url="https://mlflow.example.com" \
     username="ml-user" \
     password="secure-password"

   vault kv put ml-secrets/training/feature-store \
     api_key="fs-key-12345" \
     endpoint="https://features.example.com"

   vault kv put ml-secrets/training/data-warehouse \
     connection_string="postgresql://user:pass@db.example.com:5432/ml_data"
   ```

#### Part 2: Python Integration (1.5 hours)

4. **Create Vault Client Wrapper**:

Implement `vault_client.py`:

```python
import hvac
import os
import time
from functools import wraps
from typing import Dict, Any, Optional

class VaultClient:
    """
    Secure Vault client for ML pipelines with automatic token renewal
    and error handling.
    """

    def __init__(self, url: str = None, namespace: str = None):
        self.url = url or os.environ.get("VAULT_ADDR", "http://localhost:8200")
        self.namespace = namespace
        self.client = hvac.Client(url=self.url, namespace=namespace)
        self._token_renewable = False
        self._authenticate()

    def _authenticate(self):
        """Authenticate using AppRole"""
        role_id = os.environ.get("VAULT_ROLE_ID")
        secret_id = os.environ.get("VAULT_SECRET_ID")

        if not role_id or not secret_id:
            raise ValueError("VAULT_ROLE_ID and VAULT_SECRET_ID must be set")

        try:
            response = self.client.auth.approle.login(
                role_id=role_id,
                secret_id=secret_id
            )
            self._token_renewable = response['auth']['renewable']
            self._token_ttl = response['auth']['lease_duration']

            # Start token renewal thread if renewable
            if self._token_renewable:
                self._start_token_renewal()

        except hvac.exceptions.VaultError as e:
            raise RuntimeError(f"Vault authentication failed: {e}")

    def _start_token_renewal(self):
        """Background thread to renew token before expiration"""
        import threading

        def renew_token():
            while self._token_renewable:
                # Renew at 80% of TTL
                sleep_time = int(self._token_ttl * 0.8)
                time.sleep(sleep_time)

                try:
                    response = self.client.auth.token.renew_self()
                    self._token_ttl = response['auth']['lease_duration']
                except Exception as e:
                    print(f"Token renewal failed: {e}")
                    self._authenticate()  # Re-authenticate

        renewal_thread = threading.Thread(target=renew_token, daemon=True)
        renewal_thread.start()

    def get_secret(self, path: str, field: Optional[str] = None) -> Any:
        """
        Retrieve secret from Vault KV v2 engine

        Args:
            path: Secret path (e.g., 'training/model-registry')
            field: Specific field to extract (optional)

        Returns:
            Full secret dict or specific field value
        """
        try:
            secret = self.client.secrets.kv.v2.read_secret_version(
                path=path,
                mount_point="ml-secrets"
            )
            data = secret['data']['data']
            return data.get(field) if field else data
        except hvac.exceptions.InvalidPath:
            raise KeyError(f"Secret not found: ml-secrets/data/{path}")

    def set_secret(self, path: str, data: Dict[str, Any]):
        """Store secret in Vault"""
        self.client.secrets.kv.v2.create_or_update_secret(
            path=path,
            secret=data,
            mount_point="ml-secrets"
        )

    def delete_secret(self, path: str):
        """Delete secret (soft delete in KV v2)"""
        self.client.secrets.kv.v2.delete_latest_version_of_secret(
            path=path,
            mount_point="ml-secrets"
        )


def with_vault_secrets(secret_paths: list):
    """
    Decorator to inject Vault secrets into function kwargs

    Usage:
        @with_vault_secrets(['training/model-registry', 'training/feature-store'])
        def train_model(**secrets):
            model_registry = secrets['training/model-registry']
            feature_store = secrets['training/feature-store']
    """
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            vault = VaultClient()
            secrets = {}
            for path in secret_paths:
                secrets[path] = vault.get_secret(path)
            kwargs['secrets'] = secrets
            return func(*args, **kwargs)
        return wrapper
    return decorator
```

5. **Integrate with ML Training Pipeline**:

Create `train_with_vault.py`:

```python
from vault_client import VaultClient, with_vault_secrets
import mlflow
import psycopg2
import requests

@with_vault_secrets([
    'training/model-registry',
    'training/feature-store',
    'training/data-warehouse'
])
def train_model(model_name: str, **secrets):
    """
    ML training function that retrieves all secrets from Vault
    """
    # Configure MLflow with secrets
    registry_secrets = secrets['secrets']['training/model-registry']
    mlflow.set_tracking_uri(registry_secrets['url'])
    mlflow.set_experiment(model_name)

    # Fetch features using API key
    feature_secrets = secrets['secrets']['training/feature-store']
    headers = {'Authorization': f"Bearer {feature_secrets['api_key']}"}
    response = requests.get(
        f"{feature_secrets['endpoint']}/features/latest",
        headers=headers
    )
    features = response.json()

    # Load training data from warehouse
    db_secrets = secrets['secrets']['training/data-warehouse']
    conn = psycopg2.connect(db_secrets['connection_string'])
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM training_data WHERE date >= NOW() - INTERVAL '30 days'")
    training_data = cursor.fetchall()

    # Training logic here...
    print(f"Training model with {len(training_data)} samples")
    print(f"Using {len(features)} features from feature store")

    # Log model to registry (authenticated via secrets)
    with mlflow.start_run():
        # Training and logging code
        mlflow.log_param("data_samples", len(training_data))
        mlflow.log_param("features_count", len(features))

    conn.close()


if __name__ == "__main__":
    # Set Vault credentials from environment
    # export VAULT_ROLE_ID=...
    # export VAULT_SECRET_ID=...

    train_model("fraud-detection-v2")
```

6. **Implement Secret Rotation Handler**:

```python
class SecretRotationHandler:
    """
    Handles graceful secret rotation without service interruption
    """

    def __init__(self, vault_client: VaultClient):
        self.vault = vault_client
        self.secret_cache = {}
        self.secret_versions = {}

    def get_secret_with_fallback(self, path: str) -> Dict[str, Any]:
        """
        Get secret with automatic fallback to previous version
        if current version fails validation
        """
        try:
            # Try current version
            secret = self.vault.get_secret(path)
            self.secret_cache[path] = secret
            return secret
        except Exception as e:
            # Fallback to cached version
            if path in self.secret_cache:
                print(f"Using cached secret for {path} due to error: {e}")
                return self.secret_cache[path]
            raise

    def rotate_database_password(self, path: str, new_password: str):
        """
        Rotate database password with zero downtime

        Process:
        1. Update database with new password
        2. Store new secret in Vault
        3. Wait for grace period
        4. Remove old password from database
        """
        # Get current credentials
        current = self.vault.get_secret(path)

        # Step 1: Add new password to database (multi-password support)
        # Implementation depends on database system

        # Step 2: Update Vault
        new_secret = current.copy()
        new_secret['password'] = new_password
        new_secret['rotated_at'] = time.time()
        self.vault.set_secret(path, new_secret)

        # Step 3: Grace period for all clients to refresh
        print(f"Waiting 60s grace period for {path} rotation...")
        time.sleep(60)

        # Step 4: Remove old password (if database supports)
        print(f"Secret rotation complete for {path}")
```

#### Part 3: Testing and Validation (1 hour)

7. **Write Integration Tests**:

```python
import pytest
from vault_client import VaultClient
import hvac

class TestVaultIntegration:

    @pytest.fixture
    def vault_client(self):
        """Fixture to provide authenticated Vault client"""
        return VaultClient()

    def test_secret_retrieval(self, vault_client):
        """Test that secrets can be retrieved"""
        secret = vault_client.get_secret('training/model-registry')
        assert 'url' in secret
        assert 'username' in secret
        assert 'password' in secret

    def test_secret_creation(self, vault_client):
        """Test secret creation and retrieval"""
        test_data = {
            'api_key': 'test-key-12345',
            'endpoint': 'https://test.example.com'
        }
        vault_client.set_secret('test/temp-secret', test_data)

        retrieved = vault_client.get_secret('test/temp-secret')
        assert retrieved == test_data

        # Cleanup
        vault_client.delete_secret('test/temp-secret')

    def test_secret_not_found(self, vault_client):
        """Test error handling for missing secrets"""
        with pytest.raises(KeyError):
            vault_client.get_secret('nonexistent/path')

    def test_field_extraction(self, vault_client):
        """Test extracting specific field from secret"""
        url = vault_client.get_secret('training/model-registry', 'url')
        assert isinstance(url, str)
        assert url.startswith('https://')
```

8. **Run Tests**:
   ```bash
   pytest test_vault_integration.py -v
   ```

### Success Criteria

- [ ] Vault server running and accessible
- [ ] AppRole authentication configured with proper policies
- [ ] Python client can authenticate and retrieve secrets
- [ ] ML training pipeline successfully uses Vault secrets
- [ ] Token renewal works automatically
- [ ] Secret rotation handler implemented
- [ ] All integration tests pass
- [ ] No secrets hardcoded in code or logs

### Deliverables

1. `vault-config/` directory with:
   - `setup.sh` - Vault initialization script
   - `policies/ml-pipeline-policy.hcl` - Vault policy definition
   - `approle-config.sh` - AppRole setup script

2. `src/` directory with:
   - `vault_client.py` - Vault client implementation
   - `train_with_vault.py` - Example ML pipeline integration
   - `secret_rotation.py` - Rotation handler

3. `tests/test_vault_integration.py` - Integration tests

4. `README.md` documenting:
   - Setup instructions
   - Architecture decisions
   - Security considerations
   - Troubleshooting guide

---

## Exercise 2: Dynamic Secrets and Credential Management

**Time**: 3-4 hours
**Difficulty**: Advanced

### Objectives

- Implement dynamic database credentials with Vault
- Configure AWS dynamic credentials for ML workloads
- Build automatic credential lifecycle management
- Implement lease renewal and revocation
- Monitor credential usage and audit logs

### Tasks

#### Part 1: Dynamic Database Credentials (1.5 hours)

1. **Set Up PostgreSQL for Dynamic Credentials**:

```bash
# Start PostgreSQL in Docker
docker run -d \
  --name postgres-vault-demo \
  -e POSTGRES_PASSWORD=rootpassword \
  -p 5432:5432 \
  postgres:14

# Configure Vault database secrets engine
vault secrets enable database

vault write database/config/ml-postgres \
  plugin_name=postgresql-database-plugin \
  allowed_roles="ml-readonly,ml-readwrite,ml-admin" \
  connection_url="postgresql://{{username}}:{{password}}@localhost:5432/postgres?sslmode=disable" \
  username="postgres" \
  password="rootpassword"
```

2. **Create Dynamic Role Definitions**:

```bash
# Read-only role for training jobs
vault write database/roles/ml-readonly \
  db_name=ml-postgres \
  creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; \
    GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
  default_ttl="1h" \
  max_ttl="24h"

# Read-write role for data pipelines
vault write database/roles/ml-readwrite \
  db_name=ml-postgres \
  creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; \
    GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
  default_ttl="2h" \
  max_ttl="8h"
```

3. **Implement Dynamic Credentials in Python**:

```python
import hvac
import psycopg2
import threading
import time
from typing import Optional
from contextlib import contextmanager

class DynamicDatabaseClient:
    """
    Database client that automatically manages dynamic credentials
    from Vault with lease renewal
    """

    def __init__(self, vault_client: hvac.Client, role_name: str = "ml-readonly"):
        self.vault = vault_client
        self.role_name = role_name
        self.credentials = None
        self.lease_id = None
        self.lease_duration = None
        self.connection = None
        self._renewal_thread = None

        # Get initial credentials
        self._refresh_credentials()

    def _refresh_credentials(self):
        """Fetch new dynamic credentials from Vault"""
        response = self.vault.read(f"database/creds/{self.role_name}")

        self.credentials = {
            'username': response['data']['username'],
            'password': response['data']['password']
        }
        self.lease_id = response['lease_id']
        self.lease_duration = response['lease_duration']

        print(f"New credentials obtained: {self.credentials['username']}")
        print(f"Lease ID: {self.lease_id}, Duration: {self.lease_duration}s")

        # Start lease renewal
        self._start_lease_renewal()

    def _start_lease_renewal(self):
        """Start background thread to renew lease"""
        if self._renewal_thread and self._renewal_thread.is_alive():
            return  # Already running

        def renew_lease():
            while True:
                # Renew at 50% of lease duration
                sleep_time = self.lease_duration / 2
                time.sleep(sleep_time)

                try:
                    response = self.vault.sys.renew_lease(lease_id=self.lease_id)
                    self.lease_duration = response['lease_duration']
                    print(f"Lease renewed for {self.lease_duration}s")
                except Exception as e:
                    print(f"Lease renewal failed: {e}")
                    print("Refreshing credentials...")
                    self._refresh_credentials()
                    break

        self._renewal_thread = threading.Thread(target=renew_lease, daemon=True)
        self._renewal_thread.start()

    @contextmanager
    def get_connection(self):
        """
        Context manager that provides database connection
        with automatic credential management
        """
        try:
            conn = psycopg2.connect(
                host="localhost",
                port=5432,
                database="postgres",
                user=self.credentials['username'],
                password=self.credentials['password']
            )
            yield conn
        finally:
            if conn:
                conn.close()

    def revoke_credentials(self):
        """Explicitly revoke credentials"""
        if self.lease_id:
            self.vault.sys.revoke_lease(lease_id=self.lease_id)
            print(f"Lease {self.lease_id} revoked")

    def __del__(self):
        """Cleanup: revoke lease on deletion"""
        self.revoke_credentials()


# Usage example
def run_ml_query():
    vault_client = hvac.Client(url="http://localhost:8200", token="dev-token")
    db_client = DynamicDatabaseClient(vault_client, role_name="ml-readonly")

    with db_client.get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT COUNT(*) FROM training_data")
        count = cursor.fetchone()[0]
        print(f"Training samples: {count}")

    # Credentials automatically revoked when db_client goes out of scope
```

#### Part 2: AWS Dynamic Credentials (1 hour)

4. **Configure AWS Secrets Engine in Vault**:

```bash
# Enable AWS secrets engine
vault secrets enable aws

# Configure AWS backend with root credentials
vault write aws/config/root \
  access_key=$AWS_ACCESS_KEY_ID \
  secret_key=$AWS_SECRET_ACCESS_KEY \
  region=us-west-2

# Create role for S3 read access
vault write aws/roles/ml-data-reader \
  credential_type=iam_user \
  policy_document=-<<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::ml-training-data/*",
        "arn:aws:s3:::ml-training-data"
      ]
    }
  ]
}
EOF
```

5. **Implement AWS Dynamic Credentials Client**:

```python
import boto3
from botocore.exceptions import ClientError

class DynamicAWSClient:
    """
    AWS client with dynamic credentials from Vault
    """

    def __init__(self, vault_client: hvac.Client, role_name: str):
        self.vault = vault_client
        self.role_name = role_name
        self.credentials = None
        self.lease_id = None
        self._refresh_credentials()

    def _refresh_credentials(self):
        """Get new AWS credentials from Vault"""
        response = self.vault.read(f"aws/creds/{self.role_name}")

        self.credentials = response['data']
        self.lease_id = response['lease_id']

        # Create boto3 session with dynamic credentials
        self.session = boto3.Session(
            aws_access_key_id=self.credentials['access_key'],
            aws_secret_access_key=self.credentials['secret_key'],
            region_name='us-west-2'
        )

    def get_s3_client(self):
        """Get S3 client with current credentials"""
        return self.session.client('s3')

    def download_training_data(self, bucket: str, key: str, local_path: str):
        """Download training data from S3"""
        s3 = self.get_s3_client()
        try:
            s3.download_file(bucket, key, local_path)
            print(f"Downloaded {key} to {local_path}")
        except ClientError as e:
            if e.response['Error']['Code'] == 'ExpiredToken':
                print("Credentials expired, refreshing...")
                self._refresh_credentials()
                # Retry
                s3 = self.get_s3_client()
                s3.download_file(bucket, key, local_path)

    def revoke(self):
        """Revoke AWS credentials"""
        if self.lease_id:
            self.vault.sys.revoke_lease(lease_id=self.lease_id)


# Usage
vault_client = hvac.Client(url="http://localhost:8200", token="dev-token")
aws_client = DynamicAWSClient(vault_client, role_name="ml-data-reader")

aws_client.download_training_data(
    bucket="ml-training-data",
    key="datasets/fraud_detection_v3.parquet",
    local_path="./data/training.parquet"
)
```

#### Part 3: Audit and Monitoring (1 hour)

6. **Enable and Configure Audit Logging**:

```bash
# Enable file audit device
vault audit enable file file_path=/var/log/vault/audit.log

# Query audit logs for credential access
cat /var/log/vault/audit.log | jq 'select(.request.path | contains("database/creds"))'
```

7. **Implement Metrics Collection**:

```python
from prometheus_client import Counter, Histogram, start_http_server
import time

# Metrics
credential_requests = Counter(
    'vault_credential_requests_total',
    'Total credential requests',
    ['role', 'status']
)

credential_lease_duration = Histogram(
    'vault_credential_lease_duration_seconds',
    'Credential lease duration',
    ['role']
)

credential_renewal_attempts = Counter(
    'vault_credential_renewal_attempts_total',
    'Lease renewal attempts',
    ['status']
)


class MonitoredDynamicClient(DynamicDatabaseClient):
    """Database client with Prometheus metrics"""

    def _refresh_credentials(self):
        start_time = time.time()
        try:
            super()._refresh_credentials()
            credential_requests.labels(role=self.role_name, status='success').inc()
            credential_lease_duration.labels(role=self.role_name).observe(self.lease_duration)
        except Exception as e:
            credential_requests.labels(role=self.role_name, status='error').inc()
            raise

    def _start_lease_renewal(self):
        """Override to add metrics"""
        original_renew = super()._start_lease_renewal

        def renew_with_metrics():
            try:
                original_renew()
                credential_renewal_attempts.labels(status='success').inc()
            except Exception:
                credential_renewal_attempts.labels(status='error').inc()
                raise

        return renew_with_metrics()


# Start metrics server
start_http_server(8000)
```

### Success Criteria

- [ ] Vault generates short-lived database credentials
- [ ] Credentials automatically renewed before expiration
- [ ] Expired credentials properly revoked
- [ ] AWS dynamic credentials working for S3 access
- [ ] Audit logs capture all credential access
- [ ] Prometheus metrics exposed for monitoring
- [ ] No long-lived credentials in use

### Deliverables

1. `dynamic-credentials/database/`:
   - `setup.sh` - Database secrets engine configuration
   - `dynamic_db_client.py` - Python implementation
   - `test_dynamic_db.py` - Tests

2. `dynamic-credentials/aws/`:
   - `setup.sh` - AWS secrets engine configuration
   - `dynamic_aws_client.py` - Python implementation
   - IAM policy documents

3. `monitoring/`:
   - `metrics.py` - Prometheus metrics
   - `grafana-dashboard.json` - Dashboard definition

4. Documentation with:
   - Architecture diagram showing credential flow
   - Lease lifecycle explanation
   - Security benefits analysis
   - Troubleshooting guide

---

## Exercise 3: IAM Policy Management and API Key Security

**Time**: 2-3 hours
**Difficulty**: Intermediate

### Objectives

- Design least-privilege IAM policies for ML workloads
- Implement API key generation with proper entropy
- Build API key rotation system
- Set up Kubernetes RBAC for ML services
- Implement service account security

### Tasks

#### Part 1: AWS IAM Policy Design (1 hour)

1. **Create Least-Privilege Policies**:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "MLTrainingDataAccess",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::ml-training-data/*",
        "arn:aws:s3:::ml-training-data"
      ],
      "Condition": {
        "StringEquals": {
          "s3:ExistingObjectTag/Environment": "production",
          "s3:ExistingObjectTag/DataClassification": "internal"
        }
      }
    },
    {
      "Sid": "MLModelArtifactsWrite",
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:PutObjectTagging"
      ],
      "Resource": "arn:aws:s3:::ml-model-artifacts/${aws:PrincipalTag/TeamName}/*",
      "Condition": {
        "StringEquals": {
          "s3:x-amz-server-side-encryption": "AES256"
        }
      }
    },
    {
      "Sid": "MLFlowTracking",
      "Effect": "Allow",
      "Action": [
        "rds-db:connect"
      ],
      "Resource": "arn:aws:rds-db:us-west-2:123456789012:dbuser:*/mlflow_user"
    },
    {
      "Sid": "DenyUnencryptedUploads",
      "Effect": "Deny",
      "Action": "s3:PutObject",
      "Resource": "*",
      "Condition": {
        "StringNotEquals": {
          "s3:x-amz-server-side-encryption": "AES256"
        }
      }
    }
  ]
}
```

2. **Implement IAM Policy Validator**:

```python
import boto3
import json
from typing import List, Dict

class IAMPolicyValidator:
    """
    Validates IAM policies for security best practices
    """

    def __init__(self):
        self.iam = boto3.client('iam')
        self.access_analyzer = boto3.client('accessanalyzer')

    def validate_policy(self, policy_document: Dict) -> List[Dict]:
        """
        Validate policy using AWS Access Analyzer
        """
        findings = []

        # Check for overly permissive actions
        for statement in policy_document.get('Statement', []):
            actions = statement.get('Action', [])
            if isinstance(actions, str):
                actions = [actions]

            # Flag wildcard actions
            for action in actions:
                if '*' in action:
                    findings.append({
                        'severity': 'HIGH',
                        'issue': f"Wildcard action detected: {action}",
                        'recommendation': "Use specific actions instead of wildcards"
                    })

            # Flag missing conditions
            if 'Condition' not in statement and statement.get('Effect') == 'Allow':
                findings.append({
                    'severity': 'MEDIUM',
                    'issue': "Statement missing Condition block",
                    'recommendation': "Add conditions to restrict access"
                })

            # Flag overly broad resources
            resources = statement.get('Resource', [])
            if isinstance(resources, str):
                resources = [resources]

            for resource in resources:
                if resource == '*':
                    findings.append({
                        'severity': 'CRITICAL',
                        'issue': "Wildcard resource detected",
                        'recommendation': "Specify explicit resource ARNs"
                    })

        # Use AWS Access Analyzer for additional validation
        try:
            response = self.access_analyzer.validate_policy(
                policyDocument=json.dumps(policy_document),
                policyType='IDENTITY_POLICY'
            )

            for finding in response.get('findings', []):
                findings.append({
                    'severity': finding['findingType'],
                    'issue': finding['issueCode'],
                    'recommendation': finding.get('learnMoreLink', '')
                })
        except Exception as e:
            print(f"Access Analyzer validation failed: {e}")

        return findings

    def check_policy_for_privilege_escalation(self, policy_document: Dict) -> bool:
        """
        Check if policy allows privilege escalation
        """
        dangerous_actions = [
            'iam:CreatePolicy',
            'iam:CreatePolicyVersion',
            'iam:SetDefaultPolicyVersion',
            'iam:PassRole',
            'iam:AttachUserPolicy',
            'iam:AttachGroupPolicy',
            'iam:AttachRolePolicy',
            'iam:PutUserPolicy',
            'iam:PutGroupPolicy',
            'iam:PutRolePolicy',
            'iam:CreateAccessKey',
            'iam:UpdateAssumeRolePolicy'
        ]

        for statement in policy_document.get('Statement', []):
            if statement.get('Effect') != 'Allow':
                continue

            actions = statement.get('Action', [])
            if isinstance(actions, str):
                actions = [actions]

            for action in actions:
                if action in dangerous_actions or action == 'iam:*':
                    return True

        return False


# Usage
validator = IAMPolicyValidator()

policy = {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": "*"
        }
    ]
}

findings = validator.validate_policy(policy)
for finding in findings:
    print(f"[{finding['severity']}] {finding['issue']}")
    print(f"  Recommendation: {finding['recommendation']}\n")

if validator.check_policy_for_privilege_escalation(policy):
    print("WARNING: Policy may allow privilege escalation!")
```

#### Part 2: Secure API Key Management (1 hour)

3. **Implement Secure API Key Generation**:

```python
import secrets
import hashlib
import hmac
from datetime import datetime, timedelta
from typing import Optional, List, Dict
import base64

class APIKeyManager:
    """
    Secure API key generation and management system
    """

    def __init__(self, secret_key: str):
        self.secret_key = secret_key.encode()

    def generate_api_key(self, prefix: str = "sk", length: int = 32) -> str:
        """
        Generate cryptographically secure API key

        Format: {prefix}_{random_bytes}_{checksum}
        """
        # Generate random bytes with high entropy
        random_bytes = secrets.token_bytes(length)
        random_str = base64.urlsafe_b64encode(random_bytes).decode('utf-8').rstrip('=')

        # Generate checksum
        checksum = self._generate_checksum(random_str)

        api_key = f"{prefix}_{random_str}_{checksum}"
        return api_key

    def _generate_checksum(self, key_body: str) -> str:
        """Generate HMAC checksum for key validation"""
        h = hmac.new(self.secret_key, key_body.encode(), hashlib.sha256)
        return base64.urlsafe_b64encode(h.digest())[:8].decode('utf-8')

    def validate_api_key(self, api_key: str) -> bool:
        """Validate API key checksum"""
        try:
            parts = api_key.split('_')
            if len(parts) != 3:
                return False

            prefix, key_body, checksum = parts
            expected_checksum = self._generate_checksum(key_body)

            # Constant-time comparison to prevent timing attacks
            return hmac.compare_digest(checksum, expected_checksum)
        except Exception:
            return False

    def hash_api_key(self, api_key: str) -> str:
        """
        Hash API key for storage (store hash, not plaintext)
        """
        return hashlib.sha256(api_key.encode()).hexdigest()

    def generate_with_metadata(self, user_id: str, scopes: List[str]) -> Dict:
        """
        Generate API key with associated metadata
        """
        api_key = self.generate_api_key()
        api_key_hash = self.hash_api_key(api_key)

        metadata = {
            'key_hash': api_key_hash,
            'user_id': user_id,
            'scopes': scopes,
            'created_at': datetime.utcnow().isoformat(),
            'expires_at': (datetime.utcnow() + timedelta(days=90)).isoformat(),
            'last_used': None,
            'usage_count': 0
        }

        return {
            'api_key': api_key,  # Show once, never stored
            'metadata': metadata
        }


class APIKeyStore:
    """
    Store and manage API keys in Vault
    """

    def __init__(self, vault_client, key_manager: APIKeyManager):
        self.vault = vault_client
        self.key_manager = key_manager

    def create_key(self, user_id: str, scopes: List[str]) -> str:
        """Create new API key and store metadata"""
        key_data = self.key_manager.generate_with_metadata(user_id, scopes)

        # Store only the hash and metadata in Vault
        self.vault.secrets.kv.v2.create_or_update_secret(
            path=f"api-keys/{key_data['metadata']['key_hash']}",
            secret=key_data['metadata'],
            mount_point="ml-secrets"
        )

        # Return plaintext key (shown once)
        return key_data['api_key']

    def validate_and_get_metadata(self, api_key: str) -> Optional[Dict]:
        """Validate key and return metadata"""
        # First check format
        if not self.key_manager.validate_api_key(api_key):
            return None

        # Get metadata from Vault
        key_hash = self.key_manager.hash_api_key(api_key)
        try:
            secret = self.vault.secrets.kv.v2.read_secret_version(
                path=f"api-keys/{key_hash}",
                mount_point="ml-secrets"
            )
            metadata = secret['data']['data']

            # Check expiration
            expires_at = datetime.fromisoformat(metadata['expires_at'])
            if datetime.utcnow() > expires_at:
                return None

            # Update usage statistics
            metadata['usage_count'] += 1
            metadata['last_used'] = datetime.utcnow().isoformat()
            self.vault.secrets.kv.v2.create_or_update_secret(
                path=f"api-keys/{key_hash}",
                secret=metadata,
                mount_point="ml-secrets"
            )

            return metadata
        except Exception:
            return None

    def revoke_key(self, api_key: str):
        """Revoke API key"""
        key_hash = self.key_manager.hash_api_key(api_key)
        self.vault.secrets.kv.v2.delete_metadata_and_all_versions(
            path=f"api-keys/{key_hash}",
            mount_point="ml-secrets"
        )

    def rotate_user_keys(self, user_id: str) -> str:
        """Rotate all keys for a user"""
        # List all keys (would need additional indexing in production)
        # Revoke old keys
        # Generate new key
        new_key = self.create_key(user_id, scopes=['ml:read', 'ml:write'])
        return new_key


# Usage
key_manager = APIKeyManager(secret_key="your-secret-key-for-hmac")
vault_client = hvac.Client(url="http://localhost:8200", token="dev-token")
key_store = APIKeyStore(vault_client, key_manager)

# Create new API key
api_key = key_store.create_key(
    user_id="user123",
    scopes=["model:inference", "data:read"]
)
print(f"New API key (save this, it won't be shown again): {api_key}")

# Validate key
metadata = key_store.validate_and_get_metadata(api_key)
if metadata:
    print(f"Valid key for user: {metadata['user_id']}")
    print(f"Scopes: {metadata['scopes']}")
    print(f"Usage count: {metadata['usage_count']}")
```

#### Part 3: Kubernetes RBAC (45 minutes)

4. **Implement RBAC for ML Workloads**:

```yaml
# ml-training-role.yaml
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ml-training-sa
  namespace: ml-workloads
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::123456789012:role/ml-training-role

---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: ml-training-role
  namespace: ml-workloads
rules:
  # Read access to ConfigMaps for configuration
  - apiGroups: [""]
    resources: ["configmaps"]
    verbs: ["get", "list"]
    resourceNames: ["ml-config", "feature-store-config"]

  # Read access to Secrets
  - apiGroups: [""]
    resources: ["secrets"]
    verbs: ["get"]
    resourceNames: ["model-registry-creds", "db-connection"]

  # Create and manage pods for distributed training
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["create", "get", "list", "delete"]

  # Access pod logs
  - apiGroups: [""]
    resources: ["pods/log"]
    verbs: ["get"]

  # No access to modify RBAC
  # No access to other namespaces
  # No access to cluster-level resources

---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: ml-training-binding
  namespace: ml-workloads
subjects:
  - kind: ServiceAccount
    name: ml-training-sa
    namespace: ml-workloads
roleRef:
  kind: Role
  name: ml-training-role
  apiGroup: rbac.authorization.k8s.io

---
# Network Policy to restrict traffic
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: ml-training-netpol
  namespace: ml-workloads
spec:
  podSelector:
    matchLabels:
      app: ml-training
  policyTypes:
    - Ingress
    - Egress
  ingress:
    # Only allow traffic from monitoring
    - from:
        - namespaceSelector:
            matchLabels:
              name: monitoring
        ports:
          - protocol: TCP
            port: 9090
  egress:
    # Allow S3 access
    - to:
        - namespaceSelector: {}
      ports:
        - protocol: TCP
          port: 443
    # Allow DNS
    - to:
        - namespaceSelector:
            matchLabels:
              name: kube-system
      ports:
        - protocol: UDP
          port: 53
```

5. **Test RBAC Configuration**:

```python
from kubernetes import client, config

def test_rbac_permissions():
    """Test that service account has correct permissions"""
    config.load_kube_config()

    # Create API clients
    v1 = client.CoreV1Api()
    rbac_v1 = client.RbacAuthorizationV1Api()

    # Test reading allowed ConfigMap
    try:
        cm = v1.read_namespaced_config_map("ml-config", "ml-workloads")
        print("✓ Can read allowed ConfigMap")
    except client.exceptions.ApiException as e:
        print(f"✗ Cannot read ConfigMap: {e.status}")

    # Test reading disallowed Secret
    try:
        secret = v1.read_namespaced_secret("admin-secret", "ml-workloads")
        print("✗ SECURITY ISSUE: Can read disallowed Secret!")
    except client.exceptions.ApiException as e:
        if e.status == 403:
            print("✓ Correctly denied access to disallowed Secret")

    # Test creating pod
    try:
        pod = client.V1Pod(
            metadata=client.V1ObjectMeta(name="test-pod"),
            spec=client.V1PodSpec(
                service_account_name="ml-training-sa",
                containers=[
                    client.V1Container(
                        name="test",
                        image="busybox",
                        command=["sleep", "3600"]
                    )
                ]
            )
        )
        v1.create_namespaced_pod("ml-workloads", pod)
        print("✓ Can create pods")

        # Cleanup
        v1.delete_namespaced_pod("test-pod", "ml-workloads")
    except client.exceptions.ApiException as e:
        print(f"✗ Cannot create pods: {e.status}")

    # Test modifying RBAC (should fail)
    try:
        role = rbac_v1.read_namespaced_role("ml-training-role", "ml-workloads")
        role.rules.append(
            client.V1PolicyRule(
                api_groups=[""],
                resources=["secrets"],
                verbs=["*"]
            )
        )
        rbac_v1.replace_namespaced_role("ml-training-role", "ml-workloads", role)
        print("✗ SECURITY ISSUE: Can modify RBAC!")
    except client.exceptions.ApiException as e:
        if e.status == 403:
            print("✓ Correctly denied RBAC modification")

test_rbac_permissions()
```

### Success Criteria

- [ ] IAM policies follow least-privilege principle
- [ ] IAM policy validator catches security issues
- [ ] API keys generated with high entropy
- [ ] API key validation includes checksum verification
- [ ] Only key hashes stored, never plaintexts
- [ ] Kubernetes RBAC limits service account permissions
- [ ] Network policies restrict pod communication
- [ ] RBAC tests verify correct permissions

### Deliverables

1. `iam-policies/`:
   - JSON policy documents for each ML workload
   - `policy_validator.py` - Validation tool
   - Test cases

2. `api-keys/`:
   - `key_manager.py` - Key generation and validation
   - `key_store.py` - Vault integration
   - Rotation automation scripts

3. `kubernetes-rbac/`:
   - YAML manifests for roles and bindings
   - Network policy definitions
   - `test_rbac.py` - Permission tests

4. Security documentation:
   - IAM policy design principles
   - API key lifecycle management
   - RBAC configuration guide

---

## Exercise 4: Certificate Lifecycle Automation

**Time**: 2-3 hours
**Difficulty**: Advanced

### Objectives

- Set up Vault PKI secrets engine
- Implement automated certificate issuance
- Build certificate rotation daemon
- Configure mTLS for ML services
- Monitor certificate expiration

### Tasks

#### Part 1: Vault PKI Setup (45 minutes)

1. **Configure Root and Intermediate CAs**:

```bash
# Enable PKI secrets engine for root CA
vault secrets enable -path=pki pki
vault secrets tune -max-lease-ttl=87600h pki

# Generate root CA
vault write -field=certificate pki/root/generate/internal \
  common_name="ML Infrastructure Root CA" \
  ttl=87600h > /tmp/ml_root_ca.crt

# Configure CA and CRL URLs
vault write pki/config/urls \
  issuing_certificates="http://vault.example.com:8200/v1/pki/ca" \
  crl_distribution_points="http://vault.example.com:8200/v1/pki/crl"

# Enable intermediate CA
vault secrets enable -path=pki_int pki
vault secrets tune -max-lease-ttl=43800h pki_int

# Generate intermediate CSR
vault write -format=json pki_int/intermediate/generate/internal \
  common_name="ML Infrastructure Intermediate CA" \
  | jq -r '.data.csr' > /tmp/pki_intermediate.csr

# Sign intermediate certificate with root CA
vault write -format=json pki/root/sign-intermediate \
  csr=@/tmp/pki_intermediate.csr \
  format=pem_bundle \
  ttl=43800h \
  | jq -r '.data.certificate' > /tmp/intermediate.cert.pem

# Set the signed certificate
vault write pki_int/intermediate/set-signed \
  certificate=@/tmp/intermediate.cert.pem
```

2. **Create Certificate Roles**:

```bash
# Role for ML service certificates
vault write pki_int/roles/ml-service \
  allowed_domains="ml.example.com,*.ml.example.com" \
  allow_subdomains=true \
  max_ttl="720h" \
  key_type="rsa" \
  key_bits=2048 \
  require_cn=true

# Role for client certificates (mTLS)
vault write pki_int/roles/ml-client \
  allowed_domains="client.ml.example.com" \
  allow_subdomains=true \
  max_ttl="168h" \
  client_flag=true \
  key_type="rsa" \
  key_bits=2048
```

#### Part 2: Certificate Management System (1.5 hours)

3. **Implement Certificate Manager**:

```python
import hvac
import os
import subprocess
import time
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, Optional
import threading

class CertificateManager:
    """
    Automated certificate lifecycle management using Vault PKI
    """

    def __init__(self, vault_client: hvac.Client, pki_mount: str = "pki_int"):
        self.vault = vault_client
        self.pki_mount = pki_mount

    def issue_certificate(
        self,
        role: str,
        common_name: str,
        alt_names: Optional[list] = None,
        ip_sans: Optional[list] = None,
        ttl: str = "720h"
    ) -> Dict:
        """
        Issue new certificate from Vault PKI

        Returns:
            Dictionary with certificate, private_key, ca_chain, serial_number
        """
        data = {
            'common_name': common_name,
            'ttl': ttl
        }

        if alt_names:
            data['alt_names'] = ','.join(alt_names)

        if ip_sans:
            data['ip_sans'] = ','.join(ip_sans)

        response = self.vault.write(
            f"{self.pki_mount}/issue/{role}",
            **data
        )

        cert_data = response['data']

        return {
            'certificate': cert_data['certificate'],
            'private_key': cert_data['private_key'],
            'ca_chain': cert_data['ca_chain'],
            'serial_number': cert_data['serial_number'],
            'expiration': cert_data['expiration']
        }

    def revoke_certificate(self, serial_number: str):
        """Revoke certificate by serial number"""
        self.vault.write(
            f"{self.pki_mount}/revoke",
            serial_number=serial_number
        )

    def get_crl(self) -> str:
        """Get Certificate Revocation List"""
        response = self.vault.read(f"{self.pki_mount}/cert/crl")
        return response['data']['certificate']

    def write_certificate_files(
        self,
        cert_data: Dict,
        cert_path: str,
        key_path: str,
        ca_path: str
    ):
        """Write certificate files to disk with proper permissions"""
        # Write certificate
        Path(cert_path).write_text(cert_data['certificate'])
        os.chmod(cert_path, 0o644)

        # Write private key (restrictive permissions)
        Path(key_path).write_text(cert_data['private_key'])
        os.chmod(key_path, 0o600)

        # Write CA chain
        ca_chain = '\n'.join(cert_data['ca_chain'])
        Path(ca_path).write_text(ca_chain)
        os.chmod(ca_path, 0o644)

        print(f"Certificate files written:")
        print(f"  Certificate: {cert_path}")
        print(f"  Private Key: {key_path}")
        print(f"  CA Chain: {ca_path}")

    def get_certificate_expiry(self, cert_path: str) -> datetime:
        """Get certificate expiration time"""
        result = subprocess.run(
            ['openssl', 'x509', '-enddate', '-noout', '-in', cert_path],
            capture_output=True,
            text=True
        )

        # Parse: notAfter=Jan  1 00:00:00 2025 GMT
        date_str = result.stdout.split('=')[1].strip()
        return datetime.strptime(date_str, '%b %d %H:%M:%S %Y %Z')

    def should_rotate(self, cert_path: str, rotation_threshold: float = 0.2) -> bool:
        """
        Check if certificate should be rotated

        Args:
            cert_path: Path to certificate file
            rotation_threshold: Rotate when this fraction of lifetime remains (0.2 = 20%)
        """
        if not Path(cert_path).exists():
            return True

        expiry = self.get_certificate_expiry(cert_path)
        now = datetime.utcnow()

        # Calculate certificate lifetime and remaining time
        result = subprocess.run(
            ['openssl', 'x509', '-startdate', '-noout', '-in', cert_path],
            capture_output=True,
            text=True
        )
        start_str = result.stdout.split('=')[1].strip()
        start = datetime.strptime(start_str, '%b %d %H:%M:%S %Y %Z')

        total_lifetime = (expiry - start).total_seconds()
        remaining = (expiry - now).total_seconds()

        return remaining < (total_lifetime * rotation_threshold)


class CertificateRotationDaemon:
    """
    Background daemon for automatic certificate rotation
    """

    def __init__(
        self,
        cert_manager: CertificateManager,
        config: Dict
    ):
        self.cert_manager = cert_manager
        self.config = config
        self.running = False
        self._thread = None

    def start(self):
        """Start rotation daemon"""
        if self.running:
            return

        self.running = True
        self._thread = threading.Thread(target=self._rotation_loop, daemon=True)
        self._thread.start()
        print("Certificate rotation daemon started")

    def stop(self):
        """Stop rotation daemon"""
        self.running = False
        if self._thread:
            self._thread.join()

    def _rotation_loop(self):
        """Main rotation loop"""
        while self.running:
            try:
                self._check_and_rotate()
            except Exception as e:
                print(f"Rotation check failed: {e}")

            # Check every hour
            time.sleep(3600)

    def _check_and_rotate(self):
        """Check all certificates and rotate if needed"""
        for service_name, service_config in self.config.items():
            cert_path = service_config['cert_path']

            if self.cert_manager.should_rotate(cert_path):
                print(f"Rotating certificate for {service_name}")
                self._rotate_service_certificate(service_name, service_config)

    def _rotate_service_certificate(self, service_name: str, config: Dict):
        """Rotate certificate for a service"""
        # Issue new certificate
        cert_data = self.cert_manager.issue_certificate(
            role=config['role'],
            common_name=config['common_name'],
            alt_names=config.get('alt_names'),
            ttl=config['ttl']
        )

        # Write certificate files
        self.cert_manager.write_certificate_files(
            cert_data=cert_data,
            cert_path=config['cert_path'],
            key_path=config['key_path'],
            ca_path=config['ca_path']
        )

        # Reload service
        if 'reload_command' in config:
            subprocess.run(config['reload_command'], shell=True)
            print(f"Service {service_name} reloaded with new certificate")

        # Store serial number for potential revocation
        serial_path = f"{config['cert_path']}.serial"
        Path(serial_path).write_text(cert_data['serial_number'])


# Usage example
vault_client = hvac.Client(url="http://localhost:8200", token="dev-token")
cert_manager = CertificateManager(vault_client)

# Issue certificate for ML inference service
cert_data = cert_manager.issue_certificate(
    role="ml-service",
    common_name="inference.ml.example.com",
    alt_names=["inference-api.ml.example.com", "api.ml.example.com"],
    ip_sans=["10.0.1.100"],
    ttl="720h"
)

cert_manager.write_certificate_files(
    cert_data=cert_data,
    cert_path="/etc/ml-service/tls.crt",
    key_path="/etc/ml-service/tls.key",
    ca_path="/etc/ml-service/ca.crt"
)

# Start rotation daemon
rotation_config = {
    'ml-inference': {
        'role': 'ml-service',
        'common_name': 'inference.ml.example.com',
        'alt_names': ['inference-api.ml.example.com'],
        'ttl': '720h',
        'cert_path': '/etc/ml-service/tls.crt',
        'key_path': '/etc/ml-service/tls.key',
        'ca_path': '/etc/ml-service/ca.crt',
        'reload_command': 'systemctl reload ml-inference-service'
    }
}

daemon = CertificateRotationDaemon(cert_manager, rotation_config)
daemon.start()
```

#### Part 3: mTLS Configuration (1 hour)

4. **Implement mTLS for ML Services**:

```python
from flask import Flask, request, jsonify
import ssl
import requests

app = Flask(__name__)

class MLServiceClient:
    """
    Client with mTLS authentication
    """

    def __init__(
        self,
        cert_path: str,
        key_path: str,
        ca_path: str
    ):
        self.cert_path = cert_path
        self.key_path = key_path
        self.ca_path = ca_path

    def predict(self, endpoint: str, data: dict) -> dict:
        """Make prediction request with mTLS"""
        response = requests.post(
            endpoint,
            json=data,
            cert=(self.cert_path, self.key_path),
            verify=self.ca_path
        )
        response.raise_for_status()
        return response.json()


# Server configuration with mTLS
def create_mtls_app():
    """Create Flask app with mTLS"""

    @app.before_request
    def verify_client_cert():
        """Verify client certificate"""
        cert = request.environ.get('SSL_CLIENT_CERT')
        if not cert:
            return jsonify({'error': 'Client certificate required'}), 403

        # Extract client identity from certificate
        subject = request.environ.get('SSL_CLIENT_S_DN')
        print(f"Request from: {subject}")

    @app.route('/predict', methods=['POST'])
    def predict():
        """Prediction endpoint"""
        data = request.json
        # ML inference logic here
        return jsonify({'prediction': 42})

    return app


if __name__ == '__main__':
    app = create_mtls_app()

    # Configure SSL context for mTLS
    context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    context.load_cert_chain(
        '/etc/ml-service/tls.crt',
        '/etc/ml-service/tls.key'
    )
    context.load_verify_locations('/etc/ml-service/ca.crt')
    context.verify_mode = ssl.CERT_REQUIRED

    app.run(host='0.0.0.0', port=8443, ssl_context=context)
```

5. **Certificate Monitoring**:

```python
from prometheus_client import Gauge, Counter, start_http_server
import time

# Metrics
cert_expiry_seconds = Gauge(
    'certificate_expiry_seconds',
    'Seconds until certificate expiration',
    ['service', 'common_name']
)

cert_rotation_total = Counter(
    'certificate_rotation_total',
    'Total certificate rotations',
    ['service', 'status']
)


class CertificateMonitor:
    """Monitor certificate expiration"""

    def __init__(self, cert_manager: CertificateManager, config: Dict):
        self.cert_manager = cert_manager
        self.config = config

    def update_metrics(self):
        """Update Prometheus metrics"""
        for service_name, service_config in self.config.items():
            cert_path = service_config['cert_path']

            if Path(cert_path).exists():
                expiry = self.cert_manager.get_certificate_expiry(cert_path)
                seconds_remaining = (expiry - datetime.utcnow()).total_seconds()

                cert_expiry_seconds.labels(
                    service=service_name,
                    common_name=service_config['common_name']
                ).set(seconds_remaining)

    def start(self):
        """Start monitoring loop"""
        while True:
            self.update_metrics()
            time.sleep(300)  # Update every 5 minutes


# Start metrics server
start_http_server(8000)
monitor = CertificateMonitor(cert_manager, rotation_config)
monitor.start()
```

### Success Criteria

- [ ] Vault PKI configured with root and intermediate CAs
- [ ] Certificates issued automatically via API
- [ ] Certificate rotation daemon running
- [ ] mTLS working between ML services
- [ ] Certificate expiration metrics exported
- [ ] Rotation happens before expiration
- [ ] Service reloads gracefully with new certificates

### Deliverables

1. `pki-setup/`:
   - `setup-pki.sh` - Vault PKI configuration script
   - `create-roles.sh` - Certificate role definitions

2. `certificate-manager/`:
   - `cert_manager.py` - Certificate lifecycle management
   - `rotation_daemon.py` - Automatic rotation
   - `mtls_server.py` - mTLS server example
   - `mtls_client.py` - mTLS client example

3. `monitoring/`:
   - `cert_monitor.py` - Prometheus metrics
   - `grafana-cert-dashboard.json` - Dashboard

4. Documentation:
   - PKI architecture diagram
   - Certificate lifecycle workflow
   - mTLS setup guide
   - Troubleshooting common issues

---

## Additional Resources

### Tools & Libraries

- **HashiCorp Vault**: https://www.vaultproject.io/docs
- **hvac (Python Vault client)**: https://hvac.readthedocs.io/
- **AWS Secrets Manager**: https://docs.aws.amazon.com/secretsmanager/
- **Azure Key Vault**: https://docs.microsoft.com/en-us/azure/key-vault/
- **GCP Secret Manager**: https://cloud.google.com/secret-manager/docs

### Best Practices

1. **Never commit secrets to git** - Use git-secrets or similar tools
2. **Rotate secrets regularly** - Automate rotation where possible
3. **Use short-lived credentials** - Dynamic secrets preferred over static
4. **Audit all secret access** - Enable and monitor audit logs
5. **Principle of least privilege** - Grant minimum necessary permissions
6. **Encrypt secrets at rest** - Use Vault Transit or cloud KMS
7. **Monitor certificate expiration** - Set alerts well before expiration

### Common Pitfalls

- Hardcoding secrets in environment variables (still visible in process list)
- Using root tokens in production
- Not implementing secret rotation
- Overly permissive IAM policies
- Not monitoring secret access patterns
- Missing certificate expiration alerts
- Inadequate key entropy for API keys

### Assessment Rubric

**Advanced (90-100%)**
- All exercises completed with automation
- Comprehensive error handling and retry logic
- Production-ready monitoring and alerting
- Detailed security documentation
- Advanced features (mTLS, rotation, dynamic secrets)

**Proficient (75-89%)**
- Core functionality working correctly
- Basic error handling implemented
- Monitoring configured
- Good documentation
- Some advanced features

**Developing (60-74%)**
- Basic secret management working
- Manual processes acceptable
- Limited monitoring
- Minimal documentation
- Advanced features attempted

**Needs Improvement (<60%)**
- Incomplete implementations
- Secrets management basics not working
- No monitoring
- Poor documentation
