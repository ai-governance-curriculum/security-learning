# Module 05 — Secrets Management for ML Systems

> **Note on AI-assisted content.** Drafted with AI assistance and
> under human review. Vault and ESO are actively developed; verify
> against the current upstream documentation before implementing.
> See [`resources.md`](./resources.md).

---

## 1. What "secret" actually means here

A secret, in this module, is **any value whose disclosure to an
unintended party is a security event**. Practically:

- API keys (to your services, to third-party services).
- Database passwords.
- Model-artifact store credentials.
- Cloud IAM credentials (access keys, refresh tokens).
- Signing keys (for artifacts, for audit logs, for JWTs).
- Customer-managed keys for application-layer encryption.
- TLS private keys.
- OIDC client secrets.
- Webhook signing secrets.
- LLM provider API keys (OpenAI, Anthropic, Cohere) — increasingly
  central in ML systems.

Not a secret:
- Public keys (publishing is the point).
- Configuration that's safe to publish (feature flags,
  non-sensitive endpoints, model names).
- IDs that aren't usable without an accompanying secret.

The boundary is squishy in practice. When in doubt, treat as a
secret; the cost of over-protecting is low.

---

## 2. The three classes of secrets and why they need different
handling

| Class | Examples | Lifetime | Storage |
|---|---|---|---|
| **Static long-lived** | Third-party API keys with no rotation API | months to years | Vault KV or cloud secret manager |
| **Dynamic short-lived** | Database creds issued per-session | minutes to hours | Vault dynamic engine, never persisted at rest in your system |
| **Workload-identity-derived** | Cloud IAM creds via OIDC trust, SPIRE-issued SVIDs | minutes | Issued on demand from identity provider |

The strategic shift: **as much as possible, move secrets from
"static long-lived" toward "dynamic short-lived" or "workload-
identity-derived."**

A long-lived API key sitting in Vault is better than the same key
in a Kubernetes Secret, but both are worse than a dynamic
credential issued per-request that auto-expires in 15 minutes.

---

## 3. HashiCorp Vault: the core

Vault is the most-deployed open-source secret manager. Knowing
its core architecture matters even if you're using a cloud
secret manager — concepts transfer.

### 3.1 Vault's mental model

- **Auth methods**: how callers authenticate. Kubernetes, JWT/OIDC,
  AppRole, AWS IAM, GCP IAM, LDAP, etc.
- **Policies**: HCL files that grant capabilities on paths.
- **Secret engines**: mounted at a path, each engine handles a
  class of secrets.
- **Tokens**: short-lived bearer tokens issued after
  authentication. Used for API calls.

A caller authenticates → Vault checks policies → if allowed,
returns a token with bounded capabilities. The token expires.

### 3.2 The engines that matter

#### KV (Key-Value) engine

The vanilla "store a secret, retrieve it later" engine. Use
`kv-v2` (versioned). Properties:

- Versioned: every write produces a new version; old versions
  retained.
- Metadata: per-secret metadata (labels, deletion timestamps).
- Use for: static secrets that don't fit other engines (third-
  party API keys, SaaS credentials).

```bash
vault kv put secret/openai-api-key value=sk-xxx
vault kv get secret/openai-api-key
```

#### PKI engine

Vault as an internal CA. Properties:

- Vault issues short-lived X.509 certs.
- Integrates with cert-manager (the Vault issuer pulls certs).
- Can run as an intermediate CA signed by an offline root.

Use for: internal mTLS certs, end-entity certs for service
identity. (For SPIFFE-style workload identity, SPIRE is the more
specialized tool; Vault PKI is the general-purpose tool.)

#### Transit engine

Crypto-as-a-service. Keys stay inside Vault; callers ask Vault to
encrypt / decrypt / sign / verify. Use for:

- Application-layer encryption of PII columns.
- Signing audit log entries.
- Tokenization (deterministic encryption for searchable
  fields).

The interesting property: the **data** flows through Vault, but
the **key** never leaves.

#### Database engine

Dynamic credentials for databases (PostgreSQL, MySQL, MongoDB,
Snowflake, etc.). Properties:

