# Chapter 01 — NIST AI RMF Sub-Categories to Security Controls and Evidence

> **Note on AI-assisted content.** This chapter maps the NIST
> AI Risk Management Framework (AI RMF 1.0) and its companion
> Generative AI Profile (NIST AI 600-1) to concrete security-
> engineering controls. The framework is voluntary; the
> mappings below are one team's operationalisation, not a
> NIST-blessed compliance certification. Verify each sub-
> category against the primary text (see
> [`resources.md`](./resources.md)) before quoting a specific
> mapping to an auditor.

---

## Why this chapter exists

The AI RMF is a *function-and-outcome* framework, not a
control catalogue. Its four functions — **GOVERN**, **MAP**,
**MEASURE**, **MANAGE** — decompose into categories, which
decompose into sub-categories phrased as outcomes ("policies
and procedures are in place to define…"). Auditors,
customers, and internal governance teams increasingly ask
"how does your organisation address the AI RMF?" and expect
an answer that is more than "we read it".

The failure mode this chapter prevents:

> A security team is handed the AI RMF and told to "adopt
> it". They print the Playbook, tick the sub-categories that
> feel familiar, and produce a slide deck listing 40 out of
> 72 sub-categories as "in place". Six months later a customer
> asks for evidence that GOVERN 4.3 (documentation of AI
> risks) is operating. There is no owner, no artefact, no
> repeatable run — only the slide. The organisation is stuck
> answering the audit with rhetoric.

The fix is to treat every sub-category as a triple:

- **Sub-category outcome** — what the AI RMF asks for.
- **Concrete control** — the thing engineering ships.
- **Evidence artefact** — the file, record, or metric that
  proves the control is in place at a given point in time.

If a sub-category has no evidence, the org has adopted a
slogan, not a control. This chapter walks the four functions
and produces one triple per representative sub-category, and
gives the pattern the remaining sub-categories fit into.

You leave this chapter able to:

- Explain what each of the four AI RMF functions is
  responsible for, and *what fails* if a function is absent.
- Translate a sub-category outcome into a security-engineering
  control and an evidence artefact that a governance auditor
  can verify.
- Build a **control-mapping matrix** that the rest of this
  module (chapters 02–06) can extend to ISO 42001, EU AI Act,
  SOC 2, sector regs, and RSP-style frameworks.
- Recognise the sub-categories that are strengthened or added
  by the **Generative AI Profile (NIST AI 600-1)** and know
  where to fit generative-specific controls.

---

## The framework in one page

The AI RMF v1.0 (January 2023) organises risk work into four
functions. In shorthand:

- **GOVERN** — the organisation's standing posture. Policies,
  ownership, culture, third-party governance, incident
  response readiness. Runs *continuously* and *cross-cuts*
  the other three functions.
- **MAP** — the per-system framing. What context is the
  system deployed into, what stakeholders are affected, what
  risks does its intended use raise. Runs *once per system*
  (and re-runs when scope changes).
- **MEASURE** — the per-system measurement. Metrics that
  quantify identified risks, benchmarks, testing, tracking of
  residual risk. Runs *continuously* against a deployed
  system.
- **MANAGE** — the per-system decision. Prioritise risks,
  respond, monitor, retire. Runs *on the results of MEASURE*.

A useful mental model: **GOVERN is a program; MAP, MEASURE,
and MANAGE together are a per-system lifecycle**. Programs
without lifecycles are theatre; lifecycles without programs
drift.

The **AI 600-1 Generative AI Profile** (July 2024) does not
replace the four functions. It adds *generative-specific*
sub-categories and calls out where existing sub-categories
need extension for models that can produce text, code, images,
or media at scale. Treat it as a delta applied to each of the
four functions, not a separate framework.

---

## The mapping shape

Every sub-category maps to the same triple:

```yaml
- sub_category: GOVERN 1.1
  outcome: >
    Legal and regulatory requirements involving AI are
    understood, managed, and documented.
  control:
    what: >
      A per-system regulatory-scope register that names every
      statute, regulation, standard, and contractual clause
      that applies to the deployed system.
    where:
      - service registry annotation `regulatory_scope`
      - `governance/scope-register.yaml` in the platform repo
    owner: Governance / DPO
  evidence:
    artefact: >
      `governance/scope-register.yaml` referenced from the
      model card; reviewed at each release-gate.
    verification: >
      CI job fails if `regulatory_scope` annotation missing
      on any production-tier service; DPO signs quarterly
      register review.
```

The triple is the atom this module works in. Chapters 02–06
add analogous columns (ISO clause, EU AI Act article, SOC 2
criterion, sector-reg citation). The unified matrix at the
end of the module is the artefact chapter 04's OPA policies
enforce.

---

## GOVERN — the standing posture

GOVERN sub-categories are *always on*. They describe the
organisation's ambient capacity to manage AI risk. Most map
to controls that live outside a single service — policies,
role definitions, training programmes, third-party assessment
processes.

Representative sub-categories and their engineering
translations:

### GOVERN 1.1 — Legal and regulatory requirements are understood

**Control.** Per-system *regulatory-scope register*. Every
production ML system carries a machine-readable annotation
naming which regimes apply — GDPR, HIPAA, EU AI Act, SR 11-7,
FDA GMLP, SOC 2, PCI-DSS, sector-specific rules — plus
contractual obligations (customer DPAs, BAA counterparties).

**Evidence.** `regulatory_scope` field on the service
registry; `governance/scope-register.yaml` versioned in the
platform repo; the model card links to the register line for
its system. Reviewed at each release-gate; DPO co-signs
quarterly.

**Failure mode this prevents.** Teams shipping systems into
jurisdictions or sectors whose regime they did not know
applied — the "we didn't realise this was a high-risk
system under the AI Act" conversation with counsel.

### GOVERN 1.2 — Trustworthiness characteristics inform risk management

**Control.** The seven AI RMF trustworthiness
characteristics (valid & reliable, safe, secure & resilient,
accountable & transparent, explainable & interpretable,
privacy-enhanced, fair with harmful bias managed) become
**required sections** on every model card / system card and
required review dimensions in each design review.

**Evidence.** Model-card schema enforces the seven-section
structure at CI (mod-104 chapter 05); design-review template
enumerates the seven characteristics as review dimensions;
review sign-off records the reviewer per dimension.

### GOVERN 2.1 — Roles, responsibilities, and lines of communication are documented

**Control.** RACI matrix for AI/ML risk, published and
current. Every production system names an accountable
executive, a responsible engineering owner, a security lead,
a privacy lead, and (where applicable) a model-risk officer.

**Evidence.** `governance/raci.yaml` in the platform repo;
per-system RACI reference in the model card; on-call rotation
in the incident-response tool references the ML incident
runbook (mod-111).

### GOVERN 3.2 — Diversity, equity, inclusion, and accessibility considerations are integrated

**Control.** Review-board composition policy: any production
ML system that touches a *rights-affecting* decision (credit,
housing, employment, benefits, healthcare access) requires
review-board sign-off with at least one non-engineering
reviewer representing the impacted population or a subject-
matter expert.

**Evidence.** Review-board roster and each system's sign-off
record; the model card names the reviewers.

### GOVERN 4.1 — Organisational practices support risk-taking

**Control.** A named channel for engineers to raise AI-safety
concerns without retaliation — bug-bounty-style intake for
model behaviour issues, a dedicated Slack channel or email
alias monitored by the ML security lead.

**Evidence.** Channel exists and is documented in
onboarding; response-time SLA published; escalation history
in the incident-tracker.

### GOVERN 5.1 — Organisational policies address risks and impacts

**Control.** The AI/ML security policy, versioned and
approved. Names the tier map for data classification
(mod-108 chapter 01), the deployment-tier gating policy
(chapter 06 of this module), the change-management gates,
and the accepted-risk register.

**Evidence.** `policy/ai-ml-security.md` in the org's
policy repo; version-controlled; approval history recorded;
referenced from every design-review template.

### GOVERN 6.1 — Policies address AI risks from third-party software, data, and models

**Control.** Third-party AI supplier assessment programme
(mod-110). Every imported model, dataset, or hosted model API
is registered with its provenance, licence, and safety
disclosures. Suppliers of production-tier models must supply
a signed **AI supplier assessment** covering training data
provenance, safety evaluations, and incident-response
commitments.

**Evidence.** Supplier register with per-supplier assessment;
model card notes the imported artefacts and links to
supplier assessments; procurement gate blocks purchase
without an assessment.

### GOVERN 6.2 — Contingency processes handle third-party failures

**Control.** Named fallback path per imported dependency: a
second inference provider, a self-hosted alternative, a
degraded-service mode. Contract terms require notice of
model deprecation or safety recall.

**Evidence.** `governance/third-party-contingency.md`; the
runbook in mod-111 for third-party outage references the
fallback.

### Generative-AI additions (AI 600-1) that hit GOVERN

- **GV-1.3.001** — the org policy addresses GAI risks, not
  only traditional-ML risks (data leakage, hallucination,
  prompt injection, tool misuse, IP misuse, confabulation).
  The AI/ML security policy has a *generative-specific*
  section.
- **GV-4.1.001** — a channel for **downstream users** and
  **impacted third parties** to report generative-AI harms —
  jailbreaks discovered in production, defamatory outputs,
  IP-infringing outputs. Not just for internal engineers.

---

## MAP — the per-system framing

MAP sub-categories are answered *once per system* and re-
answered when scope changes materially. They anchor the
per-system record — who the users are, what the model does
and does not do, what could go wrong, how well the team
understands the domain.

Representative sub-categories:

### MAP 1.1 — Intended purposes, potentially beneficial uses, context-specific laws, norms and expectations are understood

**Control.** The **system card / model card** (mod-104
chapter 05). Its opening sections state the *intended use*,
the *out-of-scope uses*, the applicable jurisdictions and
domain norms.

**Evidence.** Model card `intended_use` and `out_of_scope_use`
fields; sign-off by product owner and legal.

### MAP 1.2 — Interdisciplinary AI actors, competencies, skills, and capacities for MAP are prioritized

**Control.** Design-review roster policy: MAP-stage reviews
require at least one domain expert (clinical for healthcare,
credit-risk for lending, security for security tooling) and
one AI-safety-literate reviewer. Named on the review record.

**Evidence.** Design-review roster; sign-off record names
the reviewers and their competencies.

### MAP 2.2 — Information about the AI system's knowledge limits and how outputs may be utilised is documented

**Control.** **Known-limitations register** on the model
card: training data cutoff, populations under-represented in
training, known failure modes, tasks the model is not
authorised for.

**Evidence.** `known_limitations` block on the model card;
per-limitation regression test in the evaluation suite
(mod-104 chapter 06) that keeps the limitation from silently
disappearing when someone claims the model has improved.

### MAP 3.1 — Potential benefits are examined; the risk of AI benefits being unevenly distributed is examined

**Control.** Impact assessment template: MAP-stage
deliverable that names beneficiaries, harmed parties, and
distributional considerations. For rights-affecting systems,
this ties into the EU AI Act **Fundamental Rights Impact
Assessment** (Article 27; see chapter 03).

**Evidence.** `impact-assessment.md` per system, versioned;
review sign-off.

### MAP 4.1 — Approaches for mapping AI risks are documented

**Control.** Threat model per system (mod-102). AI-specific
threat categories — poisoning, extraction, membership
inference, prompt injection, tool misuse, model theft — are
represented in the STRIDE-for-ML or LINDDUN-GO artefact.

**Evidence.** `threat-model.md` per system; review sign-off;
CI check that the threat model is not older than N months.

### MAP 5.1 — Likelihood and magnitude of each identified impact are evaluated

**Control.** Risk register per system: each identified
threat has an **inherent** and **residual** risk score after
controls are applied. Scoring rubric published in the policy
repo.

**Evidence.** `risk-register.yaml` per system; reviewed at
release-gate; residual risks above tier-set threshold
require accepted-risk sign-off from the accountable
executive.

### Generative-AI additions (AI 600-1) that hit MAP

- **MP-2.3.001** — the system's *capabilities* (task
  scope, output modalities, context length, tool access)
  and *limits* are enumerated in the system card. For
  agentic systems, the tool inventory and per-tool blast
  radius are named (see mod-107 chapter 03).
