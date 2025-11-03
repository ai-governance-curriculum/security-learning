# Module 4: Secrets & Identity Management

## Overview

This module focuses on secure secrets management and identity access management for ML systems. You'll learn to use HashiCorp Vault, AWS Secrets Manager, Azure Key Vault, implement robust IAM, manage API keys, and handle certificate rotation—all critical for securing ML infrastructure.

**Duration**: 20 hours
**Prerequisites**: Module 1 (ML Security Fundamentals), cloud platforms basics, basic cryptography

## Learning Objectives

By completing this module, you will:

1. Deploy and configure HashiCorp Vault for ML secrets
2. Integrate AWS Secrets Manager and Azure Key Vault
3. Implement least-privilege IAM policies for ML workloads
4. Securely manage API keys and credentials
5. Automate certificate management and rotation
6. Build secrets injection pipelines
7. Implement dynamic secrets for databases

---

## 1. Secrets Management Fundamentals (3 hours)

### 1.1 What Are Secrets?

**Secrets** are sensitive data that should never be exposed:

**Categories**:
1. **Credentials**: Passwords, API keys, tokens
2. **Certificates**: TLS/SSL certificates, private keys
3. **Database Credentials**: Connection strings, passwords
4. **Cloud Provider Keys**: AWS access keys, GCP service account keys
5. **Encryption Keys**: Data encryption keys, signing keys
6. **ML-Specific**: Model API keys, training job credentials, feature store access

### 1.2 Why Secrets Management Matters

**Common Anti-Patterns (DO NOT DO THIS)**:

```python
# ❌ NEVER hardcode secrets in code
AWS_ACCESS_KEY = "AKIAIOSFODNN7EXAMPLE"
AWS_SECRET_KEY = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"

# ❌ NEVER commit secrets to git
DATABASE_PASSWORD = "super_secret_password_123"

# ❌ NEVER use environment variables for sensitive secrets (can leak in logs)
os.environ["API_KEY"] = "sk-1234567890abcdef"

# ❌ NEVER store secrets in config files
config.yaml:
  database:
    password: "plaintext_password"
```

**Consequences**:
- GitHub has billions of leaked secrets
- AWS keys leaked → $50,000 AWS bill in hours
- Database passwords in code → data breaches
- API keys in logs → unauthorized access

**Proper Secrets Management**:

```python
# ✅ Use secrets manager
from vault_client import VaultClient

vault = VaultClient()
db_password = vault.get_secret("database/password")

# ✅ Use short-lived credentials
credentials = vault.get_dynamic_database_credentials(ttl=3600)  # 1 hour

# ✅ Use IAM roles (no keys needed)
boto3.client('s3')  # Uses instance role, no hardcoded keys
```

### 1.3 Secrets Management Requirements

**CIA Triad for Secrets**:

1. **Confidentiality**: Only authorized entities can access secrets
2. **Integrity**: Secrets cannot be tampered with
3. **Availability**: Secrets available when needed (but not exposed)

**Additional Requirements**:
- **Rotation**: Regular password/key changes
- **Auditing**: Track all secret access
- **Revocation**: Immediately revoke compromised secrets
- **Encryption**: Secrets encrypted at rest and in transit
- **Least Privilege**: Minimum necessary access

---

## 2. HashiCorp Vault (8 hours)

### 2.1 Vault Architecture

**Core Components**:

```
Client (ML App) → Vault Server → Storage Backend (Consul, etcd, etc.)
                       ↓
                  Secrets Engines
                  - KV (Key-Value)
                  - Database (dynamic credentials)
                  - AWS (dynamic IAM credentials)
                  - PKI (certificates)
                  - Transit (encryption as a service)
```

**Key Features**:
- **Secrets Engines**: Pluggable backends for different secret types
- **Dynamic Secrets**: Generate credentials on-demand with TTL
- **Encryption as a Service**: Encrypt/decrypt without storing keys
- **Audit Logging**: Complete audit trail
- **Policies**: Fine-grained access control

### 2.2 Vault Setup and Configuration

**Installation**:

```bash
# Install Vault
wget https://releases.hashicorp.com/vault/1.15.0/vault_1.15.0_linux_amd64.zip
unzip vault_1.15.0_linux_amd64.zip
sudo mv vault /usr/local/bin/

# Verify installation
vault version
```

**Configuration** (`config.hcl`):

```hcl
# Vault server configuration for production

storage "consul" {
  address = "127.0.0.1:8500"
  path    = "vault/"
}

listener "tcp" {
  address       = "0.0.0.0:8200"
  tls_cert_file = "/etc/vault/tls/vault.crt"
  tls_key_file  = "/etc/vault/tls/vault.key"
}

# Seal configuration (auto-unseal with cloud KMS recommended for production)
seal "awskms" {
  region     = "us-west-2"
  kms_key_id = "arn:aws:kms:us-west-2:123456789012:key/12345678-1234-1234-1234-123456789012"
}

api_addr = "https://vault.example.com:8200"
cluster_addr = "https://vault.example.com:8201"

ui = true
```

**Initialization**:

```bash
# Start Vault server
vault server -config=config.hcl

# Initialize Vault (run once)
vault operator init -key-shares=5 -key-threshold=3

# Output:
# Unseal Key 1: <key1>
# Unseal Key 2: <key2>
# Unseal Key 3: <key3>
# Unseal Key 4: <key4>
# Unseal Key 5: <key5>
# Initial Root Token: <root_token>

# ⚠️ CRITICAL: Store unseal keys securely (split among trusted parties)

# Unseal Vault (requires 3 of 5 keys)
vault operator unseal <key1>
vault operator unseal <key2>
vault operator unseal <key3>

# Authenticate with root token
export VAULT_TOKEN=<root_token>
```

### 2.3 Key-Value Secrets Engine

**Enable KV Engine**:

```bash
# Enable KV v2 (versioned secrets)
vault secrets enable -path=ml-secrets kv-v2

# Store a secret
vault kv put ml-secrets/model-api-key \
  api_key=sk-1234567890abcdef \
  endpoint=https://api.openai.com \
  rate_limit=10000

# Read a secret
vault kv get ml-secrets/model-api-key

# Read specific field
vault kv get -field=api_key ml-secrets/model-api-key
```

**Python Integration**:

```python
import hvac

class VaultClient:
    """
    HashiCorp Vault client for ML applications
    """
    def __init__(self, url="http://localhost:8200"):
        self.client = hvac.Client(url=url)

        # Authenticate using AppRole
        self._authenticate()

    def _authenticate(self):
        """
        Authenticate to Vault using AppRole
        """
        # AppRole credentials (from environment or K8s secret)
        role_id = os.environ.get("VAULT_ROLE_ID")
        secret_id = os.environ.get("VAULT_SECRET_ID")

        self.client.auth.approle.login(
            role_id=role_id,
            secret_id=secret_id
        )

    def get_secret(self, path, field=None):
        """
        Retrieve secret from Vault

        Args:
            path: Secret path (e.g., "ml-secrets/model-api-key")
            field: Optional specific field to extract

        Returns:
            Secret value(s)
        """
        try:
            secret = self.client.secrets.kv.v2.read_secret_version(
                path=path,
                mount_point="ml-secrets"
            )

            data = secret['data']['data']

            if field:
                return data.get(field)
            return data

        except hvac.exceptions.InvalidPath:
            raise ValueError(f"Secret not found: {path}")

    def write_secret(self, path, **kwargs):
        """
        Write secret to Vault
        """
        self.client.secrets.kv.v2.create_or_update_secret(
            path=path,
            secret=kwargs,
            mount_point="ml-secrets"
        )

    def delete_secret(self, path):
        """
        Delete secret from Vault
        """
        self.client.secrets.kv.v2.delete_latest_version_of_secret(
            path=path,
            mount_point="ml-secrets"
        )

# Usage in ML application
vault = VaultClient()

# Get API key for model inference
api_key = vault.get_secret("model-api-key", field="api_key")

# Make API call
response = requests.post(
    "https://api.openai.com/v1/completions",
    headers={"Authorization": f"Bearer {api_key}"},
    json={"prompt": "Hello, world!", "max_tokens": 50}
)
```

