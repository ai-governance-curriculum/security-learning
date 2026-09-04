# Exercise 05 — Secret Leak Runbook

**Estimated effort:** ~3 hours
**Deliverable:** A runbook bundle consisting of (a) a
top-level detect / contain / rotate / notify master
document with the SLA table for the target platform,
(b) one filled-in per-class runbook file for **every
severity-1 secret class** in exercise 01's inventory,
(c) the detection routing table naming source → alert
payload → channel → owner, (d) a rehearsal calendar
with a walked-through game-day for at least one class,
and (e) the post-drill improvement log capturing what
missed SLA and why.
**Prerequisites:** Exercise 01 (the inventory names the
classes, the owners, and the blast radii — the runbook
is the operational shell around it). Exercise 02
(Vault detections wire into the detect phase). Exercise
03 (KMS-key compromise runbook depends on the key
hierarchy). Exercise 04 (signing-key compromise runbook
depends on the keyless-CI trust policy). Chapter 05
read end-to-end. Familiarity with the org's incident-
management tooling (PagerDuty / Opsgenie / equivalent)
and its declared incident-severity scheme.

---

## Objective

Author the runbook the on-call engineer executes when a
secret leaks in the target ML platform. The runbook must:

- Cover every severity-1 secret class from the exercise
  01 inventory with a class-specific fill-in of the four
  phases from chapter 05.
- Bind every phase to a measurable SLA that a post-mortem
  can grade against, not a vague verb.
- Route every detection source (pre-commit scanner, CI
  scanner, provider webhook, Vault audit, KMS anomaly,
  IAM anomaly) into one paged incident channel with a
  structured payload — no raw secret values.
- Prove itself with a rehearsal — a game-day walk-through
  that produces timing evidence, not just a "we discussed
  it" note.
- Update itself. Every drill and every real incident
  ends in the runbook getting edited.

By the end you should have a document the on-call rotates
around at 3 AM without needing to interpret it, and a
rehearsal record that shows it has been walked through
on real timing — not just written.

---

## Problem statement

Take the platform from exercise 01 and its inventory rows.
The current-state incident response for a leaked
credential in this org:

- **Detection.** GitHub Advanced Security push protection
  is on for the org; GitHub Secret Scanning is enabled;
  gitleaks runs on every PR as an advisory (non-blocking)
  check. Vault audit and KMS CloudTrail events flow into
  Datadog but have no incident routing. GuardDuty is on
  in every AWS account.
- **Alerting.** Findings from all scanners land in a
  `#sec-alerts` Slack channel. The channel is not paged;
  it is monitored during business hours by whoever is
  around. There is a shared `sec-oncall@` email that fires
  on a schedule but no clear ack SLA.
- **Runbook.** A single Confluence page titled "What to
  do if a secret leaks" written eighteen months ago,
  referenced twice, never rehearsed. Half its links 404.
- **Regulatory posture.** The org is a US fintech serving
  EU customers; PII is under GDPR + US state laws; a
  healthcare-partner subset is under HIPAA. Regulator
  notification decisions are made by legal, not by
  security engineers.
- **Recent history.** An `AKIA…` key was committed to a
  notebook two quarters ago. Time from commit to rotation
  was somewhere between "eight hours" and "a day" (the
  Slack thread was not preserved). The incident review
  never happened.

If your real target platform differs, substitute — the
exercise structure is identical.

---

## Requirements

### Section 1 — Master runbook document

A single Markdown document that a new on-call reads first.
It contains:

1. **Severity classification.** Explicit definitions of
   severity 1, 2, and 3 for this platform, keyed to
   exercise 01's blast-radius column. A leaked signing key
   is severity 1; a leaked read-only dev token is
   severity 3. The document names the specific secret
   classes (and, where useful, individual inventory rows)
   that map to each severity.