- **MP-3.4.001** — for GAI systems, the *misuse pathway*
  analysis names dual-use risks (bio/chem/cyber uplift,
  CSAM, non-consensual intimate imagery, defamation,
  copyright infringement, election-related misinformation
  where applicable).

---

## MEASURE — the per-system measurement

MEASURE sub-categories are the *evaluations* that back the
claims MAP made. If MAP says "we ship a fair model", MEASURE
is the fairness-metric report that quantifies the claim.

Representative sub-categories:

### MEASURE 1.1 — Approaches for measuring identified risks are selected

**Control.** Per-system **evaluation plan** naming, per
risk in the risk register, the metric, the dataset, the
frequency, and the threshold that triggers action.

**Evidence.** `eval-plan.yaml` per system; the ML CI runner
(mod-104 chapter 06) executes the eval and stores the
result versioned against the model artefact.

### MEASURE 2.1 — Test sets, metrics, and details about the tools used are documented

**Control.** Every metric produced has a **reproduction
recipe** — the exact eval dataset (hashed), the eval script
version, the environment. mod-104's lineage system holds
these pointers.

**Evidence.** Model card links to eval reproduction bundle;
eval bundle is content-addressable.

### MEASURE 2.7 — AI system security and resilience are evaluated and documented

**Control.** Security evaluation suite (mod-106) covering
robustness (adversarial-example accuracy under stated
threat model), extraction resistance (query-rate limits and
MI-AUC), and generative-specific evals (jailbreak resistance
via harm taxonomy; mod-107 chapter 04). Results carry a
**date, model version, and reviewer**.

