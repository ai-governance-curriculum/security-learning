# Network Security for ML

## Table of Contents

1. [VPC and Network Segmentation](#vpc-and-network-segmentation)
2. [TLS and mTLS for ML Services](#tls-and-mtls-for-ml-services)
3. [API Gateway Security](#api-gateway-security)
4. [DDoS Protection](#ddos-protection-for-inference-endpoints)
5. [Service Mesh Security](#service-mesh-security)

---

## 1. VPC and Network Segmentation

### 1.1 Network Architecture for ML Workloads

ML infrastructure requires careful network design to isolate sensitive components while enabling necessary communication.

**Three-Tier Architecture**:

```
┌─────────────────────────────────────────────────────────────┐
│                      Public Internet                         │
└────────────────────────┬────────────────────────────────────┘
                         │
                         v
┌────────────────────────────────────────────────────────────┐
│                   DMZ / Public Subnet                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │
│  │ Load         │  │ API Gateway  │  │ WAF          │    │
│  │ Balancer     │  │              │  │              │    │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘    │
│         │                  │                  │             │
└─────────┼──────────────────┼──────────────────┼─────────────┘
          │                  │                  │
          v                  v                  v
┌─────────────────────────────────────────────────────────────┐
│              Application / Private Subnet                    │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │ ML Inference │  │ Model API    │  │ Feature      │     │
│  │ Service      │  │ Service      │  │ Service      │     │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘     │
│         │                  │                  │              │
└─────────┼──────────────────┼──────────────────┼──────────────┘
          │                  │                  │
          v                  v                  v
┌─────────────────────────────────────────────────────────────┐
│                 Data / Database Subnet                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │ PostgreSQL   │  │ Model        │  │ Feature      │     │
│  │ (Metadata)   │  │ Registry     │  │ Store        │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
│                                                              │
│  ┌──────────────┐  ┌──────────────┐                        │
│  │ Training     │  │ Logging      │                        │
│  │ Data (S3)    │  │ Storage      │                        │
│  └──────────────┘  └──────────────┘                        │
└─────────────────────────────────────────────────────────────┘

Separate VPC (Isolated):
┌─────────────────────────────────────────────────────────────┐
│              ML Training Environment                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │ Training     │  │ Experiment   │  │ Data         │     │
│  │ Jobs         │  │ Tracking     │  │ Processing   │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
│                                                              │
│  Access via VPC Peering (controlled)                        │
└─────────────────────────────────────────────────────────────┘
```

### 1.2 AWS VPC Configuration for ML

**VPC Setup with Terraform**:

```hcl
# vpc.tf
resource "aws_vpc" "ml_production" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "ml-production-vpc"
    Environment = "production"
    Purpose     = "ml-inference"
  }
}

# Public subnets for load balancers
resource "aws_subnet" "public" {
  count             = 3
  vpc_id            = aws_vpc.ml_production.id
  cidr_block        = "10.0.${count.index}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "ml-public-${count.index + 1}"
    Tier = "public"
  }
}

# Private subnets for ML services
resource "aws_subnet" "private_app" {
  count             = 3
  vpc_id            = aws_vpc.ml_production.id
  cidr_block        = "10.0.${count.index + 10}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "ml-private-app-${count.index + 1}"
    Tier = "application"
  }
}

# Database subnets (most restricted)
resource "aws_subnet" "private_data" {
  count             = 3
  vpc_id            = aws_vpc.ml_production.id
  cidr_block        = "10.0.${count.index + 20}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "ml-private-data-${count.index + 1}"
    Tier = "data"
  }
}

# Internet Gateway for public subnets
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.ml_production.id

  tags = {
    Name = "ml-igw"
  }
}

# NAT Gateways for private subnets (one per AZ)
resource "aws_eip" "nat" {
  count  = 3
  domain = "vpc"

  tags = {
    Name = "ml-nat-eip-${count.index + 1}"
  }
}

resource "aws_nat_gateway" "main" {
  count         = 3
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "ml-nat-${count.index + 1}"
  }
}

# Route table for public subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.ml_production.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "ml-public-rt"
  }
}

# Route tables for private subnets (via NAT)
resource "aws_route_table" "private_app" {
  count  = 3
  vpc_id = aws_vpc.ml_production.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = {
    Name = "ml-private-app-rt-${count.index + 1}"
  }
}

# Route tables for data subnets (NO internet access)
resource "aws_route_table" "private_data" {
  count  = 3
  vpc_id = aws_vpc.ml_production.id

  # Only local routes, no internet access

  tags = {
    Name = "ml-private-data-rt-${count.index + 1}"
  }
}
```

**Security Groups**:

```hcl
# security_groups.tf

# Load balancer security group (internet-facing)
resource "aws_security_group" "alb" {
  name        = "ml-alb-sg"
  description = "Security group for ML inference ALB"
  vpc_id      = aws_vpc.ml_production.id

  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description     = "To ML inference services"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.ml_inference.id]
  }

  tags = {
    Name = "ml-alb-sg"
  }
}

# ML inference service security group
resource "aws_security_group" "ml_inference" {
  name        = "ml-inference-sg"
  description = "Security group for ML inference services"
  vpc_id      = aws_vpc.ml_production.id

  ingress {
    description     = "From ALB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description     = "From feature service"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.feature_service.id]
  }

  egress {
    description     = "To model registry"
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.model_registry.id]
  }

  egress {
    description = "To feature store"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    security_groups = [aws_security_group.feature_store.id]
  }

  tags = {
    Name = "ml-inference-sg"
  }
}

# Database security group (most restrictive)
resource "aws_security_group" "database" {
  name        = "ml-database-sg"
  description = "Security group for ML databases"
  vpc_id      = aws_vpc.ml_production.id

  ingress {
    description     = "PostgreSQL from app subnet"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ml_inference.id]
  }

  # No egress to internet
  egress {
    description = "Only within VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.ml_production.cidr_block]
  }

  tags = {
    Name = "ml-database-sg"
  }
}
```

### 1.3 Kubernetes Network Policies

**Network Policies for ML Namespaces**:

```yaml
# network-policies/ml-inference-policy.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: ml-inference-netpol
  namespace: ml-production
spec:
  podSelector:
    matchLabels:
      app: ml-inference

  policyTypes:
    - Ingress
    - Egress

  ingress:
    # Allow ingress from API gateway
    - from:
        - namespaceSelector:
            matchLabels:
              name: api-gateway
        - podSelector:
            matchLabels:
              app: gateway
      ports:
        - protocol: TCP
          port: 8080

    # Allow ingress from monitoring
    - from:
        - namespaceSelector:
            matchLabels:
              name: monitoring
      ports:
        - protocol: TCP
          port: 9090  # Prometheus metrics

  egress:
    # Allow egress to model registry
    - to:
        - namespaceSelector:
            matchLabels:
              name: ml-registry
        - podSelector:
            matchLabels:
              app: mlflow
      ports:
        - protocol: TCP
          port: 5000

    # Allow egress to feature store
    - to:
        - namespaceSelector:
            matchLabels:
              name: ml-data
        - podSelector:
            matchLabels:
              app: feature-store
      ports:
        - protocol: TCP
          port: 5432

    # Allow DNS
    - to:
        - namespaceSelector:
            matchLabels:
              name: kube-system
        - podSelector:
            matchLabels:
              k8s-app: kube-dns
      ports:
        - protocol: UDP
          port: 53

    # Deny all other egress
```

**Default Deny Policy**:

```yaml
# network-policies/default-deny.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: ml-production
spec:
  podSelector: {}
  policyTypes:
    - Ingress
    - Egress

  # Empty rules = deny all
```

### 1.4 VPC Endpoints for AWS Services

**Avoid Internet Gateway for AWS Service Access**:

```hcl
# vpc_endpoints.tf

# S3 VPC endpoint (gateway endpoint)
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.ml_production.id
  service_name = "com.amazonaws.${var.region}.s3"

  route_table_ids = concat(
    aws_route_table.private_app[*].id,
    aws_route_table.private_data[*].id
  )

  tags = {
    Name = "ml-s3-endpoint"
  }
}

# Secrets Manager VPC endpoint
resource "aws_vpc_endpoint" "secrets_manager" {
  vpc_id              = aws_vpc.ml_production.id
  service_name        = "com.amazonaws.${var.region}.secretsmanager"
  vpc_endpoint_type   = "Interface"

  subnet_ids         = aws_subnet.private_app[*].id
  security_group_ids = [aws_security_group.vpc_endpoints.id]

  private_dns_enabled = true

  tags = {
    Name = "ml-secrets-manager-endpoint"
  }
}

# SageMaker Runtime VPC endpoint
resource "aws_vpc_endpoint" "sagemaker_runtime" {
  vpc_id              = aws_vpc.ml_production.id
  service_name        = "com.amazonaws.${var.region}.sagemaker.runtime"
  vpc_endpoint_type   = "Interface"

  subnet_ids         = aws_subnet.private_app[*].id
  security_group_ids = [aws_security_group.vpc_endpoints.id]

  private_dns_enabled = true

  tags = {
    Name = "ml-sagemaker-runtime-endpoint"
  }
}

# CloudWatch Logs VPC endpoint
resource "aws_vpc_endpoint" "logs" {
  vpc_id              = aws_vpc.ml_production.id
  service_name        = "com.amazonaws.${var.region}.logs"
  vpc_endpoint_type   = "Interface"

  subnet_ids         = aws_subnet.private_app[*].id
  security_group_ids = [aws_security_group.vpc_endpoints.id]

  private_dns_enabled = true

  tags = {
    Name = "ml-logs-endpoint"
  }
}
```

---

## 2. TLS and mTLS for ML Services

### 2.1 TLS Configuration

**Nginx Reverse Proxy with TLS**:

```nginx
# nginx.conf
upstream ml_inference {
    least_conn;
    server ml-inference-1:8080;
    server ml-inference-2:8080;
    server ml-inference-3:8080;
}

server {
    listen 443 ssl http2;
    server_name inference.ml.company.com;

    # TLS configuration
    ssl_certificate     /etc/nginx/certs/server.crt;
    ssl_certificate_key /etc/nginx/certs/server.key;

    # Modern TLS configuration (TLS 1.2+)
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384';
    ssl_prefer_server_ciphers off;

    # HSTS
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # OCSP stapling
    ssl_stapling on;
    ssl_stapling_verify on;
    ssl_trusted_certificate /etc/nginx/certs/ca.crt;

    # Session cache
    ssl_session_cache shared:SSL:50m;
    ssl_session_timeout 1d;

    location /predict {
        proxy_pass http://ml_inference;

        # Security headers
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 300s;
        proxy_read_timeout 300s;
    }

    location /health {
        proxy_pass http://ml_inference;
        access_log off;
    }
}

# Redirect HTTP to HTTPS
server {
    listen 80;
    server_name inference.ml.company.com;
    return 301 https://$server_name$request_uri;
}
```

### 2.2 Mutual TLS (mTLS)

**mTLS with Nginx**:

```nginx
# nginx-mtls.conf
server {
    listen 443 ssl http2;
    server_name api.ml.company.com;

    # Server certificate
    ssl_certificate     /etc/nginx/certs/server.crt;
    ssl_certificate_key /etc/nginx/certs/server.key;

    # Client certificate verification (mTLS)
    ssl_client_certificate /etc/nginx/certs/ca.crt;
    ssl_verify_client on;
    ssl_verify_depth 2;

    # TLS configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256';

    location / {
        # Pass client certificate DN to backend
        proxy_set_header X-SSL-Client-Cert $ssl_client_cert;
        proxy_set_header X-SSL-Client-DN $ssl_client_s_dn;
        proxy_set_header X-SSL-Client-Verify $ssl_client_verify;

        proxy_pass http://ml_inference;
    }
}
```

**Python Client with mTLS**:

```python
# client_mtls.py
import requests
from typing import Dict, Any

class MLInferenceClient:
    """
    ML inference client with mTLS authentication
    """

    def __init__(
        self,
        base_url: str,
        cert_path: str,
        key_path: str,
        ca_path: str
    ):
        self.base_url = base_url
        self.cert = (cert_path, key_path)
        self.verify = ca_path

    def predict(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Make prediction request with mTLS

        Args:
            data: Input features

        Returns:
            Prediction response
        """
        response = requests.post(
            f"{self.base_url}/predict",
            json=data,
            cert=self.cert,
            verify=self.verify,
            timeout=30
        )

        response.raise_for_status()
        return response.json()

    def health_check(self) -> bool:
        """Check if service is healthy"""
        try:
            response = requests.get(
                f"{self.base_url}/health",
                cert=self.cert,
                verify=self.verify,
                timeout=5
            )
            return response.status_code == 200
        except Exception:
            return False


# Usage
client = MLInferenceClient(
    base_url="https://api.ml.company.com",
    cert_path="/path/to/client.crt",
    key_path="/path/to/client.key",
    ca_path="/path/to/ca.crt"
)

prediction = client.predict({
    "features": [1.0, 2.0, 3.0, 4.0]
})
print(f"Prediction: {prediction}")
```

### 2.3 Certificate Management at Scale

**cert-manager for Kubernetes**:

```yaml
# cert-manager/ml-certificate.yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: ml-inference-tls
  namespace: ml-production
spec:
  secretName: ml-inference-tls-secret

  issuerRef:
    name: company-ca
    kind: ClusterIssuer

  commonName: inference.ml.company.com
  dnsNames:
    - inference.ml.company.com
    - api.ml.company.com
    - "*.ml.company.com"

  # Automatic renewal
  duration: 2160h  # 90 days
  renewBefore: 360h  # 15 days before expiration

  privateKey:
    algorithm: RSA
    size: 2048
    rotationPolicy: Always

  usages:
    - server auth
    - client auth
```

**Automated Certificate Rotation**:

```python
# cert_rotation_monitor.py
from kubernetes import client, config
from datetime import datetime, timedelta
from prometheus_client import Gauge, start_http_server
import time

# Metrics
cert_expiry_days = Gauge(
    'certificate_expiry_days',
    'Days until certificate expiration',
    ['namespace', 'secret_name']
)

def check_certificate_expiry():
    """Check all TLS certificates in cluster"""
    config.load_incluster_config()
    v1 = client.CoreV1Api()

    namespaces = ['ml-production', 'ml-staging']

    for namespace in namespaces:
        secrets = v1.list_namespaced_secret(
            namespace,
            field_selector='type=kubernetes.io/tls'
        )

        for secret in secrets.items:
            cert_data = secret.data.get('tls.crt')
            if not cert_data:
                continue

            # Parse certificate
            import base64
            from cryptography import x509
            from cryptography.hazmat.backends import default_backend

            cert_bytes = base64.b64decode(cert_data)
            cert = x509.load_pem_x509_certificate(cert_bytes, default_backend())

            # Calculate days until expiry
            days_remaining = (cert.not_valid_after - datetime.utcnow()).days

            # Update metric
            cert_expiry_days.labels(
                namespace=namespace,
                secret_name=secret.metadata.name
            ).set(days_remaining)

            # Alert if expiring soon
            if days_remaining < 15:
                print(f"WARNING: Certificate {secret.metadata.name} expires in {days_remaining} days")

# Start metrics server
start_http_server(8000)

# Monitor loop
while True:
    check_certificate_expiry()
    time.sleep(300)  # Check every 5 minutes
```

---

## 3. API Gateway Security

### 3.1 Kong API Gateway Configuration

**Kong for ML API Management**:

```yaml
# kong/kong-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kong
  namespace: api-gateway
spec:
  replicas: 3
  selector:
    matchLabels:
      app: kong
  template:
    metadata:
      labels:
        app: kong
    spec:
      containers:
        - name: kong
          image: kong:3.4
          env:
            - name: KONG_DATABASE
              value: "postgres"
            - name: KONG_PG_HOST
              value: "kong-postgres"
            - name: KONG_PROXY_ACCESS_LOG
              value: "/dev/stdout"
            - name: KONG_ADMIN_ACCESS_LOG
              value: "/dev/stdout"
            - name: KONG_PROXY_ERROR_LOG
              value: "/dev/stderr"
            - name: KONG_ADMIN_ERROR_LOG
              value: "/dev/stderr"
          ports:
            - name: proxy
              containerPort: 8000
            - name: proxy-ssl
              containerPort: 8443
            - name: admin
              containerPort: 8001
          livenessProbe:
            httpGet:
              path: /status
              port: 8001
            initialDelaySeconds: 30
            periodSeconds: 10
```

**Rate Limiting Plugin**:

```yaml
# kong/rate-limit-plugin.yaml
apiVersion: configuration.konghq.com/v1
kind: KongPlugin
metadata:
  name: ml-rate-limit
  namespace: api-gateway
config:
  minute: 100  # 100 requests per minute per consumer
  hour: 5000   # 5000 requests per hour
  policy: local
  fault_tolerant: true
plugin: rate-limiting
```

**JWT Authentication Plugin**:

```yaml
# kong/jwt-auth-plugin.yaml
apiVersion: configuration.konghq.com/v1
kind: KongPlugin
metadata:
  name: ml-jwt-auth
  namespace: api-gateway
config:
  key_claim_name: kid
  secret_is_base64: false
  claims_to_verify:
    - exp
    - nbf
plugin: jwt
```

**ML API Route Configuration**:

```yaml
# kong/ml-route.yaml
apiVersion: configuration.konghq.com/v1
kind: KongIngress
metadata:
  name: ml-inference-route
  namespace: ml-production
route:
  methods:
    - POST
  paths:
    - /api/v1/predict
  protocols:
    - https
  strip_path: false
  preserve_host: true

---
apiVersion: v1
kind: Service
metadata:
  name: ml-inference
  namespace: ml-production
  annotations:
    konghq.com/plugins: ml-rate-limit,ml-jwt-auth
spec:
  ports:
    - port: 80
      targetPort: 8080
      protocol: TCP
  selector:
    app: ml-inference
```

### 3.2 API Gateway Security Policies

**Request Validation**:

```python
# api_gateway/request_validator.py
from pydantic import BaseModel, Field, validator
from typing import List, Optional
from fastapi import FastAPI, HTTPException, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
import jwt

app = FastAPI()
security = HTTPBearer()

class PredictionRequest(BaseModel):
    """Validated prediction request"""
    features: List[float] = Field(..., min_items=1, max_items=100)
    model_version: Optional[str] = Field(None, regex="^v[0-9]+\\.[0-9]+\\.[0-9]+$")

    @validator('features')
    def validate_features(cls, v):
        """Validate feature values"""
        for feature in v:
            if not -1e6 <= feature <= 1e6:
                raise ValueError("Feature values must be between -1e6 and 1e6")
        return v

def verify_jwt(credentials: HTTPAuthorizationCredentials = Depends(security)):
    """Verify JWT token"""
    token = credentials.credentials

    try:
        payload = jwt.decode(
            token,
            "your-secret-key",  # In production, use public key from JWKS endpoint
            algorithms=["RS256"],
            audience="ml-api"
        )
        return payload
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token expired")
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=401, detail="Invalid token")

@app.post("/api/v1/predict")
async def predict(
    request: PredictionRequest,
    user=Depends(verify_jwt)
):
    """
    ML prediction endpoint with validation and authentication
    """
    # Check user permissions
    if "ml:predict" not in user.get("permissions", []):
        raise HTTPException(status_code=403, detail="Insufficient permissions")

    # Rate limit check (would be implemented via Redis)
    # ...

    # Forward to ML inference service
    # ...

    return {"prediction": 0.42, "model_version": request.model_version}
```

### 3.3 WAF (Web Application Firewall)

**AWS WAF Rules for ML API**:

```hcl
# waf.tf
resource "aws_wafv2_web_acl" "ml_api" {
  name  = "ml-api-waf"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  # Rule 1: Rate limiting
  rule {
    name     = "RateLimitRule"
    priority = 1

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 2000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name               = "RateLimitRule"
      sampled_requests_enabled  = true
    }
  }

  # Rule 2: Geo-blocking (example: only allow US)
  rule {
    name     = "GeoBlockingRule"
    priority = 2

    action {
      block {}
    }

    statement {
      not_statement {
        statement {
          geo_match_statement {
            country_codes = ["US", "CA"]
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name               = "GeoBlockingRule"
      sampled_requests_enabled  = true
    }
  }

  # Rule 3: SQL injection protection
  rule {
    name     = "SQLiProtection"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name               = "SQLiProtection"
      sampled_requests_enabled  = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name               = "ml-api-waf"
    sampled_requests_enabled  = true
  }

  tags = {
    Name        = "ml-api-waf"
    Environment = "production"
  }
}

# Associate WAF with ALB
resource "aws_wafv2_web_acl_association" "ml_alb" {
  resource_arn = aws_lb.ml_inference.arn
  web_acl_arn  = aws_wafv2_web_acl.ml_api.arn
}
```

---

## 4. DDoS Protection for Inference Endpoints

### 4.1 CloudFlare DDoS Protection

**CloudFlare Configuration**:

```
inference.ml.company.com
├─ Proxied through CloudFlare (orange cloud)
├─ DDoS Protection: Enabled
├─ Rate Limiting: 1000 req/min per IP
├─ Bot Fight Mode: Enabled
├─ Challenge Passage: 30 seconds
└─ Cache: Disabled (dynamic ML responses)
```

**CloudFlare Workers for Request Filtering**:

```javascript
// cloudflare-worker.js
addEventListener('fetch', event => {
  event.respondWith(handleRequest(event.request))
})

async function handleRequest(request) {
  // Only allow POST requests
  if (request.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 })
  }

  // Check content type
  const contentType = request.headers.get('content-type')
  if (contentType !== 'application/json') {
    return new Response('Content-Type must be application/json', { status: 400 })
  }

  // Check request size
  const contentLength = request.headers.get('content-length')
  if (contentLength && parseInt(contentLength) > 1024 * 100) {  // 100KB limit
    return new Response('Request too large', { status: 413 })
  }

  // Rate limiting per IP
  const ip = request.headers.get('cf-connecting-ip')
  const rateLimitKey = `rate_limit:${ip}`

  // Check rate limit in KV store
  const requests = await RATE_LIMIT_KV.get(rateLimitKey)
  if (requests && parseInt(requests) > 100) {
    return new Response('Rate limit exceeded', { status: 429 })
  }

  // Increment counter
  await RATE_LIMIT_KV.put(rateLimitKey, (parseInt(requests) || 0) + 1, {
    expirationTtl: 60  // 1 minute
  })

  // Forward to origin
  return fetch(request)
}
```

### 4.2 AWS Shield Advanced

**Enable Shield Advanced for ML Infrastructure**:

```hcl
# shield.tf
resource "aws_shield_protection" "ml_alb" {
  name         = "ml-alb-shield"
  resource_arn = aws_lb.ml_inference.arn

  tags = {
    Name = "ml-alb-ddos-protection"
  }
}

# DDoS response team (DRT) access
resource "aws_shield_drt_access_role_arn_association" "ml" {
  role_arn = aws_iam_role.drt_access.arn
}

resource "aws_iam_role" "drt_access" {
  name = "ShieldDRTAccessRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "drt.shield.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "drt_access" {
  role       = aws_iam_role.drt_access.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSShieldDRTAccessPolicy"
}
```

### 4.3 Application-Level DDoS Mitigation

**Request Queue with Circuit Breaker**:

```python
# ddos_protection.py
from collections import deque
from threading import Lock
from time import time
from typing import Callable
import asyncio

class CircuitBreaker:
    """
    Circuit breaker to prevent service overload
    """

    def __init__(
        self,
        failure_threshold: int = 5,
        recovery_timeout: int = 60,
        expected_exception: Exception = Exception
    ):
        self.failure_threshold = failure_threshold
        self.recovery_timeout = recovery_timeout
        self.expected_exception = expected_exception

        self.failure_count = 0
        self.last_failure_time = None
        self.state = "CLOSED"  # CLOSED, OPEN, HALF_OPEN
        self.lock = Lock()

    def call(self, func: Callable, *args, **kwargs):
        """Execute function with circuit breaker"""
        with self.lock:
            if self.state == "OPEN":
                if time() - self.last_failure_time > self.recovery_timeout:
                    self.state = "HALF_OPEN"
                    self.failure_count = 0
                else:
                    raise Exception("Circuit breaker is OPEN")

        try:
            result = func(*args, **kwargs)

            with self.lock:
                self.failure_count = 0
                if self.state == "HALF_OPEN":
                    self.state = "CLOSED"

            return result

        except self.expected_exception as e:
            with self.lock:
                self.failure_count += 1
                self.last_failure_time = time()

                if self.failure_count >= self.failure_threshold:
                    self.state = "OPEN"

            raise


class RequestThrottler:
    """
    Throttle incoming requests to prevent overload
    """

    def __init__(self, max_concurrent: int = 100, queue_size: int = 500):
        self.max_concurrent = max_concurrent
        self.queue_size = queue_size

        self.current_requests = 0
        self.request_queue = deque(maxlen=queue_size)
        self.lock = Lock()

    async def acquire(self):
        """Acquire permission to process request"""
        with self.lock:
            if self.current_requests < self.max_concurrent:
                self.current_requests += 1
                return True

            if len(self.request_queue) < self.queue_size:
                self.request_queue.append(time())
                return False

            # Queue full - reject request
            raise Exception("Service unavailable - queue full")

    def release(self):
        """Release request slot"""
        with self.lock:
            self.current_requests -= 1

            # Process next request from queue
            if self.request_queue:
                self.request_queue.popleft()
                self.current_requests += 1


# Usage in FastAPI
from fastapi import FastAPI, HTTPException
app = FastAPI()

throttler = RequestThrottler(max_concurrent=100)
circuit_breaker = CircuitBreaker(failure_threshold=10)

@app.post("/predict")
async def predict(request: dict):
    # Check throttle
    try:
        acquired = await throttler.acquire()
        if not acquired:
            raise HTTPException(status_code=503, detail="Service busy, please retry")
    except Exception as e:
        raise HTTPException(status_code=503, detail=str(e))

    try:
        # Call ML model with circuit breaker
        result = circuit_breaker.call(run_inference, request)
        return result
    finally:
        throttler.release()
```

---

## 5. Service Mesh Security

### 5.1 Istio Service Mesh

**Install Istio**:

```bash
# Install Istio
curl -L https://istio.io/downloadIstio | sh -
cd istio-1.19.0
export PATH=$PWD/bin:$PATH

# Install with strict mTLS
istioctl install --set profile=production \
  --set values.global.mtls.enabled=true \
  --set values.global.mtls.auto=true

# Enable sidecar injection for ml namespace
kubectl label namespace ml-production istio-injection=enabled
```

**mTLS Policy**:

```yaml
# istio/mtls-policy.yaml
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: ml-production
spec:
  mtls:
    mode: STRICT  # Require mTLS for all traffic

---
# Authorization policy
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: ml-inference-authz
  namespace: ml-production
spec:
  selector:
    matchLabels:
      app: ml-inference
  action: ALLOW
  rules:
    # Allow from API gateway
    - from:
        - source:
            namespaces: ["api-gateway"]
            principals: ["cluster.local/ns/api-gateway/sa/gateway"]
      to:
        - operation:
            methods: ["POST"]
            paths: ["/predict"]

    # Allow from monitoring
    - from:
        - source:
            namespaces: ["monitoring"]
      to:
        - operation:
            methods: ["GET"]
            paths: ["/metrics"]
```

**Traffic Management**:

```yaml
# istio/virtual-service.yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: ml-inference
  namespace: ml-production
spec:
  hosts:
    - ml-inference
  http:
    - match:
        - headers:
            x-api-version:
              exact: "v2"
      route:
        - destination:
            host: ml-inference
            subset: v2
          weight: 100

    - route:
        - destination:
            host: ml-inference
            subset: v1
          weight: 90
        - destination:
            host: ml-inference
            subset: v2
          weight: 10

    # Fault injection for testing
    fault:
      delay:
        percentage:
          value: 0.1
        fixedDelay: 5s

    # Retry policy
    retries:
      attempts: 3
      perTryTimeout: 2s
      retryOn: 5xx

    # Timeout
    timeout: 30s

---
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: ml-inference
  namespace: ml-production
spec:
  host: ml-inference
  trafficPolicy:
    connectionPool:
      tcp:
        maxConnections: 100
      http:
        http1MaxPendingRequests: 50
        http2MaxRequests: 100
        maxRequestsPerConnection: 2
    outlierDetection:
      consecutiveErrors: 5
      interval: 30s
      baseEjectionTime: 30s
      maxEjectionPercent: 50
  subsets:
    - name: v1
      labels:
        version: v1
    - name: v2
      labels:
        version: v2
```

### 5.2 Service Mesh Observability

**Distributed Tracing with Jaeger**:

```yaml
# istio/tracing.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    enableTracing: true
    defaultConfig:
      tracing:
        sampling: 100.0  # 100% sampling in staging
        zipkin:
          address: jaeger-collector.observability.svc.cluster.local:9411

---
# Jaeger deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: jaeger
  namespace: observability
spec:
  replicas: 1
  selector:
    matchLabels:
      app: jaeger
  template:
    metadata:
      labels:
        app: jaeger
    spec:
      containers:
        - name: jaeger
          image: jaegertracing/all-in-one:1.50
          env:
            - name: COLLECTOR_ZIPKIN_HOST_PORT
              value: ":9411"
            - name: SPAN_STORAGE_TYPE
              value: "elasticsearch"
            - name: ES_SERVER_URLS
              value: "http://elasticsearch:9200"
          ports:
            - containerPort: 5775
              protocol: UDP
            - containerPort: 6831
              protocol: UDP
            - containerPort: 6832
              protocol: UDP
            - containerPort: 5778
              protocol: TCP
            - containerPort: 16686
              protocol: TCP
            - containerPort: 14268
              protocol: TCP
            - containerPort: 9411
              protocol: TCP
```

---

## Summary

Network security for ML infrastructure requires:

1. **Network Segmentation**: VPCs, subnets, security groups, network policies
2. **TLS/mTLS**: Encrypted communication, mutual authentication
3. **API Gateway**: Rate limiting, authentication, request validation
4. **DDoS Protection**: CloudFlare, AWS Shield, circuit breakers
5. **Service Mesh**: Istio for mTLS, traffic management, observability

**Key Takeaways**:

- Implement defense in depth with multiple network layers
- Use mTLS for all service-to-service communication
- Deploy API gateway for centralized security controls
- Protect against DDoS with rate limiting and circuit breakers
- Use service mesh for fine-grained traffic control
- Monitor all network traffic and audit logs

---

**Next Module**: [Module 7: Audit, Logging & Compliance](../mod-007-audit-compliance/lecture-notes/01-audit-compliance.md)