2. **SLA table.** The four phases (detect / contain /
   rotate / notify) crossed with the three severities.
   Every cell holds a concrete number — minutes, hours —
   not a verb. Cite the reasoning where a number departs
   from chapter 05's starting points (regulatory regime,
   contractual requirement, operational cost).
3. **Roles and paging.** Who is the incident commander,
   who is the containment operator, who is the notifier,
   who is legal, who is comms. Each role names the paging
   handle (a rotation, not a person) that fires it.
4. **Kill switch.** The one command / one dashboard that
   the containment operator opens when the pager fires —
   the "start here" that eliminates the "wait, where do I
   log in" delay.
5. **Cross-references.** Explicit links to every per-class
   runbook (Section 2) and every detection route
   (Section 3).

### Section 2 — Per-class runbook files

For **every severity-1 secret class** in the exercise 01
inventory, author one runbook file in the shape shown at
the end of chapter 05. Each file must contain:

- **Header.** Class name; exercise-01 inventory reference;
  severity; owning teams for contain / rotate / notify;
  the SLA numbers (echoed from the master table).
- **Contain steps.** The literal commands or console
  actions to make the credential unusable — `aws iam
  update-access-key --status Inactive …`, `vault lease
  revoke …`, `kms:DisableKey …`, and so on. Every
  destructive action names its reversibility.
- **Rotate steps.** The step-by-step to issue a new
  credential and cut consumers over. For dynamic
  credentials, this reduces to "revoke; next request
  auto-issues" — say so explicitly, do not skip the row.
- **Notify steps.** Internal notifications (who to page /
  slack / email within the internal SLA) and the trigger
  for legal to evaluate external notification.
- **Cutover verification.** The queries or checks that
  prove the new credential is in use and the old one is
  silent — a provider audit query, a Vault lease list, a
  KMS `KeyUsage` metric, and so on.
- **Post-incident.** The checklist item to update the
  inventory (exercise 01), the runbook (this file), and
  the rehearsal calendar (Section 4).

Minimum coverage — you must have a per-class file for at
least these seven ML-specific classes named in chapter 05:

1. Training-data-store credentials.
2. Feature-store credentials (with the
   compromise-window model-poisoning check).
3. Model-registry credentials (with the compromise-window
   version audit).
4. External-API keys (with the finance / prompt-exposure
   notification path).
5. Model-artifact signing keys (with the re-sign +
   compromise-window denylist workflow).
6. Judge-model credentials (with the compromised-judge
   rollout re-evaluation).
7. PII/PHI decryption keys — KMS CMK compromise (with
   "disable, do not schedule deletion until re-wrap"
   handling).

Additional classes appearing as severity-1 in the target
inventory (CI OIDC role, cluster admin credential, break-
glass root, and so on) also require their own file.

### Section 3 — Detection routing table

One row per detection source. Every row must fill every
cell — a source without a destination is a source that
does not exist.

| Source | Trigger | Alert payload fields (structured, no raw secret) | Destination channel + paging rotation | Ack SLA | Auto-triage rule (if any) | Owning team |

Sources to cover (add any others live in the target
platform):

- Pre-commit / pre-receive scanner (gitleaks / GHAS push
  protection).
- CI-pipeline scanner (per-PR + per-`main`).
- Historical repo scans (periodic full-history).
- Artifact scans (container images, model weights,
  notebooks).
- Log / metric scanning for secret-shaped strings.
- Provider-side alerts (GitHub Secret Scanning, AWS
  token-leak notifications, third-party SaaS webhooks).
- Vault audit anomalies (chapter 02: read-rate spike,
  denied paths, root-token use, auth-config change).
- KMS audit anomalies (`Decrypt` spikes, unexpected
  principal, wrapped-DEK unwrap rate).
- Cloud IAM anomalies (GuardDuty / SCC / Defender).

Payload rules:

- **Never** include the raw secret value. Hash it
  (`sha256:…`) and correlate by hash.
