# Module 6: Network Security for ML - Exercises

## Overview

These exercises provide hands-on experience securing ML infrastructure through network architecture, TLS/mTLS implementation, API gateway security, and service mesh configuration.

**Total Time**: 10-13 hours
**Prerequisites**:
- Terraform installed and configured
- Kubernetes cluster access
- Docker and kubectl installed
- Basic understanding of networking concepts

---

## Exercise 1: VPC and Network Architecture Setup

**Time**: 3-4 hours
**Difficulty**: Intermediate

### Objectives

- Design secure multi-tier VPC architecture for ML workloads
- Implement network segmentation with Terraform
- Configure security groups and network policies
- Set up VPN/bastion access for secure management
- Implement flow logs and network monitoring

### Tasks

**Part 1: VPC Architecture Design (1 hour)**

1. Design three-tier VPC architecture:
   - **Public Tier**: API Gateway, Load Balancers (10.0.0.0/24)
   - **Private Tier**: ML inference services (10.0.10.0/23)
   - **Data Tier**: Databases, model storage (10.0.20.0/23)

2. Create architecture diagram showing:
   - VPC CIDR blocks
   - Subnet allocation
   - Route tables
   - Internet Gateway and NAT Gateway placement
   - Security group rules

3. Document security requirements:
   - Ingress rules per tier
   - Egress rules per tier
   - Cross-tier communication policies

**Part 2: Terraform Infrastructure (1.5 hours)**

4. Create `terraform/vpc.tf`:
   ```hcl
   terraform {
     required_providers {
       aws = {
         source  = "hashicorp/aws"
         version = "~> 5.0"
       }
     }
   }

   provider "aws" {
     region = var.aws_region
   }

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
     count                   = 3
     vpc_id                  = aws_vpc.ml_production.id
     cidr_block              = "10.0.${count.index}.0/24"
     availability_zone       = data.aws_availability_zones.available.names[count.index]
     map_public_ip_on_launch = true

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

   # Data tier subnets
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
   ```

5. Create `terraform/security_groups.tf`:
   ```hcl
   # Load balancer security group (public-facing)
   resource "aws_security_group" "alb" {
     name        = "ml-alb-sg"
     description = "Security group for Application Load Balancer"
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
       Name = "ml-alb-security-group"
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

     egress {
       description     = "To database"
       from_port       = 5432
       to_port         = 5432
       protocol        = "tcp"
       security_groups = [aws_security_group.database.id]
     }

     egress {
       description = "To S3 (via VPC endpoint)"
       from_port   = 443
       to_port     = 443
       protocol    = "tcp"
       prefix_list_ids = [aws_vpc_endpoint.s3.prefix_list_id]
     }

     tags = {
       Name = "ml-inference-security-group"
     }
   }

   # Database security group (data tier)
   resource "aws_security_group" "database" {
     name        = "ml-database-sg"
     description = "Security group for databases"
     vpc_id      = aws_vpc.ml_production.id

     ingress {
       description     = "PostgreSQL from application tier"
       from_port       = 5432
       to_port         = 5432
       protocol        = "tcp"
       security_groups = [aws_security_group.ml_inference.id]
     }

     # No egress to internet
     egress {
       description = "Internal VPC only"
       from_port   = 0
       to_port     = 0
       protocol    = "-1"
       cidr_blocks = [aws_vpc.ml_production.cidr_block]
     }

     tags = {
       Name = "ml-database-security-group"
     }
   }
   ```

6. Deploy infrastructure:
   ```bash
   cd terraform
   terraform init
   terraform plan -out=tfplan
   terraform apply tfplan
   ```

**Part 3: Kubernetes Network Policies (1 hour)**

7. Create `k8s/network-policy.yaml`:
   ```yaml
   apiVersion: networking.k8s.io/v1
   kind: NetworkPolicy
   metadata:
     name: ml-inference-policy
     namespace: ml-production
   spec:
     podSelector:
       matchLabels:
         app: ml-inference
     policyTypes:
       - Ingress
       - Egress
     ingress:
       # Allow traffic from API gateway
       - from:
         - namespaceSelector:
             matchLabels:
               name: api-gateway
         ports:
         - protocol: TCP
           port: 8080
     egress:
       # Allow DNS
       - to:
         - namespaceSelector:
             matchLabels:
               name: kube-system
         ports:
         - protocol: UDP
           port: 53
       # Allow database access
       - to:
         - namespaceSelector:
             matchLabels:
               name: databases
         ports:
         - protocol: TCP
           port: 5432
       # Allow model storage (S3)
       - to:
         - podSelector:
             matchLabels:
               app: s3-endpoint
         ports:
         - protocol: TCP
           port: 443
   ---
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
   ```

