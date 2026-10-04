# Chapter 04 — AI Incident Severity Ladder Mapped Into the Enterprise SOC

> **Note on AI-assisted content.** Regulator-disclosure
> timelines (GDPR, HIPAA, PCI DSS, EU AI Act, US state
> breach laws, sector rules) and SOC-tier internal
> conventions change frequently. Treat every article number
> and SLA as a pointer to look up against the primary source
> and the organisation's legal team, not as an authoritative
> citation. See [`resources.md`](./resources.md).

---

## Why this chapter exists

Mod-107 chapter 05 built a five-tier severity ladder for
LLM/agent incidents on the model-serving side. mod-110
chapter 02 established what signed supply-chain events
mean. This chapter does a different, operationally
critical job:

> Enterprise SOCs already run a severity ladder. The AI
> ladder has to fit *into it* — same vocabulary, same
> paging infrastructure, same SLAs, same auditability —
> or it will be ignored at the moments that matter.

If the AI/ML programme invents its own `AI-SEV-1`…`AI-
SEV-5` outside the SOC's existing paging surface, the
most likely failure mode is well-documented:

> At 02:37 Monday the ML severity dashboard shows a
> "SEV-1 AI incident". The on-call engineer for the ML
> platform sees it. The SOC on-call sees nothing — the
> ML ladder was never wired into PagerDuty's primary
> rotation. The ML on-call tries to escalate; the SOC's
> ticket system does not accept "AI-SEV-1" as a valid
> priority. Legal is not paged because the clock-tracker
> service listens on the SOC's SEV-1 queue, not the AI
> ladder. The 72-hour GDPR clock starts ticking
> internally while the two teams negotiate ownership.

The ladder in this chapter is the merger: AI/ML
incidents express themselves in the SOC's vocabulary,
page the SOC's rotations, start the SOC's disclosure
clocks, and feed the SOC's auditable incident record.
The ML-specific knowledge (trajectory evidence, reach
counters, model-version pinning) rides inside that
envelope.

You leave this chapter able to:

- Translate the five-tier LLM/agent ladder (mod-107
  chapter 05) and the broader AI-incident taxonomy
  (chapter 03's playbooks) into the enterprise SOC's
  existing severity vocabulary.
- Design objective triggers that use the SOC's current
  paging mechanics (PagerDuty / Opsgenie / xMatters)
  and ticket system (Jira / ServiceNow / Shortcut).
- Attach each AI/ML severity level to the enterprise's
  disclosure-clock service so GDPR, HIPAA, PCI DSS, EU
  AI Act, and sector rules fire from the same place
  as classical incidents.
- Separate three decisions on the ladder — *severity*,
  *paging*, and *disclosure* — so a change to one
  does not silently affect the other two.
- Build the ladder's **governance evidence** (mod-109)
  so an auditor can walk from an incident back to a
  policy, to a detector, to a trajectory.

---

## The three decisions on the ladder

Classical severity ladders conflate three things:

- **Severity** — how bad is this? What SLO applies?
  Is this a "wake someone up" event or a "file a
  ticket" event?
- **Paging** — who gets the page? SOC, ML platform,
  legal, exec, comms, finance?
- **Disclosure** — what external obligations apply?
  Regulator notification windows, customer-contract
  commitments, status-page updates, SEC Form 8-K
  (for material cyber incidents at US public
  companies).

Mature enterprise programmes already separate these
three — the AI/ML programme uses the same separation.

| Decision | Source | Updates when |
| --- | --- | --- |
| Severity | Detector + policy (code) | A new detector / tier is added. |
| Paging | On-call rota schedule | A rota changes. |
| Disclosure | Legal + the regulatory index | Law or contract changes. |

Mixing them means a legal-team change (new regulator in
scope) requires a code deploy; a rota change requires a
legal review; neither should be true.

---

## The ladder — AI incidents in the SOC's vocabulary

Below is the ladder as it maps into a typical SOC
severity set (SEV-1 … SEV-5). If the org uses P0 … P4,
S1 … S4, Critical / High / Medium / Low / Informational,
or similar: substitute. The *definitions* are what
matter.

### SEV-1 — Confirmed material harm (AI incident)

**Triggers (AI-specific; any one).** These are the AI-
specific objective triggers; the SOC's existing SEV-1
list (ransomware, confirmed data exfil, major outage)
remains in force unchanged.

- Confirmed exfiltration of regulated data (PII, PHI,
  cardholder, trade secret) attributable to an
  AI-system failure: through a tool call, through the
  model's output, through retrieval, through model-
  theft.
- Confirmed unauthorised action against a Tier-3 tool
  (mod-107 chapter 03) — payments moved, admin role
  granted, production infrastructure changed — as a
  result of prompt injection, model misuse, or agent
  compromise.
- Confirmed cross-tenant data crossover attributable
  to the LLM/RAG layer.
- Confirmed customer-facing material harm from a
  safety-critical output (medical, legal, financial,
  safety-of-life) attributable to the AI system.
- Confirmed exfiltration of a production model's
  weights by an unauthorised party.
- Dataset poisoning confirmed in a model currently
  serving material-impact decisions.
- Estimated financial impact ≥ $ORG_SEV1_THRESHOLD
  (your SOC fills in the number).

**Response.** The org's existing SEV-1 response
applies in full: incident commander, immediate paging
rota (security, ML platform, legal, executive, comms),
status-page handling, war-room / bridge activation. The
AI-specific additions on top:

- The appropriate playbook from chapter 03 is run (A,
  B, C, or D as applicable).
- Trajectory, model digest, retrieval-index version,
  and tool-registry version are preserved per
  chapter 03's evidence manifest.
- The reach counter is computed and reported in the
  incident record.

**Disclosure.** The org's SEV-1 clock-tracker fires;
legal determines applicability of GDPR Article 33
(72 h), HIPAA Breach Rule (60 d / 60 d / annual as
applicable), PCI DSS (per contract), EU AI Act Article
73 (verify applicability for the system), US state
breach laws (per NCSL index), sector rules, SEC Form
8-K if the entity is a US public company and the
incident is material. The playbook does not decide the
applicable regulations; it page-s legal and provides
the facts.

### SEV-2 — Confirmed exposure, no confirmed material harm (AI incident)

**Triggers.**

- Prompt-injection exploit that reached a Tier-2 tool
  (mod-107 chapter 03) — external send, cross-
  boundary write — without an established data-exfil
  outcome.
- System-prompt leak revealing competitor-sensitive or
  legally-privileged content without regulated-
  personal-data crossing.
- Retrieval-index poisoning that served to users
  without regulated data crossing.
- HITL-bypass that was blocked downstream before
  SEV-1 impact.
- Model-theft indicator confirmed without confirmed
  exfiltration.
- Dataset-poisoning signal on a model trained on
  suspect data but not yet in SEV-1 scope.
- Cost incident with impact above $SEV2_THRESHOLD,
  below $SEV1_THRESHOLD.

**Response.** SOC paging per the SEV-2 schedule
(security on-call, ML platform on-call, legal within
business day). Playbook from chapter 03. Post-mortem
within one week. Governance evidence record (mod-109)
required.

**Disclosure.** Often not a regulator event; state
rules and sector contracts can still apply. Legal
decides. The clock-tracker starts in "assessment"
state.

### SEV-3 — Successful attack, runtime prevention (AI incident)

**Triggers.**

- Injection payload reached the model; a Tier-2+ tool
  call attempted; the runtime policy *blocked* it.
- A jailbreak succeeded; DLP / content filter caught
  the output before return.
- A red-team payload (mod-107 chapter 04) succeeded
  against a specific runtime version before promotion.
- A Falco rule (chapter 02) fired on a credential
  path read that was blocked by a NetworkPolicy / RBAC
  deny.

**Response.** Notification-only to SOC within one
business hour; no out-of-hours page. Playbook from
chapter 03's eradication / recovery sections.
Regression test donated to mod-107 chapter 04's
corpus. Post-mortem within two weeks.

**Disclosure.** Internal record. Usually no external
obligation.

### SEV-4 — Detected attempt, unexploited (AI incident)

**Triggers.**

- Input-side classifier fires on a specific identity;
  no downstream tool call attempted.
- Cost-anomaly detector fires; budget cap held.
- System-prompt-leak attempt in a response the DLP
  redacted; nothing disclosed.
- Retrieval-time detector flags a chunk before
  serving.
- Falco notice-level rule fires on a diagnostic
  signature.

**Response.** Notification only; batch-reviewed in
the SOC's regular tuning cadence. Payload donated to
the corpus.

**Disclosure.** None.

### SEV-5 — Diagnostic / test / noise (AI incident)

**Triggers.**

- Red-team run under a scheduled engagement generated
  the signal; engagement documented.
- Known-benign user pattern tripped a detector; the
  tuning ticket is filed.
- Duplicate of a still-open higher-severity incident.

**Response.** Filed; no page. Chronic SEV-5 volume
triggers a tuning review.

**Disclosure.** None.

---

## Mapping into the SOC's existing severity vocabulary

The AI-specific tiers above are expressed as **SEV-1 …
SEV-5** because that is the common denominator. If the
SOC's vocabulary is different, publish a mapping table
and keep it in version control alongside the ladder:

```yaml
mapping:
  org_severity_vocabulary: ["P0", "P1", "P2", "P3", "P4"]
  ai_ladder_mapping:
    AI-SEV-1 (confirmed material harm):      P0
    AI-SEV-2 (confirmed exposure):           P1
    AI-SEV-3 (prevented attack):             P2
    AI-SEV-4 (detected attempt):             P3
    AI-SEV-5 (noise / drill / duplicate):    P4
```

Rules:

- **Severity is the SOC's severity.** If the AI
  trigger says SEV-1 and that maps to P0, the ticket
  priority is P0; the page is P0.
- **No parallel universe.** The AI incident does *not*
  live in a separate dashboard that the SOC does not
  look at. It is in the same queue.
- **The ML-specific metadata rides inside.** The
  ticket has a `ai_specific: true` tag, an `atlas_
  techniques:` list, a `playbook_id:` reference, a
  `model_digest:` and `runtime_version:` enrichment.
  The SOC's reporting infrastructure already knows how
  to render arbitrary metadata.

---

## The disclosure-clock service

Enterprise SOCs that already handle regulated data have
a disclosure-clock service of some kind — a system that
reads the incident stream, extracts the trigger facts,
and tracks the deadlines automatically. If the org does
not have one, this is one of the gaps the AI programme
will highlight.

The service's job is three-fold:

- **Start the clock** on the first awareness event
  (SEV-1 or SEV-2 that touches regulated data).
- **Track the deadline** per obligation (GDPR 72 h,
  HIPAA 60 d, PCI per contract, EU AI Act per Article
  73 timelines, SEC Form 8-K at four business days
  for public companies, state laws per NCSL index).
- **Alert the incident commander and legal** as the
  deadline approaches without a disclosure decision.

The AI programme contributes to this service by
emitting the required *facts* in a structured way:

- `data_classifications_touched: ["pii", "phi",
  "cardholder", "sensitive_personal_data_eu"]`
- `jurisdictions_in_scope: ["eea", "us-ca", "us-ny",
  "uk"]`
- `individuals_affected_estimate: <integer>`
- `confirmed: true | false` (vs. suspected)
- `root_cause_category: "ai_tool_call_misuse" | "ai_
  retrieval_poisoning" | "model_theft" | "dataset_
  poisoning" | ...`

The clock service does not need to understand the AI
specifics; it needs enough facts to pick the applicable
obligation.

---

## Objective triggers from detectors

The ladder is wired to the detectors from chapters 01
and 02 via a policy table in code. The policy table has
columns:

```yaml
- detector_id: "7f3b2e7e-8b4c-4e3b-9e3b-ml-registry-dl-001"
  detector_name: "Anomalous Model-Registry Full Weight Download"
  default_severity: SEV-3
  escalation_rules:
    - "If identity.type == 'human' AND bytes_out > 2 GiB -> SEV-2"
    - "If 3 or more pulls across the model family in 24 h -> SEV-2"
    - "If source.ip not in enterprise_cidr -> SEV-1 (model-theft playbook)"
  playbook_id: "playbook-C"
  owners:
    primary: "soc-oncall"
    secondary: "ml-platform-oncall"
    legal: "legal-ir-rota"
  disclosure_clock: "ip-theft, contractual-notifications"
  atlas_techniques: ["AML.T0044"]

- detector_id: "2a7c9f3b-7d4b-4e3b-9e3b-ml-agent-oob-001"
  detector_name: "Agent Tool Call to Unknown Destination After External Retrieval"
  default_severity: SEV-3
  escalation_rules:
    - "If tool.tier == 2 AND tool.destination_bytes_out > 10 KiB -> SEV-2"
    - "If tool.tier == 3 -> SEV-1"
    - "If regulated_data_touched -> SEV-1 (regardless of tier)"
  playbook_id: "playbook-B"
  owners:
    primary: "soc-oncall"
    secondary: "ml-platform-oncall"
    legal: "legal-ir-rota"
  disclosure_clock: "gdpr-33, state-breach, eu-ai-act-73"
  atlas_techniques: ["AML.T0049", "AML.T0053"]
```

Rules:

- **The policy table is code.** Changes go through
  the same review process as detection rule changes.
- **Escalation is a function of event fields.** The
  on-call does not compute severity; the policy
  engine does.
- **Owners name roles, not people.** The rota resolves
  to a person; the policy table does not.
- **The disclosure-clock reference is to an obligation
  identifier, not to a legal statute's prose.** The
  clock service owns the statute mapping.

---

## Reach, trajectory, and the AI-specific metadata contract

Every AI-specific incident ticket carries three fields
not present on classical tickets:

- **`trajectory_ref`** — pointer to the full
  trajectory evidence bundle (mod-107 chapter 05's
  trajectory, chapter 03's evidence manifest). The
  bundle is content-addressed; its digest is the
  ticket's immutable reference.
- **`reach_count`** — the number of distinct users /
  sessions / inferences estimated to have been
  affected. Computed by the runtime from the shared-
  resource version (retrieval-index version, system-
  prompt-cache version, model version) and the serving
  log for the window.
- **`model_digest`**, **`runtime_version`**, **`tool_
  registry_version`**, **`retrieval_index_version`** —
  the pin set that lets a responder reproduce the
  state the incident fired against.

Fields missing on an AI ticket are themselves a
quality signal; the ticket intake webhook rejects a
submission that lacks the AI-specific minimum set.

---

## Cost (LLM10) as an orthogonal axis

Unbounded consumption incidents (mod-107 chapter 01
LLM10) can be financially larger than data-loss
incidents while technically less serious. The ladder
treats cost as an **orthogonal axis** — a secondary tag
on the ticket rather than a separate ladder:

- `cost_impact_usd: <integer>` emitted automatically
  from the budget-manager (mod-107 chapter 05).
- Severity floor: a cost impact above $ORG_COST_SEV2
  cannot be rated below SEV-2; above $ORG_COST_SEV1,
  cannot be rated below SEV-1 regardless of other
  factors.
- Finance is paged alongside SOC when cost impact is
  above $ORG_COST_SEV2.

Cost incidents run through the same evidence and
disclosure surface as other incidents.

---

## Metrics the ladder produces

The ladder is itself an evidence surface. The regular
metrics it should produce:

- **MTTA / MTTR by tier.** Mean time to acknowledge
  and mean time to resolve, split by severity. The
  governance programme (mod-109) consumes these.
- **Disclosure-clock performance.** Were SEV-1 and
  SEV-2 clocks met? What was the margin?
- **Detector precision.** For each detector, the ratio
  of true-positive to total alerts, bucketed by tier
  the detector triggered.
- **Reach-counter distribution.** The histogram of
  reach counters per tier; useful for calibrating
  thresholds.
- **Playbook adherence.** How often did the response
  follow the playbook; where did it diverge; why.
- **Rehearsal cadence.** Tabletop and live-fire
  exercises per playbook per year.

The metrics are presented to leadership and to
auditors. They are also the input to the next tuning
cycle: a detector with 5 % precision is a tuning
candidate; a playbook with 40 % adherence is a
rewrite candidate.

---

## Standard failure modes

- **A parallel AI dashboard.** The AI ladder exists;
  the SOC does not see it; the two queues never
  reconcile. Fix: AI incidents in the SOC's queue, in
  the SOC's severity vocabulary, with ML metadata.
- **"Severity" that requires narrative judgement.**
  The ladder's triggers are objective; the on-call
  reads the severity from the policy engine, not from
  a paragraph.
- **Disclosure clocks that only legal knows about.**
  The clock service receives the incident facts
  automatically; legal does not have to be in the
  room to start the countdown.
- **AI-specific severity that is incompatible with
  the SOC's SLAs.** If "AI SEV-1" has a 30-minute
  response but the SOC's SEV-1 has a 15-minute
  response, there is one of each — not two
  conflicting commitments.
- **Reach not instrumented.** The ticket says "a
  small number of users were affected"; nobody knows
  the number. The runtime instrumentation feeds
  `reach_count` automatically.
- **Trajectory lost at pod restart.** The evidence
  bundle writes to persistent storage *before* the
  pod exits; the alert fires only *after* the write
  acknowledges.
- **The policy table drifts from the detector set.**
  New detectors deployed without a policy entry
  default to SEV-5; silent coverage holes result. CI
  gate: no detector merges without a matching policy
  entry.
- **Cost incidents handled as ops.** The $50k runaway
  agent goes to finance, not to the SOC. The ladder
  treats it as a security incident with a cost tag.
- **AI incidents close as "bug fixed."** The
  classical close reason does not reach the AI-
  specific regression surface (mod-107 chapter 04,
  mod-109 governance evidence). The ticket template
  requires those entries on close.

---

## Summary

- **The AI incident ladder lives inside the SOC's
  existing severity vocabulary.** Translation table in
  version control; AI incidents use the SOC's priority
  values, SLAs, and paging rotations.
- **Three decisions kept separate** — severity (code),
  paging (rota schedule), disclosure (legal + clock
  service) — so a change to one does not silently
  affect the others.
- **Objective triggers** come from the detectors in
  chapters 01 and 02 via a policy table that names
  default severity, escalation rules, playbook ID,
  owners, disclosure-clock identifiers, and ATLAS
  technique mappings.
- **AI-specific metadata** rides on every ticket:
  `trajectory_ref`, `reach_count`, `model_digest`,
  `runtime_version`, `retrieval_index_version`,
  `tool_registry_version`.
- **The disclosure-clock service** receives the
  incident facts automatically; legal decides which
  obligations apply; the service tracks and alerts.
- **Cost is an orthogonal axis**, not a parallel
  ladder.
- **Metrics** — MTTA/MTTR, disclosure-clock
  performance, detector precision, reach distribution,
  playbook adherence — are the audit artefact the
  governance programme consumes.
- The ladder's job is to make an AI incident
  *indistinguishable at response time* from a
  classical SOC incident, while preserving the
  ML-specific evidence and feedback loops that make
  the response usable.
