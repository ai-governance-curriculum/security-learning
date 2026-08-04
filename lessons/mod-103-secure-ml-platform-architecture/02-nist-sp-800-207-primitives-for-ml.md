# Chapter 02 — NIST SP 800-207 Primitives Applied to the Training, Registry, and Serving Planes

> **Note on AI-assisted content.** Verify every SP 800-207 tenet and
> primitive definition against the current published SP 800-207
> document and any published updates (e.g., SP 800-207A). Vendor
> descriptions of "PDP" and "PEP" occasionally drift from the SP
> 800-207 definitions — trust the standard, not the marketing. See
> [`resources.md`](./resources.md).

---

## Why this chapter exists

Chapter 01 introduced the three planes (training, registry, serving)
and the seven SP 800-207 tenets, and named the primitives (PEP,
PDP, PIP, trust-algorithm inputs) at the highest level.

This chapter maps each primitive onto a specific enforcement point
in the ML platform and closes with the gap-assessment method used
in exercise 01. By the end of the chapter you should be able to
point at any request in the three-plane model and answer:

- Which component is the PEP?
- Which component renders the decision — the PDP?
- What identity, posture, and context inputs (PIP feeds) does the
  PDP consult?
- What is the trust-algorithm variant (criteria-based, score-based,
  singular vs contextual) that applies here?
- What is the fallback when a PIP feed is unavailable — deny, permit
  with an audit flag, permit for a bounded set?

The output artifact this chapter is building toward is the
**zero-trust gap assessment** — exercise 01 asks you to produce
one for a target ML platform. The next four chapters supply the
concrete controls (workload identity, network / mesh authz, cluster
hardening, admission-time policy) that close the gaps this
assessment surfaces.

---

## The SP 800-207 logical architecture — recap

SP 800-207 §3.2 diagrams the logical components:

```
   ┌───────────────────────┐
   │   Policy Decision     │
   │   Point (PDP)         │
   │                       │
   │  ┌─────────┐          │
   │  │  Policy │          │
   │  │  Engine │          │
   │  │  (PE)   │          │
   │  └────┬────┘          │
   │       │               │
   │  ┌────▼────┐          │
   │  │  Policy │          │
   │  │  Admin. │          │
   │  │  (PA)   │          │
   │  └────┬────┘          │
   └───────┼───────────────┘
           │
           ▼
   ┌───────────────────────┐        ┌────────────────┐
   │  Policy Enforcement   │◄──────►│    Subject      │
   │  Point (PEP)          │        │ (user/workload) │
   └───────────┬───────────┘        └────────────────┘
               │
               ▼
        ┌─────────────┐
        │  Resource    │
        │ (data / API) │
        └─────────────┘

   PIP feeds into the PE:
   - Identity provider (OIDC / SPIFFE)
   - Data-access policy (RBAC + ABAC)
   - Continuous diagnostics / posture (CD/M)
   - Threat intelligence
   - Activity logs (SIEM feed)
   - PKI, ID management, industry-compliance
```

The **PE** is the brain — it renders allow / deny per request. The
**PA** is the hand — it opens or closes the specific communication
path once the PE has decided. Both together are the PDP. The **PEP**
is the enforcement muscle at the resource. The PDP is remote from
the PEP; the PEP consults it (either per-request, or via a cached
policy pushed by the PA).

The **PIP feeds** are the sources the PE consults for context. In
SP 800-207 §3.3, the trust algorithm variants are:

- **Criteria-based** vs **score-based** — does the decision
  require a fixed set of attribute matches, or a weighted score
  crossing a threshold?
- **Singular** vs **contextual** — does the decision look only at
  the current request, or does it also consider recent activity by
  the same subject / resource?

Most ML-platform enforcement points are **criteria-based +
contextual**: fixed attribute matches (signature present, provenance
match, image on allow-list) plus contextual state (this workload's
attestation is fresh, this SBOM was fetched within the freshness
window).

---

## Mapping the primitives onto the ML platform

Every enforcement point on the ML platform is either a PEP, a PDP,
or a PIP. This is the reference mapping the rest of the module
uses.

### The training plane

