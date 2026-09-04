# Chapter 06 — Frontier-Lab Deployment-Tier Gating for Enterprise Systems

> **Note on AI-assisted content.** The three frontier-lab
> frameworks discussed — Anthropic's **Responsible Scaling
> Policy (RSP)**, OpenAI's **Preparedness Framework**, and
> Google DeepMind's **Frontier Safety Framework (FSF)** — are
> published, versioned commitments by frontier-model
> developers. Each has been revised multiple times since
> introduction. Verify the current published versions
> (see [`resources.md`](./resources.md)) before quoting a
> specific threshold, capability level, or evaluation
> protocol to an internal review board or an external party.

---

## Why this chapter exists

The regulations in chapters 01–05 answer *what a deployed
system must ship with*. They largely assume the system is
already at a defined risk level. The frontier-lab
frameworks answer a different question: **what capability
does this system have, and at what capability threshold do
new controls become mandatory?**

For an enterprise, the framing translates. Most enterprise
teams are not training frontier models — they are deploying
purchased or hosted foundation models, sometimes with
fine-tuning, into product surfaces. The failure mode this
chapter prevents:

> The team is rolling out an internal LLM-powered assistant.
> Version 1 is a chat-only Q&A over a public knowledge base;
> version 3 is a code-writing assistant with shell tool
> access on developer machines; version 5 is a browser-tool-
> using research assistant that can transact on the corporate
> banking portal. Each version ships through the same
> generic ML release process. The controls that gate v1 are
> the controls that gate v5. Nobody sat down and asked
> "what changed in the risk between v1 and v5, and what
> should have gated the step-change?"

Frontier labs have this problem in a form the whole industry
is watching: what happens when a training run produces a
model materially more capable than the last one, and at
what point do the safety controls need to *step up* rather
than *linearly extend*? Their answer — capability tiers with
tier-specific safeguards — is directly reusable inside
enterprise deployment.

You leave this chapter able to:

- Summarise the three frontier-lab frameworks (Anthropic
  RSP, OpenAI Preparedness Framework, DeepMind FSF) and
  the shared shape they converge on.
- Adapt tier-gating into an **enterprise deployment-tier
  policy** covering purchased and hosted models, fine-tunes,
  and agentic capabilities.
- Author the **tier taxonomy** the org uses — what each
  tier can do, what evaluations gate it, what controls are
  required, who signs off.
- Tie the tier policy to chapter 04's admission gates so
  tier violations are enforced at deployment.
- Recognise the limits of borrowing from frontier
  frameworks — where the analogy breaks and enterprise
  controls have to fill in.

---

## The frontier frameworks in one page each

The three frameworks converge on a common shape:

- **Capability categories** — the axes along which the
  model's dangerous or high-consequence capability is
  measured. Frontier labs share a rough consensus:
  bio/chem weapons uplift, cybersecurity uplift, autonomy
  (self-exfil, replication, long-horizon agentic action),
  and (varyingly) persuasion / manipulation, CBRN more
  broadly, AI R&D acceleration.
- **Threshold levels** — points on each axis at which
  additional controls become mandatory. RSP calls them
  ASL levels; Preparedness Framework calls them
  Preparedness Levels or capability levels (Low, Medium,
  High, Critical); FSF calls them Critical Capability
  Levels (CCLs).
- **Evaluations** — the tests that determine whether a
  model has reached a threshold. Combination of automated
  benchmarks, red-team probes, and structured expert
  elicitation.
- **Required safeguards per level** — safeguards that
  become mandatory *before* a model reaching that level
  can be trained further, internally deployed, or
  externally deployed.
- **Governance** — internal review board (Anthropic:
  Responsible Scaling Officer + board; OpenAI: Safety
  Advisory Group + board; DeepMind: Google/DeepMind
  responsible-development structure) that reviews
  evaluations and makes deployment decisions.

### Anthropic Responsible Scaling Policy (RSP)

Introduced September 2023; substantially revised October
2024 and subsequently. Core structure:

- **AI Safety Levels (ASL-1 through ASL-4+).** ASL-1
  models pose no meaningful catastrophic risk (small,
  narrow). ASL-2 covers current-generation frontier
  models (e.g., Claude family at time of RSP publication)
  with baseline safety mitigations. ASL-3 is triggered
  when a model shows capability that "substantially
  increases risk of catastrophic misuse" or "shows early
  signs of autonomous self-replication" — additional
  security and deployment safeguards required. ASL-4 (and
  higher) are anticipatory: reserved for models that
  would enable state-level actors to acquire mass-
  casualty capabilities, or that show substantially
  autonomous behaviour.
