# Exercise 01 — Zero-Trust Gap Assessment for an ML Platform

**Estimated effort:** ~2 hours
**Deliverable:** One Markdown document containing (a) the three-plane
architecture diagram of a target ML platform, (b) a PEP / PDP / PIP
mapping table for every cross-plane flow, and (c) a seven-tenet
scorecard with per-cell remediation tickets.
**Prerequisites:** Chapters 01 and 02 read end-to-end. NIST SP 800-207
skimmed (or open in a tab). The mod-102 asset inventory for the same
target system.

---

## Objective

For a target ML platform, produce the **zero-trust gap assessment**
that becomes the engineering roadmap the rest of the module (and
mod-112 program leadership) executes against.

By the end of the exercise you should be able to point at any
request between planes on the platform and answer: which component
enforces (PEP), which component decides (PDP), which sources inform
the decision (PIP), and where against the seven SP 800-207 tenets
the answer is green / yellow / red.

## Problem statement

You are the AI/ML Security & Governance Engineer for the fintech
introduced in mod-101 exercise 01 (and carried through mod-102).
The current-state platform:

- **Training plane.** Kubeflow on a shared GKE / EKS cluster. Node
  IAM role attached to the training node pool grants read on every
  S3 prefix in the data-lake account. Kubeflow experiments run
  under a shared service account.
- **Registry plane.** MLflow server in its own namespace. CI pushes
  candidate models with cosign signatures; there is *no* admission
  check on serving side that verifies the signature — the serving
  pod trusts the registry tag.
- **Serving plane.** KServe `InferenceService`s in the `serving`
  namespace. Ingress via an NGINX gateway; SSO on the customer-
  facing surface.
- **Cross-plane network.** No NetworkPolicies. Istio installed with
  `PeerAuthentication: PERMISSIVE`; no AuthorizationPolicies apart
  from a global `allow-all`.
- **Cluster hardening.** No `kube-bench` report on file. PSA
  labels not present. Cluster-admin role bound to every user in
  the `mlops` group.
- **Admission-time policy.** None beyond the built-in kube-apiserver
  chain.

If you have a real platform in front of you (an internal ML
platform, a public research platform you have permission to
model), substitute it — the exercise structure is identical.

## Requirements

Produce a single Markdown document with the following sections.

### Section 1 — Target-platform architecture (max 1 page)

Draw the three-plane architecture (Mermaid, PlantUML, ASCII, image
— any format that is version-controllable). Label:

- Every namespace / cluster / plane boundary.
- Every workload with its component name (KServe, MLflow, Kubeflow
  pipeline runner, Istio ingressgateway, etc.).
- Every cross-plane arrow with the payload it carries (model
  artifact, feature read, feature write, retraining trigger, etc.).
- Every external entity (customer, CI, human operator via bastion,
  cloud IAM STS).

Legend included; boundaries labelled.

### Section 2 — PEP / PDP / PIP mapping table

One row per cross-plane arrow from your diagram. Use the row
template from chapter 02:

| Flow ID | From | To | Purpose | PEP | PDP | PIP feeds | Trust-algorithm variant | Fail-mode |

Rules:

- Every arrow that crosses a plane boundary appears as its own
  row. Do not collapse multiple arrows into a single row.
- Where a PEP is missing (the arrow reaches the destination
  without any enforcement), write `NONE` in the PEP column. That
  is an *explicit* red row later.
- Where the PDP and PEP are the same component (the enforcer
  makes its own decision from its own config), write both cells
  with the same name and flag the row for scorecard purposes.
- Trust-algorithm variant is one of `criteria-based, singular`,
  `criteria-based, contextual`, `score-based, contextual`. If
  none applies (the flow is unenforced), write `NONE`.
- Fail-mode is `deny`, `permit-with-audit-flag`, or `permit`.

### Section 3 — Seven-tenet scorecard

Score the platform against the seven SP 800-207 tenets. Table
form:

| Tenet | Statement (brief) | Score (🟢 / 🟡 / 🔴) | Evidence | Gap | Remediation ticket |

Rules:

- Every tenet gets a row, even the ones the current platform
  ignores (score them 🔴 with a specific ticket).
