# Exercise 05 — Sector-Reg and RSP Adaptation Map

**Estimated effort:** ~3 hours
**Deliverable:** A **sector-and-tier overlay** that closes the
unified matrix, consisting of (a) SOC 2 Trust Services Criteria
mapped onto the exercise-01/02 matrix as a new column, (b) one
sector regime of the student's choice — SR 11-7, FDA GMLP /
PCCP, or HIPAA Security Rule — mapped as a second column, (c)
an enterprise deployment-tier policy adapted from the frontier
frameworks (Anthropic RSP, OpenAI Preparedness, DeepMind FSF)
with ≥ 3 tiers defined and the exercise-01 system placed in
one, (d) the admission-gate hook for tier transitions wired
into the exercise-04 policy pack, and (e) a short safety-case
narrative for the system at its chosen tier.
**Prerequisites:** Exercises 01–04 complete; the matrix carries
NIST + ISO + EU AI Act columns and the stub `cross_refs.soc2`,
`cross_refs.sector`, and `cross_refs.deployment_tier` keys
ready to populate; chapter 05 and chapter 06 read end-to-end;
mod-110 chapter-06 supplier register (if available) because
the sector overlays depend on it; mod-107 chapter 03 (tier /
HITL patterns) and mod-108 chapter 03 (DLP / PII handling)
feed the HIPAA and GMLP overlays specifically.

---

## Objective

Chapters 05 and 06 close the module's claim: **one control
library; multiple cross-references; one deployment-tier
discipline**. This exercise is the one that produces the
cross-referenced matrix and the tier policy the rest of the
programme operates against.

By the end of this exercise you have:

- A **SOC 2 column** on the matrix mapping every row touched
  by SOC 2 Common Criteria to the relevant TSC reference.
- A **sector column** populated with one of SR 11-7, FDA
  GMLP/PCCP, or HIPAA; the choice justified by the system
  under test.
- An **enterprise deployment-tier taxonomy** with ≥ 3
  defined tiers (not six — three is the minimum useful
  working set for an exercise), each tier carrying its
  capability description, its evaluation bundle, its
  required controls, and its sign-off body.
- The exercise-01 system **classified** into a tier with a
  written reasoning note.
- A **tier-transition admission gate** added to the
  exercise-04 policy pack (or named as a stretch item for
  the pack) that enforces tier TTLs and re-tier triggers.
- A **safety-case narrative** for the system at its chosen
  tier: the chapter 06 analogue of a frontier-lab safety
  case.
- A **mapping note** that calls out where the three
  frontier frameworks' concepts translate directly, where
  they translate loosely, and where they do not translate
  at all.

You are **not** adopting a sector regime wholesale, applying
for FedRAMP or HITRUST certification, or publishing a
Responsible-Scaling-Policy-equivalent as an org commitment.
You are producing the engineering map and the tier scaffold.

---

## Problem statement

The target is the exercise-01 system. State before you start:

- Whether the system falls under a sector regime at all
  today, and which one makes sense to overlay. Heuristics:
  - If the system touches **PHI** or runs for a healthcare
    customer: HIPAA Security Rule.
  - If the system runs for a **US-federally-supervised
    bank** and feeds a decision used for regulatory
    purposes (credit, capital, stress testing): SR 11-7.
  - If the system is **medical device software** (SaMD) or
    a clear candidate for medical-device marketing: FDA
    GMLP / PCCP.
  - If none of the above: pick the regime whose discipline
    is most useful to practise. HIPAA is the most
    commonly encountered; SR 11-7 is the most structurally
    different from the previous exercises; FDA GMLP/PCCP
    is the most forward-looking.
- The SOC 2 scope the organisation already attests to (if
  any) — Common Criteria only, Common + Confidentiality,
  Common + Confidentiality + Privacy, etc.
- The chapter-06 tier the system is **expected** to land in
  (pre-exercise hypothesis). The exercise then confirms or
  revises the hypothesis.

If the exercise-01 system is Tier 0 (deterministic classical
ML) and the org has no generative deployments at all, pick a
Tier 1–4 hypothetical for this exercise so the tier taxonomy
has substance to grip. State the choice.

---

## Requirements

### Deliverable A — SOC 2 overlay column

Walk the matrix. For every row, populate
`cross_refs.soc2`. Shape:

```yaml
cross_refs:
  soc2:
    criteria: ["CC3.2", "CC7.4"]      # TSC references
    optional_categories: ["C"]        # if Confidentiality / Privacy relevant
```

Required mappings (at minimum):

- **CC1 (Control Environment).** The AI/ML policy and the
  RACI (GV-5.1 and GV-2.1) land here.
- **CC2 (Communication and Information).** Downstream-user
  harm reporting (chapter 01 GAI overlay); logging-spec
  distribution.
- **CC3 (Risk Assessment).** The AI risk register (MP-5.1).
- **CC4 (Monitoring).** Post-market monitoring (Article
  72); eval regression suite.
- **CC5 (Control Activities).** The admission gates from
  exercise 04.
- **CC6 (Logical and Physical Access).** Workload identity;
  model-registry access (mod-103); KMS binding (mod-105).
- **CC7 (System Operations).** Change management; incident
  response; monitoring; decision retention from exercise 04.
- **CC8 (Change Management).** Model-registry promotion
  policy; deployment-tier transitions.
- **CC9 (Risk Mitigation).** Supplier assessment programme
  (mod-110); third-party / GPAI attestations (chapter 06).
- **Confidentiality (C1).** Confidential-data controls for
  training data and prompt logs.
- **Privacy (P)** — if the SOC 2 Privacy criteria are in
  scope: mapping to mod-108 artefacts.

Add rows if an SOC 2 criterion is not covered by any existing
matrix row — e.g. a specific CC7.3 (evaluation of events)
pattern. Each new row carries owner, artefact, verification,
and status.

### Deliverable B — sector overlay column

Walk the matrix again with the sector-regime lens. Populate
`cross_refs.sector`.

#### If SR 11-7:

```yaml
cross_refs:
  sector:
    regime: SR 11-7
    sections: ["III.A", "III.B"]  # Development/Implementation/Use + Validation + Governance
    pillar: validation            # development / validation / governance
```

Required mappings:

- **Pillar 1 — Development, implementation, and use.** Model
  purpose, assumptions, data lineage. Lines up with MP-1.1,
  MP-5.1, and data-governance rows.
- **Pillar 2 — Validation.** Independent, effective
  challenge; evaluation suite; benchmark comparator; ongoing
  monitoring. Lines up with MS-* rows.
- **Pillar 3 — Governance.** Model inventory; policies;
  roles including model-risk officer; audit; board
  reporting. Lines up with GV-2.1, GV-5.1, GOVERN rows.

Add any new rows the SR 11-7 walk surfaces: model inventory
field schema; challenger-model requirement; "effective
challenge" record.

#### If FDA GMLP / PCCP:

```yaml
cross_refs:
  sector:
    regime: FDA GMLP + PCCP
    gmlp_principles: [1, 3, 5, 7, 9]       # the ten guiding principles
    pccp_section: performance_monitoring   # for change-control plans
```

Required mappings:

- **GMLP 1 (multi-disciplinary expertise)** — matrix review
  roster; cross-ref GV-3.2.
- **GMLP 3 (clinical study participants and data sets are
  representative of intended population)** — Article 10
  data-governance dossier bridge.
- **GMLP 5 (gold-standard reference)** — eval plan (MS-1.1).
- **GMLP 7 (performance of human-AI team)** — Article 14
  human-oversight record bridge.
- **GMLP 9 (users are provided clear, essential
  information)** — labelling, instructions-for-use.

If the system has a **predetermined change control plan
(PCCP)** — rare outside explicit SaMD — add rows for the
PCCP scope definition and the modification protocol.
Otherwise, note that the system is not under a PCCP and the
"planned modifications" column is `n/a`.

#### If HIPAA Security Rule:

```yaml
cross_refs:
  sector:
    regime: HIPAA Security Rule
    section: 164.312
    standard: audit_controls           # access_control / audit_controls / integrity / transmission_security
    implementation_specification: required
```

Required mappings:

- **§ 164.308(a)(1) — Security management process.** Risk
  analysis; sanction policy; information-system activity
  review. Lines up with GOVERN rows and the mod-111 incident
  posture.
- **§ 164.308(a)(5) — Security awareness and training.**
  Clause 7.3 awareness bridge.
- **§ 164.308(a)(8) — Evaluation (periodic technical and
  non-technical evaluation).** Internal-audit programme from
  exercise 02.
