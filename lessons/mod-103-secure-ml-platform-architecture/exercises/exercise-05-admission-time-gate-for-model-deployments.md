# Exercise 05 — Admission-Time Gate for Model Deployments

**Estimated effort:** ~3 hours
**Deliverable:** One directory containing (a) the four Gatekeeper
constraint templates for the four evidence gates (signed artifact,
ML-BOM present, scan clean, provenance verified), (b) the
corresponding constraints applied to the target namespaces, (c)
the external-data provider deployments the templates call, (d)
Rego unit tests, and (e) a rollout runbook.
**Prerequisites:** Chapter 06 read end-to-end. Exercises 01–04
completed. A Kubernetes cluster with Gatekeeper 3.14+ (or the
current release supporting external-data providers) installed.
Familiarity with cosign, in-toto SLSA v1.0 attestations, and
CycloneDX ML-BOM.

---

## Objective

Author the admission-time policy set that gates every model
deployment on the four security-evidence checks:

1. **Signed artifact** — cosign signature verified against a
   pinned trust root and identity allow-list.
2. **ML-BOM present** — CycloneDX ML-BOM referencing the deployed
   digest, at the required completeness, within the freshness
   window.
3. **Scan clean** — artifact scanner result within the freshness
   window, no open above-severity-floor findings.
4. **Provenance verified** — SLSA v1.0 in-toto provenance
   attestation from an allow-listed builder identity, subject
   digest matches the deployed digest.

The policies must be enforced at admission time — a Deployment /
InferenceService / SeldonDeployment that lacks any evidence must
be rejected before it reaches the scheduler.

## Problem statement

Continue with the fintech reference platform. The model
deployment target is a KServe `InferenceService` in the `serving`
namespace, referencing an OCI image
`registry.acme.local/models/fraud-v42@sha256:…`. The following
evidence pipelines already exist (from mod-110 and the module's
prior exercises, or assume them as inputs):

- CI signs the image with cosign, publishing the signature to a
  Rekor transparency log. The signer identity is the SPIFFE ID
  `spiffe://td.acme.internal/plane/ci/component/cosign-signer`
  (from exercise 02).
- CI attaches a SLSA v1.0 in-toto provenance attestation.
- CI generates a CycloneDX ML-BOM at build time and pushes it to
  a designated ML-BOM store (S3 bucket keyed by artifact digest).
- A scanner service runs on a schedule against every artifact in
  the registry and publishes results to a scan-results service.

Your job is to author the admission gates that enforce these
evidences at deploy time.

## Requirements

Deliver a directory with the following structure:

```
exercise-05/
  constraint-templates/
    k8srequirecosignsignature.yaml
    k8srequiremlbom.yaml
    k8sscanclean.yaml
    k8srequireslsaprovenance.yaml
  constraints/
    serving-images-must-be-signed.yaml
    serving-must-carry-mlbom.yaml
    serving-must-be-scan-clean.yaml
    serving-must-carry-slsa-v1-provenance.yaml
  providers/
    cosign-verifier.yaml
    mlbom-fetcher.yaml
    scanner-fetcher.yaml
    slsa-verifier.yaml
  tests/
    happy-path/
      deployment.yaml
      evidence-fixtures/
    negative/
      no-signature/
      no-mlbom/
      stale-scan/
      wrong-builder/
    opa-tests/
      cosign_test.rego
      mlbom_test.rego
      scan_test.rego
      provenance_test.rego
  RUNBOUT.md   # rollout runbook — dryrun → enforce plan
  DESIGN.md    # notes on choices and known deferrals
```

Rules:

### Constraint templates

Each of the four constraint templates:

- Uses external-data providers to fetch evidence at admission
  time (do not embed static allow-lists in Rego).
- Emits a specific violation message on failure that names the
  image, the missing evidence, and the constraint name.
- Handles missing input fields defensively — no panic on absent
  container spec or missing tag.
- Is unit-tested with `opa test`; at least one happy-path test
  and one negative test per template.

### Constraints

Each constraint:

- Scopes to the `serving` namespace (and any other model-serving
  namespaces in your platform).
- Matches the CRDs your platform uses: at minimum
  `apps/Deployment`; if you use KServe or Seldon, add their
  `InferenceService` / `SeldonDeployment`.
- Enumerates parameters explicitly — no bare defaults.
- Has an `enforcementAction: dryrun` first pass and a plan to
  graduate to `deny`.

### External-data providers

Each provider Deployment:

- Runs in `platform-system` (or its own dedicated namespace).
- Has its own SPIFFE ID from exercise 02.
- Is reachable only from Gatekeeper (mesh AuthorizationPolicy +
  NetworkPolicy from exercise 03).
- Speaks Sigstore / Rekor / in-toto / ML-BOM APIs against the
  pinned endpoints your platform uses.
