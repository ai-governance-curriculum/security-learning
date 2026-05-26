# Module 05 Quiz — Secrets Management

> Closed-book first.

---

## Conceptual (10 questions)

### Q1
Name the three classes of secrets from §2 and one example each.
For each, explain in one sentence why it requires different
handling than the others.

### Q2
The lecture argues "move secrets from static long-lived toward
dynamic short-lived or workload-identity-derived" (§2). Give one
example each of:
- (a) A secret you can convert to dynamic.
- (b) A secret you can replace with workload identity entirely.
- (c) A secret that must stay static. Explain why.

### Q3
For each Vault engine below, name one ML-workload-specific use
case:
- KV-v2.
- PKI.
- Transit.
- Database.
- AWS (or your cloud's equivalent).

### Q4
A team uses Vault AppRole for all their workloads. Identify
three weaknesses of this choice and recommend a specific
migration target for each.

### Q5
ESO syncs external secrets into Kubernetes Secret resources.
Describe a threat model where this is **better** than apps
calling Vault directly, and a threat model where it's **worse**.

### Q6
Compare Vault and AWS Secrets Manager for SmartRecs. Which would
you pick given:
- SmartRecs is single-cloud (AWS).
- Team of 6 engineers.
- Needs dynamic database credentials.
- Plans to add a second region in 12 months.

Defend the choice in 6-10 sentences.

### Q7
Explain the **keyless CI pattern** (§8.1) in your own words.
Then describe a CI pipeline that *can't* be keyless — what kind
of secret keeps it static, and what mitigations apply?

### Q8
For each of the following secrets, identify the **best storage
pattern** and the **rotation cadence**:
- (a) Internal mTLS cert for service-to-service.
- (b) OpenAI API key.
- (c) Database password for the training warehouse.
- (d) Cosign signing identity.
- (e) Customer-managed encryption key.

### Q9
Pre-commit secret scanning catches the obvious cases but not all
leaks. Name three patterns that slip past gitleaks-style
scanning, and what additional control catches each.

### Q10
A break-glass procedure has minimum components (§11.1). Which
single component is most often missing from real-world runbooks?
Why?

---

## Applied (5 questions)

### Q11
Walk through the Vault setup needed for a training job in the
`recs-train` namespace to read training data from a PostgreSQL
warehouse:
- (a) The Vault Database engine config (engine, connection,
  role).
- (b) The Kubernetes auth role binding (namespace, SA, Vault
  policy).
- (c) The Vault policy granting access.
- (d) How the training job code obtains the credential.
- (e) What happens if the job exceeds the credential TTL
  mid-run.

### Q12
Audit the following secret-handling code path (the team's
proposed design) and produce a finding list:

```yaml
# A Kubernetes Secret in namespace recs:
apiVersion: v1
kind: Secret
metadata:
  name: ml-credentials
  namespace: recs
type: Opaque
data:
  # Base64-encoded values:
  OPENAI_API_KEY: c2stcHJvai14eHh4eHh4eHh4
  AWS_ACCESS_KEY_ID: QUtJQTNDRVhBTVBMRQ==
  AWS_SECRET_ACCESS_KEY: ...
  DATABASE_URL: cG9zdGdyZXM6Ly9hZG1pbjpmb29iYXJAd2FyZWhvdXNlOjU0MzIvbWw=
  COSIGN_PRIVATE_KEY: ...
  TENANT_ENCRYPTION_KEY: ...
```

Identify at least 5 findings. For each, name the threat and the
specific replacement pattern.

### Q13
Design a **secret rotation playbook** for the SmartRecs OpenAI
API key:
- Routine rotation: who, when, how, with no downtime.
- Emergency rotation (key leaked): the rapid procedure.
- Detection: how would you discover the key had leaked in the
  first place?

Keep under 1 page.

### Q14
Your CI pipeline currently uses a static `AWS_ACCESS_KEY_ID`
stored in GitHub Secrets to deploy to AWS. Migrate to keyless
CI:
- (a) The IAM trust policy required.
- (b) The GitHub Actions workflow changes.
- (c) What `permissions:` block is needed in the workflow.
- (d) The rollback if keyless auth fails in production.

### Q15
A signing key (used by your CI to sign model artifacts via
cosign) has been confirmed exposed in a public GitHub repo.
Execute the break-glass procedure in writing:
- Step-by-step, with specific commands or named systems.
- Include the audit-of-usage step (what was signed with this
  key between leak and revocation?).
- Include the post-mortem outline.
- Include the customer / stakeholder notification plan.

---

## Self-assessment rubric

Same as previous modules. Passing: average ≥ 2.0, no zero.