### 2.4 Dynamic Secrets for Databases

**Enable Database Engine**:

```bash
# Enable database secrets engine
vault secrets enable database

# Configure PostgreSQL connection
vault write database/config/ml-postgres \
  plugin_name=postgresql-database-plugin \
  allowed_roles="ml-readonly,ml-readwrite" \
  connection_url="postgresql://{{username}}:{{password}}@localhost:5432/mldb" \
  username="vault_admin" \
  password="vault_admin_password"

# Create role for read-only access
vault write database/roles/ml-readonly \
  db_name=ml-postgres \
  creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; \
    GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
  default_ttl="1h" \
  max_ttl="24h"

# Generate dynamic credentials
vault read database/creds/ml-readonly

# Output:
# Key                Value
# ---                -----
# lease_id           database/creds/ml-readonly/abcd1234
# lease_duration     1h
# lease_renewable    true
# password           A1a-random-generated-password
# username           v-root-ml-readonly-abcd1234
```

**Python Integration**:

```python
class VaultDatabaseClient:
    """
    Generate dynamic database credentials from Vault
    """
    def __init__(self, vault_client):
        self.vault = vault_client
        self.lease_id = None

    def get_database_credentials(self, role_name="ml-readonly"):
        """
        Get short-lived database credentials

        Returns:
            dict: {'username': '...', 'password': '...'}
        """
        response = self.vault.client.read(f"database/creds/{role_name}")

        self.lease_id = response['lease_id']

        return {
            'username': response['data']['username'],
            'password': response['data']['password'],
            'lease_duration': response['lease_duration']
        }

    def renew_lease(self):
        """
        Renew database credentials lease
        """
        if self.lease_id:
            self.vault.client.sys.renew_lease(
                lease_id=self.lease_id,
                increment=3600  # Extend by 1 hour
            )

    def revoke_lease(self):
        """
        Revoke database credentials immediately
        """
        if self.lease_id:
            self.vault.client.sys.revoke_lease(lease_id=self.lease_id)

# Usage in ML training job
vault_client = VaultClient()
db_client = VaultDatabaseClient(vault_client)

# Get dynamic credentials (valid for 1 hour)
creds = db_client.get_database_credentials("ml-readonly")

# Connect to database
import psycopg2

conn = psycopg2.connect(
    host="localhost",
    database="mldb",
    user=creds['username'],
    password=creds['password']
)

# Load training data
df = pd.read_sql("SELECT * FROM training_data", conn)

# Train model
model = train_model(df)

# Revoke credentials when done
db_client.revoke_lease()
conn.close()

# Credentials automatically revoked after TTL expires
# No long-lived database passwords!
```

**Benefits of Dynamic Secrets**:
- ✅ No long-lived credentials
- ✅ Automatic rotation (new credentials every use)
- ✅ Automatic revocation after TTL
- ✅ Audit trail of all credential generation
- ✅ Immediate revocation if compromised

### 2.5 AWS Dynamic Credentials

**Enable AWS Secrets Engine**:

```bash
# Enable AWS secrets engine
vault secrets enable aws

# Configure AWS root credentials (stored securely in Vault)
vault write aws/config/root \
  access_key=AKIAIOSFODNN7EXAMPLE \
  secret_key=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY \
  region=us-west-2

# Create role for S3 read-only access
vault write aws/roles/ml-s3-readonly \
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

# Generate dynamic AWS credentials
vault read aws/creds/ml-s3-readonly

# Output:
# Key                Value
# ---                -----
# lease_id           aws/creds/ml-s3-readonly/xyz789
# access_key         AKIAIOSFODNN7DYNAMIC
# secret_key         wJalrXUtnFEMI/K7MDENG/DYNAMICKEY
# security_token     <none>
```

**Python Integration**:

```python
class VaultAWSClient:
    """
    Generate dynamic AWS credentials from Vault
    """
    def get_aws_credentials(self, role_name="ml-s3-readonly"):
        """
        Get short-lived AWS credentials
        """
        response = self.vault.client.read(f"aws/creds/{role_name}")

        return {
            'aws_access_key_id': response['data']['access_key'],
            'aws_secret_access_key': response['data']['secret_key'],
            'lease_id': response['lease_id']
        }

# Usage
vault_aws = VaultAWSClient(vault_client)
creds = vault_aws.get_aws_credentials("ml-s3-readonly")

# Use with boto3
import boto3

s3_client = boto3.client(
    's3',
    aws_access_key_id=creds['aws_access_key_id'],
    aws_secret_access_key=creds['aws_secret_access_key']
)

# Download training data
s3_client.download_file('ml-training-data', 'train.csv', 'local_train.csv')

# Credentials automatically revoked after TTL
```

### 2.6 Transit Secrets Engine (Encryption as a Service)

**Use Case**: Encrypt sensitive data without managing encryption keys

```bash
# Enable transit engine
vault secrets enable transit

# Create encryption key
vault write -f transit/keys/ml-data-encryption

# Encrypt data
vault write transit/encrypt/ml-data-encryption \
  plaintext=$(base64 <<< "sensitive training data")

# Output: vault:v1:8SDd3WHDOjf7mq69CyCqYjBXAiQQAVZRkFM96XVcRMI=

# Decrypt data
vault write transit/decrypt/ml-data-encryption \
  ciphertext=vault:v1:8SDd3WHDOjf7mq69CyCqYjBXAiQQAVZRkFM96XVcRMI=

# Output (base64): c2Vuc2l0aXZlIHRyYWluaW5nIGRhdGEK
```

**Python Integration**:

```python
import base64

class VaultEncryption:
    """
    Encryption as a Service using Vault Transit
    """
    def __init__(self, vault_client, key_name="ml-data-encryption"):
        self.vault = vault_client
        self.key_name = key_name

    def encrypt(self, plaintext):
        """
        Encrypt data using Vault

        Args:
            plaintext: String or bytes to encrypt

        Returns:
            Encrypted ciphertext
        """
        if isinstance(plaintext, str):
            plaintext = plaintext.encode('utf-8')

        # Base64 encode plaintext
        encoded = base64.b64encode(plaintext).decode('utf-8')

        # Encrypt with Vault
        response = self.vault.client.secrets.transit.encrypt_data(
            name=self.key_name,
            plaintext=encoded
        )

        return response['data']['ciphertext']

    def decrypt(self, ciphertext):
        """
        Decrypt data using Vault
        """
        response = self.vault.client.secrets.transit.decrypt_data(
            name=self.key_name,
            ciphertext=ciphertext
        )

        # Base64 decode plaintext
        encoded = response['data']['plaintext']
        plaintext = base64.b64decode(encoded).decode('utf-8')

        return plaintext

    def rotate_key(self):
        """
        Rotate encryption key (old data still decryptable)
        """
        self.vault.client.secrets.transit.rotate_key(name=self.key_name)

# Usage: Encrypt sensitive features before storage
encryption = VaultEncryption(vault_client)

# Encrypt PII before storing in feature store
sensitive_data = "SSN: 123-45-6789, DOB: 1990-01-01"
encrypted = encryption.encrypt(sensitive_data)

# Store encrypted data
feature_store.write("user_123_pii", encrypted)

# Later: Decrypt for authorized use
encrypted_pii = feature_store.read("user_123_pii")
decrypted = encryption.decrypt(encrypted_pii)

# Benefits:
# - Encryption keys never leave Vault
# - Automatic key rotation
# - Centralized key management
# - Audit logging of all encrypt/decrypt operations
```

### 2.7 Vault Policies (Least Privilege)

**Policy Language**:

```hcl
# ml-training-policy.hcl
# Policy for ML training jobs

# Read-only access to model API keys
path "ml-secrets/data/model-api-key" {
  capabilities = ["read"]
}

# Generate dynamic database credentials
path "database/creds/ml-readonly" {
  capabilities = ["read"]
}

# Encrypt/decrypt training data
path "transit/encrypt/ml-data-encryption" {
  capabilities = ["update"]
}

path "transit/decrypt/ml-data-encryption" {
  capabilities = ["update"]
}

# No access to production secrets
path "ml-secrets/data/production/*" {
  capabilities = ["deny"]
}
```