- **Capability thresholds.** For each ASL, a defined set
  of evaluations must be run; passing certain thresholds
  triggers the next ASL's requirements.
- **Safeguards.** Per ASL, a defined set of security
  controls (weights protection), deployment controls
  (misuse detection, hard refusal training, monitoring),
  and governance controls (review board approval,
  incident response, public disclosure commitments).
- **If-then commitment.** The RSP is *conditional*: "if
  we develop a model at ASL-N, we will apply the ASL-N
  safeguards *before* deploying or continuing training".

### OpenAI Preparedness Framework

Introduced December 2023; subsequently updated. Core
structure:

- **Tracked risk categories.** As of the framework's
  published version, categories include cybersecurity,
  CBRN (chemical, biological, radiological, nuclear),
  persuasion, and model autonomy; the framework enumerates
  more as capabilities emerge.
- **Capability levels per category.** Typically Low,
  Medium, High, Critical.
- **Score cards.** Per model, per category, a scorecard
  is produced using specified evaluations and expert
  judgement.
- **Deployment thresholds.** Only models scoring **Medium
  or below** post-mitigation can be deployed; only models
  scoring **High or below** post-mitigation can be
  developed further.
- **Governance.** Preparedness team runs evaluations;
  Safety Advisory Group reviews; leadership (and board's
  Safety and Security Committee) approve deployment
  decisions and can pause launches.

### Google DeepMind Frontier Safety Framework (FSF)

Introduced May 2024. Core structure:

- **Critical Capability Levels (CCLs).** Points at which
  a model's capability could pose severe risk in specific
  domains (autonomy, biosecurity, cybersecurity, machine-
  learning R&D). Each domain has multiple CCLs of
  escalating severity.
- **Early-warning evaluations.** Run periodically during
  training; designed to fire *before* a CCL is reached,
  so mitigations can be prepared.
- **Mitigations.** Per CCL, a defined set of security
  mitigations (weight-protection, training-data controls)
  and deployment mitigations (misuse-detection, output
  monitoring, restricted access).
- **Governance.** Internal review; the framework
  commits to publishing safety-case-style analyses for
  models that approach or exceed CCLs.

### The convergent shape

All three frameworks describe:

- An **assessment protocol** — specific evaluations run
  before deployment (and periodically during training) that
  score the model on defined capability axes.
- A **tier taxonomy** — levels of concern with named
  transition thresholds.
- A **mitigation matrix** — per tier, the mitigations
  required *before* the model can be deployed at that
  tier.
- A **governance body** — the accountable decision-maker
  who reviews the assessment and approves the tier
  assignment.
- A **conditional commitment** — the "if we develop a
  model at tier T, we will apply the tier-T mitigations
  before deployment".

The enterprise adaptation borrows every piece.

---

## Why an enterprise cares

An enterprise deployer of AI does not typically train
frontier models. But an enterprise deployer does:

- **Import capability** — every foundation model brought
  in from a supplier carries the supplier's capability
  posture. Deploying GPT-4-class or Claude-Sonnet-class
  systems into a corporate workflow is deploying that
  capability level into the corporate risk surface.
- **Extend capability** — fine-tuning, retrieval
  augmentation, and tool-integration all *add* capability
  to a base model. A base model that cannot execute code
  becomes a base-plus-tool system that can. A base model
  that cannot access customer records becomes a base-plus-
  retrieval system that can.
- **Compose capability** — agentic systems with multiple
  tools, planning loops, and long-horizon action are the
  enterprise version of the "autonomy" axis frontier labs
  worry about. A model that can call `send_email`, read
  its own drafts, and iterate has agency the base model
  does not.

The enterprise question is: **what is the deployment tier
for this system, and what controls does that tier require?**

Framing this as tiers rather than binary "safe/unsafe":

- Version 1 (chat-only, public knowledge) → Tier 1;
  minimal controls.
- Version 3 (code assistant with shell on developer
  machines) → Tier 2 or 3; substantial controls (HITL on
  execution of high-privilege commands, sandboxing,
  audit).
- Version 5 (browser-tool assistant, transactional
  access) → Tier 4; hard-gated (dual-signoff on
  transactional actions, per-action approval, hard-
  isolated network, full observability).

Each tier transition is a *review event*, not a routine
release. This is exactly the discipline the frontier
frameworks install.

---

## Designing the enterprise tier taxonomy

