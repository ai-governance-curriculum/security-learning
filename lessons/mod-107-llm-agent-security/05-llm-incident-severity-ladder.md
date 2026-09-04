# Chapter 05 — LLM/Agent Incident Severity Ladder

> **Note on AI-assisted content.** Regulator disclosure timelines
> (EU AI Act, GDPR, HIPAA, PCI DSS, US state breach laws, sector-
> specific rules) change; the article numbers below are pointers
> to *look up*, not authoritative citations. Verify every SLA and
> article number against the primary source and the org's legal
> team before quoting operationally. See
> [`resources.md`](./resources.md).

---

## Why this chapter exists

Chapters 01–04 built the *pre-incident* stack: category
mitigations, indirect-injection defence, tool ACLs and HITL,
red-team engagements. This chapter assumes something got
through anyway. Incidents happen; the question is whether the
team responds by the shape of the incident or by luck.

Most organisations already have an incident-severity ladder —
SEV-1 through SEV-5 or an equivalent. That ladder is written
against outages, security breaches, and data leaks in the
classical sense: services down, PII exfiltrated, credentials
compromised. It does not know how to score:

- A prompt-injection payload that exfiltrated a customer's
  data through a *tool call* (no CVE, no server compromise,
  no traditional breach signal — just an agent doing an
  attacker-directed thing).
- A jailbreak in a customer-facing app that produced a
  harmful response before being retracted (a
  reputational / safety-critical incident, not a data
  incident).
- A retrieval-index poisoning that has been affecting
  answers for six weeks and was only just detected.
- A runaway agent loop that cost the org $47,000 overnight
  (unbounded consumption; the finance team notices, not
  security).
- A system-prompt leak that revealed a competitor policy the
  legal team said was confidential.

The ladder in this chapter maps LLM/agent incidents onto
severity levels the on-call rota can respond to, connects
each severity to the disclosure obligations the org faces,
and names the tooling and evidence required for a post-
incident report a governance auditor (mod-109) can accept.

The specific failure mode this chapter is written to prevent:

> A prompt injection allows an attacker to exfiltrate ~200
> customer records via a tool call over three hours. The
> on-call, following the classical playbook, treats the
> event as a bug — patches the tool, marks the incident
> "resolved". Two weeks later, legal discovers that GDPR
> Article 33 required notification within 72 hours and the
> clock started when *the org* knew, not when the on-call
> escalated. The org is now late; the missed notification
> becomes its own regulatory finding. The ladder in this
> chapter is the fix — it triggers the notification clock
> as part of the on-call playbook, not as an afterthought
> from legal.

You leave this chapter able to:

- Design a five-tier severity ladder specifically for
  LLM/agent misuse events, mapped to concrete objective
  triggers and to time-to-page.
- Route each tier to the right responders — security
  on-call, legal, comms, ML platform, executive — with
  the right notification cadence.
- Cross-map each tier to the disclosure obligations the
  org may owe under GDPR, HIPAA, PCI DSS, EU AI Act, and
  applicable state / sector rules.
- Wire the ladder into the platform: the detection
  signals from chapters 02–04 fire, the runtime
  paginates, the incident is triaged, and the response
  actions are pre-authorised.
- Own the post-mortem: what evidence is captured, what
  goes in the model-card update (mod-104, mod-109), and
  what feeds back into the red-team corpus (chapter 04).

---

## What makes LLM/agent incidents different

Four properties that classical playbooks did not have to
account for:

- **The compromise is often *behavioural*, not a code
  execution.** No CVE was exploited; the model was
  steered. Traditional signals — WAF hits, process
  spawns, egress spikes — may not fire. The signals live
  in the LLM telemetry (chapters 02 / 04) and in the
  tool-call audit log (chapter 03).
- **The blast is often through a *tool call*, not a
  network path.** Data leaves via `mail.send`,
  `slack.post`, `crm.update`, a webhook call, or a
  tool-driven database read that returned more than
  intended. The right question is not "what did the
  process do" but "what tools were called with what
  arguments".
- **Time-to-detect is often long.** Retrieval-index
  poisoning may live in the store for weeks. Slow-drip
  data exfil through frequent low-volume tool calls is
  below the anti-abuse radar. Model-side leakage of
  training data may only be discovered when a customer
  reports it.