- **§ 164.310 — Physical safeguards.** Cloud-provider SOC 2
  reliance; cross-ref CC6.
- **§ 164.312(a)(1) — Access control.** Workload identity,
  unique user identification, emergency access, automatic
  logoff.
- **§ 164.312(b) — Audit controls.** The exercise-04
  decision retention, model-serving audit log, Article 12
  logging-spec bridge.
- **§ 164.312(c)(1) — Integrity.** Model-signing, audit-log
  integrity.
- **§ 164.312(e)(1) — Transmission security.** mTLS, model-
  serving transport.
- **§ 164.316(b)(2)(i) — Retention of documentation.** Six
  years; aligns with the exercise-04 decision-retention
  design.

### Deliverable C — enterprise deployment-tier taxonomy

A `governance/deployment-tiers.yaml` with ≥ 3 tiers defined.
Minimum useful set — Tier 1 (bounded generative or
deterministic ML), Tier 3 (tool-using low-blast), Tier 4
(tool-using high-blast). Each tier carries:

```yaml
tiers:
  "1":
    capability: >
      Foundation model or hosted API; text in / text out;
      no tools; public or non-sensitive data only.
    examples: [customer-support Q&A over public docs]
    required_evals:
      - name: prompt_injection
      - name: output_safety_classifier
      - name: hallucination_rate
    required_controls:
      - input_validation
      - output_safety_gate
      - prompt_log_dlp
      - rate_limit
      - kill_switch
    sign_off: [ml_governance_lead, product_owner]
    tier_ttl_days: 365
    re_tier_triggers:
      - new tool added
      - retrieval source added
      - base model updated
      - prompt template materially changed
  "3":
    capability: >
      Model + tools; each tool has bounded, reversible blast
      radius (read-only queries, ephemeral sandbox, non-
      destructive writes).
    examples: [sandboxed code interpreter; public-web browsing]
    required_evals:
      - name: prompt_injection
      - name: indirect_prompt_injection
      - name: tenant_isolation
      - name: retrieval_integrity
      - name: tool_abuse_redteam
      - name: sandbox_escape
    required_controls: [tier_1_controls, tool_acls, per_tool_rate_limit, per_tool_action_log, sandbox_monitoring, hitl_on_notable]
    sign_off: [tier_3_review_board]
    tier_ttl_days: 180
  "4":
    capability: >
      Model + tools with irreversible or material blast
      radius (production writes, external communications,
      financial transactions, regulated data).
    examples: [email-triage with send; DevOps agent with deploy]
    required_evals:
      - name: capability_elicitation_composed_tools
      - name: adversarial_multi_turn
    required_controls: [tier_3_controls, hitl_material_actions, scoped_credentials, egress_control, dual_signoff, capability_disable_hooks]
    sign_off: [tier_4_review_board]
    tier_ttl_days: 180
    external_review: required
```

### Deliverable D — tier placement for the exercise-01 system

A short note (`tier-placement.md`) stating:

- The hypothesised tier the system falls into.
- The reasoning — which tier's capability description best
  fits the system's actual behaviour; which tool / data /
  blast-radius facts drove the choice; which tier
  immediately above and below were considered.
- The required-evals the system has run and the results;
  the required-controls currently implemented vs
  outstanding.
- The sign-off body that owns the tier assignment.
- The TTL; the next review date; the re-tier triggers that
  would move the system up or down.

### Deliverable E — tier-transition admission gate

A new Rego policy (`aicg.controls.deployment_tier_integrity`)
or an extension of the exercise-04 `deployment_tier_gate`,
that enforces:

- The system's declared `tier` matches the capability facts
  on the input (e.g., has tools but declares Tier 1 → deny).
- The required-evals bundle for the tier is referenced and
  current.
- The required-controls are present on the deployment.
- The tier assignment is less than TTL days old.
- The sign-off body named for the tier has signed the
  current assignment.

Tests cover: happy path at each defined tier; deny on
capability-fact mismatch; deny on expired tier assignment;
deny on wrong sign-off body; abstain on Tier 0 /
deterministic ML.

If deferring the policy to the next sprint, document the
check as a `planned` row on the matrix with the owner and
target date; do not pretend it exists.

### Deliverable F — safety case narrative

A one-to-two-page narrative (`safety-case.md`) following a
template like:

- **Claim.** "This system at Tier *N* is deployable because
  the capabilities it has are bounded by the controls
  listed, the evaluations we ran provide evidence the
  bounds hold, and the oversight body named has reviewed
  and accepted the residual risk."
- **Context.** One paragraph on the system, its intended
  use, and the capabilities relevant to the tier.
- **Capability characterisation.** For each capability axis
  the frontier frameworks care about — autonomy; tool-use
  reach; data-access reach; persuasion / social manipulation
  surface — a stated bound and the mechanism enforcing it.
- **Evidence.** For each bound, the eval or control that
  provides evidence. Include failure modes considered and
  rejected.
- **Governance.** The sign-off body, the review cadence,
  the capability-disable hook, the kill-switch.
- **Caveats.** What this safety case does not cover; what
  future capability growth would require the safety case
  to be re-written.

The safety case is a chapter 06 frontier-framework
analogue: a written argument, not a checklist. Reviewers
read it and decide whether they are convinced.

### Deliverable G — frontier-framework translation note

A short note (`rsp-translation.md`) stating, for the chosen
tier taxonomy:

- Which **frontier-framework concept** each tier maps to —
  "Tier 3 is the enterprise analogue of OpenAI Preparedness
  Medium capability", "Tier 4 is the enterprise analogue of
  Anthropic ASL-3 deployment safeguards" (or the corollary
  as understood at the time of writing).
- Which concepts **do not translate**: the frontier labs'
  concern with training-run-level thresholds does not apply
  if the org only deploys imported models; the labs' public-
  disclosure commitments do not apply enterprise-side.
- Which concepts **translate loosely**: the labs' expert
  elicitation process maps to the Tier 4 external-reviewer
  requirement, but the enterprise substitutes contracted
  external red-teamers for the labs' in-house safety
  teams.
- A one-paragraph **borrowed-posture** statement — what the
  org adopts verbatim and what it adapts.

### Deliverable H — matrix close-out

Walk the matrix one last time. The SOC 2 + sector + tier
columns should be populated on every row the overlays
touch. Any row that still has `cross_refs.*: null` after
all five exercises either explicitly does not apply to that
regime (annotate with a note) or is a gap for a successor
exercise (annotate with the gap note).

Run the Deliverable F validator from exercise 01 (updated to
include the new columns) and attach the pass / fail output.

---

## Starter guidance

- **Pick the sector regime where you have the strongest
  working context.** The exercise is more valuable if the
  overlay is one you can defend to a sector auditor.
- **Three tiers is a sufficient taxonomy for the
  exercise.** Chapter 06's six-tier scheme is a reference;
  the exercise's three is the minimum useful working set.
- **For SOC 2, do not over-map.** Many TSC rows do not
  need an ML-specific extension — the generic SaaS SOC 2
  posture covers them. Flag the rows that need an ML
  extension and leave the rest.
- **For the sector regime, write one representative row in
  depth before mapping the rest.** Pick a single SR 11-7
  pillar (validation), a single GMLP principle (clinical
  representativeness), or a single HIPAA § 164.312
  standard (audit controls); walk it row-by-row with full
  cross-refs and remediation; then batch-map the remaining
  rows in a lighter pass.
- **The safety case is the hardest deliverable.** Writing
  it after the tier placement is the natural order; writing
  it under time pressure produces a slide deck instead of
  a narrative. If the time budget runs out, flag the safety
  case as `partial` and name the dates by which it will be
  completed.
- **Use the chapter-06 Enterprise Tier 0–5 table as a
  reference, not a template.** Rename and renumber tiers if
  the org already has a different tier taxonomy.

---

## Acceptance criteria

A passing overlay:

- Every matrix row touched by SOC 2 Common Criteria carries
  the TSC reference(s); the mapping covers CC1 through CC9.
- Sector regime chosen with justification; every matrix row
  touched by the regime carries the regime's section /
  principle / clause; new rows added where the regime
  surfaces an obligation not previously in the matrix.
- Deployment-tier taxonomy has ≥ 3 tiers; each tier names
  capability, examples, required evals, required controls,
  sign-off body, TTL, re-tier triggers.
- Exercise-01 system placed in a tier with a reasoning note
  that considers adjacent tiers.
- Tier-transition admission gate authored (or named as a
  `planned` matrix row with owner and date).