- Include `secret_class` keyed to the exercise 01
  inventory taxonomy, `location`, `detector`,
  `severity_guess`, and a `correlation_id`.
- Any suppressed / auto-triaged alert is logged, not
  silent.

### Section 4 — Rehearsal calendar and game-day

The written runbook is a hypothesis; the rehearsal is the
test.

Produce:

- A **rehearsal calendar** — quarterly per severity-1
  class, plus one annual cross-team drill including
  security / platform / legal / comms.
- A **game-day script** for at least one class (author's
  choice; the signing-key one is a strong candidate
  because it exercises the most cross-team coordination).
  The script names: the synthetic-leak injection method
  (no real secret used), the participants and their
  roles, the wall-clock start time, and the observer
  who records timing.
- The **observation record** from an executed dry run of
  the game-day (a walk-through with the actual team is
  ideal; a tabletop with individual role-holders is
  acceptable for the exercise). Record:
  - Time from alert-fire to first-human ack.
  - Time from ack to containment action.
  - Time from containment to rotation cutover.
  - Time from alert to first internal notification.
  - Every dependency that surprised the team (missing
    permission, stale link, ambiguous owner).

### Section 5 — Post-drill improvement log

The final section is the delta between the runbook as
written and the runbook as executed. For each SLA gate
missed and each surprise dependency, one entry:

| Finding | Root cause | Runbook edit (link to the specific line the edit changes) | Owner | Deadline |

The improvement log is the exercise's real proof of
value. A drill that produced no edits either found a
perfect runbook (unlikely on first pass) or a drill that
did not stress the runbook.

### Section 6 — External notification appendix

A non-authoritative summary of the regulator-notification
regimes in scope for the target platform, with the SLA
window each requires. Explicitly cite the primary source
for each and mark anything you could not confirm from a
primary source with `<!-- needs-research: … -->`. Legal
owns the decision at incident time; the runbook's job is
to put legal in the room, with the facts, within the
SLA.

At minimum, name the regime, cite the primary source
(regulation article / statute), and record the current
notification-window text — do **not** invent numbers.
Chapter 05's `needs-research` note applies here.

---

## Starter guidance

- Do exercise 01 first and hard. The runbook is a fill-in
  over the inventory; a weak inventory means a weak
  runbook. If a class has no owner in exercise 01, the
  runbook exposes that gap immediately.
- Author the master document first, then produce per-class
  files by templating the shape shown at the end of
  chapter 05. Do **not** copy-paste blindly — every
  per-class file must have its own contain / rotate /
  notify substance; the shell is shared, the substance is
  not.
- Pick one per-class runbook to make the reference
  example — the signing-key runbook is a strong choice
  because it forces you through Rekor revocation lists,
  admission-policy denylists, and re-signing workflows.
  The other files can be terser once one is deep.
- For the SLA numbers, chapter 05 gives starting points
  for a regulated fintech / healthcare posture. Adjust
  for your risk appetite and regulatory regime, but do
  not loosen without a written justification — SLA
  slippage is the failure mode.
- Rehearse without a real leak. Use a hash of a
  never-issued fake secret; wire the detector to fire on
  the fake pattern. The point is to exercise the
  human-and-process path, not to actually burn a
  credential.
- Involve legal early on Section 6. The external-
  notification appendix is where security engineers most
  often invent numbers; do not.
- If the org has no PagerDuty / Opsgenie yet, do not stop
  — write the pager column as "Slack channel `#sec-oncall`
  with 24/7 on-call rotation on top of it (dependency:
  set up the rotation)" and file the rotation as a
  prerequisite ticket. The runbook can exist without the
  paging tooling but must name what the tooling will be.

## Acceptance criteria

A passing document:

- Master runbook defines severities, SLA cells for all
  four phases × three severities, roles with paging
  rotations, and the kill-switch action.
