# Chapter 05 — The Secret-Leak Response Runbook

> **Note on AI-assisted content.** SLA numbers below are
> *starting points* for a runbook, not authoritative regulatory
> minima. Verify against your specific regulatory regime and
> your organisation's incident-response policy before adopting.
> See [`resources.md`](./resources.md).

---

## Why this chapter exists

Chapters 01–04 shrank the surface: fewer long-lived
credentials, per-object encryption, keyless CI. The residual
risk is real, and it eventually fires. This chapter is the
runbook — the sequence you execute when a secret leaks.

The specific failure mode this chapter is written to prevent:

> A GitHub Advanced Security scan alerts on a commit merged
> yesterday: a long-lived AWS access key is in a Jupyter
> notebook. The alert lands in a Slack channel. The channel is
> muted by the two engineers who normally would triage it. Six
> hours pass. When someone reads the alert, the discussion
> ("should we rotate?" "who owns this?" "wait, is this the
> real prod key or the sandbox one?") takes another four hours.
> The rotation itself takes fifteen minutes. Total time between
> leak and rotation: 10 hours 15 minutes, of which 15 minutes
> was actual work.

The runbook exists so that the answer to "who owns this" and
"what do we do" is a lookup, not a discussion. Chapter 01's
inventory named the owner; this chapter names the steps.

You leave this chapter able to:

- Name the four runbook phases (detect, contain, rotate,
  notify) and the SLA that gates each.
- Author a per-secret-class runbook variant — a signing-key
  leak differs materially from a database-credential leak
  differs from a KMS-CMK compromise.
- Read a leak alert and, within minutes, decide the initial
  severity classification and mobilise the right responders.
- Rehearse the runbook (game-day drills) and improve it
  between rehearsals.

---

## The four phases and their SLA gates

Every leak-response has four phases, and each has an SLA that
should be defined and measured. The numbers below are starting
points for a regulated fintech / healthcare posture; adapt for
your risk appetite and regulatory regime.

| Phase | Question | Starting SLA (severity 1) | Starting SLA (severity 2) |
| --- | --- | --- | --- |
| **Detect** | The gap between the leak occurring and the org knowing | Continuous detection; alert on-call within **5 min** | Same |
| **Contain** | Cut the attacker's ability to use the credential | Deny / revoke within **15 min** of alert acknowledgement | **60 min** |
| **Rotate** | Issue a new credential and cut over consumers | Fully cut over within **4 h** of alert | **24 h** |
| **Notify** | Inform the humans and systems that need to know — legal, comms, customers, regulators | Internal notification within **1 h**; regulator/customer notification within the applicable regime deadline | Same |

Severity classification (start point):

- **Severity 1** — signing key, KMS CMK, key that protects
  production customer data, prod deploy credential.
- **Severity 2** — non-production credential, low-blast-radius
  bearer token, read-only access to non-sensitive data.
- **Severity 3** — expired secret, correctly-rotated secret
  found in stale location, false positive.

The **detect** SLA is the one most orgs get wrong — you cannot
respond to what you do not see. Continuous scanning of every
commit, every log stream, every artifact — plus the alert
channel being staffed 24/7 with acknowledgement SLA — is
non-optional for production-affecting secrets.

---

## Phase 1 — Detect

Detection sources, in decreasing order of latency to leak:

- **Pre-commit secret scanning.** Tools like
  [gitleaks](https://github.com/gitleaks/gitleaks),
  [detect-secrets](https://github.com/Yelp/detect-secrets),
  [trufflehog](https://github.com/trufflesecurity/trufflehog)
  run at commit time; the earliest possible catch. Even better:
  wire the same tool into a **pre-receive hook** on the git
  server (or GitHub Advanced Security's push protection) so the
  push itself is refused.
- **CI-pipeline scanning.** Same tools, invoked on every PR
  and on `main`. Catches secrets that slipped past
  pre-commit.
- **Repository history scans.** Periodic scans of every branch
  and every historical commit (secrets in old commits are still
  leaked). Catches historical leaks and re-scans against new
  patterns.
- **Artifact scans.** Scan built container images, model
  weights (they can contain accidentally-embedded config /
  tokens), and notebooks for secrets.
- **Log / metric scanning.** Watch application logs and
  request/response bodies for secret-shaped strings. This is
  the last line of defence and often catches secrets an
  attacker has *actually used* rather than merely committed.
- **Provider-side alerts.** GitHub Secret Scanning, GitLab
  Secret Detection, and many SaaS providers (AWS, Stripe,
  GitHub itself) will notify you when they detect one of their
  own tokens on a public source. Wire the webhook to your
  incident channel.
- **Vault / KMS audit anomalies.** Chapter 02 covers
  Vault-audit detections; the equivalent applies to KMS —
  spike in `Decrypt` calls, decrypt attempts by an unexpected
  principal, `GetSecretValue` calls at unusual rate.
- **Cloud IAM anomalies.** GuardDuty / Security Command
  Center / Defender alerts on unusual credential usage —
  logins from a new ASN, API calls the credential has never
  made before, calls at odd hours.

The alerting rule: every detection source pipes into **one**
incident channel (paged, 24/7 acknowledgement) with a
**structured payload**:

```
{
  "detector": "gitleaks-ci",
  "secret_class": "aws-access-key",  # class per chapter 01
  "location": {"repo": "…", "commit": "…", "path": "…", "line": …},
  "match_pattern": "AKIA[0-9A-Z]{16}",
  "matched_value_hash": "sha256:…",  # never the raw value
  "correlation_id": "…",
  "severity_guess": "1"  # detector's initial guess, human confirms
}
```

Notes:

- **Never put the raw secret value into the alert.** The alert
  itself is a leak surface. Hash the value; the responder
  correlates by hash with the store.
- **Correlate to inventory.** The `secret_class` and `location`
  fields let the responder look up the chapter-01 inventory
  row: owner, blast radius, contain steps. If the secret has
  no inventory row, that is itself a finding.
- **Auto-triage low-risk classes.** A test-fixture token in a
  fixtures directory can be auto-triaged if there is a clear
  fingerprint (e.g. `AWS_ACCESS_KEY_ID=AKIAEXAMPLEEXAMPLE`).
  The auto-triage must be observable — a suppressed alert is
  logged, not silent.

---

## Phase 2 — Contain

Contain means: **make the credential unusable, or make its use
impossible from the paths the attacker likely has**. Rotation
(phase 3) comes after — containment is the fast action.

Containment actions by secret class:

- **AWS access key.** `aws iam delete-access-key
  --access-key-id AKIA…` if certain the key is fully replaced;
  otherwise `aws iam update-access-key --access-key-id AKIA…
  --status Inactive` (reversible), which immediately breaks
  the attacker's use without deleting the audit record.
- **Vault-issued dynamic credential.** `vault lease revoke
  <lease-id>` (or `vault lease revoke -prefix <path>`) — Vault
  removes the DB user immediately.
- **Vault-stored static token.** Overwrite the KV path with a
  placeholder value; then rotate the underlying provider
  token in the provider's console.
- **KMS CMK compromise.** Disable the key
  (`kms:DisableKey`); do **not** schedule deletion yet
  (deletion is irreversible and you may need to re-wrap DEKs
  first). Every application relying on the key will fail on
  its next call — coordinate with app owners before disabling
  a production key.
- **Cosign signing key.** For keyed cosign, revoke the key
  and add the identity to a Sigstore Rekor "revoked" list
  consulted by verification policy. For keyless cosign, the
  cert is already short-lived; the containment is to tighten
  the CI trust policy so no new certs can be issued to the
  compromised identity.
- **CI OIDC role.** Update the trust policy to add a
  `Condition` that denies the specific compromised branch or
  workflow; or delete the trust policy altogether if the CI
  system itself is suspect.
- **Kubernetes service-account token.** Revoke the SA
  (`kubectl delete serviceaccount <name>`) or rotate the
  cluster's SA-token signing key (SA-token rotation is a
  cluster-wide operation, use only if wide compromise
  suspected).
- **Third-party API key (OpenAI, Anthropic, etc.).** Revoke
  via the provider's console API; the provider must also
  invalidate any cached auth server-side. Provider-specific
  latency for revocation varies — some are instant, some are
  delayed. Verify.

The universal containment principle: **contain before you
investigate**. The compromise is real until the credential is
inert; investigation happens in parallel, not before.

**When containment causes an outage.** For a production
credential in active use, containment breaks the workload. The
tradeoff is: outage now vs data exfiltration continuing.
Default to containment; if the specific credential is
essential and the leak evidence is thin, escalate to the
incident commander for a hold decision — but the default is
contain.

---

## Phase 3 — Rotate

Rotate = issue a new credential and cut every consumer over
to it. The steps are secret-class-specific.

For **dynamic credentials** (Vault-issued DB users, cloud IAM
STS): rotation is automatic. Vault revoked the lease in phase
2; the next request from the workload issues a fresh
credential. Nothing else to do.

For **static credentials** (KV-stored bearer tokens, cloud
access keys not federated via OIDC): the rotation is a
multi-step operation:

1. **Provision the new credential** in the provider.
2. **Store it in Vault** at the same path, incrementing the
   KV version.
3. **Trigger the consumer to re-read** — either by restart
   (if the consumer reads once at startup) or by the Vault
   Agent's automatic renewal (if the consumer reads via
   sidecar and the sidecar polls for KV updates).
4. **Verify the new credential is in use** — check the
   provider's audit log for the new token being used and the
   old one falling silent.
5. **Delete the old credential** in the provider only after
   verification.

For **key material** (KMS CMK, signing key):

1. **Rotate the KEK.** For AWS KMS with automatic rotation,
   this is a `RotateKeyOnDemand` call; the alias points at
   the new material; wrapped DEKs are re-wrapped as they are
   next used. For manual rotation, create a new key,
   re-point aliases, re-wrap DEKs (potentially a
   background job — chapter 03).
2. **Do not delete the old KEK material immediately.** Any
   ciphertext still wrapped under the old material becomes
   unrecoverable if you do. Schedule deletion for the end of
   the re-wrap window (days to weeks depending on data
   volume).
3. **Add the old material's identifier to a revocation list**
   so any surprise ciphertext under the old material is
   surfaced rather than silently succeeding.

For **signing keys** (cosign, in-toto):

1. **Rotate the signing identity.** For keyless cosign, that
   is a CI-identity change (the SAN pattern the admission
   verifier accepts); for keyed cosign, that is a new key.
2. **Re-sign artifacts** that must remain trustworthy.
   Artifacts signed by the compromised identity in the
   compromise window must either be re-signed by the new
   identity, or added to a **denylist** at the admission
   verifier so downstream consumers refuse them.
3. **Publish the compromise window** (a signed statement
   naming the compromised identity and the time window of
   distrust) so downstream verifiers can reject
   compromise-window signatures forever.

**Cutover verification** is the step that separates "rotated"
from "rotated on paper". The runbook must include:

- A **confirmation query** against the provider's audit log
  showing the old credential's last use was before rotation
  and the new credential is in use.
- A **secret-scanner rerun** on the code / artifact where
  the leak was found, confirming the new credential is not
  itself now leaked.
- A **regression check** on the workload that uses the
  credential — the rotation may have missed a caller. Chapter
  01 inventory drives this list.

---

## Phase 4 — Notify

The notification phase runs partly in parallel with contain
and rotate.

**Internal notification (SLA: within 1 hour of alert):**

- Incident commander (rotates by on-call schedule).
- Owning team's on-call (per chapter 01 inventory row).
- Security-leadership on-call.
- Communications / legal on-call (they decide external
  notification timing; they need lead time).

**External notification (SLA: per regime):**

- **Regulators.** GDPR Article 33 has a 72-hour notification
  requirement for personal-data breaches (verify current text
  against the applicable jurisdiction; this changed post-
  Brexit for UK, and other regimes differ). HIPAA Breach
  Notification Rule has separate timing (verify against 45
  CFR §§ 164.400 et seq.). US state-level data-breach laws
  each have their own timing.
  <!-- needs-research: pin the current article/section
  numbers and deadlines per applicable jurisdiction — GDPR,
  UK GDPR, HIPAA, US state laws, EU AI Act (for AI-system
  incidents), CCPA, etc. Do not adopt these numbers as
  authoritative without verification against the primary
  source. -->
- **Customers.** Where a breach exposed customer data,
  customer notification obligations follow regulatory
  requirements; work with legal and communications on
  wording and channels.
- **Partners / downstream consumers.** If a signing key
  was compromised, downstream consumers of signed artifacts
  need to know within the same window as regulators — every
  minute they run the compromised artifact is a minute of
  ongoing risk.

The **notification decision** is a legal / privacy decision,
not a security-engineering decision. The runbook's job is to
put legal in the room, with the facts, within the SLA.

---

## The per-class runbook variants

The four phases above are the shell; the substance is the
per-secret-class fill-in. Below are the seven ML-specific
classes from chapter 01, each with its distinctive step. Full
per-class runbooks are exercise-05 deliverables.

**Training-data-store credentials.** Contain via Vault lease
revoke or IAM deactivation; rotate via re-issue; notify data-
protection team (a read of the training corpus is a potential
data-subject-access event).

**Feature-store credentials.** Contain and rotate as above;
additionally verify no writes to the online store during the
compromise window — a compromised feature-store write is a
model-poisoning event (mod-106 scope) and requires model
rollback to a pre-compromise snapshot.

**Model-registry credentials.** Contain by rotating the
credential and, critically, **audit every model version
registered during the compromise window**. Any suspicious
version is quarantined until re-verified. Downstream deploys
that pulled from the registry in the window are re-evaluated.

**External-API keys (class 4).** Contain via provider console;
rotate via provider API; notify finance (cost exposure) and
security (data-exposure via the provider's request logs, if
they contain sensitive prompts).

**Model-artifact signing keys.** The highest-blast-radius
class. Contain by disabling the signing identity; rotate to
a new identity; **re-sign every artifact meant to remain
trustworthy**, publish the compromise-window denylist to
every admission verifier, and audit the transparency log
(Rekor) for signatures issued in the window by the
compromised identity. Chapter 04 makes this cheaper by
making signatures per-CI-run and per-identity.

**Judge-model credentials.** Contain and rotate as class 4;
additionally, verify that no rollouts were gated by the
compromised judge during the compromise window (a compromised
judge could have permitted a bad rollout). If any were,
re-evaluate those rollouts with the rotated judge.

**PII/PHI decryption keys.** The KMS runbook. Disable the
key; **do not delete** until every ciphertext wrapped by the
key has been re-wrapped or archived; notify privacy /
compliance (a key-compromise on regulated data is a
data-breach event in most regimes).

---

## Rehearsal — the runbook's real quality check

A runbook that has never been rehearsed is a runbook that
will not survive its first fire. Rehearse:

- **Quarterly, per severity-1 secret class.** A game-day
  drill: injection of a synthetic leak alert, timed walk-
  through of the runbook, capture of every step that took
  longer than the SLA.
- **Annually, cross-team.** A larger drill involving
  security, platform, legal, comms — the notification
  phase's real bottleneck is usually cross-team coordination,
  not the technical steps.
- **After every real incident.** A post-mortem that updates
  the runbook with everything that was learned. The runbook
  is a living document; if it did not change after an
  incident, the post-mortem missed something.

The rehearsal captures:

- Time from alert to acknowledgement.
- Time from acknowledgement to containment.
- Time from containment to rotation completion.
- Time from alert to internal notification.
- Any dependency that was not documented (a step required
  access nobody had; a runbook link that 404'd).

---

## What the runbook file actually looks like

A per-class runbook file:

```
# Runbook: Model-Artifact Signing Key Compromise
#
# Severity: 1
# Chapter-01 inventory class: 5
# Owner (contain): platform-security-oncall
# Owner (rotate): platform-security-oncall
# Owner (notify): security-leadership + legal
#
# SLA
#   Detect → Acknowledge: 5 min
#   Acknowledge → Contain: 15 min
#   Alert → Rotate cutover: 4 h
#   Alert → Internal notify: 1 h
#   Alert → External notify: per regime (legal decides)
#
# Contain
#   1. Determine whether the signing identity is keyed or keyless.
#   2. If keyed: disable the key in the KMS
#      `aws kms disable-key --key-id <arn>`.
#   3. If keyless: update the CI trust policy to remove the
#      compromised branch / workflow pattern; verify Fulcio
#      rejects new signing requests from the identity by
#      test-run.
#   4. Post to Rekor a revocation entry naming the identity and
#      the compromise start time.
#
# Rotate
#   1. Provision a new signing identity (new SPIFFE ID + Fulcio
#      config, or new keyed CMK for the legacy path).
#   2. Update the CI workflow to sign with the new identity.
#   3. Re-sign every artifact meant to remain trustworthy.
#      Query: `list all model artifacts in <registry> with
#      last-signed-at > <compromise start>`. For each, either
#      re-sign or add to admission denylist.
#   4. Update admission verifier policy to (a) accept new
#      identity, (b) reject compromise-window signatures from
#      old identity, (c) log any deploy attempt that would have
#      matched the old identity.
#
# Notify
#   1. Internal (< 1 h): #incident-response, security-leadership
#      pager, legal, comms.
#   2. External (per legal): downstream consumers of signed
#      artifacts, regulators (if applicable), customers (if
#      applicable).
#
# Cutover verification
#   1. New identity is signing new artifacts (Rekor query).
#   2. Admission verifier rejects old-identity signatures
#      dated after compromise start (test with a synthetic
#      signature; expect a rejection).
#   3. Every downstream consumer has pulled the updated
#      verification policy.
#
# Post-incident
#   1. Update chapter-01 inventory with any drift found.
#   2. Update this runbook with every step that missed SLA.
#   3. Schedule the next quarterly rehearsal.
```

The exercise-05 deliverable is one such file per severity-1
secret class in the target platform's inventory.

---

## Common mistakes

- **No detect SLA.** "We rotate when someone tells us" is
  not a runbook; it is a hope. Detection is the first SLA.
- **Contain-then-investigate inverted.** Investigating
  before containing gives the attacker more of the resource.
  Contain first.
- **Rotating without cutover verification.** A "rotated"
  credential that is still the value some cached client
  presents is unchanged from the attacker's perspective.
  Verify the new credential is in use.
- **Notification decisions made by security engineers.**
  Legal decides external notification; security's job is to
  give them the facts within the SLA.
- **Runbook that has never been drilled.** Every step that
  has not been walked through recently is a step that will
  discover a broken link, a missing permission, or a stale
  owner at 3 AM.
- **No feedback loop from incidents to inventory.** Every
  incident should update chapter 01's inventory — a leaked
  secret that had no inventory row means the inventory is
  incomplete; a rotation that hit consumers not listed in
  the inventory means the inventory is inaccurate. Fix both,
  every time.
- **SLA numbers copied blindly from another org.** The
  numbers in this chapter are starting points. Your org's
  SLAs are set by your regulatory context and by the results
  of your rehearsals — not by another team's template.

---

## Summary

- Every leak-response has four phases — detect, contain,
  rotate, notify — each with an SLA that is defined,
  measured, and rehearsed.
- Detection is continuous, multi-source (commit scan, CI
  scan, history scan, artifact scan, log scan, provider
  webhooks, Vault/KMS audit anomalies, cloud IAM anomalies),
  and pipes into one alert channel with structured payloads
  that never contain the raw secret.
- Containment precedes investigation. Make the credential
  inert first; the compromise is real until proven otherwise.
  Dynamic credentials (Vault-issued) are trivially contained
  by lease revoke; static credentials require provider-side
  disable/rotate; KMS CMKs are disabled (not deleted) until
  re-wrap completes.
- Rotation is per-class: dynamic credentials rotate
  automatically; static credentials require provision → store
  → cutover → verify → delete-old; keys require re-wrap and
  publication of a compromise window; signing keys additionally
  require re-signing or denylisting artifacts from the
  compromise window.
- Notification runs partly in parallel; legal owns the
  external-notification decision; the runbook's job is to
  put legal in the room with the facts within the SLA.
- The runbook is per-class; the seven ML-specific classes
  from chapter 01 each get their own file with contain /
  rotate / notify steps specific to the class.
- The runbook is only as good as its rehearsals: quarterly
  per class, annually cross-team, updated after every real
  incident.