- Caller asks Vault for a DB credential.
- Vault creates a new DB user with the requested permissions.
- Vault returns the credential with a TTL (15 min — 24 hr).
- After TTL, Vault deletes the DB user.

Use for: training jobs that need DB access (a per-job credential,
auto-cleaned).

#### AWS / GCP / Azure engines

Dynamic credentials for cloud IAM. Similar pattern to Database
engine — Vault assumes a role and issues short-lived STS
credentials.

Use for: workloads that need cloud IAM access but you don't want
to embed long-lived IAM credentials.

### 3.3 Vault auth methods that matter for ML systems

#### Kubernetes auth

Pods authenticate to Vault using their ServiceAccount JWT. Vault
verifies the JWT against the cluster's API, looks up the role
attached to the SA, and issues a token with the role's policies.

The setup:
1. Mount the Kubernetes auth method.
2. Configure with the cluster's API endpoint and CA.
3. Create roles binding (namespace + SA) → Vault policy.

Caveats:
- The cluster's JWT signer needs to be reachable / known by Vault.
- Token TTLs matter — short TTLs are better.
- Don't share roles across namespaces unless the policy reflects
  the broader scope.

#### JWT/OIDC auth

For CI pipelines, GitHub Actions, GitLab CI. The CI runner
authenticates with an OIDC token issued by the CI platform; Vault
verifies the OIDC signature and issues a Vault token.

This is the **keyless CI pattern** — no long-lived CI credentials
in Vault to manage.

#### AppRole

A username/password pattern for cases where the other methods
don't apply (legacy systems, scripts).

Avoid when possible. AppRole secrets ARE long-lived credentials;
they have the problems we're trying to fix.

### 3.4 Vault's operational realities

Running Vault yourself is non-trivial:

- **HA** — runs on a Raft cluster of 3 or 5 nodes.
- **Sealing** — Vault starts sealed; needs to be unsealed before
  it can serve. Auto-unseal via cloud KMS removes the manual
  step.
- **Backup** — Raft snapshots, off-cluster.
- **Disaster recovery** — Vault can be brought back from a snapshot,
  but dynamic secrets in flight are lost.
- **Upgrade cadence** — meaningful breaking changes between
  major versions. Plan upgrades.

For teams that don't want to operate Vault: **HashiCorp Cloud
Platform (HCP) Vault** is the managed option. Cloud-native
secret managers (next section) are an alternative path.

---

## 4. Cloud-native secret managers

For teams that already run on a major cloud, the cloud's native
secret manager may be a better fit than Vault.

### 4.1 AWS Secrets Manager

- KV-style secret storage with versioning.
- Built-in rotation via Lambda functions (for RDS, Redshift, and
  custom rotation).
- IAM-controlled access.
- Cost per secret + per API call.

Notable: AWS Secrets Manager does **not** have a direct
equivalent of Vault Transit. For application-layer encryption,
use AWS KMS directly.

### 4.2 GCP Secret Manager

- KV-style with versioning.
- IAM-controlled access via Cloud IAM.
- No built-in rotation (you implement via Cloud Functions).
- Audit-log integration via Cloud Audit Logs.

### 4.3 Azure Key Vault

- Combines secret storage, key storage, and certificate storage
  in one service.
- Closest to Vault in feature set among cloud-native options.
- Azure RBAC-controlled access.
- Built-in rotation for some scenarios.

### 4.4 Choosing: Vault vs. cloud-native

| Factor | Vault | Cloud-native |
|---|---|---|
| **Multi-cloud portability** | Yes | No (each cloud has its own) |
| **Dynamic database secrets** | Strong | Limited (you build the rotation) |
| **Operational cost** | High (you run it) | Low (managed) |
| **Cost at scale** | Predictable (license + infra) | Per-API-call billing can surprise |
| **Ecosystem integration** | Broad, including ESO | Tight per-cloud |
| **Audit-log integration** | Self-managed | Cloud-native, with caveats |

The honest defaults:

- **Single-cloud, small team, no FIPS requirement**: cloud-
  native is the right choice. Lower operational cost wins.
- **Multi-cloud, on-prem, or strong dynamic-secret needs**:
  Vault.
- **FIPS-validated cryptographic-module requirement**: depends.
  Both Vault Enterprise and the cloud KMS / Key Vault tiers
  have FIPS-validated options.

