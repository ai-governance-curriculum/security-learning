# Chapter 06 — Admission-Time Policy-as-Code: Gating Model Deployments on Security Evidence

> **Note on AI-assisted content.** Verify OPA and Gatekeeper syntax
> against the current OPA / Gatekeeper docs (Rego version, constraint
> template API version, provider CRDs). Sigstore / cosign verification
> APIs change between minor versions. Verify SLSA v1.0 predicate
> field names against the current SLSA spec. See
> [`resources.md`](./resources.md).

---

## Why this chapter exists

Chapters 03–05 built up the runtime substrate: attested identity,
segmented planes, hardened cluster. This chapter installs the
**last gate before a model artifact is allowed to run** — the
admission-time policy check that answers "does this deployment
carry the required security evidence?"

The specific failure mode this chapter is written to prevent:

> An attacker with write access to the model registry (via
> compromised CI credentials, insider access, or a supply-chain
> compromise upstream) pushes a backdoored model artifact into
> the `production` tag of an existing model. The next scheduled
> rollout of the serving pod pulls the new digest, starts, and
> begins serving. Because the platform trusted the registry
> tag ("if it's in the registry, CI already signed it"), no
> admission-time check re-verified the signature at deployment.
> The compromise sits undetected until an ATLAS-tagged incident
> lands weeks later.

The refusal is authored as **policy-as-code** and enforced by an
admission webhook. This chapter uses **OPA Gatekeeper** as the
concrete example. The pattern is portable to Kyverno, jsPolicy,
or a bespoke `ValidatingAdmissionWebhook`; Gatekeeper is the
reference because it is upstream-CNCF and its constraint-template
model expresses the four gates cleanly.

The four evidence gates this chapter authors:

1. **Signed artifact** — cosign signature verified against a
   pinned trust root.
2. **ML-BOM present** — CycloneDX ML-BOM attached to the artifact,
   at required completeness.
3. **Scan clean** — artifact scanner result within the freshness
   window, no unmitigated high-severity findings.
4. **Provenance verified** — SLSA v1.0 in-toto provenance
   attestation from an allow-listed builder.

Any deployment missing evidence for any of the four is rejected at
admission and never reaches the pod scheduler.

---

## What "admission time" means

Kubernetes admission runs in a chain when any resource is
created / updated. The chain has three phases:

1. **Mutating admission** — mutating webhooks that modify the
   incoming object (e.g., sidecar injection).
2. **Object schema validation** — the API server validates the
   object against its schema.
3. **Validating admission** — validating webhooks that either
   admit or reject the object. Gatekeeper runs here.

Gatekeeper hooks into every create / update by default. A
`Constraint` that matches a resource triggers evaluation of its
associated `ConstraintTemplate` — a Rego policy that returns a
list of violations. Non-empty violations → the request is
rejected with an audit trail.

Two additional Gatekeeper concepts:

- **Audit mode.** Constraints can be enforced (`deny`) or
  audit-only (`dryrun`). Roll out `dryrun → deny` in the same way
  chapter 05 rolled out PSA.
- **External data providers.** Gatekeeper 3.9+ supports
  `Provider` CRDs that fetch external evidence (signatures,
  attestations, ML-BOMs, scan results) synchronously at admission
  time. This is how the four gates below reach outside the
  cluster.

---

## Gate 1 — Signed artifact (cosign)

Sigstore's `cosign` signs OCI artifacts by digest. The signature
is stored either alongside the artifact in the same OCI registry
(the `sigstore` tag convention) or in the Rekor transparency log
(keyless mode).

### The verification the gate performs

For every incoming Deployment (or KServe `InferenceService`, or
Seldon `SeldonDeployment` — pick your CRD), for every container
image:

1. Resolve the image reference to a digest. If the reference is a
   tag, resolve it via the registry.
2. Fetch the cosign signature for `sha256:<digest>` — from the
   registry-attached `.sig` tag or from Rekor.
3. Verify the signature against a pinned public key or a
   Fulcio-issued certificate whose subject matches the allow-list
   (e.g., `subject-regexp: "spiffe://td.acme.internal/plane/ci/component/cosign-signer"`).