8. Apply network policies:
   ```bash
   kubectl apply -f k8s/network-policy.yaml
   kubectl get networkpolicies -n ml-production
   ```

**Part 4: VPC Flow Logs and Monitoring (30 minutes)**

9. Create `terraform/flow_logs.tf`:
   ```hcl
   resource "aws_flow_log" "ml_vpc" {
     vpc_id          = aws_vpc.ml_production.id
     traffic_type    = "ALL"
     iam_role_arn    = aws_iam_role.flow_logs.arn
     log_destination = aws_cloudwatch_log_group.flow_logs.arn

     tags = {
       Name = "ml-vpc-flow-logs"
     }
   }

   resource "aws_cloudwatch_log_group" "flow_logs" {
     name              = "/aws/vpc/ml-production"
     retention_in_days = 30

     tags = {
       Name = "ml-vpc-flow-logs"
     }
   }
   ```

10. Create CloudWatch dashboard for network monitoring:
    - VPC flow log analysis
    - Security group rule hits
    - Network bytes in/out
    - Rejected connection attempts

### Success Criteria

- [ ] Three-tier VPC architecture deployed successfully
- [ ] Security groups enforce least-privilege access
- [ ] Network policies block unauthorized pod-to-pod communication
- [ ] VPC flow logs capturing all traffic
- [ ] No direct internet access from data tier
- [ ] All resources tagged appropriately
- [ ] Infrastructure deployed via Terraform (IaC)

### Deliverables

1. `terraform/` directory with:
   - `vpc.tf`
   - `security_groups.tf`
   - `flow_logs.tf`
   - `variables.tf`
   - `outputs.tf`

2. `k8s/network-policy.yaml`

3. Documentation:
   - Network architecture diagram
   - Security group rules matrix
   - Network policy explanation
   - Flow log analysis guide

---

## Exercise 2: TLS/mTLS Implementation for ML Services

**Time**: 3-4 hours
**Difficulty**: Advanced

### Objectives

- Configure TLS for ML inference endpoints
- Implement mutual TLS (mTLS) between services
- Set up cert-manager for automated certificate management
- Configure certificate rotation
- Implement certificate validation

### Tasks

**Part 1: Certificate Authority Setup (1 hour)**

1. Create private CA with OpenSSL:
   ```bash
   # Generate CA private key
   openssl genrsa -aes256 -out ca-key.pem 4096

   # Generate CA certificate
   openssl req -new -x509 -days 3650 -key ca-key.pem -sha256 -out ca.pem \
     -subj "/C=US/ST=CA/L=SF/O=MLCompany/CN=ML-Root-CA"

   # Verify CA certificate
   openssl x509 -in ca.pem -text -noout
   ```

2. Create server certificate for ML service:
   ```bash
   # Generate server private key
   openssl genrsa -out ml-server-key.pem 4096

   # Generate CSR
   openssl req -subj "/CN=ml-inference.example.com" -sha256 -new \
     -key ml-server-key.pem -out ml-server.csr

   # Create extensions file
   cat > extfile.cnf <<EOF
   subjectAltName = DNS:ml-inference.example.com,DNS:*.ml-inference.example.com
   extendedKeyUsage = serverAuth
   EOF

   # Sign certificate
   openssl x509 -req -days 365 -sha256 -in ml-server.csr -CA ca.pem \
     -CAkey ca-key.pem -CAcreateserial -out ml-server-cert.pem \
     -extfile extfile.cnf
   ```

3. Create client certificates for mTLS:
   ```bash
   # Generate client private key
   openssl genrsa -out ml-client-key.pem 4096

   # Generate client CSR
   openssl req -subj "/CN=ml-client" -new -key ml-client-key.pem \
     -out ml-client.csr

   # Sign client certificate
   echo "extendedKeyUsage = clientAuth" > client-extfile.cnf
   openssl x509 -req -days 365 -sha256 -in ml-client.csr -CA ca.pem \
     -CAkey ca-key.pem -CAcreateserial -out ml-client-cert.pem \
     -extfile client-extfile.cnf
   ```