- **The affected population is often *cross-tenant* or
  *cross-user*, not a single victim.** An injected
  document in a shared RAG store affects every user who
  triggers it. An injected system-prompt cache affects
  every user hitting that cache. Incident scope depends
  on *how many* users the runtime served the affected
  context to.

Each property has a matching evidence surface: LLM
telemetry (fingerprints, retrieval logs, tool-call
audits), the trajectory replay (Inspect logs / runtime
transcripts), and the reach counter (how many sessions
were exposed). Chapter 03 already required that every
tool call be audited; this chapter cashes that in.

---

## The five-tier severity ladder

Every tier has three definitions: **objective triggers**
(what fires the tier), **response** (who is paged, in what
time window, and what they do), and **disclosure surface**
(what obligations the tier lights up).

### SEV-1 — Confirmed material harm

**Objective triggers (any one).**

- Confirmed exfiltration of PII, PHI, cardholder data, or
  regulated data to an unauthorised party — through a
  tool call, through the model's response, or through the
  retrieval / embedding layer.
- Confirmed unauthorised action against a Tier-3 tool
  (chapter 03) — payments moved, admin roles granted,
  production infrastructure changed — as a result of
  prompt injection or agent misuse.
- Confirmed customer-facing harm from a jailbreak /
  misinformation output in a safety-critical domain
  (medical, legal, financial advice) attributable to the
  system.
- Cross-tenant data crossover (a user of tenant A received
  content from tenant B) attributable to the LLM/RAG
  layer.
- Estimated financial impact ≥ $ORG_SEV1_THRESHOLD
  (the org fills this in), including runaway-consumption
  costs above the threshold.

**Response.**

- Page security on-call, ML platform on-call, legal, and
  the executive on-call within 15 minutes.
- Runbook: contain (kill the affected agent identity or
  tool scope; snapshot the retrieval store), preserve
  (freeze the trajectory logs, tool-call audits, model
  version, retrieval-index version), assess (who was
  affected, over what window), disclose (start the
  clocks below).
- Formal incident commander assigned; comms briefed.
- Public status page updated within the org's SLA.

**Disclosure surface.** The following obligations *may
apply* — legal owns the determination, but the on-call
runbook starts the clocks:

- **GDPR Article 33** (EEA / UK personal data): notify
  the supervisory authority within 72 hours of the
  controller becoming aware, unless unlikely to result in
  a risk. Notification of data subjects under Article 34
  if high risk.
- **HIPAA Breach Notification Rule** (US, PHI, 45 CFR
  §§ 164.400–.414): notify affected individuals without
  unreasonable delay and in no case later than 60 days;
  notify HHS within 60 days for large breaches (or
  annually for smaller).
- **PCI DSS incident response** (Requirement 12 in
  v4.x): notify card brands / acquirers per contract.
- **US state breach-notification laws**: vary by state;
  NCSL maintains a reference index. Multiple states apply
  when the affected users span them.