---

## 5. External Secrets Operator (ESO)

ESO is the Kubernetes-native pattern for bringing external
secret stores (Vault, cloud secret managers) into Kubernetes
as native `Secret` resources.

### 5.1 The pattern

1. Install ESO.
2. Configure a `SecretStore` (or `ClusterSecretStore`) pointing
   at your external store (Vault, AWS Secrets Manager, etc.).
3. Create `ExternalSecret` resources that reference the
   external secret.
4. ESO reconciles — pulls the value, creates / updates a
   Kubernetes `Secret`.

The Kubernetes `Secret` exists in the cluster, but its content
came from the external store and is refreshed on a schedule.

### 5.2 Why ESO and not direct API calls

The alternative is: each application calls Vault / AWS SM
directly. Why not just do that?

ESO advantages:
- **Decouples app from secret source.** App reads a regular
  Kubernetes Secret; underlying source can change.
- **Centralized refresh.** ESO refreshes on a schedule; app
  doesn't need a refresh loop.
- **Easier to onboard legacy apps** that expect env vars or
  mounted files.

Direct API call advantages:
- **Tighter freshness.** App pulls the latest at the moment of
  use; no caching delay.
- **No materialized Kubernetes Secret.** The secret never exists
  in the cluster's etcd encrypted-at-rest, only in app memory.

Pick based on the threat model. For most production setups, ESO
is fine; for high-stakes secrets (e.g., signing keys), direct
API call is tighter.

### 5.3 ESO security gotchas

- The `SecretStore`'s **own credentials** are themselves a
  secret. How does ESO authenticate to Vault / AWS SM?
  - Best: Kubernetes auth (Vault) or IRSA (AWS) — no embedded
    credentials.
  - Worse: a `Secret` containing the credentials. Now you have a
    chicken-and-egg problem.
- The materialized `Secret` is stored in etcd. Make sure etcd
  encryption-at-rest is enabled, with a KMS-backed key.
- ESO has cluster-wide access by default. Scope it via RBAC.

---

## 6. Dynamic secrets

The strategic move: replace static secrets with dynamic ones
issued per use.

### 6.1 What dynamic looks like

Static pattern:
1. Engineer creates a DB user, generates a password.
2. Password stored in Vault / Secrets Manager.
3. Service reads the password at startup, holds it in memory.
4. Password rotates every 90 days.

Dynamic pattern:
1. Vault is configured with a "database role" that knows how to
   create DB users with specific permissions.
2. Service requests a credential from Vault at startup (or per
   request).
3. Vault creates a new DB user, returns the credential.
4. Credential TTL = 15 minutes.
5. After 15 minutes, Vault deletes the DB user.

Properties of the dynamic pattern:
- **Compromise window is minutes**, not 90 days.
- **Auditable**: every credential issuance is logged. You can
  trace "which workload had what credential when."
- **Revocable**: revoking a Vault token revokes all dynamic
  secrets it produced.
- **No rotation work**: the next issuance is the next
  credential. There's no "rotation event."

### 6.2 Dynamic secret patterns for ML systems

For each common ML credential, the dynamic pattern:

| Credential | Dynamic source |
|---|---|
| Training data warehouse password | Vault Database engine, per-job |
| Object-store IAM credentials | Vault AWS engine, per-job |
| Internal API keys | SVID + identity-based auth (no shared key) |
| Customer-managed encryption keys | KMS-derived per-tenant, fetched per request |
| LLM provider API key | Cloud SM (rotated daily via cloud function) — static but rotated |

The pattern breaks for *external* third-party APIs (OpenAI, etc.)
because those vendors don't issue dynamic credentials. The
mitigation is: rotate frequently, scope per-purpose, monitor
usage.

---

## 7. Secret rotation

Rotation is the discipline; dynamic secrets are the goal.

### 7.1 Why rotation matters even with dynamic secrets

- Some secrets can't be dynamic (third-party API keys).
- KMS root keys are long-lived by design.
- TLS certs need rotation regardless.
- Signing keys need rotation on compromise suspicion.

### 7.2 Two flavors of rotation

#### Scheduled rotation