| Request flow | PEP | PDP | Primary PIP feeds |
| --- | --- | --- | --- |
| Training pod starts | K8s admission controllers (Gatekeeper) | Gatekeeper (OPA engine) + registered constraint templates | Signed image allow-list, PSA level, node-selector policy, ML-BOM presence for base image, mod-102 asset-inventory tags |
| Training pod requests cloud IAM credentials | Cloud IAM / STS token exchange | Cloud IAM policy + workload federation policy | SPIFFE JWT-SVID (chapter 03), OIDC federation trust config, project-scoped IAM allow-list |
| Training pod reads dataset from feature store | Feature store API + mesh sidecar | Mesh AuthorizationPolicy + feature-store's own RBAC | Workload SPIFFE ID, dataset ACL, mod-102 sensitivity tag, retention policy |
| Training pod writes candidate model to registry | Registry write API + admission-time sign policy | Registry RBAC + Rekor + cosign verification (deferred to serving-plane admission) | SPIFFE ID of training pipeline, signing key attestation, ML-BOM emitter proof, provenance builder identity |

### The registry plane

| Request flow | PEP | PDP | Primary PIP feeds |
| --- | --- | --- | --- |
| CI attaches a signature / attestation | Registry attestation API | Rekor transparency log + registry RBAC | CI OIDC identity (Sigstore keyless), builder-identity allow-list |
| Serving pod pulls model artifact | Registry auth API + serving-plane admission controller | Gatekeeper — verifies signature, provenance, ML-BOM, scan window | Rekor entry, cosign signature verification, in-toto attestation, ML-BOM completeness score, scanner freshness |
| Human operator promotes a candidate to `production` tag | Registry API + workflow guard | Registry RBAC + change-management workflow | SSO identity (with MFA state), on-call rotation, ticket reference |

### The serving plane

| Request flow | PEP | PDP | Primary PIP feeds |
| --- | --- | --- | --- |
| Serving pod starts | K8s admission (Gatekeeper) | Gatekeeper policies (signed artifact, provenance, ML-BOM, scan clean) | Rekor / cosign, in-toto, ML-BOM store, scanner, mod-102 asset inventory |
| Client hits serving endpoint | Ingress gateway + mesh sidecar | Ingress auth (JWT / mTLS) + mesh AuthorizationPolicy | OIDC IdP for the tenant, mesh trust-bundle, rate-limit policy |
| Serving pod reads online features | Mesh sidecar on the feature-store side | Mesh AuthorizationPolicy scoped by SPIFFE ID | Serving SPIFFE ID, per-tenant ACL, mod-102 feature-sensitivity tag |
| Serving pod calls an LLM tool | Tool-invocation gateway + mesh | Tool-invocation policy (mod-107 territory) + mesh AuthorizationPolicy | SPIFFE ID + agent-scope claim + tenant identity |

Every row here is a concrete implementation of "authenticate,
authorise, log". Chapters 03–06 walk the concrete YAML / policy
code for the recurring shapes.

---

## Choosing PIP feeds — the "trust algorithm inputs" for ML

The trust algorithm's inputs determine what the PDP can reason
about. SP 800-207 names identity, device posture, environmental
factors, and behavioural attributes. For ML platforms, useful PIP
feeds and their sources:

| PIP feed | Source | Consumed by |
| --- | --- | --- |
| Workload identity (SPIFFE SVID) | SPIRE server + agents (chapter 03) | Mesh authz, cloud IAM federation, admission controllers |
| User identity (OIDC) | Enterprise IdP (Okta, Entra ID, Keycloak) | Ingress gateway, registry, cluster API |
| Signed image allow-list | cosign / Rekor + signature policies | Gatekeeper (chapter 06) |
| SLSA provenance attestation | in-toto attestation + verifier | Gatekeeper (chapter 06) |
| ML-BOM completeness | CycloneDX ML-BOM store | Gatekeeper (chapter 06) |
| Artifact scanner result + freshness | Scanner (ModelScan for safetensors, container scanner for images) | Gatekeeper (chapter 06) |
| Node hardening posture | Kube-bench / CIS-benchmark report | Gatekeeper (labels-based) + SIEM |
| Pod posture (PSA level, seccomp, RO root) | Kubernetes PSA + PodSecurityPolicy-shaped OPA constraints | Gatekeeper (chapter 05) |
| Threat intelligence — deny-list of image digests, CVEs above severity | External TI feed + internal ticket store | Gatekeeper (rejection reasons) |
| Behavioural signal — recent access anomalies | SIEM (from mod-111) | Ingress gateway rate-limit, mesh circuit-breaker |
| Data-classification tag | mod-102 asset inventory | Feature-store ACL + mesh AuthorizationPolicy per-tenant |