- Has a per-provider fail-mode — deny on the critical-path gates
  (signature, provenance) and clear "fail-closed" language in
  configuration.

### Tests

- **Happy path.** A well-formed InferenceService with valid
  evidence for all four gates is admitted.
- **Negative — no signature.** Deploy with an image that has no
  cosign signature; verify admission is refused with the cosign
  violation.
- **Negative — no ML-BOM.** Deploy with a signed image that has
  no ML-BOM; refused.
- **Negative — stale scan.** Deploy with an artifact whose scan
  timestamp is older than the freshness window; refused.
- **Negative — wrong builder.** Deploy with a provenance
  attestation from a builder identity not on the allow-list;
  refused.
- **Negative — subject-mismatch attestation.** Deploy with a
  provenance whose `subject.digest` differs from the deployed
  digest; refused.

### Rollout runbook (`RUNBOUT.md`)

- **Pre-conditions.** Which mod-110 evidence pipelines must be in
  place; which mod-105 keys must be issued; which mod-103
  exercise-02 SPIFFE registrations must exist.
- **Phase 1 (dryrun, staging cluster).** All constraints at
  `dryrun`. Observe violations for at least one release cycle.
- **Phase 2 (enforce in staging).** Flip to `deny`. Verify no
  legitimate rollout breaks.
- **Phase 3 (dryrun, production).** Enforce dryrun in production.
  Observe.
- **Phase 4 (enforce production, one gate at a time).** Enable
  gates in order: signature → provenance → ML-BOM → scan. Each
  gate soaks for one release cycle before the next.
- **Rollback.** How to disable a specific gate quickly, and what
  detection content mod-111 has in place to catch abuse of that
  window.
- **Break-glass.** The named label / annotation your platform
  accepts, the audit event it emits, and the mod-111 detection
  rule that alerts on it.

## Starter guidance

- Start with the cosign signature gate — it has the cleanest
  external-data flow and is the easiest to test.
- Use `opa test` from the beginning; every template gets a happy
  path and a negative test before it graduates to `dryrun` in a
  cluster.
- The provenance gate is the trickiest — SLSA v1.0's field names
  are different from SLSA 0.2's. Pin the version explicitly.
- Do not embed static allow-lists in Rego — use external-data
  providers so the allow-lists live in the mod-103 ADR store and
  can be rotated without a policy change.
- Test with realistic fixtures — an in-toto Statement JSON
  document, a CycloneDX ML-BOM JSON document, a Trivy scan JSON
  output. Copy-paste representative examples from the tool
  outputs.
- The break-glass mechanism should not be an ambient bypass —
  it is a named annotation with a ticket ID that is logged as a
  security event.

## Acceptance criteria

A passing gate set:

- All four constraint templates exist and are well-formed.
- All four constraints scoped to the serving namespace(s).
- External-data providers deployed and reachable only from
  Gatekeeper.
- `opa test` runs all Rego tests to green; at least one happy-
  path and one negative test per template.
- Negative-test deployments in the cluster show admission
  refusal with the expected violation message.
- Rollout runbook covers all four phases and a rollback / break-
  glass procedure.

A failing gate set:

- Any constraint enforcement is `dryrun` in production without a
  planned graduation date.
- Static allow-lists embedded in Rego (identity allow-list,
  builder allow-list) rather than fetched via provider — makes
  rotation require a policy release.
- Missing Rego tests.
- Fail-open behaviour on the critical-path gates (e.g., "if
  Rekor is down, admit").
- Wildcards on builder identities or signer identities.
- No break-glass mechanism, or a break-glass that is silent
  (no audit event).

## Stretch goals

- Add a **fifth gate** — model-card / evaluation-record required.
  The gate rejects deployments whose evaluation record does not
  meet minimum quality bars for the target production tier. This
  ties chapter 06 to mod-109 governance's model-card requirement.
- Author the same gates in **Kyverno** as well as Gatekeeper, and
  compare authoring effort, test coverage, and operational
  behaviour. Add a note in `DESIGN.md` recommending which to
  standardise on.
- Add a **transparency dashboard** — the number of deployments
  attempted, admitted, denied per constraint per week. Ties to
  mod-111 SecOps detection content.
- Wire the admission events to **mod-104 lineage** so every
  admitted deployment lands as a signed lineage event referencing
  the digest, the evidence, and the SPIFFE ID of the applier.

## Do not

- Do not commit a solution to any repository — solutions live in
  the paired solutions repo.
- Do not use wildcards on identity allow-lists — the gate becomes
  ceremonial.
- Do not embed the trust root into Rego. Reference it externally
  through the provider; rotate it there.
- Do not skip the negative tests. The negative tests are the
  evidence the gate is real.
- Do not treat "dryrun in production forever" as acceptable —
  every dryrun constraint must have a graduation date.
