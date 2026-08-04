# Chapter 02 — Vault and Dynamic Secrets for Shared Data Stores

> **Note on AI-assisted content.** Verify Vault CLI syntax, policy
> language, and secrets-engine paths against the current
> [HashiCorp Vault documentation](https://developer.hashicorp.com/vault/docs)
> before quoting in production. Vault's API surface changes between
> minor versions. See [`resources.md`](./resources.md).

---

## Why this chapter exists

Chapter 01 produced an inventory. Every row in the inventory
marked `Long-lived = YES` is a design defect: a credential that
sits in some store, waiting to be stolen, waiting to be rotated,
waiting to leak. This chapter converts the largest single class of
those defects — credentials to shared data stores that many
workloads need to read from — into **dynamically issued,
time-bounded credentials**.

The specific failure mode this chapter is written to prevent:

> Every training job in the org has read access to the Snowflake
> data warehouse via a shared `SNOWFLAKE_ML_ROLE` and a
> long-lived password stored in a Kubernetes `Secret`. A CI
> pipeline runs a `kubectl get secret snowflake -o yaml` in a
> debug session; the pod's logs are shipped to a third-party log
> aggregator with broad org-wide access. The password is now in
> the log store, in the log-aggregator vendor's index, on the
> attacker's laptop after a support-engineer credential is
> phished. Two months later a training job exfiltrates the entire
> customer table. Post-mortem: the credential was correct;
> nobody had rotated it in eighteen months; nobody could tell
> from Snowflake's audit log which workload had actually made
> the query because *every* training job used the same shared
> user.

The failure has three parts, and dynamic secrets fix all three:

1. **Static credential** → attacker who ever sees it can use it
   indefinitely. Fix: credentials expire in an hour.
2. **Shared identity** → the audit trail cannot attribute the
   query to a specific workload. Fix: each workload gets its own
   credential, tagged with its identity.
3. **Manual rotation** → nobody rotates when nothing has visibly
   broken. Fix: rotation is automatic and continuous — a
   credential's *lifetime* is the rotation window.

Vault's [database secrets
engine](https://developer.hashicorp.com/vault/docs/secrets/databases)
is the reference implementation.

You leave this chapter able to:

- Choose between the KV secrets engine (for static bearer
  tokens) and dynamic-issuance engines (databases, cloud IAM,
  PKI, SSH).
- Wire a Kubernetes-hosted workload to authenticate to Vault
  via its projected service-account token and receive short-
  lived DB credentials.
- Write Vault ACL policies that scope a workload to the
  smallest possible set of secret paths.
- Author the Vault topology decisions that separate blast
  radius: namespaces per environment, mounts per team, seal
  keys per region.
- Read a Vault audit log and identify the four common signs of
  policy abuse.

---

## Vault in one paragraph

**HashiCorp Vault** is an identity-based secret and encryption
management system. Clients (workloads, humans) authenticate via
one of many **auth methods** (Kubernetes SA token, AWS IAM,
GCP IAM, OIDC, LDAP, TLS cert, AppRole for machine-to-machine).
On successful auth, the client receives a **Vault token** with a
bounded lifetime and an attached **policy** (an ACL granting or
denying paths). The client uses the token to read from **secrets
engines** mounted at paths — some engines store static values
(KV), others *generate credentials on demand* (database, cloud
IAM, PKI). Every action is audited to a **file / socket audit
device**. The server persists state in a **storage backend**
(Integrated Storage / Raft is the default; Consul is legacy).

That paragraph is the mental model. The rest of the chapter is
what you do with it.

There are open-source alternatives (OpenBao is the actively
maintained Linux Foundation fork of Vault OSS) and cloud-native
alternatives (AWS Secrets Manager + IAM, GCP Secret Manager +
Workload Identity, Azure Key Vault + Managed Identity). The
architectural patterns in this chapter map to all of them; the
concrete API surfaces do not. Pick one; adapt from there.

---

## Static vs dynamic secrets

Vault supports both.

**Static secrets** — the KV v2 engine stores arbitrary
key-value pairs and versions them. The workload reads
`kv/data/prod/openai-api-key`. Vault does not know or care what
the value means; it just returns bytes and audits the read. Use
KV for:

- External-provider API keys where the provider does not
  support OIDC / dynamic issuance (chapter 01 class 4 and 6).
- Bootstrap secrets you cannot issue dynamically (a cluster's
  root TLS certificate; a very first credential a new tenant
  needs before Vault-issued flows apply).
- Small configuration values that must be secret but not
  frequently rotated.

**Dynamic secrets** — engines that generate a fresh credential
for each request. The workload reads
`database/creds/ml-training-role`; Vault contacts the database,
runs a `CREATE USER` with a random password and a TTL, returns
the credential, and schedules the user for deletion when the
lease expires. The workload uses the credential; Vault revokes it
on schedule. Use dynamic issuance for:

- Every relational-DB credential (Postgres, MySQL, MSSQL,
  Snowflake, BigQuery via connector, Redshift).
- Every cloud IAM credential — the `aws`, `gcp`, `azure` engines
  issue short-lived STS / SA-key / service-principal tokens.
- Every SSH credential — the SSH signed-certificates engine
  issues short-lived, host-scoped certificates.
- Every PKI leaf certificate — the PKI engine acts as an
  intermediate CA.

The rule for the ML inventory: **if the credential is a database
or cloud IAM credential, it is a dynamic secret** unless there is
an explicit written exception. Static-in-KV for these classes is
a gap.

---

## The reference topology

For an org running ML on Kubernetes with two production clusters
(one per region) and separate dev / staging / prod environments,
the reference Vault topology looks like this:

```
                Vault cluster (HA, Raft, 5 nodes across 3 AZs)
                └── seal: AWS KMS (auto-unseal); DR mode enabled
                    │
                    ├─ namespace "root"
                    │    └─ system policies, root credentials
                    │
                    ├─ namespace "platform"
                    │    ├─ auth/kubernetes/  (bound to platform cluster)
                    │    ├─ database/         (dynamic-DB engine, prod)
                    │    ├─ aws/              (dynamic-IAM engine, prod)
                    │    └─ policies for platform SREs
                    │
                    ├─ namespace "ml-prod"
                    │    ├─ auth/kubernetes/  (bound to ml-prod cluster)
                    │    ├─ database/         (dynamic-DB — training warehouse)
                    │    ├─ database/         (dynamic-DB — feature-store offline)
                    │    ├─ aws/              (dynamic-IAM — training S3 read)
                    │    ├─ kv/               (static — external API keys,
                    │    │                     class 4 + 6 secrets)
                    │    └─ pki/              (mesh cert issuance for mod-103)
                    │
                    ├─ namespace "ml-staging"
                    │    └─ … (mirror of ml-prod, distinct engines)
                    │
                    ├─ namespace "ml-dev"
                    │    └─ … (mirror; read-only mirrors of API keys where
                    │            legally allowed, otherwise separate accounts)
                    │
                    └─ audit device: file + syslog → SIEM
                                     off-cluster
```

Key decisions in the topology:

- **Namespaces per environment.** Vault Enterprise namespaces
  give hard isolation — a policy or token in `ml-staging` cannot
  read a secret in `ml-prod` even by accident. Vault OSS lacks
  namespaces but supports the same isolation via **separate
  clusters per environment**, which most regulated orgs run
  anyway.
- **Kubernetes auth per cluster.** Each Kubernetes cluster's
  API server signs the projected service-account tokens Vault
  validates. Bind one Kubernetes auth mount per cluster; do not
  share the same auth mount across clusters (a compromised
  cluster's tokens would then be valid against another cluster's
  secrets).
- **Auto-unseal via cloud KMS.** Vault must decrypt its own
  storage on start. Auto-unseal via a cloud KMS eliminates the
  Shamir-key-holder rite and integrates recovery keys with the
  cloud IAM. Store the recovery keys per Vault docs — usually a
  set of holders with an M-of-N threshold.
- **Audit-device off-cluster.** The audit device streams every
  request (with request bodies hashed by default) to a stream
  the operators of Vault themselves do not control. If Vault is
  compromised, the audit trail of *how* it was compromised must
  survive.
- **DR replication.** Vault Enterprise offers Performance +
  Disaster Recovery replication; Vault OSS relies on
  storage-backend replication of Raft or an application-layer
  replication design.

If the environment is Vault Enterprise-less (OSS or OpenBao)
with a single-cluster Vault, the pattern collapses to one Vault
per environment.

---

## Authenticating a Kubernetes workload

Every workload authentication in Vault answers three questions:
*who are you?*, *what may you do?*, *for how long?* The
Kubernetes auth method answers each concretely.

**Step 1 — enable the auth method (once, per cluster):**

```bash
vault auth enable -path=kubernetes -namespace=ml-prod kubernetes
vault write auth/kubernetes/config -namespace=ml-prod \
    kubernetes_host="https://kubernetes.default.svc" \
    kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
    token_reviewer_jwt=@/var/run/secrets/kubernetes.io/serviceaccount/token \
    issuer="https://kubernetes.default.svc.cluster.local"
```

Vault will validate service-account tokens by calling
Kubernetes' TokenReview API using `token_reviewer_jwt`. The
issuer value should match your cluster's OIDC issuer discovery
(`kubectl get --raw /.well-known/openid-configuration`).

**Step 2 — bind a Kubernetes service-account to a Vault role:**

```bash
vault write auth/kubernetes/role/ml-training \
    -namespace=ml-prod \
    bound_service_account_names="ml-training-sa" \
    bound_service_account_namespaces="ml-training" \
    audience="vault" \
    policies="ml-training-policy" \
    ttl=1h \
    max_ttl=8h
```

The role grants the SA `ml-training/ml-training-sa` a
Vault token with the `ml-training-policy` (defined below), TTL
1 hour, renewable to a max of 8 hours.

**Step 3 — the workload authenticates:**

```bash
# Inside the training pod:
JWT=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
VAULT_TOKEN=$(vault write -field=token \
    auth/kubernetes/login role=ml-training jwt="$JWT")
```

Or, more commonly, this is done by a Vault sidecar or the
Vault CSI driver so the training container never handles the
JWT or the Vault token directly.

**Step 4 — the workload requests a dynamic DB credential:**

```bash
vault read database/creds/snowflake-ml-training
# → returns username=v-ml-training-<random>-<epoch>, password=..., lease_id=..., lease_duration=3600
```

The workload uses the returned username / password for its
Snowflake connection. When the lease expires, Vault runs the
configured `revocation_statements` (`DROP USER ...`) and the
credential no longer exists.

---

## A minimal policy

Vault policies are HCL. The important property is that they
**deny by default** — a path not listed is not accessible.

```hcl
# ml-training-policy — attached to Kubernetes role ml-training

# Allow reading dynamic DB credentials for the training warehouse
path "database/creds/snowflake-ml-training" {
  capabilities = ["read"]
}

# Allow reading dynamic AWS IAM creds for the training S3 bucket
path "aws/creds/ml-training-s3-read" {
  capabilities = ["read"]
}

# Allow reading the OpenAI API key from KV (static)
path "kv/data/ml-training/openai-api-key" {
  capabilities = ["read"]
}

# Explicitly deny production ML registry writes (should be a
# separate CI role, not the training pod)
path "kv/data/ml-registry/*" {
  capabilities = ["deny"]
}

# Renew our own token
path "auth/token/renew-self" {
  capabilities = ["update"]
}
```

Notes:

- **One policy per workload role.** The temptation to write
  `path "kv/data/ml-training/*"` and be done saves five minutes
  today and costs a compromise investigation in a year. Grant
  the exact leaf paths.
- **`deny` beats `allow`.** Explicit denies are the safe way
  to enforce cross-team isolation. The `ml-training` workload
  should not, for any reason, be able to read `ml-registry/*`;
  a deny catches an accidental future policy edit that grants it.
- **Response wrapping** is optional but valuable for
  credential handoff — Vault returns a single-use wrapping
  token; the workload unwraps once; a replay by an attacker
  observing the network never succeeds.

---

## Dynamic-DB engine — the concrete example

Vault's database engine has plugins for every mainstream
database. The `snowflake-database-plugin` example, abbreviated:

```bash
vault write database/config/snowflake -namespace=ml-prod \
    plugin_name=snowflake-database-plugin \
    allowed_roles="snowflake-ml-training,snowflake-ml-eval" \
    connection_url="{{username}}:{{password}}@acme.snowflakecomputing.com/db?role=VAULT_ADMIN" \
    username="VAULT_ADMIN_USER" \
    password="<initial-admin-password-known-only-to-vault>" \
    verify_connection=true

# Optionally rotate the admin credential Vault itself uses,
# so nobody in the org knows it after this:
vault write -force database/rotate-root/snowflake -namespace=ml-prod
```

Now define the training role:

```bash
vault write database/roles/snowflake-ml-training -namespace=ml-prod \
    db_name=snowflake \
    creation_statements=@snowflake-ml-training-create.sql \
    revocation_statements=@snowflake-ml-training-revoke.sql \
    default_ttl=1h \
    max_ttl=4h
```

Where `snowflake-ml-training-create.sql` contains, roughly:

```sql
CREATE USER "{{name}}" PASSWORD='{{password}}' DEFAULT_ROLE=ML_READ
    DAYS_TO_EXPIRY=1;
GRANT ROLE ML_READ TO USER "{{name}}";
```

And `snowflake-ml-training-revoke.sql`:

```sql
DROP USER IF EXISTS "{{name}}";
```

Every training-pod DB session is now:

1. Vault issues `v-ml-training-<random>` with a 1-hour TTL.
2. The pod uses it against Snowflake.
3. Vault revokes at lease expiry.
4. Snowflake's audit log shows the query attributed to
   `v-ml-training-<random>`, and Vault's audit log ties that
   name back to the training pod's Vault token, the Kubernetes
   SA, and by transitive attestation (mod-103 chapter 03) the
   SPIFFE identity of the workload.

That is what "attribution" means in a dynamic-secrets world.

---

## When dynamic issuance is not available

Some ML integrations do not support dynamic issuance:

- Third-party model providers (Anthropic, OpenAI, Cohere,
  Hugging Face Inference API) — mostly static bearer tokens.
  <!-- needs-research: some providers now support OIDC or
  workload-identity federated credential exchange; confirm
  current support matrix before recommending. -->
- Legacy on-prem systems that only accept a single admin user.
- SaaS integrations where the API is designed for humans
  clicking "generate token".

For these, use KV v2 with the following mitigations:

1. **Store one token per workload identity, not one shared
   token.** If OpenAI is called from three services, buy three
   API keys and store each in a distinct KV path with a distinct
   Vault policy.
2. **Automate rotation.** Every provider that offers a
   token-rotation API should be scripted; the script pulls
   the new token into Vault and revokes the old. Chapters 04
   and 05 orchestrate this.
3. **Set a rotation SLA in the inventory** for providers that
   do not offer an API — 90 days maximum for tokens with cost
   exposure; 30 days for tokens with data exfiltration
   exposure. The rotation itself is a human action but it must
   land on the calendar.
4. **Response-wrap** the token on retrieval so the pod sees
   the token only once and the wrapping token cannot be
   replayed.

---

## Vault audit — what to actually watch

Vault emits an audit event for **every request**, including
authentication attempts and failed reads. The four highest-value
detections for an ML platform:

1. **Unusual read-rate on a KV path.** A workload that normally
   reads `kv/data/ml-training/openai-api-key` once per training
   run suddenly reads it 100 times in a minute — either a
   restart loop (benign) or a compromised pod attempting to
   exfiltrate under the guise of the workload's identity
   (malicious). Set a per-path rate alarm.
2. **A denied path with the workload's identity.** If
   `ml-training` attempts to read `kv/data/ml-registry/*` and is
   denied, the workload code should never have made the call.
   Investigate — the deny caught a misconfigured deploy or a
   compromised pod.
3. **Root-token use.** The root token should be sealed away
   after initial setup. Any use is a chapter-05 event.
4. **Auth-method configuration change.** A change to
   `auth/kubernetes/config` is either a legitimate cluster
   rotation or an attacker widening the trust surface. Alert on
   every change; verify against the change-management record.

The audit log itself is the mod-104 chapter-06 WORM sink; it
does not live only inside Vault.

---

## What the training workload actually looks like

The end-to-end shape, with Vault, of a training-pod pulling
credentials:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ml-training-sa
  namespace: ml-training
  annotations:
    vault.hashicorp.com/agent-inject: "true"
---
apiVersion: batch/v1
kind: Job
metadata:
  name: fraud-training-run-42
  namespace: ml-training
  annotations:
    vault.hashicorp.com/agent-inject: "true"
    vault.hashicorp.com/role: "ml-training"
    vault.hashicorp.com/agent-inject-secret-db: "database/creds/snowflake-ml-training"
    vault.hashicorp.com/agent-inject-template-db: |
      {{ with secret "database/creds/snowflake-ml-training" -}}
      SNOWFLAKE_USER="{{ .Data.username }}"
      SNOWFLAKE_PASSWORD="{{ .Data.password }}"
      {{- end }}
    vault.hashicorp.com/agent-inject-secret-openai: "kv/data/ml-training/openai-api-key"
    vault.hashicorp.com/agent-inject-template-openai: |
      {{ with secret "kv/data/ml-training/openai-api-key" -}}
      OPENAI_API_KEY="{{ .Data.data.token }}"
      {{- end }}
spec:
  template:
    spec:
      serviceAccountName: ml-training-sa
      containers:
        - name: trainer
          image: acme-registry/ml-training/fraud:sha-abcdef
          command: ["/bin/bash", "-lc", "source /vault/secrets/db && source /vault/secrets/openai && ./train.py"]
```

The training script never sees Vault. The Vault Agent sidecar
authenticates on the pod's behalf, requests the dynamic
credential, writes it to a tmpfs at `/vault/secrets/db`, and
renews the lease as long as the pod runs. Alternatives include
the [Vault Secrets Operator for
Kubernetes](https://developer.hashicorp.com/vault/docs/platform/k8s/vso)
(operator-managed CRD-driven approach) or the Secrets Store
CSI driver — pick one per platform, do not mix.

---

## Common pitfalls

- **Long TTLs "so nothing breaks".** A 30-day TTL is not a
  dynamic secret; it is a static secret in disguise. Set TTLs
  in hours or minutes and let the auto-renewal handle
  long-running workloads.
- **Shared Vault roles.** Ten teams sharing one `ml-workload`
  role means the audit trail cannot attribute a lease to a
  specific team. One Vault role per Kubernetes SA (or per
  SPIFFE identity).
- **Storing dynamic-secret leases as if they were static.**
  A dynamic credential should never appear in a config file,
  a git repo, or a persistent volume. It exists in memory for
  its TTL and disappears.
- **Skipping the audit device.** Vault will start without one;
  don't. Every deployment configures the audit device before
  anything else, and every audit event ships off-cluster.
- **Not testing revocation.** A `vault lease revoke -force`
  should tear down the credential in the database within
  seconds. Rehearse this quarterly; if the revoke does not
  actually revoke (a plugin bug, a network partition), the
  chapter-05 runbook needs the fallback.
- **Cross-environment auth mounts.** Never let a single
  Kubernetes cluster's tokens authenticate against another
  environment's Vault namespace. One mount per cluster.

---

## Summary

- Vault (or an equivalent: OpenBao, AWS Secrets Manager + IAM,
  GCP Secret Manager + Workload Identity, Azure Key Vault +
  Managed Identity) is the reference store; the pattern is the
  same, the API changes.
- Prefer **dynamic-issuance** engines (database, cloud IAM,
  SSH, PKI) over **KV static** wherever the underlying system
  supports it. Every training-warehouse credential should be a
  dynamic DB credential.
- Topology: namespaces (or clusters) per environment;
  Kubernetes auth per cluster; auto-unseal via cloud KMS;
  audit device off-cluster; DR replication.
- Policies: deny by default; leaf paths only; explicit deny
  for cross-team paths; one role per workload identity.
- Static-KV is acceptable for external-provider API keys that
  do not yet support OIDC / dynamic issuance; mitigate with
  per-workload tokens, automation, and rotation SLAs.
- Audit-log detections: read-rate anomalies, deny events with
  workload identity, root-token use, auth-method config changes.
- The training-pod integration is the Vault Agent sidecar (or
  VSO / CSI); the workload code never handles Vault directly.
