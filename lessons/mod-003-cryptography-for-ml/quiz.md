# Module 03 Quiz — Cryptography for ML

> Closed-book first. Open-book to fill gaps after.

---

## Conceptual (10 questions)

### Q1
For each scenario, name the most appropriate encryption-at-rest
approach (storage-layer, envelope, or application-layer) and
explain in one sentence:
- (a) A 10 GB model artifact in S3.
- (b) A 1 KB row in a feature store containing user PII.
- (c) The complete training-data warehouse (PB-scale).
- (d) An audit log in PostgreSQL.

### Q2
Why is storing a KMS-encrypted KEK in a Kubernetes `Secret`
resource (rather than using the KMS API at runtime) considered a
mistake, even though the KEK is encrypted in the Secret?

### Q3
List three things mTLS does **not** protect against, despite
being correctly configured. For each, name the layer of defense
that does protect against it.

### Q4
Describe the difference between **SPIRE-issued SVIDs** and
**cert-manager-issued certs**. For each, give one scenario where
it's the right choice over the other.

### Q5
A team proposes "let's just use self-signed certs internally,
they're easier." Respond in 4–6 sentences. Be specific about
what breaks.

### Q6
For a hash-chain audit log, explain in 3–4 sentences why
**anchoring** (publishing periodic hashes to an external
service) is necessary. What threat does the unanchored hash
chain leave open?

### Q7
The lecture notes argue that "for most production ML, don't use
homomorphic encryption" (§9.3). Defend or refute this position
in 4–6 sentences. If you defend it, name one scenario where HE
*is* the right tool; if you refute, explain why HE is more
practical than the lecture suggests.

### Q8
Cosign keyless signing depends on:
- (a) Fulcio (the CA).
- (b) Rekor (the transparency log).
- (c) An OIDC identity provider.

For each, describe what happens if it's unavailable when a
signer tries to sign, and what happens if it's unavailable when
a verifier tries to verify.

### Q9
Name 4 of the 8 common cryptographic mistakes from §10. For
each, give a 2-sentence corrective recommendation.

### Q10
"Encrypting in use" (confidential computing) addresses a
specific threat. Describe the threat in your own words. For an
ML platform that doesn't have a regulatory mandate, give one
argument *for* using it and one argument *against*.

---

## Applied (5 questions)

### Q11
Design a **key-management plan** for SmartRecs that separates
keys by purpose (per §5.4). Specify:
- The KEK hierarchy.
- Which workloads have access to which keys.
- Rotation cadence per key.
- The IAM model used to grant access.

Draft as a structured table; keep under 1 page.

### Q12
You inherit a serving deployment whose mTLS configuration is:
- TLS 1.0 enabled.
- Certificate verification disabled in the Python client
  (`verify=False`).
- The Helm chart contains a 90-day cert as a Kubernetes Secret,
  shared across all 12 serving services.

Write the 5–7 highest-priority fixes, in order. For each, name
the specific change and the threat it closes.

### Q13
Draft a Cosign-based admission policy (pseudo-Kyverno is fine)
that:
- Allows pulling images only if signed by a cosign keyless
  signature.
- Requires the OIDC subject to match
  `https://github.com/smartrecs-org/*` (i.e., the org's GitHub
  Actions identity).
- Requires the signature to be recorded in Rekor.
- Rejects any image without all three.

### Q14
A new requirement: customers want to submit prompts to an LLM
without the platform operator seeing plaintext prompts. The
latency budget is 5 seconds end-to-end. Which option do you
choose?
- (a) Homomorphic encryption.
- (b) Confidential computing (AMD SEV-SNP VMs).
- (c) Application-layer encryption with a customer-managed key,
      decrypted only inside the model service.
- (d) None of the above; the requirement is incompatible with
      acceptable latency.

Defend your choice in 6–10 sentences. If you pick (d), explain
which constraints would have to relax to make any option
viable.

### Q15
The team has 24 model artifacts in production. None are signed.
Promotion to production today is a `kubectl apply` by a
platform engineer. Propose a phased plan to introduce signing
and admission verification *without* a production outage. Aim
for 3 phases; for each, name the deliverable, the rollback
plan, and the duration estimate.

---

## Self-assessment rubric

Same as Modules 01–02. Passing: average ≥ 2.0, no question
scored 0.
