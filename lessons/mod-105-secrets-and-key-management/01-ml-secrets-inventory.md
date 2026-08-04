# Chapter 01 — What Secrets an ML Platform Actually Holds

> **Note on AI-assisted content.** These lecture chapters were drafted
> with AI assistance and are under human review. Verify every standard
> version, tool API, and control claim against the primary source
> before quoting in production work. See
> [`resources.md`](./resources.md).

---

## Why this chapter exists

Mod-102 built a threat model. Mod-103 stood up zero-trust primitives
and admission gates. Mod-104 authored signed provenance for datasets,
features, and model artifacts. Every one of those controls is
underwritten by **secret material** — signing keys, workload
credentials, cloud tokens, decryption keys — that must exist
somewhere, must be rotated, and must never leak.

The specific failure mode this chapter is written to prevent:

> An SRE runs a git-secrets scan across the ML org's mono-repo out of
> curiosity and finds seventeen distinct API keys and cloud
> credentials committed at various points in the last two years —
> some rotated, some still live. A separate scan of the notebooks
> directory finds another forty-two. A Slack search turns up more.
> No one on the security team can produce a list of "the secrets
> the ML platform uses" because no such list exists. When leadership
> asks "what's our exposure if the CI system is compromised
> tomorrow", the honest answer is *we don't know what's in it*.

You cannot manage what you have not enumerated. This chapter is the
enumeration. Chapters 02–05 turn the inventory into managed
lifecycles.

You leave this chapter able to:

- Enumerate the seven ML-specific secret classes (plus the four
  generic-infra classes ML platforms inherit) and, for each, name
  the primary owner, storage store, rotation frequency, and blast
  radius on leak.
- Distinguish **secrets** (credentials that grant access) from
  **key material** (cryptographic keys that perform an operation)
  and understand why the two classes have different rotation and
  custody models.
- Distinguish **short-lived** from **long-lived** credentials and
  articulate why every long-lived credential is a chapter-05
  incident waiting to happen.
- Produce a per-secret **classification** — sensitivity tier,
  environment, tenant scope — that chapters 02 and 03 use to place
  the secret in the right store with the right key.

---

## Secrets vs keys — a distinction that matters

Common usage collapses "secrets" and "keys" into one bucket. For
platform design they behave differently:

- A **secret** is a credential — a bearer token, a database
  username/password, a cloud access key, an API key. The holder
  presents it to a service; the service authenticates them; the
  service grants access. Secrets are usually opaque to the platform
  that stores them.
- A **key** is cryptographic material — a signing key, an AEAD
  encryption key, a KMS-wrapped data key, an RSA private key
  used for TLS. The holder does not present it; the holder uses
  it to perform an operation (sign, decrypt, negotiate).

The two classes diverge on custody:

| Property | Secret | Key |
| --- | --- | --- |
| Best-case storage | Vault / Secrets Manager retrieved just-in-time by workload | HSM / KMS; key never leaves the boundary; workload gets an operation, not the material |
| Rotation trigger | Time-based + on leak | Time-based + on cryptoperiod expiry (NIST SP 800-57 Part 1 has cryptoperiod guidance per key type) |
| "Zero trust" ideal | Short-lived, dynamically issued per workload identity | Never-touched key, operations invoked via signed workload identity |
| What "compromise" means | Credential known to attacker → revoke and reissue | Key known to attacker → revoke; re-sign / re-encrypt everything the key protected |

The design implication: **prefer keys that live in an HSM/KMS the
workload never sees, and prefer credentials that are dynamically
issued per session rather than provisioned as static strings**.
Chapters 02 (Vault dynamic secrets) and 03 (envelope encryption
with cloud KMS) install both.

---

## The eleven secret classes on an ML platform

Below is the working inventory. The first seven are ML-specific;
the remaining four are the generic-infra classes any platform
inherits. For each: what it is, who typically owns it, where it
tends to live today (often badly), and what a leak actually costs.

### 1. Training-data-store credentials

Credentials that let a training job read the raw dataset — a
data-warehouse connection string (Snowflake, BigQuery, Redshift),
an S3 access key with `s3:GetObject` on the training bucket, a
JDBC connection to a Postgres feature source, a Kafka SASL
credential for streaming data.

- **Primary owner.** Platform / data engineering.
- **Where it lives (bad).** Kubeflow pipeline component env vars
  set from a Kubernetes `Secret` referenced in the pipeline YAML;
  a Notebook cell containing `os.environ["SNOWFLAKE_PASSWORD"] =
  "…"`.
- **Where it should live.** Vault database secrets engine
  issuing short-lived DB credentials scoped to the training-run
  identity (chapter 02); or a cloud IAM role assumed via
  workload-identity federation (chapter 04).
- **Blast radius on leak.** Read of the entire training corpus,
  including any PII / PHI, including any competitor data if the
  same warehouse mixes tenants.