**Evidence.** `security-eval.json` per model version;
governance dashboard renders trend; regressions above tier-
set threshold block release (chapter 04).

### MEASURE 2.8 — Risks associated with transparency and accountability are examined and documented

**Control.** Model card completeness audit: automated check
that every required field is present and not empty; manual
audit sampled quarterly on a random subset of production
models.

**Evidence.** CI report of missing fields; audit sample
records.

### MEASURE 2.9 — The AI model is explained, validated, and documented

**Control.** For models where post-hoc explanation is
tractable (tabular classifiers, small NNs), a saved SHAP /
LIME / attention explanation for a fixed benchmark of
example inputs; for models where it is not (large LLMs), an
explicit *explainability limitations* section on the model
card describing what can and cannot be explained and what
compensating controls (chapter 04's human oversight) apply.

**Evidence.** Explanation artefacts committed alongside the
model version; limitations block on the model card.

### MEASURE 2.10 — Privacy risk of the AI system is examined and documented

**Control.** DP budget claim + MI-AUC + DLP coverage from
mod-108 chapters 01–03; reflected as evidence on the model
card.

**Evidence.** Model-card `privacy` block; per-run privacy
packet (mod-108 chapter 01).

### MEASURE 2.11 — Fairness and bias are evaluated and results are documented

**Control.** Per-system fairness plan: chosen fairness
definition (demographic parity, equalised odds, calibration
across groups, disparate impact), protected attributes,
threshold, and stratified evaluation on the eval dataset.

**Evidence.** `fairness-report.json` per model version;
governance dashboard trend; regressions block release.

### MEASURE 3.1 — Approaches used to identify AI risks are commensurate to residual risk

**Control.** Tiering policy: the eval budget scales with
the deployment tier (chapter 06). Tier-3 systems get red-
team evaluation and third-party review; tier-1 systems get
automated eval only.

**Evidence.** Tier assignment recorded; eval bundle
composition matches tier.

### MEASURE 4.1 — Risk tracking approaches consider social and organizational context

**Control.** Post-market monitoring runbook: production
metrics that watch for drift, novel failure modes, harmful
outputs, complaints from users. Ties into EU AI Act Article
72 (chapter 03) and to mod-111.

**Evidence.** Runbook exists; monitoring dashboards live;
incident-response has trained on the runbook.

### Generative-AI additions (AI 600-1) that hit MEASURE

- **MS-2.6.001** — dangerous-capabilities evals for GAI:
  test the system's ability to produce content in high-risk
  categories (bio/chem/cyber uplift, CSAM, targeted
  harassment). Score against a published threshold. For
  frontier-tier systems, this ties into the RSP-style
  gating in chapter 06.
- **MS-2.7.006** — prompt-injection and jailbreak
  resistance evaluated per model version against a curated
  attack set; regression policy defined.
- **MS-2.11.001** — bias evaluation extended to *generative
  outputs* (representation across demographics, stereotype
  reinforcement in generations, sentiment-by-group deltas),
  not only classifier-style parity metrics.

---

## MANAGE — the per-system decision

MANAGE closes the loop. MEASURE produces numbers; MANAGE
decides what to do with them — accept, mitigate, defer,
retire.

Representative sub-categories:

### MANAGE 1.1 — A determination is made whether the AI system meets its purpose and stated risks are acceptable

**Control.** **Release-gate decision record**. At each
release, an accountable owner records the deployment
decision citing the risk register, the eval results, and
any accepted risks.

**Evidence.** `release-decisions/<system>/<version>.md`
signed by named owner; content-addressable; reviewed at
each release.

### MANAGE 1.3 — Responses to AI risks are prioritized, planned, tested, and documented

**Control.** Risk-response backlog integrated with the
engineering roadmap. Every open risk above threshold has a
target close date and an owner; risks that will not be
closed have accepted-risk sign-off.

**Evidence.** Backlog is queryable; SLO for close time
tracked; accepted-risk register audited quarterly.

### MANAGE 2.1 — Resources to sustain AI risk management are allocated

**Control.** Budget line item for AI safety / security
engineering; team roster and headcount published.

**Evidence.** Budget artefact; headcount roster; renewed
annually.

### MANAGE 2.3 — Post-deployment monitoring plans are implemented

**Control.** Live monitors per risk: drift, jailbreak
attempts, safety-classifier hits, unusual query patterns,
tool-call abuse (mod-107 chapter 03). Alerts route to the
incident-response rotation (mod-111).

**Evidence.** Monitors live; alert history in the incident
tracker; on-call has practiced the runbook.

### MANAGE 2.4 — Mechanisms are in place to supersede, disengage, or deactivate AI systems

**Control.** **Kill-switch** (feature flag or equivalent)
to disable each production ML system, invocable by the on-
call rotation without an engineering change. Documented in
the runbook.

**Evidence.** Kill-switch tested at least quarterly in a
game-day; runbook step includes the switch; time-to-disable
measured.

### MANAGE 3.1 — AI risks from third-party resources are managed

**Control.** Ongoing supplier monitoring — supplier releases
a new model, changes safety-mitigation posture, or
experiences a security incident → supplier assessment is
re-run and downstream impact assessed.

**Evidence.** Supplier assessment history; re-review
triggers recorded; downstream impact notes.

### MANAGE 4.1 — Post-deployment monitoring includes mechanisms for user, third-party, and impacted-community input

**Control.** External-user reporting channel for harmful
model behaviour; abuse-report intake; complaint SLA.

**Evidence.** Channel exists; ticket volume tracked;
resolution-time SLA measured.

### Generative-AI additions (AI 600-1) that hit MANAGE

- **MG-2.4.001** — for GAI, the disengagement mechanism
  includes the ability to disable *specific dangerous
  capabilities* (a mode that blocks the model from
  generating in category X) without full deactivation.
  Enterprise deployment tiers (chapter 06) name which
  capabilities are gated per tier.
- **MG-4.1.001** — content-provenance mechanisms
  (watermarks on generated media, per-response
  provenance metadata) are deployed where technically
  feasible; where not, the limitation is documented.

---

## The unified matrix — the artefact this chapter produces

The deliverable of this chapter is a **control-mapping
matrix**. One row per sub-category the org has decided is in
scope; columns for outcome, control-what, control-where,
control-owner, evidence-artefact, evidence-verification, and
review-cadence.

A workable schema (YAML; check into the platform's governance
repo):

```yaml
version: 2026.09
review_cadence: quarterly

controls:
  - id: NIST-AI-RMF.GV-1.1
    function: GOVERN
    subcategory_outcome: >
      Legal and regulatory requirements involving AI are
      understood, managed, and documented.
    control:
      what: >
        Per-system regulatory-scope register naming every
        statute, regulation, standard, and contractual
        clause that applies.
      where:
        - service-registry annotation `regulatory_scope`
        - governance/scope-register.yaml
      owner: DPO
    evidence:
      artefact: governance/scope-register.yaml
      verification: >
        CI job fails if `regulatory_scope` annotation missing
        on production-tier services; DPO quarterly review.
    generative_delta: >
      For GAI systems, the register also names AI-Act Annex
      III category (if any) and RSP-tier gating (chapter 06).
    cross_refs:
      iso_42001: [4.1, 4.2]      # chapter 02 fills these
      eu_ai_act: [9, 10]         # chapter 03
      soc_2: [CC1.4, CC3.2]      # chapter 05
      sector: [SR-11-7.III.2]    # chapter 05

  - id: NIST-AI-RMF.MP-4.1
    function: MAP
    ...
```

The matrix is **the single source of truth** the rest of
this module extends:

- **Chapter 02** fills the `iso_42001` cross-ref column.
- **Chapter 03** fills the `eu_ai_act` column.
- **Chapter 04** authors OPA/Rego policies that enforce the
  evidence-verification field at admission time.
- **Chapter 05** fills the `soc_2` and `sector` columns.
- **Chapter 06** attaches deployment-tier gating (RSP / PF /
  FSF adaptations) to the applicable MEASURE and MANAGE
  rows.

The matrix is versioned. Each version has a review-cadence
line; each review renews the accuracy of the mapping and
adds new rows for framework updates (AI RMF v1.1, new AI
600-1 revisions, new sector regs).

---

## What "adopted the AI RMF" means

The framework is **outcome-oriented**, so "adopted" is a
scaled claim, not a binary. Useful discrimination:

- **Level 0 — read.** The org has downloaded the document.
  Not a claim.
- **Level 1 — mapped.** Every sub-category has been
  reviewed; in-scope subset has been chosen and rationale
  recorded. The unified matrix has at least a `control` row
  per in-scope sub-category.
- **Level 2 — evidenced.** Every in-scope sub-category has
  an evidence artefact that actually exists (a file, a
  metric, a runbook), and that artefact is verifiable at
  the frequency named in `review_cadence`.
- **Level 3 — enforced.** The controls are enforced at
  admission (chapter 04) — missing evidence blocks
  deployment; drift produces alerts.
- **Level 4 — audited.** The matrix is externally reviewed
  (SOC 2 audit, ISO 42001 stage-2 audit, sector regulator
  examination) at a stated cadence.

A programme should be honest about which level it is at
for which sub-category. Different sub-categories legitimately
sit at different levels; a serious posture is one where the
gap between Level 1 and Level 3 has a written closing plan.

---

## Standard failure modes

- **Sub-category adopted, evidence undefined.** The row
  exists in the matrix; the `evidence.artefact` field
  reads "TBD". The control is aspirational. Fix: the
  matrix schema requires `evidence.artefact` to point at a
  real path.
- **Adoption without ownership.** No named human owns the
  control. Fix: `control.owner` is required; "governance
  team" is not acceptable.
- **Evidence with no verification.** The artefact exists
  but there is no automated or scheduled check that it is
  current. Fix: `evidence.verification` is required and is
  either a CI job identifier, a monitor identifier, or a
  named review cadence with an owner.
- **GOVERN theatre.** A one-time policy is written and
  filed; there is no ongoing operation. Fix: GOVERN rows
  have `review_cadence` and a named reviewer; failure to
  review is tracked.
- **MAP treated as one-time.** The threat model, model
  card, and risk register are written at v1 and never
  updated. Fix: material scope change triggers re-MAP; CI
  fails when MAP artefacts are older than N months without
  explicit sign-off.
- **MEASURE as a snapshot.** Metrics generated once at
  release; drift not tracked. Fix: MEASURE runs on a
  cadence tied to production traffic; regressions alert.
- **MANAGE by omission.** No kill switch, no accepted-risk
  register, no third-party contingency. Fix: MG rows are
  release-gate blockers, not decorative.
- **Generative-AI additions ignored.** AI 600-1 delta
  applied only to "the LLM team"; classical-ML rows
  unchanged. Fix: the delta is applied wherever the system
  has generative capability, including retrieval-augmented
  classifiers and hybrid systems.
- **Matrix that is not the source of truth.** A separate
  compliance database or GRC tool duplicates the matrix
  and drifts. Fix: one system of record; other tools
  reference it.

---

## Summary

- The **AI RMF** is a function-and-outcome framework: four
  functions (GOVERN, MAP, MEASURE, MANAGE), each a set of
  sub-categories phrased as outcomes.
- Every sub-category adopted must be a **triple** — outcome,
  control, evidence — and every control must have an
  **owner** and a **verification method**.
- **GOVERN** is the standing programme. **MAP** frames each
  system. **MEASURE** quantifies the risks named in MAP.
  **MANAGE** decides what to do.
- The **AI 600-1 Generative AI Profile** adds generative-
  specific sub-categories; treat them as deltas applied to
  each of the four functions, not a separate framework.
- The **unified control-mapping matrix** — one row per in-
  scope sub-category with cross-refs to ISO 42001, EU AI
  Act, SOC 2, and sector regs — is the artefact this
  module produces and chapters 02–06 extend.
- **Adoption is scaled**, not binary. Level 1 (mapped) is a
  reasonable starting posture; Level 3 (enforced at
  admission) is where policy-as-code (chapter 04) lands the
  matrix in the platform.