A workable schema. Adapt names and thresholds to the org.

### Tier 0 — Deterministic AI

- **Capability.** Small models, classical ML,
  deterministic classifiers; no generative capability.
- **Examples.** Fraud classifier, recommendation ranker,
  churn model.
- **Controls.** Standard ML platform controls (mod-101
  through mod-108). No LLM-specific overlay.
- **Sign-off.** ML Governance Lead.

### Tier 1 — Bounded generative AI

- **Capability.** Foundation model or hosted API. Text-
  in / text-out. No tools. Constrained output length.
  Public data or non-sensitive internal data only.
- **Examples.** Customer-support Q&A over public docs;
  internal knowledge chatbot on public-domain content.
- **Required evaluations.** Prompt-injection resistance
  (mod-107 chapter 04); output safety classifier
  coverage; hallucination-rate baseline.
- **Required controls.** Input validation, safety-
  classifier gate on outputs, prompt-log DLP, rate
  limits per caller, kill switch.
- **Sign-off.** ML Governance Lead + product owner.

### Tier 2 — Retrieval-augmented generative AI

- **Capability.** Model + retrieval over internal
  documents. May include sensitive but non-regulated
  data (internal engineering docs, product roadmaps).
- **Examples.** RAG-backed internal support agent; code-
  aware documentation assistant.
- **Required evaluations.** Tier 1 evals + indirect
  prompt-injection resistance (mod-107 chapter 02);
  tenant-isolation tests; retrieval-source integrity
  tests.
- **Required controls.** Tier 1 controls + retrieval-
  source classification, per-tenant retrieval isolation,
  provenance labelling on retrieved fragments, source
  attribution in outputs.
- **Sign-off.** ML Security Lead + ML Governance Lead +
  product owner.

### Tier 3 — Tool-using generative AI (low blast radius)

- **Capability.** Model + tools; each tool has *bounded,
  reversible* blast radius (read-only queries,
  ephemeral computation in a sandbox, non-destructive
  writes to isolated developer environments).
- **Examples.** Sandboxed code interpreter; browsing over
  public web; internal knowledge editor with rollback.
- **Required evaluations.** Tier 2 evals + tool-abuse
  red-team suite; sandbox escape tests; unintended-tool-
  chain analysis.
- **Required controls.** Tier 2 controls + tool ACLs
  (mod-107 chapter 03); per-tool rate limits; per-tool
  action logging; sandbox integrity monitoring; HITL
  approval for tools flagged as bounded-but-notable.
- **Sign-off.** Tier 3 review board (ML Security Lead
  chair; product owner; representative from any
  business function whose systems the tools touch).

### Tier 4 — Tool-using generative AI (high blast radius)

- **Capability.** Model + tools with *irreversible* or
  *material* blast radius (production writes; external
  communications sent from a corporate identity;
  financial transactions; access to regulated data).
- **Examples.** Email-triage agent that can send email;
  DevOps agent that can deploy code to production;
  fraud-investigation agent that can freeze accounts.
- **Required evaluations.** Tier 3 evals + capability
  elicitation for the specific tool set (can the agent
  compose tools to achieve unintended goals? can it be
  socially engineered to?); scenario-based red-team
  exercises; adversarial-multi-turn resistance.
- **Required controls.** Tier 3 controls + per-action
  HITL for material actions (mod-107 chapter 03 tier map);
  per-agent scoped credentials (never platform admin);
  hard network-scoped egress; **dual-signoff** on
  irreversible actions; explicit **capability disable**
  hooks (frontier framework analogue: MG-2.4.001 from
  chapter 01) per tool.
- **Sign-off.** Tier 4 review board (ML Security Lead
  + accountable executive + Legal + on-call security
  engineer + product owner).

### Tier 5 — Reserved: novel autonomous or high-uplift capability

- **Capability.** Systems that show autonomy indicators
  (long-horizon planning across many turns; self-
  modification of its own tool set; explicit multi-agent
  coordination), or that would meaningfully uplift a
  malicious actor's capability in categories the org has
  determined require executive-level oversight (e.g.,
  cyber offense, mass communication).
- **Required evaluations.** Domain-specific expert
  elicitation; internal red-team + external red-team;
  full frontier-framework-analogue safety case.
- **Required controls.** Tier 4 controls + explicit
  executive sign-off per deployment; time-limited
  deployments (renew at N months); explicit rollback
  plan tested at deployment; external attestation where
  applicable.