4. If verification fails or no signature is present, deny.

### Constraint template (Rego, simplified)

```yaml
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: k8srequirecosignsignature
spec:
  crd:
    spec:
      names:
        kind: K8sRequireCosignSignature
      validation:
        openAPIV3Schema:
          type: object
          properties:
            trustRoot:
              type: string
            allowedIdentities:
              type: array
              items: { type: string }
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package k8srequirecosignsignature

        violation[{"msg": msg}] {
          container := input.review.object.spec.template.spec.containers[_]
          not signature_verified(container.image, input.parameters)
          msg := sprintf("image %v has no cosign signature verifiable against trust root %v", [container.image, input.parameters.trustRoot])
        }

        signature_verified(image, params) {
          # External data call to a Provider that runs cosign verify
          resp := external_data({
            "provider": "cosign-verifier",
            "keys": [image],
            "parameters": params
          })
          resp.responses[_][1] == "verified"
        }
```

The corresponding `Provider` is the Gatekeeper external-data
plugin that speaks to a Sigstore verification service (or a
sidecar running cosign). Deploy the plugin as its own Deployment
in `platform-system`, with its own SPIFFE ID and its own
NetworkPolicy allowing only mesh-authenticated Gatekeeper.

### The constraint

```yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequireCosignSignature
metadata:
  name: serving-images-must-be-signed
spec:
  enforcementAction: deny
  match:
    kinds:
      - apiGroups: ["apps"]
        kinds: ["Deployment"]
      - apiGroups: ["serving.kserve.io"]
        kinds: ["InferenceService"]
    namespaces: [serving]
  parameters:
    trustRoot: "https://tuf-root.acme.internal/root.json"
    allowedIdentities:
      - "spiffe://td.acme.internal/plane/ci/component/cosign-signer"
      - "spiffe://td.acme.internal/plane/registry/component/promoter"
```

`enforcementAction: deny` is production-mode. Start with `dryrun`
in a staging cluster; graduate.

### Failure modes to prevent

- **Tag not resolved to digest before verification.** An attacker
  can swap the tag between "resolve" and "verify" if verification
  is against the tag. Always resolve to digest and pin the
  Deployment to the digest, or resolve at admission and pin the
  mutated Deployment to the resolved digest.
- **Verification against a key held in-cluster with wide access.**
  The verifier's trust root is mod-105 territory; the constraint
  references *what* to verify against, not *how the key is
  stored*.
- **Empty allow-list.** A signature verified against "any Fulcio
  identity" is nearly no verification. Enumerate the SPIFFE IDs
  or key hashes that are allowed to sign for this namespace.

---

## Gate 2 — ML-BOM present (CycloneDX)

The **ML-BOM** (Machine Learning Bill of Materials) is a
CycloneDX document listing model provenance: base model, training
dataset references, dependencies used at training, tokenizer,
preprocessing components, evaluation datasets. The presence and
completeness of the ML-BOM is a supply-chain evidence bar (mod-
110 authors the generation pipeline).

### What "present" means at admission

- An ML-BOM document exists, referenced from the model registry
  entry by digest.
- Its CycloneDX schema version is on the accepted-versions list.
- Its `components` include at least: base model reference, at
  least one training-dataset reference, all direct dependencies
  used at training with pinned versions.
- The `metadata.timestamp` is within the freshness window (e.g.,
  the artifact and ML-BOM were generated in the same build).

### The constraint template

```yaml
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: k8srequiremlbom
spec:
  crd:
    spec:
      names:
        kind: K8sRequireMLBOM
      validation:
        openAPIV3Schema:
          type: object
          properties:
            minComponents:
              type: integer
            requiredComponentTypes:
              type: array
              items: { type: string }
            maxAgeDays:
              type: integer
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package k8srequiremlbom

        violation[{"msg": msg}] {
          image := input.review.object.spec.template.spec.containers[_].image
          not mlbom_ok(image, input.parameters)
          msg := sprintf("image %v has no valid ML-BOM meeting requirements", [image])
        }

        mlbom_ok(image, params) {
          resp := external_data({
            "provider": "mlbom-fetcher",
            "keys": [image],
            "parameters": params
          })
          bom := resp.responses[_][1]
          bom.completeness_score >= params.minComponents
          all_types_present(bom, params.requiredComponentTypes)
          bom.age_days <= params.maxAgeDays
        }

        all_types_present(bom, types) {
          count([t | t := types[_]; bom.component_types[t]]) == count(types)
        }
```