**Part 2: cert-manager Installation (30 minutes)**

4. Install cert-manager:
   ```bash
   kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

   # Verify installation
   kubectl get pods -n cert-manager
   ```

5. Create ClusterIssuer for Let's Encrypt:
   ```yaml
   apiVersion: cert-manager.io/v1
   kind: ClusterIssuer
   metadata:
     name: letsencrypt-prod
   spec:
     acme:
       server: https://acme-v02.api.letsencrypt.org/directory
       email: admin@example.com
       privateKeySecretRef:
         name: letsencrypt-prod
       solvers:
       - http01:
           ingress:
             class: nginx
   ```

6. Create self-signed ClusterIssuer for internal services:
   ```yaml
   apiVersion: cert-manager.io/v1
   kind: ClusterIssuer
   metadata:
     name: selfsigned-issuer
   spec:
     selfSigned: {}
   ---
   apiVersion: cert-manager.io/v1
   kind: Certificate
   metadata:
     name: ml-internal-ca
     namespace: cert-manager
   spec:
     isCA: true
     commonName: ml-internal-ca
     secretName: ml-internal-ca-secret
     privateKey:
       algorithm: ECDSA
       size: 256
     issuerRef:
       name: selfsigned-issuer
       kind: ClusterIssuer
   ---
   apiVersion: cert-manager.io/v1
   kind: ClusterIssuer
   metadata:
     name: ml-internal-ca-issuer
   spec:
     ca:
       secretName: ml-internal-ca-secret
   ```

**Part 3: TLS Configuration for ML Service (1 hour)**

7. Create Certificate resource for ML inference:
   ```yaml
   apiVersion: cert-manager.io/v1
   kind: Certificate
   metadata:
     name: ml-inference-tls
     namespace: ml-production
   spec:
     secretName: ml-inference-tls-secret
     duration: 2160h # 90 days
     renewBefore: 360h # 15 days
     commonName: ml-inference.production.svc.cluster.local
     dnsNames:
     - ml-inference.production.svc.cluster.local
     - ml-inference.example.com
     issuerRef:
       name: ml-internal-ca-issuer
       kind: ClusterIssuer
   ```

8. Configure Nginx Ingress with TLS:
   ```yaml
   apiVersion: networking.k8s.io/v1
   kind: Ingress
   metadata:
     name: ml-inference-ingress
     namespace: ml-production
     annotations:
       cert-manager.io/cluster-issuer: letsencrypt-prod
       nginx.ingress.kubernetes.io/ssl-redirect: "true"
       nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
   spec:
     ingressClassName: nginx
     tls:
     - hosts:
       - ml-inference.example.com
       secretName: ml-inference-tls-secret
     rules:
     - host: ml-inference.example.com
       http:
         paths:
         - path: /
           pathType: Prefix
           backend:
             service:
               name: ml-inference
               port:
                 number: 8080
   ```

9. Update ML service deployment to use TLS:
   ```yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: ml-inference
     namespace: ml-production
   spec:
     replicas: 3
     selector:
       matchLabels:
         app: ml-inference
     template:
       metadata:
         labels:
           app: ml-inference
       spec:
         containers:
         - name: inference
           image: ml-inference:latest
           ports:
           - containerPort: 8080
             name: https
           volumeMounts:
           - name: tls-certs
             mountPath: /etc/tls
             readOnly: true
           env:
           - name: TLS_CERT_FILE
             value: /etc/tls/tls.crt
           - name: TLS_KEY_FILE
             value: /etc/tls/tls.key
         volumes:
         - name: tls-certs
           secret:
             secretName: ml-inference-tls-secret
   ```

**Part 4: Mutual TLS (mTLS) Configuration (1.5 hours)**

10. Create mTLS configuration for service-to-service communication:
    ```yaml
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: nginx-mtls-config
      namespace: ml-production
    data:
      nginx.conf: |
        server {
          listen 8443 ssl;
          server_name ml-inference.production.svc.cluster.local;

          # Server certificate
          ssl_certificate /etc/tls/server/tls.crt;
          ssl_certificate_key /etc/tls/server/tls.key;

          # Client certificate verification
          ssl_client_certificate /etc/tls/ca/ca.crt;
          ssl_verify_client on;
          ssl_verify_depth 2;

          # TLS configuration
          ssl_protocols TLSv1.2 TLSv1.3;
          ssl_ciphers HIGH:!aNULL:!MD5;
          ssl_prefer_server_ciphers on;

          location / {
            proxy_pass http://localhost:8080;
            proxy_set_header X-Client-Cert $ssl_client_cert;
            proxy_set_header X-Client-Verify $ssl_client_verify;
            proxy_set_header X-Client-DN $ssl_client_s_dn;
          }
        }
    ```