- **Sign-off.** Board-level accountable executive; ML
  Security Lead; General Counsel.

---

## The evaluation protocol

Analogous to the frontier framework "run these evals to
decide the tier". Enterprise version, per system:

- **Per tier, a defined evaluation bundle.** The bundle
  is content-addressed and versioned. Every deployment at
  a tier runs the bundle; results are stored alongside the
  deployment (mod-104 lineage).
- **Trigger conditions to re-run.** New tool added,
  retrieval source added, base model updated, prompt
  template materially changed → re-run.
- **Trigger conditions to re-tier.** Adding a tool that
  moves the system to a new blast-radius category → re-
  tier explicitly, not implicitly.
- **Expert elicitation for Tier 4/5.** Automated evals
  are necessary but insufficient. Structured expert
  review (analogous to frontier labs' safety cases)
  produces a written argument that the system's capability
  is bounded as claimed.

An evaluation-bundle schema:

```yaml
# eval-bundle-tier-4.yaml
tier: 4
version: 2026.09
automated_evals:
  - name: prompt_injection_v2026
    dataset: eval/prompt-injection/v2026
    threshold: pass_rate >= 0.95
  - name: indirect_prompt_injection_v2026
    dataset: eval/indirect-pi/v2026
    threshold: pass_rate >= 0.90
  - name: tool_abuse_redteam_v2026
    dataset: eval/tool-abuse/v2026
    threshold: pass_rate >= 0.95
  - name: capability_elicitation_composed_tools_v2026
    dataset: eval/composed-tools/v2026
    threshold: unintended_composition_rate <= 0.02
  - name: adversarial_multi_turn_v2026
    dataset: eval/multi-turn/v2026
    threshold: safety_maintenance_rate >= 0.90
expert_elicitation:
  required: true
  panel_composition:
    - ML Security Lead (chair)
    - Product owner
    - Domain safety expert (e.g., finance ops for financial-tool agents)
    - External red-teamer (contracted; independent)
  deliverable: written safety case following template `templates/safety-case-tier-4.md`
sign_off:
  authority: Tier 4 review board
  cadence:
    initial: before first production deployment
    renewal: every 6 months, or after any material change
```

---

## Wiring the tiers into policy-as-code

Chapter 04's admission gates enforce the tier policy. The
data the policies read:

```yaml
# governance/deployment-tiers.yaml
version: 2026.09
tiers:
  0: {sign_off: ml_governance_lead, evals: [none]}
  1:
    sign_off: [ml_governance_lead, product_owner]
    required_evals: [prompt_injection, safety_classifier, hallucination]
    required_controls: [input_validation, output_safety_gate, prompt_log_dlp, rate_limit, kill_switch]
  2:
    sign_off: [ml_security_lead, ml_governance_lead, product_owner]
    required_evals: [tier_1_evals, indirect_prompt_injection, tenant_isolation, retrieval_integrity]
    required_controls: [tier_1_controls, retrieval_classification, retrieval_isolation, provenance_labelling, source_attribution]
  3:
    sign_off: [tier_3_review_board]
    required_evals: [tier_2_evals, tool_abuse_redteam, sandbox_escape]
    required_controls: [tier_2_controls, tool_acls, per_tool_rate_limit, per_tool_action_log, sandbox_monitoring, hitl_on_notable]
    review_board: {chair: ml_security_lead, seats: 3}
  4:
    sign_off: [tier_4_review_board]
    required_evals: [tier_3_evals, capability_elicitation, scenario_redteam, adversarial_multi_turn]
    required_controls: [tier_3_controls, hitl_material_actions, scoped_credentials, egress_control, dual_signoff, capability_disable_hooks]
    review_board: {chair: ml_security_lead, seats: 5, external_review: required}
    deployment_ttl_days: 180
  5:
    sign_off: [board_authority]
    required_evals: [tier_4_evals, external_redteam, expert_elicitation, safety_case]
    required_controls: [tier_4_controls, executive_sign_off_per_deployment, ttl_deployment, tested_rollback]
    review_board: {chair: cxo_designee, seats: 5, external_review: required}
    deployment_ttl_days: 90
    external_attestation: recommended
```

A Rego policy that gates on this:

```rego
package aicg.controls.deployment_tier_gate

import rego.v1

applies if input.action == "model_registry.promote"
applies if input.action == "runtime_admission.deploy"

# Look up tier from the artefact.
tier := input.artefact.deployment_tier
tier_spec := data.deployment_tiers.tiers[format_int(tier, 10)]

violations contains v if {
  applies
  some required_eval in tier_spec.required_evals
  not eval_present_and_current(required_eval)
  v := {
    "rule": "tier_required_eval_missing",
    "tier": tier,
    "eval": required_eval,
    "remediation": sprintf(
      "Run the `%v` evaluation and record the result in the eval bundle before promoting a tier-%v system.",
      [required_eval, tier]),
  }
}

violations contains v if {
  applies
  some required_control in tier_spec.required_controls
  not control_present(required_control)
  v := {
    "rule": "tier_required_control_missing",
    "tier": tier,
    "control": required_control,
    "remediation": sprintf(
      "Tier-%v deployments require the `%v` control; wire it before promotion.",
      [tier, required_control]),
  }
}

violations contains v if {
  applies
  some required_signer in tier_spec.sign_off
  not signer_present(required_signer)
  v := {
    "rule": "tier_required_signoff_missing",
    "tier": tier,
    "signer_role": required_signer,
    "remediation": sprintf(
      "Tier-%v promotion requires sign-off from `%v`; obtain and record before promotion.",
      [tier, required_signer]),
  }
}

# For Tier 4/5, deployments have a TTL.
violations contains v if {
  applies
  ttl := tier_spec.deployment_ttl_days
  ttl > 0
  input.artefact.last_tier_review
  age_days := (time.now_ns() - time.parse_rfc3339_ns(input.artefact.last_tier_review)) / 1e9 / 86400
  age_days > ttl
  v := {
    "rule": "tier_deployment_ttl_exceeded",
    "tier": tier,
    "ttl_days": ttl,
    "age_days": age_days,
    "remediation": sprintf(
      "Tier-%v deployments must be re-reviewed every %v days; %v days have elapsed since last review. Book the review board.",
      [tier, ttl, age_days]),
  }
}

allow if {
  applies
  count(violations) == 0
}

allow if not applies

eval_present_and_current(name) if {
  some e in input.artefact.eval_results
  e.name == name
  e.result == "pass"
  e.threshold_met == true
}

control_present(name) if {
  input.artefact.controls[name] == "in_place"
}

signer_present(role) if {
  some s in input.artefact.approvals
  s.role == role
  s.signed_at
}
```

The pattern generalises. Tier changes are enforced; TTL
enforces re-review; missing evidence produces
remediation.

---

## The safety-case pattern (for Tier 4+ and beyond)

Frontier labs are converging on **safety cases** — written
arguments that the system is safe for the intended
deployment, with evidence, assumptions, and residual-risk
statements. Adopting for enterprise Tier 4+:

A safety-case skeleton:

```markdown
# Safety case — <system name>, tier <N>, version <V>

## 1. Claim
This deployment of <system> at Tier <N> for <deployment
scope> is acceptably safe for its intended use, subject to
the assumptions and residual risks below.

## 2. Deployment scope
<Who uses it, in what workflow, with what tools, over what
data, at what rate, for how long.>

## 3. Capability characterisation
<Structured argument, backed by evaluation evidence, that
the system's capability is bounded as claimed. For each
in-scope capability axis: what capability does it have; how
was that measured; what are the confidence intervals.>

## 4. Threat model
<Reference to mod-102 threat model + tier-specific
elaboration. Who might attack this system; how; what would
they get; what does the org have to lose.>

## 5. Controls and evidence
<Per required control at this tier: description; where
implemented; how verified; last verified.>

## 6. Assumptions
<What we assume that we haven't verified. Assumptions the
argument depends on. Every assumption has an owner and a
review cadence.>

## 7. Residual risks
<Risks that remain after controls. Acceptance authority.>

## 8. Fallback and disengagement
<How the system is disabled if a control fails. Tested
when.>

## 9. Sign-off
<Named signers per tier requirement.>

## 10. Renewal cadence
<Next review date. Triggers for out-of-cadence review.>
```

The safety case is versioned. Its Section 6 (controls) is
generated from the admission-gate decision (chapter 04);
its Section 3 (capability) references the eval bundle;
its Section 4 (threats) references mod-102. The document
composes existing artefacts into an argument.

---

## Where the analogy to frontier frameworks breaks

Not everything in a frontier RSP/PF/FSF has an enterprise
analogue. Places the adaptation has to bend:

- **The organisation isn't the model trainer.** Weights
  protection (a key frontier control) is the supplier's
  problem, not yours. Your version is *supplier
  assessment* — mod-110 covers.
- **Bio/chem/cyber uplift** is (mostly) not the enterprise
  deployer's threat model. The enterprise's Tier 4/5
  concerns are typically corporate-scale: transactional
  authority, customer-communication authority, access to
  regulated data. Frame the tiers for the org's actual
  blast surface, not for the frontier's.
- **Publishing safety cases externally** is a frontier-lab
  commitment; enterprises generally do not. Internal
  circulation to the review board and to auditors is
  sufficient. Where an enterprise deployer holds public
  attestation obligations (SOC 2, ISO 42001), the safety
  case can be one of the audit inputs — but rarely a
  public document.
- **"If-then" commitments to pause training** are frontier-
  lab commitments. Enterprises can commit to pause
  deployment — the promotion gate is the technical
  version. Do not overpromise: the enterprise commits to
  what it can operationalise.

Borrow the *shape* (tier taxonomy, per-tier controls,
review board, evaluation protocol, safety case). Localise
the *content* to the enterprise's actual risk axes.

---

## Standard failure modes

- **Same tier for all releases.** Every version of the
  assistant ships as Tier 2 because "we always ship at
  Tier 2". Fix: tier assignment is per-version; adding a
  tool triggers re-tier review.
- **Tier assignment as self-declaration.** Product team
  declares Tier 2 to avoid the Tier 3 review board. Fix:
  tier assignment is *checked* by policy — if the system
  has any tool with material blast radius, it is at
  minimum Tier 3, regardless of what the product declares.
- **Review boards that don't meet.** Tier 4 board is
  supposed to sit before deployment; the board is a
  calendar event that gets skipped. Fix: policy gates
  deployment on documented board decision; no meeting →
  no deployment.
- **Eval bundle that stopped mattering.** Bundle from
  eighteen months ago; nobody re-ran it against the new
  base model. Fix: TTL on eval results at each tier;
  admission gate checks currency.
- **Sign-off by unqualified authority.** "The engineering
  manager signed off Tier 4" — the manager is not on the
  Tier 4 board. Fix: policy checks signer role against
  the tier's sign-off list.
- **Tier drift under the same version tag.** Adding a
  tool without bumping the version; the platform doesn't
  notice the capability change. Fix: capability signature
  (tools, retrieval sources, base model, prompt template)
  is a versioned artefact; changes trigger re-tier.
- **Deployment TTL treated as advisory.** Tier 4 deploys
  live for a year without re-review because "everything
  is fine". Fix: TTL is enforced at the gate; TTL breach
  blocks continued deployment.
- **Frontier vocabulary applied without meaning.** Team
  says "we're ASL-3 compliant" because they read the RSP.
  Nothing is measured; there is no elicitation, no
  safeguards mapped. Fix: language borrowed from the
  frameworks must reference the enterprise version — the
  named tier, the named evals, the named controls.
- **External-review requirement waived quietly.** Tier 4
  or 5 requires external red-team; the review board
  waived it for the last three releases. Fix: waivers are
  audit-visible; waiver rate above threshold triggers
  policy review.
- **Kill-switch untested.** The tier requires a capability-
  disable hook; it exists but has never been exercised.
  Fix: game-day cadence per tier; game-day success
  recorded as evidence.

---

## Summary

- Frontier-lab frameworks — Anthropic **RSP**, OpenAI
  **Preparedness Framework**, DeepMind **FSF** — describe
  a common shape: *capability categories*, *tier
  thresholds*, *tier-specific mitigations*, *governance
  body*, *if-then commitments*.
- Enterprise deployers adapt the shape into a **deployment-
  tier taxonomy**: Tier 0 deterministic through Tier 5
  reserved-autonomous. Each tier defines its own required
  evaluations, controls, sign-off, and (for higher tiers)
  TTL and safety case.
- Tier assignment is *checked*, not self-declared. The
  system's capability signature — tools, retrieval,
  prompts, base model — determines the minimum tier;
  chapter 04 policies enforce.
- **Safety cases** — written arguments composed from
  existing artefacts — become the Tier 4+ headline
  deliverable. Reviewed at deployment; renewed on TTL;
  updated on material change.
- The analogy has limits: enterprises don't train frontier
  models, don't face the same threat axes, and don't
  usually publish safety cases externally. Borrow the
  shape; localise the content.
- The end state is a deployment discipline where the
  release process *steps up* when capability changes,
  rather than *linearly extending* the previous release's
  controls. That step-up discipline is what the frontier
  frameworks operationalise; it is what enterprise
  deployers of increasingly capable systems need too.