### The constraint

```yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequireMLBOM
metadata:
  name: serving-must-carry-mlbom
spec:
  enforcementAction: deny
  match:
    kinds:
      - apiGroups: ["serving.kserve.io"]
        kinds: ["InferenceService"]
    namespaces: [serving]
  parameters:
    minComponents: 5
    requiredComponentTypes:
      - "machine-learning-model"
      - "dataset"
      - "library"
    maxAgeDays: 30
```

### Failure modes to prevent

- **ML-BOM references an artifact digest that differs from the
  deployed image digest.** The fetcher must resolve the ML-BOM by
  the *deployed* digest and reject a BOM whose subject is a
  different one.
- **Completeness score is a self-report.** If the training
  pipeline sets its own score, an attacker with pipeline write
  can set it to 100. Prefer computing completeness from the ML-
  BOM content at admission (count declared components, verify
  required types), not from a summary field.
- **CycloneDX schema version drift.** Pin accepted versions;
  reject others so parser assumptions hold.

---

## Gate 3 — Scan clean, within freshness window

The artifact scanner is model-appropriate:

- For safetensors weights, `safetensors` format validation +
  `ModelScan` for pickled files.
- For OCI images (the serving-container image), a container CVE
  scanner (Trivy, Grype, Clair, Snyk).
- For agent tool schemas, a JSON-schema validator + LLM-specific
  scanner.

The scan output is a record with:

- Scanner name + version.
- Artifact digest under test.
- Findings, each with severity and status (open / mitigated).
- Timestamp.

The gate:

### What "clean, fresh" means at admission

