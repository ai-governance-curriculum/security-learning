# Chapter 03 — AI-Specific Incident-Response Playbooks

> **Note on AI-assisted content.** The playbook structure
> below is a reusable scaffold — Prepare / Detect / Contain
> / Eradicate / Recover / Learn — borrowed from the NIST
> SP 800-61r3 incident-response life cycle and the SANS
> PICERL variant. The commands and tool invocations are
> shaped against the referenced ecosystem (Falco, Elastic
> / Splunk, cosign, Kubernetes). Confirm every argument
> against the installed tool before pasting into a live
> runbook. See [`resources.md`](./resources.md).

---

## Why this chapter exists

Chapters 01 and 02 produced detections. A detection
without a playbook attached is a page at 3 a.m. where the
on-call reads the alert, confirms they do not know what
to do, and tries not to make it worse. Playbooks are the
pre-authored answer to "what do I do when this fires".

Playbooks for classical security incidents (malware,
account compromise, data exfil via a known channel)
exist in every mature SOC. The playbooks in this chapter
cover **four AI-specific incident shapes** that classical
playbooks do not handle well:

- **Data-poisoning discovery** — a signal (lineage
  mismatch, offline eval regression, downstream
  behavioural anomaly) suggests the training data for a
  deployed model was tampered with, before or after
  training.
- **Prompt-injection exploitation in production** — an
  indirect-injection payload reached a production agent,
  the agent made a tool call it shouldn't have, data or
  action impact is in play.
- **Model-theft indicators** — model-registry access
  patterns, membership-inference probes, or outright
  weight-exfiltration events suggest an adversary is
  staging or executing model theft.
- **Agent misuse** — a legitimate user (or a compromised
  identity) is operating an agent in ways outside the
  authorised scope: cost blowout, unauthorised third-
  party API calls, action against a protected resource.

Each playbook is written as the on-call sees it: trigger
→ triage → contain → preserve → eradicate → recover →
learn. "Learn" is where the detection content pack
(chapter 01), the Falco rules (chapter 02), and the
governance evidence surface (mod-109) are updated.

The failure mode this chapter is written against:

> At 02:37 the SIEM pages: "AML.T0049 — agent tool call
> to new destination, high severity". The on-call reads
> the alert, confirms it is real, and spends the next
> forty minutes groping for context: which agent, which
> runtime version, which identity, which retrieval
> source, how many sessions were affected, is this a
> SEV-1, do we page legal, do we snapshot the retrieval
> store, is there a kill switch? The incident commander
> arrives at 04:00 and starts the questions over. By
> then, exfiltration is 90 minutes stale and some of the
> evidence is gone. A playbook that specified the
> commands, the preservation steps, and the escalation
> contacts would have compressed this to twelve minutes.

You leave this chapter able to:

- Pick the playbook shape — PICERL / SP 800-61 — your
  org already uses, and populate it with the four
  AI-specific scenarios.
- Write playbook steps that are executable at 3 a.m. by
  someone who did not design the system: command,
  expected output, next step.
- Attach to each playbook the evidence it must preserve
  — trajectory, model digest, retrieval-index snapshot,
  tool-call audit log — so the post-mortem has
  something to read.
- Connect the playbook to the severity ladder
  (chapter 04) so the response actions and the
  disclosure clocks line up.
- Keep the playbook rehearsed; a never-run playbook has
  the operational value of a never-written playbook.

---

## Life-cycle scaffold

NIST SP 800-61 (currently r3) frames incident response as
a cyclical process:

1. **Preparation** — ongoing, before incidents happen:
   staffed on-call, tooling, playbooks, baselines,
   detection content, user training.
2. **Detection and Analysis** — a signal arrives;
   determine what it is, how bad, how big.
3. **Containment, Eradication, and Recovery** — stop
   the bleeding; remove the attacker's foothold or the
   bad artefact; return to a known-good state.
4. **Post-Incident Activity** — learn, update, close.

SANS teaches the same loop as **PICERL** — Preparation,
Identification, Containment, Eradication, Recovery,
Lessons Learned. The names differ; the actions are the
same. Pick whichever your SOC already runs; the playbooks
below use PICERL headers for brevity.

Every playbook has three sections before PICERL:

- **Trigger** — what detections / signals cause this
  playbook to run.
- **Severity default** — the starting tier (chapter 04);
  escalation rules named.
- **Owners** — the roles that must be paged
  (chapter 05's RACI applies).

And three after:

- **Evidence manifest** — what to preserve, where to put
  it, how long to retain.
- **Disclosure clocks** — what regulatory / contractual
  obligations the playbook may start.
- **Communications** — internal and external, with
  pre-approved language.

---

## Playbook A — Data-Poisoning Discovery

### Trigger

Any one of:

- Lineage integrity verification (mod-104) failed for a
  dataset version that is referenced by a model in
  production or in the current training window.
- Offline eval regression on a tracked metric exceeded
  the SLO on a model that otherwise saw no code change
  (mod-106 / mod-104's eval bundle).
- An inbound notification from a dataset upstream (data
  provider, open-source dataset maintainer, a research
  group's advisory) that a specific dataset or dataset
  range has been tampered with or should be withdrawn.
- A Falco rule (chapter 02) fired on an unauthorised
  write into the training-data store.
- A SIEM rule (chapter 01) on `AML.T0019` (publish
  poisoned datasets) fired.

### Severity default

Start at **SEV-2** (confirmed exposure without confirmed
material harm). Escalates to **SEV-1** if a model trained
on the suspect data is already serving decisions with
material impact (safety-critical, financial, healthcare)
and the window of exposure includes production traffic.

### Owners

- Incident commander: mod-111 role lead.
- Model owner (the team that owns the affected model).
- Data-platform owner (the team that owns the dataset
  store).
- Legal, if the dataset contains personal data or
  regulated content.
- Executive sponsor, if SEV-1.

### P — Preparation (ongoing)

- Dataset lineage records (mod-104) include a content
  hash per version; new ingest triggers a lineage event.
- The training pipeline refuses to run against a
  dataset version whose lineage integrity does not
  verify.
- A "quarantine" dataset version slot exists in the
  dataset store — writes allowed only from the
  incident-commander identity.
- The eval bundle for every production model is
  reproducible from a committed script.

### I — Identification

Steps the on-call performs:

1. Capture the alert context: the dataset version(s)
   suspected, the model versions trained on them, their
   deployment state (production / staged / archived).
   Query the lineage store for the full fan-out.
2. Run the integrity-verification tool against the
   suspect dataset version. Record the specific files
   whose hashes do not match the lineage record.
3. Identify the write that introduced the mismatch:
   object-store audit log, which identity, which
   timestamp.
4. Snapshot the affected dataset version to the
   incident-evidence bucket (immutable; see Evidence
   Manifest below).
5. Determine the fan-out: which models were trained on
   the version, which are deployed, and the traffic
   each has served since the earliest potentially-
   affected training run.

### C — Containment

1. If a serving model is implicated, **freeze
   promotions** of models in the affected family: push a
   deployment-admission-controller rule denying any
   promotion whose provenance references the suspect
   dataset version.
2. If the model is already serving and the SEV level is
   SEV-1, **roll back to the last known-good model**
   (previous signed artefact with provenance referencing
   a dataset version earlier than the poisoning
   window). If no such version exists, degrade to a
   fallback non-ML behaviour.
3. **Revoke the write identity** that introduced the
   bad data: disable the KSA, rotate any shared creds
   it used, add a block rule for the originating
   source IP in the dataset-store firewall.
4. Freeze new training runs that would consume the
   suspect dataset version. The training pipeline's
   admission controller rejects any run whose input
   manifest references it.

### E — Eradication

1. Remove the poisoned content from the dataset. In
   practice: mark the suspect version as "quarantined"
   in the lineage store; create a *new* clean version
   from the last known-good; update the pipeline to
   reference the clean version.
2. Rebuild any affected models from the clean dataset.
   The retrained model carries a new signed provenance
   (mod-110 chapter 02) and goes through the normal
   evaluation gate before deployment.
3. For *behavioural* contamination (the attacker
   introduced training examples designed to install a
   backdoor), add a specific detection to the eval
   bundle covering the backdoor condition — a regression
   test that catches a future attempt.

### R — Recovery

1. Promote the rebuilt model via the normal admission
   path. Observe serving metrics for the stabilisation
   window (hours to days depending on traffic).
2. Lift the deployment freeze on the model family once
   the admission controller's new policy (no
   references to the quarantined dataset) has caught up.
3. Restore the data-ingest path with the fix: a
   stricter integrity gate on write, a stricter
   allowlist on writer identities.

### L — Lessons Learned

1. Post-mortem within one week; written to the shared
   governance evidence surface (mod-109 chapter 04).
2. Update the dataset-poisoning Falco rule and the
   SIEM rule to reflect the specific pattern the
   attacker used (new objective trigger).
3. If the dataset came from an external upstream, open
   a supplier-notification conversation (mod-110).
4. Update the eval regression battery with a sample
   designed to catch the specific contamination
   pattern.

### Evidence manifest

- The affected dataset version snapshot (immutable
  object-store bucket, legal-hold tag).
- The lineage record for every model trained on it.
- The write audit record that introduced the bad data.
- The object-store access log for the surrounding
  window.
- The eval regression results that first detected the
  anomaly.
- The incident timeline (automatic from the IR tool).

### Disclosure clocks

Start by **paging legal** with the facts: which models,
which traffic, which data classification. Legal decides
whether GDPR, HIPAA, EU AI Act Article 73, or sector
rules apply. The playbook's role is to *start the
clock*, not to decide; chapter 04 is the authority on
how the clocks are tracked.

### Communications

- Internal: `#incident-ml` channel; model owners,
  data-platform owners, legal; executive if SEV-1.
- External: nothing until legal clears language.
- Pre-approved language exists in the comms repository
  for a model-training-data-integrity event; adapt from
  there.

---

## Playbook B — Prompt-Injection Exploitation in Production

### Trigger

Any one of:

- SIEM rule from chapter 01 for "agent tool call to
  unknown destination after external-untrusted
  retrieval" fired.
- Falco rule from chapter 02 observed suspicious
  outbound connect from a serving pod.
- A customer report of unexpected behaviour that maps
  to a prompt-injection payload shape (mod-107
  chapter 02).
- Red-team CI (mod-107 chapter 04) found a payload
  that bypasses production detectors; a corresponding
  production trajectory is suspected.
- Output-side DLP detector flagged a response
  containing content the agent should not have been
  able to produce (a leaked system prompt, a tool-call
  result returned to the user when it should have been
  internal).

### Severity default

Start at **SEV-3** (successful attack with runtime
prevention) if the tool call was blocked by runtime
policy. Escalate to **SEV-2** if the tool call reached a
Tier-2 destination (external send, cross-boundary
write). Escalate to **SEV-1** if the tool call succeeded
against a Tier-3 destination (payments, admin, prod
infra) or if confirmed PII / PHI / regulated data left
the boundary.

### Owners

- Incident commander: mod-111 role lead.
- ML platform / LLM-gateway owner.
- Agent owner (team that owns the specific agent
  product).
- Legal, if SEV-2 or SEV-1.
- Comms, if SEV-1.

### P — Preparation

- The LLM gateway emits trajectory logs with
  provenance labels and tool-call audits (mod-107
  chapters 02, 03).
- Tool registry supports tier-based ACLs and runtime
  kill-switches per tool (mod-107 chapter 03).
- Agent identity model allows per-agent revocation
  without a full redeploy.
- Content-filter / guardrail allows DLP-pattern-based
  blocks tunable in near-real-time.

### I — Identification

1. Pull the full trajectory for the triggering
   session: prompt fragments and their provenance
   labels, model responses, tool calls (name,
   arguments, result), runtime decisions.
2. Pull adjacent trajectories: same identity, same
   agent, surrounding time window. The attacker often
   runs multiple sessions.
3. If the trigger was an external-untrusted retrieval,
   identify the specific retrieval source and the
   stored chunk whose content injected the payload.
4. Count the **reach**: how many sessions in the last
   N days saw this retrieval chunk (or system-prompt
   cache entry, or compromised model version).
5. Classify the payload shape and map to mod-107
   chapter 02 taxonomy.

### C — Containment

1. **Disable the implicated tool** at the tool-
   registry level: push a config that returns
   "unavailable" to the runtime dispatcher. Do this
   first; investigation second.
2. **Revoke the agent's identity** (SPIFFE, OIDC,
   service-account token) via the identity provider.
   mod-105 chapter 03's rotation primitives apply.
3. **Freeze the retrieval index** at its current
   version; block writes until the compromised chunk
   is identified and excised.
4. If the system prompt was leaked, rotate any secrets
   or system-prompt-embedded references that leaked
   (hopefully there weren't any — mod-105 — but if
   there were, rotate immediately).
5. If a Tier-3 action occurred, start the response
   playbook for *that* action: a `payments.transfer`
   that fired incorrectly runs the payments-rollback
   path.

### E — Eradication

1. Remove the compromised chunk from the retrieval
   store (object-store delete; re-embed the sanitised
   remainder).
2. Patch the specific injection vector: either an
   input-side classifier update (mod-107 chapter 02),
   a tool-ACL update (chapter 03), or a prompt-
   template change.
3. Donate the payload to the red-team corpus
   (mod-107 chapter 04); a regression test is written
   so the CI gate blocks a future reintroduction.
4. If the attacker had an identity, revoke all its
   credentials and look for lateral movement in the
   adjacent audit logs.

### R — Recovery

1. Re-enable the tool at the registry only after the
   patch is deployed, the regression test passes, and
   the detection rule for the specific shape is
   covering the attack.
2. Restore the agent identity (new credentials) once
   the patch is live.
3. Normal serving resumes; monitor for the specific
   shape for the following week.

### L — Lessons Learned

1. Post-mortem within one week.
2. The red-team corpus (mod-107 chapter 04) gains the
   payload. The CI gate adds a regression test.
3. The ATLAS detection content pack (chapter 01)
   gains a tuned rule or a new rule covering the
   specific technique.
4. If reach is high, model-card update and governance
   evidence record (mod-109 chapter 04).

### Evidence manifest

- Full trajectory logs for the triggering and
  adjacent sessions.
- Tool-call audit log for the window.
- Retrieval-store snapshot at the implicated version.
- The compromised retrieval chunk (or its sanitised
  reference).
- The deployed system-prompt version at the time.
- Model version digest, runtime version, tool-registry
  version.
- Reach counter: how many sessions were exposed.

### Disclosure clocks

Starts if PII / PHI / regulated data left the
boundary (SEV-1) or if the exploit affected a
regulatory-scope agent (SEV-2 or SEV-1). GDPR Article
33 (72 h), HIPAA Breach Rule, PCI DSS, EU AI Act
Article 73 may apply; legal decides.

### Communications

- Internal: `#incident-ml`.
- External: per legal.
- If a customer-visible outage, a status-page update
  within SLA; use the pre-approved language in the
  comms repository.

---

## Playbook C — Model-Theft Indicators

### Trigger

Any one of:

- SIEM rule from chapter 01 for anomalous model-weight
  download fired.
- Membership-inference probe-pattern rule fired at
  high volume or in combination with a weight-download
  anomaly.
- Model-registry access by an identity outside the
  normal consumer set.
- A model-fingerprint / watermark check (if the
  programme runs one) found the model's weights or
  outputs on a third-party service.
- An insider report that an engineer with model access
  has resigned under contested circumstances and
  retained access during their notice period.

### Severity default

**SEV-2** on indicator alone; **SEV-1** on confirmed
exfiltration or confirmed third-party reproduction.

### Owners

- Incident commander.
- ML platform owner.
- Legal.
- Security / IR team.
- Executive sponsor if SEV-1 (model IP is often a
  balance-sheet concern).

### P — Preparation

- Model-registry access is logged with identity and
  bytes transferred.
- Registry access is network-restricted (private
  endpoints) and workload-identity-authenticated.
- Human engineer access to full model artefacts is
  minimised: inference, not raw-weight, is the default.
- A fingerprint / watermark scheme is in place if
  the model's IP value justifies it (acknowledge: this
  is an evolving field and robustness is limited).