- **EU AI Act Article 73** (providers of high-risk AI
  systems): reporting of serious incidents (verify the
  article number and the definition of "serious
  incident" against the OJEU consolidated text).
- **Sector rules** (financial, healthcare, telecoms,
  critical infrastructure): whatever additional
  timelines apply.

### SEV-2 — Confirmed exposure without confirmed material harm

**Objective triggers (any one).**

- Confirmed prompt-injection exploitation that reached a
  Tier-2 tool (chapter 03) — external send, cross-
  boundary write — without an established data-exfil
  outcome, or where the outcome is bounded to a small
  set of internal users.
- Confirmed system-prompt leakage that revealed
  competitor-sensitive or legally-privileged content but
  not regulated-personal-data.
- Confirmed retrieval-index poisoning where the
  affected content has been served to users but no
  regulated data crossed the boundary.
- Successful HITL bypass — an attacker got a human to
  approve a malicious action — that did not (yet)
  result in SEV-1 harm because a downstream control
  stopped it.
- Runaway consumption incident with financial impact
  above the SEV-2 threshold and below the SEV-1
  threshold.

**Response.**

- Page security on-call, ML platform on-call within 30
  minutes; legal notified same day.
- Contain, preserve, assess as above; disclosure
  determined by legal from the specific facts.
- Post-mortem within one week; ladder chapter 04
  regression tests filed within two.

**Disclosure surface.** Often *not* a regulator-
notification event, but state law and sector rules can
still apply if any affected user is in a jurisdiction with
a low threshold. Legal owns the call.

### SEV-3 — Successful attack with runtime prevention

**Objective triggers (any one).**

- An injection payload reached the model and the model
  attempted a Tier-2+ tool call which the runtime
  blocked (chapter 03 ACL fired). Detection worked; the
  harm was prevented.
- A jailbreak succeeded on the model output but a
  downstream DLP / content filter caught it before
  return.
- A red-team payload (chapter 04) succeeded in a
  production replay against a specific runtime version,
  before that version was promoted.

**Response.**

- Notify security on-call within one business hour; no
  page.
- Incident record filed; the payload donates to the
  chapter-04 corpus with a regression test.
- Post-mortem within two weeks focusing on why the
  detection at the *upstream* layer (input classifiers,
  content filters) did not catch it, rather than on the
  prevention that did.

**Disclosure surface.** Internal record; usually no
external obligation. The finding may still land in the
governance evidence surface (mod-109) as part of the
control-effectiveness story.

### SEV-4 — Detected attempt, unexploited

**Objective triggers (any one).**

- Input-side injection detector fired on a specific
  identity; no downstream tool call was attempted.
- Cost-anomaly detector fired for an identity but the
  budget cap held the impact bounded.
- System-prompt-leak attempt detected in a response the
  DLP redacted; no actual system-prompt content
  disclosed.
- Retrieval-time detector flagged a suspicious chunk
  before it was served to a user.

**Response.**

- Notification-only to security triage; batch-reviewed
  weekly.
- Payload donates to the corpus.
- No external disclosure surface.

### SEV-5 — Diagnostic / test / rate-noise

**Objective triggers (any one).**

- A red-team run under a scheduled engagement generated
  the signal (chapter 04); the engagement is documented;
  the signal is expected.
- A known-benign user pattern tripped a detector
  (well-characterised false positive); the tuning ticket
  is filed.
- Duplicate of a still-open higher-severity incident.

**Response.** Filed; no page; used for FP-rate
management. Chronic SEV-5 volume against a specific
detector triggers a tuning review.

---

## Wiring the ladder — triggers, routing, and evidence

The ladder is only real if the runtime *fires* it. Three
wire-level rules:

### Every detector maps to a tier by policy

Chapter 02's input-side classifier, chapter 03's tool-ACL
block, chapter 04's regression-gate CI failure, mod-106's
membership-inference alert, mod-104's provenance mismatch —
each has a **policy** that names the tier on default
severity. The policy also names the *escalation* condition:
what makes the default tier escalate.

For example: a single input-classifier alert against one
identity is SEV-4. Ten alerts against the same identity in
an hour is SEV-3. If, additionally, a Tier-2 tool call was
attempted by the same identity, it escalates to SEV-2. If
the Tier-2 call succeeded (runtime did *not* block for any
reason), SEV-1.

Escalation rules live in code — they are part of the
incident-management config, not a runbook prose paragraph.

### Every incident has a preserved trajectory

The evidence artefact for every LLM incident is the
**trajectory**: the exact sequence of prompt fragments (with
provenance labels from chapter 02), model responses, tool
calls (with arguments and results), and runtime decisions
that produced the outcome. The trajectory is preserved for
the org's retention period (per legal, typically 3–7 years
for a security incident). It is the artefact the responder
replays, the post-mortem cites, and the governance auditor
inspects.

Every trajectory record includes:

- Timestamps for every event.
- The prompt-record data structure (chapter 02) with
  provenance labels.
- The tool-registry version and each tool call's
  registry-declared tier.
- The runtime version and any policy decisions the
  runtime made (allow / block / HITL-required).
- The caller identity (via mod-103 workload identity /
  mod-105 identity chain) and the affected identities.
- For SEV-1 / SEV-2: the *reach counter* — how many
  distinct users were served this trajectory shape (for
  retrieval-index or system-prompt-cache incidents).

Trajectories are handled as regulated data — encrypted at
rest, access-logged, non-exportable without approval —
because they contain the raw payloads and, often, the
customer content the incident touched.

### Every SEV-1 / SEV-2 starts the disclosure clocks