- A scan record exists for the deployed digest.
- Its timestamp is within the freshness window (e.g., 7 days for
  container images; the ML-BOM's `maxAgeDays` for weights).
- The record has no `open` findings above the configured
  severity floor (usually `high`), or every above-floor finding
  has a mitigation attestation attached (mod-110 territory).

### The constraint template (excerpt)

```yaml
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: k8sscanclean
spec:
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package k8sscanclean

        violation[{"msg": msg}] {
          image := input.review.object.spec.template.spec.containers[_].image
          not scan_ok(image, input.parameters)
          msg := sprintf("image %v has no clean, fresh scan record", [image])
        }

        scan_ok(image, params) {
          resp := external_data({
            "provider": "scanner-fetcher",
            "keys": [image],
            "parameters": params
          })
          scan := resp.responses[_][1]
          scan.age_hours <= params.maxAgeHours
          count(open_above_severity(scan.findings, params.severityFloor)) == 0
        }

        open_above_severity(findings, floor) = out {
          out := [f | f := findings[_]; f.status == "open"; severity_gte(f.severity, floor)]
        }
```

### The constraint

```yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sScanClean
metadata:
  name: serving-must-be-scan-clean
spec:
  enforcementAction: deny
  match:
    kinds:
      - apiGroups: ["apps"]
        kinds: ["Deployment"]
      - apiGroups: ["serving.kserve.io"]
        kinds: ["InferenceService"]
    namespaces: [serving]
  parameters:
    maxAgeHours: 168
    severityFloor: "high"
```

### Failure modes to prevent

- **"Clean" without a floor.** Every scanner has noise;
  mitigation-attested findings must be treated as clean, but
  everything else is a fail.
- **Stale scans.** A clean scan from 6 months ago tells you
  nothing about today's CVE landscape.
- **Skipping model-weight scanning.** Container CVE scans miss
  unsafe pickle payloads inside `.pt` files; use ModelScan or
  the safetensors format enforcement in tandem.

---

## Gate 4 — Provenance verified (SLSA v1.0 + in-toto)

**SLSA v1.0** is the current spec (v1.1 in-progress at the time
this module was drafted; verify the current version at
[slsa.dev](https://slsa.dev)). It defines four build levels;
mature ML pipelines target Build L3.

The relevant evidence at admission is the **in-toto provenance
attestation** — a signed statement that describes how the
artifact was produced: which builder built it, from which source,
with which build parameters, at which materials.

### What the gate verifies

For the deployed artifact digest:

1. An in-toto attestation of type
   `https://slsa.dev/provenance/v1` exists.
2. The attestation is signed and verifiable against the same
   trust root as gate 1.
3. `predicate.buildDefinition.buildType` is on the accepted list
   (e.g., `https://github.com/actions/runner`,
   `https://tekton.dev/chains`).
4. `predicate.runDetails.builder.id` matches an allow-listed
   builder identity (a URL, an SPIFFE ID, or a Fulcio identity).
5. `predicate.runDetails.metadata.invocationId` is present and
   references a build that is reproducible and auditable.
6. `subject[].digest` matches the deployed digest.

### The constraint template (excerpt)

```yaml
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: k8srequireslsaprovenance
spec:
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package k8srequireslsaprovenance

        violation[{"msg": msg}] {
          image := input.review.object.spec.template.spec.containers[_].image
          not provenance_ok(image, input.parameters)
          msg := sprintf("image %v lacks SLSA v1 provenance from allow-listed builder", [image])
        }

        provenance_ok(image, params) {
          resp := external_data({
            "provider": "slsa-verifier",
            "keys": [image],
            "parameters": params
          })
          att := resp.responses[_][1]
          att.predicate_type == "https://slsa.dev/provenance/v1"
          allowed_builder(att.predicate.runDetails.builder.id, params.allowedBuilders)
          att.subject_digest == image_digest(image)
        }

        allowed_builder(id, allowed) {
          allowed[_] == id
        }
```

### The constraint

```yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequireSLSAProvenance
metadata:
  name: serving-must-carry-slsa-v1-provenance
spec:
  enforcementAction: deny
  match:
    kinds:
      - apiGroups: ["serving.kserve.io"]
        kinds: ["InferenceService"]
    namespaces: [serving]
  parameters:
    allowedBuilders:
      - "https://github.com/actions/runner/v2"
      - "spiffe://td.acme.internal/plane/ci/component/cosign-signer"
```

### Failure modes to prevent

- **Attestation type not verified.** An in-toto Statement can
  wrap any predicate type. Require exactly
  `https://slsa.dev/provenance/v1` (or the version you accept).
- **Builder identity wildcards.** As with cosign identity
  allow-lists, wildcards defeat the check.
- **Subject digest not matched.** An attacker with pipeline
  write can attach a provenance attestation whose subject is a
  different, legitimate artifact. The gate must confirm subject
  digest == deployed digest.

---

## The full deny-or-admit flow at deployment time

For a serving-plane deployment of `fraud-v42`:

```
   apply Deployment (spec.template.spec.containers[0].image = registry.acme.local/models/fraud-v42:2026-04-01)
             │
             ▼
   ┌───────────────────────────┐
   │  Mutating admission        │
   │  - sidecar injection       │
   │  - digest pinning (resolve │
   │    tag → sha256:…)         │
   └───────────┬───────────────┘
               │
               ▼
   ┌───────────────────────────┐
   │  Validating admission      │
   │  (Gatekeeper)              │
   │                            │
   │  Gate 1 — cosign sig?      │
   │  Gate 2 — ML-BOM present?  │
   │  Gate 3 — scan clean?      │
   │  Gate 4 — SLSA provenance? │
   │                            │
   │  Any violation → DENY      │
   └───────────┬───────────────┘
               │
       admit  ▼
   ┌───────────────────────────┐
   │  Object persisted          │
   │  Scheduler binds to node   │
   │  kubelet pulls image       │
   │  Container runtime         │
   │  performs signature check  │
   │  (defense in depth)        │
   └───────────────────────────┘
```

Every gate is fail-closed. The four together are what a mod-102
STRIDE row like "T — attacker modifies model artifact after CI"
resolves to at the enforcement layer.

---

## Rolling out gates safely

- **Draft mode first.** Every new constraint starts with
  `enforcementAction: dryrun`. Observe violations for at least
  one release cycle.
- **Per-namespace scope.** Enforce first in a low-blast-radius
  namespace (staging), then in the serving namespace, then
  cluster-wide.
- **Exception mechanism.** Some workloads may legitimately
  violate (e.g., a shadow-deploy of a candidate model). Provide a
  named-object exception at the constraint level, not a wildcard
  bypass.
- **Emergency bypass.** A break-glass label
  (`aicg.acme.local/break-glass: <ticket-id>`) can be honoured by
  the constraint *only* in an emergency namespace, and the label
  itself is logged as a security event mod-111 audits weekly.
- **Version-controlled policy.** Constraint templates and
  constraints live in Git; changes go through code review and CI
  policy testing (`conftest`, `opa test`).

---

## Testing constraint templates

Rego is testable. `opa test` runs unit tests against constraint
templates. Every template should have:

- A "happy path" test — the well-formed input passes.
- A "missing evidence" test — no signature / no ML-BOM / etc. →
  violation.
- A "wrong evidence" test — signature from wrong identity,
  ML-BOM for wrong digest, stale scan → violation.
- A "malformed input" test — the template does not panic on
  missing fields.

CI runs these on every policy change. A production Gatekeeper
policy with no tests is one syntax bug away from admitting
everything or rejecting everything.

---

## What about Kyverno, jsPolicy, Kubewarden?

The pattern (four gates, external-data fetch, deny-by-default)
is portable to every admission-policy engine currently in use:

- **Kyverno** — YAML-native policies, cleaner UX, similar
  external-data integration via `context.apiCall`.
- **Kubewarden** — WebAssembly-based policies, good sandboxing.
- **jsPolicy** — JavaScript-based, useful when the team already
  runs Node.
- **Bespoke ValidatingAdmissionWebhook** — write your own; use
  only when other options do not fit.

Gatekeeper is used in this chapter because Rego is the reference
constraint language and because it is the CNCF policy engine
most widely deployed. Every concept translates.

---

## The mistakes this chapter is trying to prevent

- **Trusting the registry tag alone.** Signatures, provenance,
  ML-BOM, and scan freshness are separate evidences that all
  must clear the gate. "In the registry" is not evidence.
- **Fail-open on gate failures.** If the cosign verifier is
  down, the admission gate must deny, not admit and log. Add
  redundancy to the verifier, not fail-open policy.
- **Wildcard allow-lists.** Identity wildcards for cosign and
  SLSA builders defeat the checks.
- **Skipping ML-BOM enforcement because "we generate one".**
  Generation is mod-110's job. Enforcement is this chapter's.
- **Not versioning the policy.** Constraint templates and
  constraints are code; treat them like it.
- **Skipping tests.** `opa test` is short. A production policy
  with no tests is a landmine.

---

## Summary

- Admission-time policy-as-code is the enforcement point that
  turns supply-chain evidence into a release gate.
- Four gates for ML model deployments: signed artifact, ML-BOM
  present, scan clean, provenance verified.
- OPA / Gatekeeper is the reference implementation; the pattern
  translates to Kyverno, Kubewarden, and others.
- Each gate is fail-closed, uses external-data providers to
  reach outside the cluster, and consumes evidence generated by
  mod-105 (keys), mod-110 (build pipeline), and this module's own
  posture.
- Roll out constraints `dryrun → deny`; version-control the
  templates; test them with `opa test`; expose exceptions as
  named objects with expiry, not wildcard bypasses.
- The gate output — admit / deny + reason — flows to SIEM
  (mod-111) and to the evidence store (mod-109 governance).
- This chapter completes the module: mod-102's threat model
  named the mitigations; chapters 03–05 hardened the substrate;
  this chapter refuses deployments that lack the evidence the
  mitigations demand.