### 2. Feature-store credentials

Credentials that let a training job or an online inference service
read materialised features — Redis / KeyDB creds for the online
store, S3 / GCS creds for the offline store, Feast registry DB
creds, Tecton API tokens.

- **Primary owner.** Platform / ML infra.
- **Where it lives (bad).** Baked into a Feast client-config
  file, checked into git; a long-lived Redis password in a
  ConfigMap.
- **Where it should live.** Dynamic Vault credentials for the
  offline store; workload-identity for the online store; the
  registry API auth uses OIDC (chapter 04).
- **Blast radius on leak.** Read of every feature every model
  in the org consumes, including derived PII (e.g. embeddings
  of customer text — often re-identifiable per mod-108). Write
  access, if granted, means an attacker can **poison every
  online prediction** by modifying feature values.

### 3. Model-registry credentials

Credentials for the model registry — MLflow tracking-server API
token, SageMaker Model Registry IAM, Azure ML workspace SP creds,
OCI registry credentials for signed model artifacts.

- **Primary owner.** Platform.
- **Where it lives (bad).** A long-lived `MLFLOW_TRACKING_TOKEN`
  in every training job's environment; an OCI registry
  username/password in a Kubernetes `imagePullSecret` shared
  across every namespace.
- **Where it should live.** OIDC-federated cloud IAM (chapter
  04); short-lived Fulcio-issued Sigstore certificate for signing
  (mod-104 chapter 02); Vault-issued token for MLflow.
- **Blast radius on leak.** Write access means an attacker can
  register a backdoored model version with a legitimate name and
  the mod-103 admission gate will accept it — unless signing +
  provenance are enforced (they should be — chapter 04 makes the
  signing keyless so this class largely evaporates).

### 4. External-API keys (third-party model providers, SaaS)

Credentials for third-party services the ML system calls at
training or inference — OpenAI API key, Anthropic API key,
Cohere / Hugging Face Inference API tokens, embeddings-provider
keys, SaaS enrichment services (Twilio, SendGrid, geocoders),
data-provider APIs.

- **Primary owner.** Application team owning the calling code;
  platform provides the secret-store integration.
- **Where it lives (bad).** In a `.env` file mounted into every
  inference pod; in a config map; in a langchain notebook cell.
- **Where it should live.** Vault KV v2 (or the cloud secrets
  manager) with per-workload read policies; issued as short-lived
  tokens where the provider supports OIDC (few do today —
  Anthropic added OIDC-style workload identity via cloud-provider
  managed credentials for some deployments; verify against
  provider docs).
  <!-- needs-research: catalogue which model-provider APIs
  support OIDC / workload identity federation as of the current
  quarter — providers add and remove these features frequently. -->
- **Blast radius on leak.** Direct cost (attacker runs the
  provider bill up), reputational (attacker uses your account to
  generate abusive content that the provider ties back to your
  org), and — often overlooked — **prompt-and-output disclosure**
  if the attacker can enumerate your account's request history
  through provider dashboards. Some providers do not log
  request bodies; some do.

### 5. Model-artifact signing keys

The key material used to sign model artifacts (mod-104 chapter
02) — a cosign private key in the "keyed" mode, or (better) the
Fulcio-issued short-lived certificate in the "keyless" mode.
Related: the SLSA / in-toto attestation signing key.

- **Primary owner.** Platform security (custody), CI (invocation).
- **Where it lives (bad).** `COSIGN_KEY` in a Kubernetes secret
  used by every CI runner; a `sigstore.key` file in a shared
  Vault KV path readable by every developer.
- **Where it should live.** In the ideal world, **it does not
  exist as a long-lived object** — chapter 04 wires keyless
  signing so the signing certificate is issued per-CI-run to
  the workload's OIDC identity and expires in minutes. If a
  long-lived key is unavoidable, it lives in an HSM / KMS the
  workload calls to *perform* the signing, never *retrieves*
  the key.
- **Blast radius on leak.** An attacker with the signing key
  can produce a signature the admission gate accepts. Every
  model deployed after the leak is untrustworthy until the key
  is revoked, the compromise window is reconstructed, and
  every artifact signed in the window is either re-signed with
  a rotated identity or blocklisted at the admission gate.
  This is a full **provenance chain break** — the most
  expensive class of leak in this list.

### 6. Judge-model credentials

The credentials used by **evaluation harnesses** to call
"judge" LLMs that grade production model outputs — an offline
eval that scores generation quality with an external Anthropic
call, a LLM-as-judge safety check that gates a rollout, an
online-eval that samples 1% of traffic through a stronger
model for QA.

- **Primary owner.** ML eval team; platform provides the
  secret binding.
- **Where it lives (bad).** Same as class 4 (external-API keys),
  often *without* the calling team realising the judge model
  path is on the critical rollout path.