Two rules to install now:

- **Every PIP feed needs a freshness policy.** A "signature
  verified" answer from 30 days ago is not the same as one from
  30 seconds ago. Freshness windows belong in the policy itself,
  not implicit in the fetch time.
- **Every PIP feed needs a fail-mode decision.** If the ML-BOM
  store is down, does the admission controller deny (fail-closed)
  or admit (fail-open)? Fail-closed is correct for gates on the
  critical path; fail-open with an audit-flag is acceptable only
  for scoring inputs that do not change the allow / deny outcome.

---

## The trust algorithm variants — which ML enforcement point uses which

Recall the two axes from SP 800-207 §3.3:

- Criteria-based vs score-based.
- Singular vs contextual.

Applied:

| Enforcement point | Variant | Why |
| --- | --- | --- |
| Admission controller for model deploy | Criteria-based, contextual | Fixed criteria (signature, provenance, ML-BOM, scan). Contextual because "signed" requires recency + issuer allow-list. |
| Mesh AuthorizationPolicy | Criteria-based, singular | Fixed criteria (source SPIFFE ID, method, path). Singular — each request evaluated against static allow rules. |
| Cluster API RBAC | Criteria-based, singular | Kubernetes RBAC is verb + resource + user. |
| Ingress gateway | Criteria-based + contextual (per-tenant rate limit) | Criteria (valid JWT, scope) plus contextual (rate limit tracks recent count). |
| Adaptive step-up for suspicious behaviour | Score-based, contextual | Score aggregates behavioural signals from SIEM; contextual by definition. |

