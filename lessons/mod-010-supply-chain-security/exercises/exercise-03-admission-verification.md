# Exercise 03 — Admission Verification Configuration

**Estimated time**: 2 hours
**Deliverable**: Kyverno / Gatekeeper policy + a verification test

---

## The assignment

Write the admission-time verification policy that ties Exercise
02 together. The policy must verify:

1. The container image has a Cosign signature.
2. The signing OIDC subject matches the expected CI workflow.
3. A SLSA Provenance attestation is attached.
4. The provenance's `buildDefinition.buildType` and source
   identity match expected values.
5. A CycloneDX SBOM attestation is attached.
6. A vulnerability scan attestation reports zero Critical CVEs.
7. (For ModelDeployment CRDs) the model artifact has a
   signature, training provenance, validation attestation, and
   approval attestation.

## The format

You can use Kyverno YAML or Gatekeeper Rego. Pick one, do it
properly. Pseudo-syntax is acceptable if you flag it.

### Required: the policy(ies)

For Kyverno, this likely splits into multiple `ClusterPolicy`
resources. For Gatekeeper, multiple `ConstraintTemplate` +
`Constraint` pairs.

### Required: the constraint values

- Expected OIDC subject (e.g.,
  `https://github.com/smartrecs-org/recs/.github/workflows/build.yml@refs/heads/main`).
- Expected Fulcio root (Sigstore production).
- The set of CVE severities that block (e.g., `["Critical"]`).
- The set of expected attestation predicate types.

### Required: a verification test

Provide examples:

- An image that **should pass** all checks (with the
  attestations that satisfy each).
- An image that **fails on signature** (no signature).
- An image that **fails on subject** (signed by an
  unexpected workflow).
- An image that **fails on SBOM** (no SBOM attestation).
- An image that **fails on vulnerability scan** (Critical
  CVE).
- A model deployment that **fails on missing approval
  attestation**.

For each failure case, the expected admission rejection
message.

## Format

```
# Admission Verification: SmartRecs

## Approach (Kyverno or Gatekeeper, and why)

## Policy: image-signing
```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: verify-image-signatures
spec:
  validationFailureAction: Enforce
  rules:
    - name: check-signature
      match:
        resources:
          kinds:
            - Pod
      verifyImages:
        - imageReferences:
            - "ghcr.io/smartrecs-org/*"
          attestors:
            - entries:
                - keyless:
                    subject: "https://github.com/smartrecs-org/*/.github/workflows/build.yml@refs/heads/main"
                    issuer: "https://token.actions.githubusercontent.com"
```

## Policy: provenance + SBOM verification
...

## Policy: model-deployment attestation chain
...

## Verification tests

### Test 1: Pass case
- Image: `ghcr.io/smartrecs-org/recs:v1.2.3` (signed by main
  build, with all attestations)
- Expected: admission allowed

### Test 2: Missing signature
- Image: `ghcr.io/smartrecs-org/recs:v1.2.3-unsigned`
- Expected: admission rejected with "image not signed"

### Test 3: Wrong subject
- Image signed by `feature/oops` branch
- Expected: rejected with "signature does not match expected
  workflow"

...

## Failure handling
(Webhook timeout, signature service unavailable, Rekor
unreachable.)

## Operational concerns
- Latency: how long does admission verification take?
- Caching: are verifications cached per image digest?
- Audit log: what's recorded for each verification decision?
```

## Quality criteria

A passing configuration:

- Uses **real Kyverno or Gatekeeper syntax** (even if some
  fields are placeholders).
- Verifies **all required claims** — signature, subject,
  provenance, SBOM, vulnerability scan, model attestations.
- Verification tests cover happy + multiple failure paths.
- Failure handling is documented.

A failing configuration:

- Single rule that only checks "is signed."
- Doesn't check the signing subject — anyone with a Sigstore
  identity could deploy.
- No tests.
- Treats webhook timeout as "fail open."

## Reflection questions

1. Should webhook failure be `failOpen` or `failClosed`?
   Defend.
2. The team objects: "These policies will reject during a
   Sigstore outage; we'll have an outage." What's the
   mitigation?
3. A new SmartRecs repo joins the org and needs to deploy
   images. What changes in the policy?