- **Where it should live.** Same as class 4, but with an
  additional flag: **judge-model credentials should be a
  separate secret from application-inference credentials to the
  same provider** — different rate limits, different rotation
  cadence, different blast radius. Do not share.
- **Blast radius on leak.** As class 4, plus: if the judge is
  on the deployment gate, an attacker can drain the judge's
  quota (denial-of-eval) and either block deploys or, if the
  fallback is "pass on eval error", let bad models through.

### 7. PII / PHI decryption keys

The KMS keys that unwrap data-encryption keys (DEKs) for
sensitive training data — a KMS CMK used to envelope-encrypt
customer records at ingest; a KMS key used for
field-level-encryption of the PHI columns of a training set; a
KMS key used to unwrap a per-row DEK for privacy-preserving
inference.

- **Primary owner.** Data protection / privacy (custody);
  data engineering (invocation).
- **Where it lives (bad).** A single cloud KMS key with
  `Encrypt`/`Decrypt` granted to a broad IAM role every training
  pipeline assumes; no per-environment or per-tenant separation.
- **Where it should live.** Chapter 03's envelope-encryption
  design — a hierarchy of keys per environment / per tenant / per
  sensitivity tier, invoked via workload-identity, never
  extracted from KMS.
- **Blast radius on leak.** If the material key is exfiltrated,
  every dataset it protected is exposed for the lifetime of
  those ciphertexts (which may be **years**, in a compliance
  archive). The re-encrypt cost for a large corpus is significant
  and disruptive. This is why chapter 03 pushes hard on **key
  hierarchies** — a compromised leaf key blows up one
  compartment, not the corpus.

### 8. Cluster credentials — kubeconfig, service-account tokens

Generic-infra: kubeconfig files with cluster-admin, long-lived
service-account tokens embedded in developer laptops, dashboard
credentials.

- **Primary owner.** Platform / SRE.
- **Where it should live.** Short-lived OIDC-federated
  kubeconfigs issued per developer session; workload service
  accounts use bound-token projection (Kubernetes ≥ 1.22 default
  behaviour), never long-lived static tokens.

### 9. CI / CD credentials

The credentials CI systems use to push artifacts, deploy, and
run infrastructure changes — cloud-provider access keys stored
in GitHub Actions secrets or Jenkins credential stores.

- **Where it should live.** Nowhere long-lived; chapter 04 is
  the answer — OIDC federation from CI to cloud IAM so no
  long-lived credential exists.

### 10. Application-secret grab-bag

Non-ML-specific integrations the ML platform is bolted onto —
Slack incoming-webhooks, PagerDuty routing keys, Datadog API
keys, on-call systems, ticketing.

- **Where it should live.** Same store, same lifecycle, as class
  1–7; no special treatment. Do not let "these are not
  sensitive" get them exempted from Vault — they are still bearer
  tokens and still on the leak-response runbook (chapter 05).

### 11. Break-glass credentials

Emergency-only credentials for when the automated identity system
is down — a break-glass root account, a stored MFA seed, a
paper-only credential in a physical safe.

- **Where it should live.** Physical safe, sealed envelope,
  two-person integrity, quarterly rehearsal. Never in Vault
  (because Vault-down is exactly when you need it). Every
  break-glass use is a chapter-05 incident regardless of whether
  a leak occurred; the rehearsal cadence catches expired
  credentials before an incident does.

---

## The inventory table — the artefact you produce

For any real ML platform, produce the following table (exercise
01) and treat it as a living document. Every column is required.

| Secret ID | Class (1–11) | Description | Primary owner | Current store | Ideal store | Long-lived? | Rotation cadence | Sensitivity tier | Environment scope | Tenant scope | Blast radius on leak | Leak-response owner |

Notes on the columns:

- **Sensitivity tier.** A 3-tier scheme (`public`, `restricted`,
  `confidential`) is enough for most orgs; regulated orgs will
  need more (e.g. HIPAA `PHI` as a distinct tier). Match the
  data-classification scheme from mod-108. Never invent a scheme
  that conflicts with the org's existing one.
- **Environment scope.** `prod-only`, `staging-only`,
  `dev-only`, or `shared` (rarely acceptable — flag as a gap).
  Cross-environment secrets are the source of most
  "prod-compromised-via-dev" incidents.
- **Tenant scope.** `single-tenant`, `per-tenant`, `shared`.
  For multi-tenant ML platforms (each customer is a tenant), a
  shared secret defeats tenant isolation from mod-103.
- **Blast radius on leak.** One sentence — what happens between
  the leak and the completion of the chapter-05 runbook. Forces
  clear thinking; drives the classification of secrets that
  actually matter.
- **Leak-response owner.** The named team or on-call rotation
  that owns the chapter-05 runbook for this secret.