### I — Identification

1. Identify the suspect identity, source IP, bytes
   transferred, artefacts touched.
2. Correlate with authentication logs: was there
   credential anomaly behaviour (MFA failures, new
   device, unusual geo)?
3. Pull the full window of registry access for the
   identity. Note which other artefacts were touched.
4. If the identity is a service account, trace back
   who recently invoked it and from which workloads.
5. For membership-inference probe patterns, cross-
   reference inference-endpoint access with the
   identity to establish whether the probe campaign
   and the download are the same actor.

### C — Containment

1. **Revoke the identity** immediately (mod-105
   chapter 03).
2. **Block the source IP** at the registry gateway.
3. **Pause further pulls** of the affected model
   family — the deployment-admission controller
   denies pulls not already in-flight. (A model
   already loaded into serving pods remains loaded;
   this containment is about *new* access.)
4. If the identity belongs to a specific employee or
   contractor, trigger the HR / off-boarding path:
   collect devices, suspend accounts, legal hold on
   mailboxes.
5. Preserve a copy of every artefact the identity
   touched to immutable storage.

### E — Eradication

1. Rotate any credentials, API tokens, cloud-identity
   bindings associated with the compromised identity.
2. If the identity had broader access (e.g.
   compromised a service account that also writes to
   production), run the full compromise-of-service-
   account playbook for that broader scope.