The credential is rotated on a fixed cadence (90 days, annually).
The team has time to test rotation, document it, and run drills.

Best practices:
- Automate the rotation; manual rotation gets skipped.
- Implement **rotation overlap** — the old credential is valid
  for a grace period after the new one is issued, to allow
  in-flight workloads to switch.
- Test rotation in staging before prod.

#### Emergency rotation

A credential is suspected compromised. Rotate immediately,
audit usage, communicate impact.

Best practices:
- Document the procedure *before* you need it. (Module 03's
  certificate runbook exercise is the template.)
- Identify what depends on the credential and how to rotate it
  without breaking those dependencies.
- Plan for the case where rotation requires downtime.

### 7.3 Rotation depends on identity binding

A credential bound to **a specific workload identity** can be
rotated without affecting other workloads. A credential **shared
across many workloads** requires coordinating the rotation
across all of them.

This is another argument for per-workload identity (Module 02):
it makes rotation locally scoped.

---

## 8. CI/CD secrets

The CI/CD pipeline needs access to: artifact registries, signing
keys, deployment credentials, possibly cloud APIs. Each is a
potential foothold for an attacker who compromises CI.

### 8.1 The keyless CI pattern

Modern CI platforms (GitHub Actions, GitLab CI, Buildkite, etc.)
issue **OIDC tokens** to each CI job. The token is a JWT that
proves "this job is running for this repo / branch / workflow."

You can use this token to authenticate to cloud / Vault / Sigstore
**without storing any long-lived credential**:

1. The CI job's OIDC token is sent to the receiver.
2. The receiver (AWS STS, Vault, Sigstore Fulcio) verifies the
   token signature against the CI platform's JWKS.
3. If the token's claims match the configured trust, the
   receiver issues a short-lived credential (STS token, Vault
   token, Sigstore cert).

The result: **no static CI credential anywhere.** A compromise of
the CI platform is contained to whatever the OIDC trust allows.

### 8.2 Setting up keyless CI to AWS

1. In AWS, configure an OIDC identity provider pointing at the
   CI platform's JWKS URL.
2. Create an IAM role with a trust policy that allows
   `sts:AssumeRoleWithWebIdentity` for the CI's OIDC subject.
3. In the CI workflow, exchange the OIDC token for STS
   credentials.

GitHub Actions has built-in support: the workflow declares
`permissions: id-token: write`, gets an OIDC token, calls AWS STS.

### 8.3 Setting up keyless CI to Vault

Vault's JWT/OIDC auth method does the same for Vault tokens.
Configure with the CI platform's JWKS URL, attach policies to
the OIDC subject claim.

### 8.4 What still needs to be a secret in CI

Even with keyless auth, some things remain static:

- **Third-party API keys** for tools that don't accept OIDC
  (most SaaS APIs).
- **Signing keys** (for things Sigstore doesn't cover).
- **Production database admin credentials** (rare, but
  sometimes).

For these, the CI platform's encrypted-variable store (GitHub
Secrets, etc.) is the right place — but rotate aggressively
and limit blast radius.

---

## 9. ML-specific secret patterns

The patterns that come up specifically in ML platforms.

### 9.1 Model artifact store credentials

The serving pod pulls a model from S3 / GCS / Azure Blob. It
needs read access to the bucket.

Best: workload identity (IRSA on AWS, Workload Identity on GCP)
maps the pod's SA to an IAM role with read access.
- No credentials in the pod.
- IAM scoped to the specific bucket prefix for the model version.
- All access logged.

Worse: an AWS access key in a Secret, mounted as env vars.
- The key is long-lived.
- The key has whatever IAM the team granted it (often too broad).
- Rotation requires coordinating across deployments.

### 9.2 Training data warehouse credentials

The training job needs to read from Snowflake / BigQuery /
Redshift / an internal warehouse.

Best: Vault Database engine. Per-job credential, 1-hour TTL,
auto-cleaned.
- Each training run has its own DB user.
- DB user is deleted when the job completes.
- Auditable per-job.

Worse: a shared "training" DB user with a static password in
Vault. Better than embedded credentials, but compromise is
broader.

### 9.3 LLM provider API keys