The on-call playbook does not decide whether GDPR / HIPAA /
etc. apply — legal decides that. The playbook *starts the
clocks* by paging legal with the specific facts at hand.
Two effects:

- The 72-hour GDPR clock (Article 33) starts from *the
  controller becoming aware*. The org's "awareness" is the
  earliest confirmation, not the eventual assessment. The
  on-call's page to legal creates the record.
- The clocks are tracked centrally: an "incident-clock"
  service reads the SEV-1 / SEV-2 incident feed, records
  the deadlines, and pages the incident commander if a
  deadline approaches without a disclosure decision.

---

## Playbook fragments — what the runbook actually says

The runbook per tier is org-specific, but the LLM-specific
fragments below are the reusable parts.

### Fragment A — Contain the agent

- Revoke the agent's service identity: the mesh / IdP
  disables the SPIFFE-attested identity or the
  short-lived token (mod-103 chapter 03, mod-105 chapter
  03) within one minute.
- Disable the affected tool at the registry (chapter 03)
  by pushing a config that returns "unavailable" to the
  runtime dispatcher. Do this *before* trying to trace
  the specific injection payload — every minute the tool
  remains callable is more risk.
- If the agent runs against a retrieval store, snapshot
  the index at the current version and freeze writes to
  it. Do not delete anything.

### Fragment B — Preserve the evidence

- The trajectory that triggered the incident is copied to
  an incident-evidence bucket; the model version is
  pinned; the retrieval-index version is pinned; the
  system-prompt version is pinned; the tool-registry
  version is pinned. Everything the runtime saw is
  recovered.
- The audit log for the affected identity is pulled for
  a rolling window (48 hours by default, longer for
  slow-drip incidents).
- For SEV-1: legal-hold notice fired on the identities
  and repositories the incident touches.

### Fragment C — Bound the reach

- Compute the reach counter: how many distinct users saw
  a poisoned retrieval chunk? How many sessions used the
  affected prompt cache? How many tool calls fired
  against the affected tool during the incident window?
- The reach counter feeds the disclosure decision — a
  single-user incident is a different disclosure surface
  from a 200-user incident.

### Fragment D — Notify

- Internal: security, legal, comms, ML platform, exec.
- External: per legal, per timeline (GDPR 72h, HIPAA 60d,
  PCI per contract, EU AI Act per Article 73). The
  incident-clock service tracks each.
- Affected users: per legal; typical timeline is "without
  unreasonable delay" once the facts are known.

### Fragment E — Fix and regress

- The immediate fix: a runtime patch or a tool-ACL
  update. The patch is deployed under the same change-
  management as production releases; skipping change
  management even in an incident is how ancillary
  incidents are created.
- The regression test: the payload donates to the
  chapter-04 corpus with a specific regression sample.
  The CI gate on subsequent releases blocks a regression.
- The model-card / evidence surface update: mod-104's
  lineage record and mod-109's governance evidence
  reflect the incident and the fix.

---

## Cost as its own severity axis (LLM10)

Unbounded consumption incidents (chapter 01 LLM10) can be
financially larger than data-loss incidents while
technically less serious. The severity ladder treats them
as a separate *axis* with its own thresholds:

- Instantaneous burn rate against per-identity budget
  exceeded by Nx for M minutes → SEV-3 or SEV-2 depending
  on cost.
- Absolute daily cost above a per-tenant threshold →
  page finance; SEV-2 on the ladder; the runbook
  disables the affected agent's budget grant.
- Cross-tenant cost anomaly → SEV-1 if the source is a
  compromised identity spanning tenants.

Cost incidents run through the same evidence and
disclosure surface as other incidents; add "financial
statement" to the evidence bundle where relevant.

---

## Mapping to sibling modules

The severity ladder is *this* module's artefact; the actual
incident-response *programme* is mod-111's.

- **mod-104 (lineage).** The trajectory and its evidence
  attach to the model / data lineage record. The
  incident's model version and data version are cited.
- **mod-105 (secrets).** Identity revocation for the
  affected agent identity uses the same primitives as a
  secret-leak runbook. Tools that emitted or accepted
  credentials get their key material rotated per mod-105
  chapter 04.
- **mod-106 (adversarial ML).** Membership-inference or
  extraction incidents that involve the underlying model
  reference mod-106's serving-layer detectors and, for
  privacy incidents, mod-106 chapter 06 (DP-SGD) as a
  post-incident control.