11. Implement Python client with mTLS:
    ```python
    import requests
    from typing import Optional

    class MTLSClient:
        def __init__(
            self,
            base_url: str,
            client_cert: str,
            client_key: str,
            ca_cert: Optional[str] = None
        ):
            self.base_url = base_url
            self.cert = (client_cert, client_key)
            self.verify = ca_cert if ca_cert else True

        def predict(self, data: dict) -> dict:
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
            try:
                response = requests.get(
                    f"{self.base_url}/health",
                    cert=self.cert,
                    verify=self.verify,
                    timeout=5
                )
                return response.status_code == 200
            except Exception as e:
                print(f"Health check failed: {e}")
                return False

    # Usage
    client = MTLSClient(
        base_url="https://ml-inference.example.com",
        client_cert="/path/to/client-cert.pem",
        client_key="/path/to/client-key.pem",
        ca_cert="/path/to/ca.pem"
    )

    result = client.predict({"features": [1, 2, 3, 4, 5]})
    print(result)
    ```

12. Test certificate validation:
    ```bash
    # Test with valid client certificate
    curl --cert ml-client-cert.pem --key ml-client-key.pem \
         --cacert ca.pem https://ml-inference.example.com/health

    # Test without client certificate (should fail)
    curl --cacert ca.pem https://ml-inference.example.com/health

    # Verify certificate details
    openssl s_client -connect ml-inference.example.com:443 \
      -cert ml-client-cert.pem -key ml-client-key.pem \
      -CAfile ca.pem -showcerts
    ```

### Success Criteria

- [ ] TLS enabled for all ML inference endpoints
- [ ] Certificates automatically managed by cert-manager
- [ ] mTLS enforced for service-to-service communication
- [ ] Client certificate validation working
- [ ] Certificate rotation automated
- [ ] No expired certificates in production
- [ ] Strong cipher suites configured (TLSv1.2+)

### Deliverables

1. `certs/` directory with CA and certificate scripts
2. `k8s/` directory with:
   - `cert-manager-setup.yaml`
   - `certificates.yaml`
   - `ingress-tls.yaml`
   - `deployment-tls.yaml`
3. `src/mtls_client.py`
4. Documentation:
   - Certificate management guide
   - mTLS architecture diagram
   - Certificate renewal procedures
   - Troubleshooting guide

---

## Exercise 3: API Gateway Security with Kong

**Time**: 2-3 hours
**Difficulty**: Intermediate

### Objectives

- Deploy Kong API Gateway for ML services
- Configure authentication (API keys, JWT, OAuth2)
- Implement rate limiting and quotas
- Set up request/response transformation
- Configure WAF rules

### Tasks

**Part 1: Kong Installation (30 minutes)**

1. Deploy Kong with Helm:
   ```bash
   helm repo add kong https://charts.konghq.com
   helm repo update

   helm install kong kong/kong \
     --namespace kong \
     --create-namespace \
     --set ingressController.enabled=true \
     --set admin.enabled=true \
     --set admin.http.enabled=true
   ```

2. Verify Kong installation:
   ```bash
   kubectl get pods -n kong
   kubectl get svc -n kong
   ```

**Part 2: Service Configuration (1 hour)**

3. Create Kong Ingress for ML service:
   ```yaml
   apiVersion: networking.k8s.io/v1
   kind: Ingress
   metadata:
     name: ml-inference-kong
     namespace: ml-production
     annotations:
       konghq.com/strip-path: "true"
       konghq.com/protocols: "https"
   spec:
     ingressClassName: kong
     rules:
     - host: api.ml-example.com
       http:
         paths:
         - path: /inference
           pathType: Prefix
           backend:
             service:
               name: ml-inference
               port:
                 number: 8080
   ```