- Safety-case narrative produced; argues capability bounds
  with evidence; names governance and caveats.
- Frontier-framework translation note identifies direct,
  loose, and non-translating concepts.
- Matrix validator passes on all five columns (NIST, ISO,
  EU AI Act, SOC 2, sector) with the new tier field.

A failing overlay:

- SOC 2 mapping that marks every row as "CC7" because
  CC7 is big — the mapping has to be specific.
- Sector mapping that cites section numbers without
  stating what the section requires in engineering terms.
- Tier taxonomy that is two tiers (allowed / denied) — the
  entire point of the chapter 06 pattern is capability-
  level step-change.
- Tier placement with no reasoning for why the system is
  not the next-tier-up.
- Safety case that reads as marketing — the point is
  argument with evidence.
- Translation note that claims the enterprise framework "is
  equivalent to" a frontier framework. Frontier frameworks
  are published commitments on frontier-scale training;
  enterprise frameworks are deployment-tier policies. They
  are relatives, not twins.

---

## Stretch goals

- **Second sector overlay.** Add a second sector regime to
  the matrix (e.g. HIPAA + SR 11-7 if the system straddles
  healthcare and finance). Produces the "one control
  library; multiple regimes" posture in its sharpest form.
- **GDPR + SOC 2 Privacy join.** Add the SOC 2 Privacy (P)
  criteria to the matrix with mod-108 chapter 04 cross-
  refs. Lines up directly for a dual-attestation.
- **State / country overlay.** Add a US-state or
  non-EU-country AI-governance rule to the matrix (e.g.
  Colorado AI Act, California AB-2273, UK AI framework
  response). Flags the heterogeneous-state problem the EU-
  only mapping obscures.
- **Model-inventory tooling.** Produce the schema and a
  starter spreadsheet / database for the SR 11-7 model
  inventory. Includes model purpose, risk tier, owner,
  validator, last-review date, next-review date.
- **FDA pre-submission checklist.** If the sector regime
  is FDA GMLP / PCCP, produce the one-page checklist the
  team would walk through before filing a 510(k) or De
  Novo pre-submission for the system — what the Q-sub
  package would include.
- **HIPAA BAA checklist.** If the sector regime is HIPAA,
  produce the per-cloud-service checklist of BAA-required
  services actually used by the system; flag any service
  used that is not on the cloud provider's BAA-eligible
  list. Lines up with mod-105 and mod-108.
- **Review-board charter.** A one-page charter for the
  Tier 4 (or chosen top-tier) review board naming its
  membership, quorum, decision rights, escalation path,
  and public-reporting commitments (if any).
- **Capability-disable rehearsal.** A tabletop exercise
  (one page of scenario + script) for the capability-
  disable hook. Produces the exercise record the next
  management review (Clause 9.3) and chapter 06 review
  board can reference.
- **Enterprise-RSP commitment draft.** For organisations
  willing to publish, draft the enterprise analogue of a
  Responsible Scaling Policy — the if-then commitments the
  org makes about capability levels in its own deployed
  systems. Mark clearly as draft; publication requires
  executive and legal sign-off.

---

## Do not

- Do not rename frontier-framework concepts and call it
  equivalence. The enterprise tier policy is adapted from,
  not identical to, Anthropic RSP / OpenAI Preparedness /
  DeepMind FSF. Clarity about the delta is a feature of the
  translation note, not a flaw.
- Do not sign an enterprise-RSP commitment without executive
  authority. Public commitments bind the organisation; the
  draft is an engineering exercise.
- Do not treat SOC 2 as the ML overlay. SOC 2 is the SaaS
  overlay; the ML extensions sit on top. If the sector
  mapping collapses into SOC 2, the sector regime is being
  under-served.
- Do not fake a safety case. If the required evaluations
  have not been run, the safety case is a *proposal* for
  what the evaluations would show, not evidence. Label it as
  a proposal.
- Do not place the system in a lower tier because the
  controls for the higher tier are expensive. The tier
  policy's point is that capability drives controls, not
  the other way around; cheating produces real risk.
- Do not overload the review board. If every system in the
  org requires Tier 4 sign-off, the review board becomes a
  rubber stamp. The tier policy should concentrate
  attention on the systems that need it.
- Do not commit the solution overlay to this repo. Solutions
  live in the paired `-solutions` repo.