A common failure mode is trying to make the model-deploy
admission gate score-based. It is tempting to write "if signature
present AND provenance verified AND ML-BOM present AND scan clean
AND builder trusted, score ≥ 4/5 → admit". Don't. Score-based
gates on release-critical paths encourage silent trade-offs
("signature was missing but everyone else's score was fine, so let
it through"). Keep the release gate criteria-based; use scoring
only for detection tiers where the outcome is "alert" or "reduce
rate", not "release".

---

## The gap-assessment method — how to walk a real ML platform

Exercise 01 asks you to run a gap assessment on a target ML
platform against the seven SP 800-207 tenets. The method:

1. **Draw the three-plane diagram.** Use chapter 01's reference.
   Any real platform will have edges the reference does not — draw
   them all. Every cross-plane arrow is a candidate PEP.
2. **For every arrow, identify the PEP.** If the answer is "there
   is no PEP; the pods just talk to each other", record that as a
   gap.
3. **For every PEP, identify the PDP and the PIP feeds.** If the
   PDP is "the pod's own code", it is not a zero-trust PDP; record
   the gap.
4. **For every tenet 1–7, produce a matrix column.** Score the
   platform: green (satisfied with evidence), yellow (partial —
   satisfied for some arrows / planes but not others), red
   (unsatisfied).
5. **For each red or yellow cell, produce a specific remediation
   ticket** naming the control class (workload identity, mesh
   authz, cluster hardening, admission-time policy) — the module
   chapters 03–06 map to these classes.

The output artifact is what exercise 01 asks for. It is also the
input to the module's own architecture-decision record: what to
build, in what order, and against which primary source.

---

## Two worked mappings from a fintech ML platform

Concrete examples, adapted from the fintech reference system
carried from mod-101 / mod-102.

### Mapping 1 — training pod reads customer-support emails corpus

- **Subject.** Training pod running `fraud-retrain-2026-04` in
  namespace `training`.
- **Resource.** S3 bucket `s3://acme-support-emails-prod`,
  containing PII-tier customer support emails, tagged as
  training-eligible after a review workflow.
- **PEP.** Cloud IAM (STS) at the bucket, mesh sidecar at the S3
  gateway.
- **PDP.** Cloud IAM policy engine + AuthorizationPolicy at the
  gateway. Both must allow.
- **PIP feeds.** SPIFFE JWT-SVID of the training pod, mod-102
  asset-inventory tag `class=training-data, sensitivity=PII`,
  bucket-object tag `training-eligible=true`.
- **Trust-algorithm variant.** Criteria-based, contextual. Criteria
  are SPIFFE ID and bucket tag; contextual because the SPIFFE ID
  is issued only for the currently-executing job, and expires when
  the job ends.
- **Fail-mode.** Deny. If SPIRE is unavailable, the pod cannot
  attest, cannot mint an SVID, cannot exchange to STS, and cannot
  read the bucket. The training job fails cleanly. This is the
  correct fail-mode for a critical-path data read.

### Mapping 2 — serving pod pulls the `fraud-v42` artifact at start

- **Subject.** Serving pod `fraud-serve-42-<pod-hash>` in
  namespace `serving`.
- **Resource.** OCI artifact `registry.acme.local/models/fraud-
  v42@sha256:…`.
- **PEP.** Kubernetes admission controller (Gatekeeper) at deploy
  time. Registry auth at pull time.
- **PDP.** Gatekeeper constraint templates: `require-cosign-
  signature`, `require-slsa-provenance`, `require-mlbom-attached`,
  `require-scan-clean`.
- **PIP feeds.** Rekor entry for the artifact (Sigstore
  transparency log), cosign signature verification, in-toto SLSA
  provenance, ML-BOM CycloneDX doc, ModelScan / safetensors
  validator result.
- **Trust-algorithm variant.** Criteria-based, contextual. All four
  criteria required. Contextual — the scanner result must be
  within a freshness window (e.g., 7 days) and the ML-BOM must
  reference the same artifact digest.
- **Fail-mode.** Deny admission. A serving pod referencing an
  artifact whose signature the PDP cannot verify does not run.
  This is chapter 06's Gatekeeper policy set in miniature.

---

## What "good" looks like versus what "bad" looks like

**Bad — PEP present but no distinct PDP.**

> "Our serving pods pull models by tag. There is a check in the
> pod's start-up script that reads the artifact digest and
> compares it against a list stored in a ConfigMap. If it
> matches, we start serving."

The PEP (the pod) is also the PDP (checks its own list) and the
PIP (reads its own ConfigMap). Every property of zero trust is
violated — no separation, no independent policy source, no
verifiable identity of the subject making the check.

**Good — PDP is separate from PEP; PIP feeds are pinned to
external sources of truth.**

> "Serving pods are admitted only through a Gatekeeper
> ValidatingAdmissionWebhook. The constraint template
> `require-cosign-signature` calls out to Sigstore's verification
> library, referencing the trust root pinned to the enterprise's
> TUF root of trust. The image digest, once verified, is written
> to an audit log consumed by SIEM. Verifying keys are held in
> mod-105's KMS; the Rekor entry is a public transparency log; the
> in-toto SLSA provenance is generated in mod-110's build
> pipeline."

Chapter 06 authors the constraint templates.

---

## The mistakes this chapter is trying to prevent

- **Collapsing the PEP and PDP into one.** If the same component
  decides *and* enforces, there is no independent policy — the
  attacker with foothold on the enforcer has bypassed the
  decision.
- **Ignoring PIP freshness.** A stale PIP answer is worse than no
  PIP answer, because the decision looks confident but the
  underlying evidence has drifted.
- **Fail-open on a critical path.** "The scanner was down, so we
  admitted the pod" is the pattern that turns a control into a
  compliance-theatre control.
- **Score-based release gates.** Reserve scoring for detection
  tiers where the outcome is "alert" or "step up", not "admit".
- **Skipping the tenets you cannot fully satisfy.** SP 800-207
  §2 tenet 5 ("integrity and posture of assets is monitored")
  is often only partially satisfied on day one. Record it as
  yellow with a specific plan, not silently skipped.

---

## Summary

- SP 800-207's logical model is PDP (PE + PA), PEP, and PIP
  feeds. Every ML-platform enforcement point maps to one of
  these.
- The training / registry / serving planes each have their own
  set of PEPs and PDPs — chapter 03 (identity), chapter 04
  (network / mesh), chapter 05 (cluster hardening), and chapter 06
  (admission-time policy) supply the concrete controls.
- The trust-algorithm variant most ML-platform gates use is
  criteria-based, contextual. Reserve score-based for detection,
  not for release gates.
- Every PIP feed needs a freshness policy and a fail-mode
  decision. Fail-closed on critical paths; fail-open with audit
  only for non-critical scoring inputs.
- The gap-assessment method (walk the three-plane diagram, name
  the PEPs and PDPs, score against the seven tenets) is the
  output artifact of exercise 01 and the input to the module's
  build plan.