- **mod-108 (privacy).** PII / PHI exposure incidents
  feed the privacy programme's DSAR / erasure obligation
  handling.
- **mod-109 (governance).** Every SEV-1 and SEV-2
  incident produces a governance-evidence record;
  chronic SEV-3 patterns feed the risk register.
- **mod-110 (supply chain).** Incidents whose root cause
  is a compromised imported artefact escalate into
  mod-110's supply-chain response.
- **mod-111 (secops).** The event bus, on-call rota,
  incident-command tooling, and post-mortem template
  live there; this chapter's ladder is the *content*
  that fills their process.

---

## Standard failure modes

- **No LLM-specific tier definitions.** The classical
  ladder is used as-is; injection incidents get filed
  as "P3 bug"; regulatory clocks don't start.
- **Trajectories not preserved.** Once the runtime
  crashes or the session ends, the trajectory is gone;
  the responder has anecdotes, not evidence.
- **The reach counter is missing.** "We think a few
  users saw this" is not a disclosure input. The
  runtime instruments reach; the incident query surfaces
  it.
- **Legal contacted only after the initial patch.** The
  clock starts at *awareness*, not at *readiness to
  disclose*. Escalate to legal as part of the paging,
  not after the fix.
- **Cost incidents treated as ops, not security.** A
  runaway agent that spent $50k is a security incident:
  someone or something drove the cost. Same ladder,
  same evidence discipline.
- **Regression test skipped after the fix.** The next
  release regresses because chapter-04's CI gate did
  not gain a sample. Every incident donates a payload.
- **Runbook that requires a human to compute severity
  from prose criteria.** Severity policy is code; the
  on-call gets a tier from the detector, not a paragraph
  they read at 3 a.m.
- **HITL bypass filed as "user error".** A user who
  approved a malicious action inside a well-designed
  HITL gate is still an incident; a user who approved a
  malicious action inside a rubber-stamp HITL gate is
  a chapter-03 finding.
- **Disclosure decisions embedded in on-call.** The
  on-call *pages* legal; the on-call does not *decide*
  what to disclose. Keep the roles separate.

---

## The mistakes this chapter is trying to prevent

- **Treating LLM/agent misuse as bugs.** Behavioural
  compromise is a security incident with regulatory
  timelines. Bugs get fixed; incidents get disclosed.
- **A ladder that requires narrative interpretation.**
  The triggers are objective; the tiers are code; the
  clocks are automated. Every judgement call is a
  future post-mortem finding.
- **Confusing *prevention* with *no incident*.** A
  runtime that blocked a Tier-2 tool call for a
  compromised session prevented harm; it also produced
  a SEV-3 incident. The event happened; ship the
  report.
- **Not measuring reach.** One user seeing bad content
  is different from ten thousand. The instrumentation
  is boring and it is essential.
- **Skipping the post-incident feedback loop.** The
  corpus grows; the regression tests grow; the
  detectors improve. An incident that leaves nothing
  behind is a discount on the next incident.

---

## Summary

- The ladder has **five tiers** — SEV-1 (confirmed
  material harm) through SEV-5 (rate noise) — with
  **objective triggers**, **response actions**, and
  **disclosure surfaces** for each.
- Every detector from chapters 02–04 maps to a tier by
  policy; the tier is code, not prose. Escalation rules
  live alongside the tier.
- Every incident preserves a **trajectory** — the
  prompt fragments with provenance, model responses,
  tool calls, runtime decisions, caller identity — as
  the durable evidence artefact.
- SEV-1 and SEV-2 start **disclosure clocks** through a
  page to legal; the incident-clock service tracks the
  regulatory deadlines. The on-call *starts* clocks; it
  does not *decide* what to disclose.
- **Cost (LLM10)** is a first-class severity axis with
  its own thresholds. Runaway consumption is a security
  incident.
- Every incident's fix is paired with a **regression
  test** into the chapter-04 corpus; every incident
  updates the governance evidence surface (mod-109).
- The failure mode this chapter is written to prevent
  is the *bug-shaped* handling of a behavioural
  compromise: clocks unstarted, evidence not preserved,
  reach unknown, regression not tested. The ladder is
  the tool that turns "the model did a bad thing" into
  a response the org — and its regulators — can accept.