You're calling OpenAI / Anthropic / Cohere from your service.
Their APIs accept static API keys.

Best:
- Per-environment keys (dev / staging / prod).
- Per-team keys (recs team / fraud team can't read each other's).
- Rotated quarterly with automated reminder.
- Usage monitored — sudden spikes are alerts.
- Stored in Vault KV or cloud SM; fetched at startup or
  per-request via ESO.

Worse: a single shared key embedded in every service.

### 9.4 Customer-managed keys (CMK)

Some enterprise customers want to bring their own encryption
keys for their data. The platform encrypts customer data with a
customer-controlled key.

Patterns:
- The customer's KMS holds the key.
- Your platform calls the customer's KMS to encrypt / decrypt.
- Your platform never has the key directly.

Implementation:
- Customer-managed keys in AWS KMS (cross-account access via
  IAM).
- Customer-managed keys in GCP Cloud KMS (cross-org access via
  IAM bindings).
- For multi-cloud: Vault Transit with customer's HSM as the
  backing.

The benefit to the customer: they can rotate / revoke at any
time. The cost to you: latency per crypto op, more complex
trust model.

### 9.5 Signing keys (a special class)

Signing keys (for artifact signing, audit-log signing) are
different from other secrets:

- Compromise allows forging signatures, which is generally
  worse than compromise of an API key.
- Rotation is harder (you may need to re-sign artifacts).
- The threat model usually includes "the operator who has
  access to the key."

Best: keep signing keys in KMS / HSM with usage-only access (the
key never leaves the module). Sigstore keyless reduces the need
for long-lived signing keys entirely (Module 03).

For audit-log signing in the hash-chain pattern (Module 03 §8),
the signing key is itself bound to a workload identity — the
identity that's allowed to write to the log signs each entry.

---

## 10. Secret detection: finding what's already leaked

The work doesn't end at "set up Vault." Secrets continue to leak
into code, logs, images, model artifacts. Detection finds them.

### 10.1 Pre-commit / CI detection

Tools that scan for secrets at commit time:

- **gitleaks** — comprehensive secret-pattern scanner.
- **detect-secrets** (Yelp) — Python tool with baseline support.
- **trufflehog** — entropy + pattern detection.
- **GitHub Secret Scanning** — built-in for public repos and
  available for private repos with GitHub Advanced Security.

Install as pre-commit hooks AND CI checks. Pre-commit prevents
local commits; CI catches the cases where pre-commit was
bypassed or not run.

### 10.2 Scanning images

Container images can contain secrets:
- Embedded in code copied into the image.
- Embedded in environment variable defaults in the Dockerfile.
- In intermediate layers (build-time secrets leaked into the
  image).

Tools:
- **trivy** — image vulnerability scanner with secret detection.
- **grype** — similar.
- The same gitleaks / trufflehog can scan extracted image
  layers.

### 10.3 Scanning logs and artifacts

ML systems produce a lot of telemetry. Secrets can leak via:
- Stack traces that include configuration.
- Log lines that include request bodies.
- Model artifacts that contain training-time configuration
  (rare but possible).

Mitigations:
- Structured logging with named-field redaction (mask anything
  named `*token*`, `*key*`, `*password*`).
- A scrubber in the log pipeline that removes known patterns
  before storage.
- Spot-checks: periodically grep audit logs for secret
  patterns.

### 10.4 Scanning model artifacts

Model artifacts shouldn't contain secrets. But:
- Pickled models can contain the training-time environment.
- Some serialization formats embed strings that look like
  configuration.

Scan model artifacts the same way you scan container images. If
your training pipeline ever embeds a secret in a model, that's
a finding to fix in the training code.

---

## 11. Break-glass procedures

When a secret is confirmed leaked, you have minutes to hours
before exploitation. The procedure must be **rehearsed**.

### 11.1 The minimum playbook