Every row that shows `Long-lived = YES` is a work item for
chapter 02 or chapter 04. Every row that shows `Current store =
Kubernetes Secret` (with no external secrets integration) is a
work item — Kubernetes `Secret` objects are base64-encoded,
readable by any pod / service-account granted the `get secrets`
verb, and are not audit-logged at the value level.

---

## What "short-lived" actually means

The phrase "short-lived credential" gets thrown around; make it
concrete. A useful ladder, from worst to best:

| Lifetime | Example | Verdict |
| --- | --- | --- |
| Indefinite (never rotated) | Cloud access key committed to git in 2019, still valid | Emergency remediation — chapter 05 |
| 90–365 days (calendar-rotated) | Manually-rotated API keys | Meets the letter of most compliance checklists; misses the spirit — a 90-day window is 90 days of exposure |
| 24 hours | A DB credential issued at start of shift | Acceptable for interactive human use; too long for workloads |
| 1 hour | A cloud STS session token, a Vault-issued short-lived token | Good for workload use |
| 15 minutes or less | OIDC-issued CI cloud-token from chapter 04; Fulcio-issued signing cert | Best — the target for CI and pipeline workloads |
| Per-request | An AWS Signature v4 signed request; a Vault response-wrapped token | Best — nothing to leak because nothing persists |

The rule for the inventory: for every long-lived credential,
identify a technical path to a short-lived replacement, or
document *why* the replacement is not currently possible (usually
a third-party provider that does not support OIDC — a real
constraint, not an excuse). The gap becomes exercise 02 or 04's
work.

---

## What "classification" gives you

The classification columns above are not decorative. Chapters 02
and 03 use them to route secrets to the correct store:

- **Sensitivity tier** decides which KMS key wraps the secret
  at rest, which audit stream is subscribed, and whether
  break-glass access requires two-person integrity.
- **Environment scope** decides which Vault namespace / mount
  the secret is stored in, and enforces the no-cross-env rule
  at the RBAC layer. A `prod` secret readable by a `dev`
  workload is a policy failure and should be treated as
  chapter-05 gray-zone leak (potentially exposed even if not
  yet used).
- **Tenant scope** decides whether the secret material is
  per-tenant (each customer's key wraps their data — the
  chapter-03 hierarchy) or shared, and how the leak-blast-radius
  is scoped.

Get the classification wrong at inventory time and every
downstream decision inherits the mistake.

---

## The mistakes this chapter is trying to prevent

- **Treating "we have Vault" as an inventory.** Vault is a
  store, not an inventory. If you cannot enumerate what is *in*
  Vault, what is *not* in Vault, and what *should* be in Vault
  but is somewhere else, you do not have an inventory. The
  inventory drives Vault; Vault does not drive the inventory.
- **Conflating secrets and keys.** A model-artifact signing key
  needs different custody (HSM/KMS, never extracted) than an
  external-API bearer token (Vault, dynamically issued). Put
  them in the same bucket and you either over-invest in secret
  storage or under-invest in key protection.
- **Treating notebooks as out of scope.** Jupyter notebooks
  are executable code with plaintext cells and get checked into
  git alongside production pipeline code. They are the top
  source of ML secret leaks in every real inventory. Include
  notebooks in the scan and in the inventory.
- **Missing the ML-specific classes.** A generic infrastructure
  inventory catches classes 8–11 and stops. Judge-model creds
  (class 6) and model-signing keys (class 5) are ML-specific and
  regularly missed on the first pass.
- **Skipping the classification columns.** An inventory without
  sensitivity / environment / tenant scoping cannot drive
  chapters 02 and 03; it is a spreadsheet that makes the
  organisation feel prepared without being prepared.
- **Not naming a leak-response owner.** A secret with no
  named owner has no chapter-05 runbook, and in practice will
  not be rotated when the leak occurs. Every row has an owner
  or it is not in the inventory.

---

## Summary

- ML platforms hold seven ML-specific secret classes (training
  data creds, feature-store creds, model-registry creds,
  external-API keys, model-signing keys, judge-model creds,
  PII/PHI decryption keys) plus the four generic-infra classes
  every platform inherits.
- Secrets (credentials) and keys (cryptographic material) have
  different custody models — secrets favour dynamic issuance
  from a store; keys favour never-extracted use inside a KMS/HSM.
- Every row of the inventory carries a classification —
  sensitivity, environment, tenant scope — that chapters 02
  (Vault) and 03 (envelope encryption with KMS) use to place
  the secret in the right store with the right key.
- Every long-lived credential is a chapter-05 incident waiting
  to happen; every OIDC-federated short-lived credential
  (chapter 04) is one less thing to rotate.
- The inventory is not a one-time deliverable — it is the
  input to every other control in this module and must be
  re-run whenever a new integration lands.