**Apply Policy**:

```bash
# Create policy
vault policy write ml-training ml-training-policy.hcl

# Create AppRole with policy
vault auth enable approle

vault write auth/approle/role/ml-training-role \
  token_policies="ml-training" \
  token_ttl=1h \
  token_max_ttl=4h

# Get role_id and secret_id
vault read auth/approle/role/ml-training-role/role-id
vault write -f auth/approle/role/ml-training-role/secret-id
```

---

## 3. Cloud Provider Secrets Management (4 hours)

### 3.1 AWS Secrets Manager

**Store Secret**:

```python
import boto3
import json

secrets_manager = boto3.client('secretsmanager', region_name='us-west-2')

# Store secret
secrets_manager.create_secret(
    Name='ml/model-api-key',
    Description='API key for ML model inference',
    SecretString=json.dumps({
        'api_key': 'sk-1234567890abcdef',
        'endpoint': 'https://api.openai.com',
        'rate_limit': 10000
    })
)

# Retrieve secret
def get_secret(secret_name):
    """
    Retrieve secret from AWS Secrets Manager
    """
    response = secrets_manager.get_secret_value(SecretId=secret_name)

    if 'SecretString' in response:
        secret = json.loads(response['SecretString'])
        return secret
    else:
        # Binary secret
        return base64.b64decode(response['SecretBinary'])

# Usage
secret = get_secret('ml/model-api-key')
api_key = secret['api_key']

# Make API call with retrieved key
response = requests.post(
    secret['endpoint'],
    headers={'Authorization': f'Bearer {api_key}'},
    json={'prompt': 'Hello, world!'}
)
```

**Automatic Rotation**:

```python
import boto3

# Enable automatic rotation (every 30 days)
secrets_manager.rotate_secret(
    SecretId='ml/database-password',
    RotationLambdaARN='arn:aws:lambda:us-west-2:123456789012:function:rotate-db-password',
    RotationRules={
        'AutomaticallyAfterDays': 30
    }
)

# Rotation Lambda function
def lambda_handler(event, context):
    """
    Rotate database password

    Steps:
    1. Create new password
    2. Set as pending in Secrets Manager
    3. Update database with new password
    4. Test new password
    5. Finalize rotation in Secrets Manager
    """
    secret_arn = event['SecretId']
    token = event['Token']
    step = event['Step']

    if step == "createSecret":
        # Generate new password
        new_password = generate_secure_password()

        # Store as pending
        secrets_manager.put_secret_value(
            SecretId=secret_arn,
            ClientRequestToken=token,
            SecretString=json.dumps({'password': new_password}),
            VersionStages=['AWSPENDING']
        )

    elif step == "setSecret":
        # Update database with new password
        pending_secret = get_secret_version(secret_arn, 'AWSPENDING')
        update_database_password(pending_secret['password'])

    elif step == "testSecret":
        # Test new password
        pending_secret = get_secret_version(secret_arn, 'AWSPENDING')
        test_database_connection(pending_secret['password'])

    elif step == "finishSecret":
        # Finalize rotation
        secrets_manager.update_secret_version_stage(
            SecretId=secret_arn,
            VersionStage='AWSCURRENT',
            MoveToVersionId=token
        )
```

### 3.2 Azure Key Vault

**Store and Retrieve Secrets**:

```python
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient

# Connect to Key Vault
credential = DefaultAzureCredential()
vault_url = "https://ml-keyvault.vault.azure.net/"
client = SecretClient(vault_url=vault_url, credential=credential)

# Store secret
client.set_secret("ml-model-api-key", "sk-1234567890abcdef")

# Retrieve secret
secret = client.get_secret("ml-model-api-key")
api_key = secret.value

# List all secrets
secrets = client.list_properties_of_secrets()
for secret in secrets:
    print(f"Secret: {secret.name}")

# Delete secret
client.begin_delete_secret("ml-model-api-key")
```