1. **Confirm the leak.** Is this real? Is the secret still
   active? (Sometimes "leaked" is actually "expired and
   replaced.")
2. **Revoke the secret.** At the source. Not just the local
   reference.
3. **Rotate dependent secrets.** If the leaked secret could
   have been used to access other secrets, rotate those too.
4. **Audit usage.** What was the leaked secret used for between
   leak and revocation? This is the blast-radius question.
5. **Notify stakeholders.** Customers if their data was
   touched. Legal if regulatory implications. Engineering
   leads if the team needs to mobilize.
6. **Post-mortem.** Why did this leak? What controls would have
   caught it?
7. **Update detection.** If this leak slipped past existing
   detection, update.

### 11.2 What needs to be pre-documented

For each secret class, the runbook should answer:

- Who has authority to revoke it?
- How is it revoked (specific command / UI path)?
- What depends on it and how do those dependencies recover?
- Who needs to be notified, and how?
- What's the expected downtime, if any?

If the runbook is missing any of these, write it before the
real incident.

### 11.3 Practice with drills

Run a tabletop quarterly. Pick a hypothetical leaked secret;
walk through the procedure with the on-call team. Identify
gaps.

---

## 12. What you should be able to do after this module

- [ ] Choose between Vault and cloud-native secret managers
      for a given environment and defend the choice.
- [ ] Configure Kubernetes auth in Vault and write Vault
      policies for ML workloads.
- [ ] Identify three places where dynamic secrets would replace
      static ones in a given system.
- [ ] Set up keyless CI to AWS or to Vault using OIDC.
- [ ] Author a secret rotation runbook for both routine and
      emergency cases.
- [ ] Identify the secrets in a container image, in code, in
      logs, in model artifacts.
- [ ] Execute a break-glass procedure for a confirmed leaked
      credential.

---

## 13. What this module deliberately doesn't cover

- **Cryptographic primitive selection** — covered in Module 03.
- **TLS certificate management** — covered in Module 03.
- **Policy-as-code for secret access** — Module 09.
- **Runtime detection of secret access** — Module 08.

---

## 14. Suggested reading order

After this:

1. Read [HashiCorp's Vault tutorials](https://developer.hashicorp.com/vault/tutorials).
2. Read [ESO documentation](https://external-secrets.io/main/).
3. Configure keyless CI for a real or test project.
4. Move to **Module 06: Adversarial ML**.

---

## Appendix A — Glossary

- **AppRole**: Vault auth method using a static role-ID / secret-
  ID pair.
- **Dynamic secret**: a secret created on demand, valid for a
  bounded time.
- **ESO**: External Secrets Operator. Kubernetes operator that
  syncs external secret stores into Kubernetes Secrets.
- **IRSA**: IAM Roles for Service Accounts (AWS).
- **JWKS**: JSON Web Key Set. The endpoint a verifier hits to
  get the public keys for verifying JWTs.
- **Keyless CI**: Pattern of authenticating CI jobs via OIDC
  rather than long-lived credentials.
- **OIDC**: OpenID Connect. Identity layer on top of OAuth 2.0.
- **PKI engine**: Vault engine for certificate issuance.
- **STS**: Security Token Service (AWS). Issues short-lived
  credentials.
- **Transit engine**: Vault engine providing crypto-as-a-service.
- **TTL**: Time to live, the lifetime of a credential / token.

---

## Appendix B — Common misconceptions

| Misconception | Reality |
|---|---|
| "It's in a Kubernetes Secret, so it's safe." | Kubernetes Secrets are base64-encoded YAML stored in etcd. Without etcd encryption + tight RBAC, this is barely protection. |
| "Our secrets are in Vault, so we're done." | Vault stores secrets; what matters is who can read what. Misconfigured Vault policies are worse than no Vault (false sense of security). |
| "Rotating quarterly is enough." | A 90-day rotation means a compromise is exploitable for up to 90 days. For high-stakes secrets, that's too long. |
| "OIDC means no secrets." | OIDC tokens are still credentials — short-lived, but credentials. The infrastructure that consumes them (IAM trust policy, Vault role binding) still needs care. |
| "We can detect any secret leak with scanning." | Pre-commit scanning catches the obvious cases. Determined leaks (encoded, base64'd, in non-text formats) slip through. Detection is necessary, not sufficient. |
| "We don't need a break-glass procedure; we'll figure it out if it happens." | The first time you need it is the worst time to design it. Pre-write the procedure. |

---

*Continue to the [exercises](./exercises/) when you're ready.*