4. Configure API key authentication:
   ```yaml
   apiVersion: configuration.konghq.com/v1
   kind: KongPlugin
   metadata:
     name: api-key-auth
     namespace: ml-production
   plugin: key-auth
   config:
     key_names:
     - apikey
     hide_credentials: true
   ---
   apiVersion: v1
   kind: Secret
   metadata:
     name: ml-api-keys
     namespace: ml-production
     labels:
       konghq.com/credential: key-auth
   stringData:
     key: "production-ml-api-key-123456"
     # Additional keys can be added
   ---
   apiVersion: configuration.konghq.com/v1
   kind: KongConsumer
   metadata:
     name: ml-client-app
     namespace: ml-production
     annotations:
       kubernetes.io/ingress.class: kong
       konghq.com/plugins: api-key-auth
   username: ml-client-app
   credentials:
   - ml-api-keys
   ```

5. Configure JWT authentication:
   ```yaml
   apiVersion: configuration.konghq.com/v1
   kind: KongPlugin
   metadata:
     name: jwt-auth
     namespace: ml-production
   plugin: jwt
   config:
     uri_param_names:
     - jwt
     claims_to_verify:
     - exp
     secret_is_base64: false
     maximum_expiration: 300
   ```

**Part 3: Rate Limiting and Security (1 hour)**

6. Configure rate limiting:
   ```yaml
   apiVersion: configuration.konghq.com/v1
   kind: KongPlugin
   metadata:
     name: rate-limit-tier1
     namespace: ml-production
   plugin: rate-limiting
   config:
     minute: 100
     hour: 10000
     policy: local
     limit_by: consumer
     fault_tolerant: true
   ---
   apiVersion: configuration.konghq.com/v1
   kind: KongPlugin
   metadata:
     name: rate-limit-tier2
     namespace: ml-production
   plugin: rate-limiting
   config:
     minute: 1000
     hour: 100000
     policy: redis
     redis_host: redis.kong.svc.cluster.local
     redis_port: 6379
     limit_by: consumer
   ```

7. Configure request size limiting:
   ```yaml
   apiVersion: configuration.konghq.com/v1
   kind: KongPlugin
   metadata:
     name: request-size-limit
     namespace: ml-production
   plugin: request-size-limiting
   config:
     allowed_payload_size: 10  # 10 MB
   ```

8. Set up IP restriction:
   ```yaml
   apiVersion: configuration.konghq.com/v1
   kind: KongPlugin
   metadata:
     name: ip-restriction
     namespace: ml-production
   plugin: ip-restriction
   config:
     allow:
     - 10.0.0.0/8      # Internal VPC
     - 203.0.113.0/24  # Office IP range
   ```

9. Configure request/response transformation:
   ```yaml
   apiVersion: configuration.konghq.com/v1
   kind: KongPlugin
   metadata:
     name: request-transformer
     namespace: ml-production
   plugin: request-transformer
   config:
     add:
       headers:
       - "X-Request-ID:$(uuid)"
       - "X-Client-IP:$(remote_addr)"
     remove:
       headers:
       - "Authorization"  # Don't pass to backend
   ---
   apiVersion: configuration.konghq.com/v1
   kind: KongPlugin
   metadata:
     name: response-transformer
     namespace: ml-production
   plugin: response-transformer
   config:
     remove:
       headers:
       - "X-Internal-Header"
     add:
       headers:
       - "X-API-Version:1.0"
   ```

**Part 4: Monitoring and Logging (30 minutes)**

10. Configure Prometheus plugin:
    ```yaml
    apiVersion: configuration.konghq.com/v1
    kind: KongClusterPlugin
    metadata:
      name: prometheus
      labels:
        global: "true"
    plugin: prometheus
    config:
      per_consumer: true
    ```

11. Apply all plugins to ingress:
    ```yaml
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: ml-inference-kong
      namespace: ml-production
      annotations:
        konghq.com/plugins: api-key-auth,rate-limit-tier1,request-size-limit,ip-restriction,request-transformer,response-transformer
    spec:
      # ... (same as before)
    ```

12. Test API gateway:
    ```bash
    # Without API key (should fail)
    curl -i https://api.ml-example.com/inference/predict

    # With API key
    curl -i -H "apikey: production-ml-api-key-123456" \
         https://api.ml-example.com/inference/predict \
         -d '{"features": [1,2,3,4,5]}'

    # Test rate limiting
    for i in {1..110}; do
      curl -H "apikey: production-ml-api-key-123456" \
           https://api.ml-example.com/inference/predict
    done
    ```

### Success Criteria