- Evidence is the concrete artifact that supports the score — a
  policy YAML present, a `kube-bench` line, a signed policy
  document, a resource that does *not* exist. Do not write "we
  do this" without a pointer.
- Gap is the specific missing behaviour. "No workload identity"
  is too vague; "training pods obtain cloud IAM via node role, no
  SPIFFE / SPIRE deployed, no OIDC federation configured" is
  specific.
- Remediation ticket names the chapter of this module that closes
  the gap (03 identity, 04 network / mesh, 05 hardening, 06
  admission-time policy). Include an initial estimate of person-
  weeks.

### Section 4 — Sequenced remediation roadmap

Turn the scorecard's ticket list into a sequenced roadmap. Order
by:

1. **Blocking dependencies.** SPIFFE (chapter 03) is a prerequisite
   for mesh AuthorizationPolicy (chapter 04) matching on principal.
   Order accordingly.
2. **Blast radius.** A ticket that closes a full-lake IAM
   compromise outranks a ticket that closes a stray port.
3. **Cost.** Where two tickets close comparable radius, the
   cheaper one goes first.

Present as a Gantt-style table or a numbered sequence with parallel
tracks called out. Every ticket has an owner and an expected
completion date; if you don't own the platform, mark owners as
placeholders and explain who signs off.

## Starter guidance

- Walk the three planes with the mod-102 asset inventory open.
  Every asset the inventory names has at least one PEP / PDP
  question associated with it.
- For flows with no PEP, do *not* stall to design the eventual
  PEP; that is the rest of this module. Record `NONE` and move
  on.
- The most common failure mode is over-scoring green. Green
  means the tenet is satisfied *with evidence you can point at*.
  "We use TLS, so we're covered" is not evidence for tenet 2 if
  half the pod-to-pod traffic is plaintext.
- Draw your diagram in a version-controllable format so the
  exercise 02 and 03 deliverables can reference it directly.

## Acceptance criteria

A passing assessment:

- Contains a diagram with at least the three planes drawn, every
  cross-plane arrow labelled, and every external entity present.
- Table in Section 2 has every arrow present, no arrow omitted.
- Score column in Section 3 has 🔴 or 🟡 for at least four of the
  seven tenets (a real fintech platform without SPIFFE / mesh
  authz / admission-time policy cannot be 🟢 across the board;
  scoring all-green is evidence you scored wrong).
- Every 🔴 / 🟡 row has a specific remediation ticket referencing
  a chapter of this module or a paired module.
- The remediation roadmap orders tickets by dependency, not
  alphabetically.

A failing assessment:

- Uses "we have SSO" or "we have TLS" as evidence for tenets 2 or
  6 without qualification.
- Has every tenet 🟢 despite the current-state description above.
- Names remediations at the level of "add zero trust" without
  specifying which chapter's control is used.
- Lacks a diagram, or has a diagram that omits any cross-plane
  arrow.

## Stretch goals

- Extend the assessment to include the **detection tenet
  coverage** — tenet 7 says the enterprise collects information
  about assets and network activity. Map to what mod-111 SecOps
  would need: which of the platform's audit logs are shipped to
  SIEM today, which are not, which admission decisions are
  logged, and which SPIFFE registration events would need
  detection content.
- Produce the same assessment for a **greenfield** version of the
  platform (as if you were designing it from scratch). Compare
  the two — which controls are cheaper to install day-one and
  which are as-cheap-later; which are dramatically more expensive
  to retrofit.
- Add an ISO/IEC 42001 clause cross-reference column to the
  scorecard so mod-109 governance can consume the artifact
  directly.

## Do not

- Do not conflate SSO with workload identity. Chapter 03 is about
  the second, not the first.
- Do not commit a solution to any repository — solutions live in
  the paired solutions repo.
- Do not skip the diagram in favour of a written narrative. The
  diagram is what exercises 02–05 attach to.
- Do not invent CIS recommendation IDs or SP 800-207 tenet
  wordings — quote from the primary sources, and where a claim
  cannot be verified, insert a `<!-- needs-research: ... -->`
  marker rather than guessing.