**Certificate Management**:

```python
from azure.keyvault.certificates import CertificateClient, CertificatePolicy

cert_client = CertificateClient(vault_url=vault_url, credential=credential)

# Create self-signed certificate
policy = CertificatePolicy.get_default()

cert_client.begin_create_certificate(
    certificate_name="ml-api-cert",
    policy=policy
).wait()

# Retrieve certificate
certificate = cert_client.get_certificate("ml-api-cert")

# Use certificate for TLS
cert_bytes = certificate.cer
private_key = cert_client.get_certificate_version(
    certificate_name="ml-api-cert",
    version=certificate.properties.version
).key_id
```

### 3.3 GCP Secret Manager

**Store and Retrieve Secrets**:

```python
from google.cloud import secretmanager

client = secretmanager.SecretManagerServiceClient()
project_id = "my-ml-project"

# Create secret
parent = f"projects/{project_id}"

secret = client.create_secret(
    request={
        "parent": parent,
        "secret_id": "ml-model-api-key",
        "secret": {"replication": {"automatic": {}}}
    }
)

# Add secret version
client.add_secret_version(
    request={
        "parent": secret.name,
        "payload": {"data": b"sk-1234567890abcdef"}
    }
)

# Access secret
name = f"projects/{project_id}/secrets/ml-model-api-key/versions/latest"
response = client.access_secret_version(request={"name": name})
secret_value = response.payload.data.decode('UTF-8')

# Delete secret
client.delete_secret(request={"name": secret.name})
```

---

## 4. Identity and Access Management (3 hours)

### 4.1 IAM for ML Workloads