- [ ] Kong API Gateway deployed and accessible
- [ ] Authentication required for all API endpoints
- [ ] Rate limiting enforced per consumer
- [ ] Request size limits preventing large payloads
- [ ] IP restrictions blocking unauthorized sources
- [ ] Request/response headers transformed appropriately
- [ ] Metrics exported to Prometheus

### Deliverables

1. `k8s/kong/` directory with:
   - `kong-install.yaml`
   - `ingress.yaml`
   - `plugins.yaml`
   - `consumers.yaml`

2. `scripts/test-api-gateway.sh`

3. Documentation:
   - API gateway architecture diagram
   - Authentication configuration guide
   - Rate limiting tiers explanation
   - Client integration guide

---

## Exercise 4: Service Mesh Security with Istio

**Time**: 2-3 hours
**Difficulty**: Advanced

### Objectives

- Deploy Istio service mesh
- Configure automatic mTLS between services
- Implement authorization policies
- Set up traffic management with security
- Configure distributed tracing

### Tasks

**Part 1: Istio Installation (30 minutes)**

1. Install Istio:
   ```bash
   curl -L https://istio.io/downloadIstio | sh -
   cd istio-*
   export PATH=$PWD/bin:$PATH

   istioctl install --set profile=production -y

   # Enable automatic sidecar injection
   kubectl label namespace ml-production istio-injection=enabled
   ```

2. Verify installation:
   ```bash
   kubectl get pods -n istio-system
   istioctl verify-install
   ```

**Part 2: mTLS Configuration (1 hour)**

3. Enable strict mTLS for namespace:
   ```yaml
   apiVersion: security.istio.io/v1beta1
   kind: PeerAuthentication
   metadata:
     name: default
     namespace: ml-production
   spec:
     mtls:
       mode: STRICT
   ```

4. Configure destination rules:
   ```yaml
   apiVersion: networking.istio.io/v1beta1
   kind: DestinationRule
   metadata:
     name: ml-inference-mtls
     namespace: ml-production
   spec:
     host: ml-inference.ml-production.svc.cluster.local
     trafficPolicy:
       tls:
         mode: ISTIO_MUTUAL
       connectionPool:
         tcp:
           maxConnections: 100
         http:
           http1MaxPendingRequests: 50
           http2MaxRequests: 100
       loadBalancer:
         simple: LEAST_REQUEST
   ```

5. Verify mTLS is working:
   ```bash
   # Check certificate details
   istioctl proxy-config secret ml-inference-<pod-id> -n ml-production

   # Verify mTLS status
   istioctl authn tls-check ml-inference-<pod-id>.ml-production \
     ml-inference.ml-production.svc.cluster.local
   ```

**Part 3: Authorization Policies (1 hour)**

6. Create default deny policy:
   ```yaml
   apiVersion: security.istio.io/v1beta1
   kind: AuthorizationPolicy
   metadata:
     name: deny-all
     namespace: ml-production
   spec:
     {}  # Empty policy = deny all
   ```

7. Allow API gateway to inference service:
   ```yaml
   apiVersion: security.istio.io/v1beta1
   kind: AuthorizationPolicy
   metadata:
     name: allow-api-gateway
     namespace: ml-production
   spec:
     selector:
       matchLabels:
         app: ml-inference
     action: ALLOW
     rules:
     - from:
       - source:
           namespaces: ["kong"]
       to:
       - operation:
           methods: ["POST"]
           paths: ["/predict", "/batch-predict"]
   ```

8. Allow service-to-service with JWT:
   ```yaml
   apiVersion: security.istio.io/v1beta1
   kind: AuthorizationPolicy
   metadata:
     name: allow-with-jwt
     namespace: ml-production
   spec:
     selector:
       matchLabels:
         app: ml-inference
     action: ALLOW
     rules:
     - from:
       - source:
           requestPrincipals: ["*"]
       when:
       - key: request.auth.claims[iss]
         values: ["https://auth.ml-example.com"]
       - key: request.auth.claims[scope]
         values: ["ml-inference"]
   ```

9. Implement request authentication:
   ```yaml
   apiVersion: security.istio.io/v1beta1
   kind: RequestAuthentication
   metadata:
     name: jwt-auth
     namespace: ml-production
   spec:
     selector:
       matchLabels:
         app: ml-inference
     jwtRules:
     - issuer: "https://auth.ml-example.com"
       jwksUri: "https://auth.ml-example.com/.well-known/jwks.json"
       audiences:
       - "ml-inference-api"
   ```