- Per-class runbook exists for every severity-1 secret
  class in the exercise 01 inventory (at minimum, the
  seven ML-specific classes from chapter 05 are
  covered).
- Every per-class file contains contain / rotate /
  notify / verify / post-incident sections with concrete
  commands (not "revoke the credential" — the literal
  CLI or console action).
- Detection routing table has one row per source with no
  empty cells; alert payloads use hashed secret values.
- Game-day script is executable (a colleague could run
  it) and the observation record has real timing
  numbers.
- Improvement log has at least one entry that
  demonstrably changes the runbook after the drill.
- External-notification appendix cites primary sources or
  is explicitly marked `needs-research`.

A failing document:

- Any SLA cell reads "as soon as possible", "promptly",
  "asap", or similar — the phase's SLA must be a
  measurable number.
- A per-class runbook that omits any of the four phases,
  or that says only "revoke" without the concrete
  action.
- Detection payload example that contains (or would
  contain) the raw secret value.
- No rehearsal record — a runbook without a walked-
  through drill has not been tested.
- Improvement log is empty — either the drill was too
  gentle or the runbook was not actually exercised.
- External-notification numbers invented from memory —
  regulator SLAs must cite a primary source or be marked
  `needs-research`.
- Any class in the exercise 01 inventory marked
  severity-1 that does not have a corresponding
  per-class runbook file.

## Stretch goals

- **Chaos-inject a live drill.** With platform-security
  approval, wire the detection routing so that a
  synthetic "canary" secret pattern fires the full paging
  path end to end (real page, real ack, real containment
  of a fake credential you provisioned for the drill).
  This exposes rotation-tooling drift that a paper drill
  will not.
- **Automated containment.** For the AWS-key class,
  design (do not implement in prod) an EventBridge
  → Lambda that auto-runs `update-access-key --status
  Inactive` on any newly-detected `AKIA…` in a public
  repo. Discuss the failure modes: false positives, the
  Lambda's own credential's blast radius, the audit
  requirement for automated destructive actions.
- **Cross-team notification templating.** Author the
  three canned messages a notifier drafts under time
  pressure: the internal Slack thread opener, the legal-
  handoff summary, the customer notification draft (for
  legal to edit, not send). Templates cut minutes off
  the notify SLA.
- **Regulator-timing decision tree.** Turn Section 6
  into an explicit decision tree — "if this class + this
  data + this jurisdiction, then this regime and this
  clock starts at this event". Legal signs the tree; the
  runbook links to it.
- **Post-mortem template pinned.** Author the post-
  mortem template the incident-commander fills after a
  real incident; wire it so that closing the incident
  requires filling it, and the template's final section
  ("runbook edits") lands as commits to this document.
- **Rehearsal metric wall.** Publish a dashboard showing
  drill-to-drill trend on the four SLA gates. Regression
  quarter-over-quarter is a signal the runbook is
  rotting; improvement quarter-over-quarter is the whole
  point of doing this.

## Do not

- Do not include real secret values, real hashes of
  real production secrets, or real cloud account IDs in
  any deliverable — placeholders only.
- Do not use real customer names or partner names in
  runbook examples; use `partner-a`, `tenant-retail`,
  and so on.
- Do not make legal-notification decisions in the
  runbook itself — the runbook triggers legal, legal
  decides. A runbook that pre-decides regulator
  notification will misfire when a real incident lands
  and the regime turns out to differ from what was
  written.
- Do not skip the rehearsal record. A runbook without
  timing evidence is exercise-01 for chapter 05 — real
  work starts with the drill.
- Do not invent regulator SLA numbers. Cite the primary
  source or mark `needs-research`.
- Do not commit a "we'll rotate later" plan for any
  severity-1 credential currently in the target
  platform's long-lived-credential list from exercise
  01 — exercise 02 or 04 owns the rotation itself, but
  the runbook must not paper over the current gap.
- Do not commit a solution here — solutions live in the
  paired solutions repo.