**Principle of Least Privilege**:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "MLTrainingS3Access",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::ml-training-data/*",
        "arn:aws:s3:::ml-training-data"
      ]
    },
    {
      "Sid": "MLModelS3Write",
      "Effect": "Allow",
      "Action": [
        "s3:PutObject"
      ],
      "Resource": [
        "arn:aws:s3:::ml-models/training-job-${aws:username}/*"
      ]
    },
    {
      "Sid": "DenyProductionAccess",
      "Effect": "Deny",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::ml-production-models/*"
      ]
    }
  ]
}
```

**IAM Roles for K8s Service Accounts (IRSA)**:

```yaml
# Kubernetes ServiceAccount with IAM role annotation
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ml-training-job
  namespace: ml-training
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::123456789012:role/ml-training-role

---
# Pod using ServiceAccount
apiVersion: v1
kind: Pod
metadata:
  name: ml-training-pod
  namespace: ml-training
spec:
  serviceAccountName: ml-training-job
  containers:
  - name: training
    image: ml-training:latest
    # Pod automatically gets AWS credentials via IRSA
    # No need to pass access keys!
```

**IAM Policy for Training Job**:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-west-2.amazonaws.com/id/EXAMPLED539D4633E53DE1B716D3041E"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "oidc.eks.us-west-2.amazonaws.com/id/EXAMPLED539D4633E53DE1B716D3041E:sub": "system:serviceaccount:ml-training:ml-training-job"
        }
      }
    }
  ]
}
```

### 4.2 Service Accounts and RBAC

**Kubernetes RBAC for ML Jobs**:

```yaml
# Role: Read-only access to training data ConfigMaps
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: ml-training-reader
  namespace: ml-training
rules:
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["get", "list"]
- apiGroups: [""]
  resources: ["secrets"]
  resourceNames: ["training-secrets"]  # Only specific secret
  verbs: ["get"]

---
# RoleBinding: Bind role to ServiceAccount
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: ml-training-reader-binding
  namespace: ml-training
subjects:
- kind: ServiceAccount
  name: ml-training-job
  namespace: ml-training
roleRef:
  kind: Role
  name: ml-training-reader
  apiGroup: rbac.authorization.k8s.io
```

### 4.3 API Key Management

**Best Practices**:

```python
import secrets
import hashlib
from datetime import datetime, timedelta

class APIKeyManager:
    """
    Manage API keys for ML services
    """
    def __init__(self, vault_client):
        self.vault = vault_client

    def generate_api_key(self, user_id, permissions, ttl_days=90):
        """
        Generate API key with metadata

        Returns:
            api_key: Plain API key (show only once)
            key_hash: Hashed key for storage
        """
        # Generate secure random key
        api_key = f"ml_{secrets.token_urlsafe(32)}"

        # Hash for storage (never store plaintext!)
        key_hash = hashlib.sha256(api_key.encode()).hexdigest()

        # Store metadata in Vault
        expiry = datetime.utcnow() + timedelta(days=ttl_days)

        self.vault.write_secret(
            path=f"api-keys/{key_hash}",
            user_id=user_id,
            permissions=permissions,
            created_at=datetime.utcnow().isoformat(),
            expires_at=expiry.isoformat(),
            revoked=False
        )

        return api_key, key_hash

    def verify_api_key(self, api_key):
        """
        Verify API key and return user info
        """
        # Hash provided key
        key_hash = hashlib.sha256(api_key.encode()).hexdigest()

        try:
            # Look up in Vault
            key_data = self.vault.get_secret(f"api-keys/{key_hash}")

            # Check if revoked
            if key_data.get('revoked'):
                return None

            # Check expiry
            expiry = datetime.fromisoformat(key_data['expires_at'])
            if datetime.utcnow() > expiry:
                return None

            return {
                'user_id': key_data['user_id'],
                'permissions': key_data['permissions']
            }

        except ValueError:
            return None

    def revoke_api_key(self, key_hash):
        """
        Revoke API key immediately
        """
        key_data = self.vault.get_secret(f"api-keys/{key_hash}")
        key_data['revoked'] = True
        key_data['revoked_at'] = datetime.utcnow().isoformat()

        self.vault.write_secret(f"api-keys/{key_hash}", **key_data)

    def rotate_api_key(self, old_key_hash, user_id, permissions):
        """
        Rotate API key (revoke old, generate new)
        """
        # Revoke old key
        self.revoke_api_key(old_key_hash)

        # Generate new key
        new_key, new_hash = self.generate_api_key(user_id, permissions)

        return new_key, new_hash

# Usage
key_manager = APIKeyManager(vault_client)

# Generate API key for user
api_key, key_hash = key_manager.generate_api_key(
    user_id="data_scientist_123",
    permissions=["model:inference", "data:read"],
    ttl_days=90
)

print(f"Your API key (save this, won't be shown again): {api_key}")

# API endpoint authentication
@app.before_request
def authenticate():
    api_key = request.headers.get('X-API-Key')

    if not api_key:
        abort(401, "API key required")

    user_info = key_manager.verify_api_key(api_key)

    if not user_info:
        abort(401, "Invalid or expired API key")

    # Store user info in request context
    g.user_id = user_info['user_id']
    g.permissions = user_info['permissions']

# Check permissions in endpoint
@app.route('/predict', methods=['POST'])
def predict():
    if 'model:inference' not in g.permissions:
        abort(403, "Insufficient permissions")

    # Proceed with inference
    ...
```

---

## 5. Certificate Management (2 hours)

### 5.1 TLS Certificate Lifecycle

**Generate Certificate with Vault PKI**:

```bash
# Enable PKI secrets engine
vault secrets enable pki

# Set max TTL to 10 years
vault secrets tune -max-lease-ttl=87600h pki

# Generate root CA
vault write pki/root/generate/internal \
  common_name="ML Infrastructure CA" \
  ttl=87600h

# Configure CA and CRL URLs
vault write pki/config/urls \
  issuing_certificates="http://vault.example.com:8200/v1/pki/ca" \
  crl_distribution_points="http://vault.example.com:8200/v1/pki/crl"

# Create role for ML services
vault write pki/roles/ml-service \
  allowed_domains="ml.example.com" \
  allow_subdomains=true \
  max_ttl="720h"

# Issue certificate
vault write pki/issue/ml-service \
  common_name="api.ml.example.com" \
  ttl="24h"

# Output includes:
# - certificate (PEM)
# - issuing_ca (PEM)
# - private_key (PEM)
# - serial_number
```

**Automatic Certificate Rotation**:

```python
import time
from pathlib import Path

class CertificateManager:
    """
    Automatic TLS certificate rotation using Vault PKI
    """
    def __init__(self, vault_client, role_name, common_name):
        self.vault = vault_client
        self.role_name = role_name
        self.common_name = common_name

        self.cert_path = Path("/etc/ssl/certs/ml-service.crt")
        self.key_path = Path("/etc/ssl/private/ml-service.key")
        self.ca_path = Path("/etc/ssl/certs/ca.crt")

    def issue_certificate(self, ttl="24h"):
        """
        Issue new certificate from Vault PKI
        """
        response = self.vault.client.write(
            f"pki/issue/{self.role_name}",
            common_name=self.common_name,
            ttl=ttl
        )

        return {
            'certificate': response['data']['certificate'],
            'private_key': response['data']['private_key'],
            'issuing_ca': response['data']['issuing_ca'],
            'serial_number': response['data']['serial_number']
        }

    def write_certificate_files(self, cert_data):
        """
        Write certificate files to disk
        """
        # Write certificate
        self.cert_path.write_text(cert_data['certificate'])

        # Write private key (restrict permissions)
        self.key_path.write_text(cert_data['private_key'])
        self.key_path.chmod(0o600)

        # Write CA certificate
        self.ca_path.write_text(cert_data['issuing_ca'])

    def rotate_certificate(self):
        """
        Rotate certificate (get new cert and update files)
        """
        # Issue new certificate
        cert_data = self.issue_certificate(ttl="24h")

        # Write to disk
        self.write_certificate_files(cert_data)

        # Reload server (send SIGHUP to nginx/gunicorn)
        import subprocess
        subprocess.run(["systemctl", "reload", "nginx"])

        print(f"Certificate rotated: serial={cert_data['serial_number']}")

    def auto_rotate_daemon(self, rotation_interval_hours=20):
        """
        Daemon to automatically rotate certificates

        Rotates every 20 hours (for 24h TTL, leaves 4h buffer)
        """
        while True:
            try:
                self.rotate_certificate()
            except Exception as e:
                print(f"Certificate rotation failed: {e}")

            # Sleep until next rotation
            time.sleep(rotation_interval_hours * 3600)

# Usage: Run as background daemon
cert_manager = CertificateManager(
    vault_client,
    role_name="ml-service",
    common_name="api.ml.example.com"
)

# Initial certificate
cert_manager.rotate_certificate()

# Start auto-rotation daemon
import threading
rotation_thread = threading.Thread(
    target=cert_manager.auto_rotate_daemon,
    args=(20,),  # Rotate every 20 hours
    daemon=True
)
rotation_thread.start()

# Main application continues running
app.run()
```

---

## Summary

This module covered secrets and identity management for ML systems:

1. **Secrets Management Fundamentals**: Never hardcode secrets, use secrets managers
2. **HashiCorp Vault**: KV secrets, dynamic secrets, encryption as a service, policies
3. **Cloud Secrets Managers**: AWS Secrets Manager, Azure Key Vault, GCP Secret Manager
4. **IAM**: Least privilege policies, service accounts, RBAC for K8s
5. **API Key Management**: Secure generation, storage (hashed), rotation, revocation
6. **Certificate Management**: TLS certificate issuance, automatic rotation with Vault PKI

**Key Takeaways**:
- Use dynamic secrets when possible (auto-rotation, auto-revocation)
- Never store secrets in code or version control
- Implement least privilege IAM policies
- Automate certificate rotation
- Audit all secret access

**Next Module**: Secure ML Pipelines (CI/CD security, container security, supply chain)

---

## References

1. HashiCorp Vault Documentation: https://www.vaultproject.io/docs
2. AWS Secrets Manager: https://docs.aws.amazon.com/secretsmanager/
3. Azure Key Vault: https://docs.microsoft.com/azure/key-vault/
4. GCP Secret Manager: https://cloud.google.com/secret-manager/docs
5. OWASP Secrets Management Cheat Sheet
6. CIS Benchmarks for Secrets Management