**Part 4: Traffic Management and Observability (30 minutes)**

10. Configure traffic shifting for canary deployment:
    ```yaml
    apiVersion: networking.istio.io/v1beta1
    kind: VirtualService
    metadata:
      name: ml-inference-vs
      namespace: ml-production
    spec:
      hosts:
      - ml-inference.ml-production.svc.cluster.local
      http:
      - match:
        - headers:
            x-canary:
              exact: "true"
        route:
        - destination:
            host: ml-inference.ml-production.svc.cluster.local
            subset: v2
          weight: 100
      - route:
        - destination:
            host: ml-inference.ml-production.svc.cluster.local
            subset: v1
          weight: 90
        - destination:
            host: ml-inference.ml-production.svc.cluster.local
            subset: v2
          weight: 10
    ---
    apiVersion: networking.istio.io/v1beta1
    kind: DestinationRule
    metadata:
      name: ml-inference-dr
      namespace: ml-production
    spec:
      host: ml-inference.ml-production.svc.cluster.local
      subsets:
      - name: v1
        labels:
          version: v1
      - name: v2
        labels:
          version: v2
    ```

11. Enable Jaeger for distributed tracing:
    ```bash
    kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.20/samples/addons/jaeger.yaml

    # Access Jaeger UI
    istioctl dashboard jaeger
    ```

12. Test authorization policies:
    ```bash
    # From unauthorized pod (should fail)
    kubectl run test-pod --image=curlimages/curl -it --rm -- \
      curl ml-inference.ml-production.svc.cluster.local:8080/predict

    # From authorized namespace with valid JWT (should succeed)
    kubectl run test-pod -n kong --image=curlimages/curl -it --rm -- \
      curl -H "Authorization: Bearer <valid-jwt>" \
      ml-inference.ml-production.svc.cluster.local:8080/predict
    ```

### Success Criteria

- [ ] Istio deployed with automatic sidecar injection
- [ ] Strict mTLS enforced between all services
- [ ] Authorization policies block unauthorized access
- [ ] JWT authentication configured and working
- [ ] Traffic management policies applied
- [ ] Distributed tracing with Jaeger operational
- [ ] No plaintext traffic between services

### Deliverables

1. `k8s/istio/` directory with:
   - `peer-authentication.yaml`
   - `authorization-policies.yaml`
   - `request-authentication.yaml`
   - `virtual-service.yaml`
   - `destination-rule.yaml`

2. `scripts/test-istio-security.sh`

3. Documentation:
   - Service mesh architecture diagram
   - mTLS configuration guide
   - Authorization policy matrix
   - Traffic management guide
   - Troubleshooting guide

---

## Additional Resources

### Tools

- **Terraform**: https://www.terraform.io/docs
- **cert-manager**: https://cert-manager.io/docs/
- **Kong**: https://docs.konghq.com/gateway/latest/
- **Istio**: https://istio.io/latest/docs/

### Best Practices

1. **Defense in Depth**: Multiple security layers (network, transport, application)
2. **Least Privilege**: Minimal permissions at every level
3. **Zero Trust**: Verify all traffic, even within VPC
4. **Encryption Everywhere**: TLS for all communications
5. **Automated Certificate Management**: Never manually manage certificates
6. **Monitoring**: Continuous monitoring of network traffic and security events

### Documentation

- **AWS VPC Best Practices**: https://docs.aws.amazon.com/vpc/latest/userguide/vpc-security-best-practices.html
- **Kubernetes Network Policies**: https://kubernetes.io/docs/concepts/services-networking/network-policies/
- **NIST TLS Guidelines**: https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-52r2.pdf
- **Istio Security**: https://istio.io/latest/docs/concepts/security/

---

## Assessment Rubric

**Advanced (90-100%)**
- All exercises completed with production-ready configurations
- Multi-layered security controls properly configured
- Comprehensive monitoring and alerting set up
- Excellent documentation with architecture diagrams
- Automated testing of security controls

**Proficient (75-89%)**
- Core functionality working in all exercises
- Good security practices implemented
- Basic monitoring configured
- Clear documentation
- Manual testing performed

**Developing (60-74%)**
- Most exercises completed
- Basic security controls in place
- Limited monitoring
- Minimal documentation

**Needs Improvement (<60%)**
- Incomplete implementations
- Security misconfigurations present
- No monitoring
- Poor documentation