3. For the specific artefact loss: nothing eradicates
   a leaked weight file. The response is detection
   (watch for the model's fingerprint elsewhere) and
   legal (chapter 04 disclosure obligations).

### R — Recovery

1. Normal registry access resumes under tightened
   policy: new identities enrolled under stricter
   least-privilege; weight pulls require time-boxed
   approvals rather than standing permissions, where
   feasible.
2. For the leaked model: if its value justifies, train
   a successor model and plan a cutover; the leaked
   version continues to serve under watch until the
   successor is ready.

### L — Lessons Learned

1. Post-mortem within one week.
2. Governance evidence record (mod-109).
3. Registry-access policy review: can standing weight-
   download permissions be removed for most roles?
4. SIEM rule tuning for the specific access shape
   that got close.
5. Executive briefing if SEV-1.

### Evidence manifest

- Registry access logs for the identity for the
  window and the identity's full history.
- Credential-use logs (OIDC provider, cloud IAM).
- The identity's associated workload identities and
  their recent audit trail.
- The specific artefact(s) exfiltrated, with digest
  and metadata.
- Chain-of-custody record for any evidence that may
  support legal action (mod-109 chapter 04).

### Disclosure clocks

Model IP theft may trigger contractual notifications
(partners, licensors) and, if trade-secret law is
implicated, legal action with its own clock. Not
usually a privacy-regulator surface, unless training
data was co-exfiltrated with the model.

### Communications

- Internal: executive briefing, legal, security, ML
  platform owner.
- External: per legal; often not publicly disclosed.

---

## Playbook D — Agent Misuse

### Trigger

Any one of:

- Cost anomaly: a per-identity burn-rate exceeded Nx
  the per-identity SLO (mod-107 chapter 05's LLM10
  axis).
- A legitimate user triggering agent flows outside the
  authorised scope (customer-service agent being used
  to run engineering tasks).
- Insider threat indicator: an engineer running
  high-volume agent sessions outside work hours and
  against non-authorised endpoints.
- Repeated HITL approvals from the same approver on
  high-tier tool calls, suggesting rubber-stamping
  rather than due diligence (mod-107 chapter 03).

### Severity default

**SEV-3** or **SEV-4** by default; **SEV-2** if the
misuse crossed a regulated-data boundary; **SEV-1** if
material harm occurred.

### Owners

- Incident commander.
- ML platform owner.
- Finance (for cost incidents).
- HR / Legal (for insider-threat shapes).
- Agent-product owner.

### I — Identification

1. Pull the identity's trajectory logs for the alert
   window.
2. Determine whether the behaviour is a *compromised*
   identity (treat as Playbook B / C) or an authorised
   user doing something off-policy (continue here).
3. For cost incidents, confirm the burn-rate against
   the budget-manager (mod-107 chapter 05 LLM10).

### C — Containment

1. Freeze the agent's budget for the identity: the
   budget-manager returns "quota exceeded" to the
   gateway, suspending further calls.
2. For insider-threat shape, HR and Legal determine
   whether access is suspended; the IR team supports.
3. Preserve the trajectory logs; mark the identity in
   the audit trail.

### E — Eradication

1. For a *policy* gap (the user did something the
   policy permits but the policy was too lax): patch
   the tool-registry ACL to narrow the scope.
2. For a *user* gap (the user violated policy): HR
   action per the org's policy.
3. For *rubber-stamp HITL*: the HITL design is a
   finding — mod-107 chapter 03's control is to make
   the approval surface informative; redesign if the
   approver cannot reasonably assess.

### R — Recovery

1. Lift the budget freeze once the fix is in place.
2. Normalise access patterns.

### L — Lessons Learned

1. Post-mortem; the policy update is tracked in the
   policy pack (mod-109 chapter 04).
2. The budget-management SLO is reviewed in light of
   the incident.
3. Governance evidence record.

### Evidence manifest

- Trajectory logs for the identity.
- Cost accounting and budget-manager records.
- Audit trail for the HITL approvals, if relevant.

### Disclosure clocks

Usually internal. If regulated data was accessed,
Playbook B applies as well.

---

## Rehearsal — the un-skippable step

A playbook never run is a document, not a plan. The
programme's maturity grows by **tabletop** and **live-
fire** exercises:

- **Tabletop** — the on-call rota walks through a
  scenario (poisoned dataset, injection exploit, model
  theft) at a whiteboard, running against the playbook
  as it is written. Gaps become playbook edits.
- **Live-fire** — the red team actually fires a
  payload against a non-production replica of
  production (or against a flagged-off path in
  production). The response proceeds; nobody tells the
  on-call it's a drill until after. The timing
  measurements become the metrics (mean time to
  contain, mean time to notify, playbook adherence).
- **Cadence** — twice a year per playbook. Playbooks
  go stale.

Every exercise produces findings that update the
playbook, the detection content, the Falco rules, and
the severity ladder. See chapter 04 for the metric
feedback loop.

---

## Standard failure modes

- **Playbooks that read as narrative.** On-call wants
  numbered steps with commands. "Investigate the
  session" is not a step; "run `kubectl -n ml-serving
  logs <pod> --since=1h --follow`" is.
- **Playbooks that assume context.** The on-call is
  not the agent's product owner; they do not know
  which tool is Tier-3 unless the playbook names it.
- **Playbooks without an evidence manifest.** The
  post-mortem has anecdotes; the governance surface
  has nothing to audit.
- **Playbooks that skip the disclosure page.** Legal
  learns about the SEV-1 at the retro; the 72-hour
  clock is already stale.
- **Playbooks that cannot be run in a drill.** The
  tool-registry kill switch requires a human approval
  that only exists during business hours; the real
  3 a.m. containment cannot happen. Fix the
  containment control, not just the playbook.
- **Playbooks maintained outside Git.** The on-call
  reads a wiki version that is three commits behind
  the production policy pack.
- **"Playbook done" at eradication.** Recovery and
  learning get skipped; the regression test is never
  written; the next incident is identical.
- **One mega-playbook.** A single document covering
  "any AI incident" collapses under its own weight.
  One playbook per incident shape; each short.
- **The runtime kill switch has side effects nobody
  understands.** Disabling a tool breaks downstream
  agents in ways the owner did not anticipate. The
  pre-authorised containment set is tested; nothing
  gets added without a dry run.

---

## Summary

- **Four AI-specific playbooks** — data poisoning,
  prompt-injection exploitation, model theft, agent
  misuse — each written against the PICERL / SP 800-61
  loop with trigger, severity default, owners,
  evidence manifest, disclosure clocks, and
  communications.
- **Each step is executable at 3 a.m.** — commands,
  expected outputs, next steps — not narrative.
- **Containment comes before investigation.** The
  common pattern: disable the tool / revoke the
  identity / freeze the index first; dig in second.
- **Every playbook ends in "learn."** The red-team
  corpus (mod-107 chapter 04), the detection content
  pack (chapter 01), the Falco rules (chapter 02), and
  the governance evidence surface (mod-109 chapter 04)
  all gain content from the incident.
- **Rehearsal is non-optional.** Tabletops and live-
  fire exercises keep the playbooks current;
  cadence of twice a year per playbook.
- Standard failure modes are narrative playbooks,
  playbooks that assume context, playbooks without
  evidence manifests, playbooks that stop at
  eradication, and playbooks the kill switch cannot
  actually execute.
