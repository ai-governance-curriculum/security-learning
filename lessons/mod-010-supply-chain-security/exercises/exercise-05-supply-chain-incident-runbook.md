# Exercise 05 — Supply-Chain Incident Runbook

**Estimated time**: 2 hours
**Deliverable**: A response runbook for confirmed CI compromise

---

## The assignment

Write SmartRecs' on-call runbook for a confirmed CI compromise.
This is the worst-case supply-chain incident: an attacker has
your CI's signing identity and could have signed malicious
artifacts.

## What the runbook must cover

### 1. Confirmation

- How do you confirm the compromise is real?
- What evidence is sufficient to act?
- What's the false-alarm rate, and how do you avoid acting on
  one?

### 2. Immediate containment (within 1 hour)

- Revoke the OIDC trust binding.
- Disable affected workflows.
- Freeze affected releases.
- Notify internal stakeholders.

### 3. Blast-radius audit (within 24 hours)

- Query Rekor for all signatures by the compromised identity
  during the suspected compromise window.
- Cross-reference with known-legitimate builds.
- Identify unexpected signatures.
- For each unexpected signature: was the artifact deployed
  anywhere? Where is it now?

### 4. Eradication

- Rotate the OIDC trust relationship.
- Re-issue signing identities.
- Re-build affected artifacts from clean source.
- Re-sign with new identities.

### 5. Recovery

- Re-establish trust:
  - New OIDC bindings in IAM.
  - New Cosign verification expectations in admission policies.
- Re-deploy verified-clean artifacts.
- Verify production is on clean versions.

### 6. Customer / stakeholder communication

- Internal: who learns what when.
- Customers: what to disclose, when, how.
- Regulators (if applicable): GDPR 72h, HIPAA 60-day, etc.
- Post-mortem timeline (when published, audience).

### 7. Post-incident

- Detection improvements (catch this sooner next time).
- Process improvements (block the path used).
- Update incident response procedures.

## Specific scenario

For the runbook examples, use a concrete scenario:

> **Scenario**: At 14:30 UTC, an external researcher reports
> to your security@ inbox that a deployment of SmartRecs'
> `recs:v1.4.7` image contains a backdoor that beacons to an
> attacker-controlled domain. Their Rekor query shows the
> image was signed by your CI's identity at 02:15 UTC — 12
> hours ago. Your team did not run a production release at
> 02:15 UTC; that was an unattended hours block.

Walk the runbook against this scenario.

## Format

```
# Supply-Chain Incident Runbook: SmartRecs

## Last updated / owner / on-call rotation

## Scope
(What this runbook covers; what it doesn't.)

## Confirmation

### Triage steps
- Source of report (researcher, customer, internal alarm).
- Reproduction of the report.
- Cross-check with Rekor.
- Initial classification.

### When to act (and when to investigate further first)

## Immediate containment

### Step 1: Revoke OIDC trust binding
- Specific commands.

### Step 2: Disable affected workflows
- Specific commands.

### Step 3: Freeze affected releases
- Specific commands.

### Step 4: Notify
- Who, in what order, with what initial message.

## Blast-radius audit

### Rekor queries
- Concrete commands.

### Cross-referencing with build records

### Identifying deployed-vs-not deployed artifacts

## Eradication

### Rotate OIDC trust
### Re-issue signing identities
### Re-build affected artifacts from clean source
### Re-sign

## Recovery

### Re-establish trust
### Re-deploy
### Verify

## Communication

| Audience | When | What | Owner |
|---|---|---|---|

## Post-incident

### Detection improvements
### Process improvements
### Procedure updates
### Customer-facing post-mortem

---

# Walkthrough of the scenario above

(Apply each section to the concrete scenario. Time-stamped.)

00:00 — Researcher report received.
00:05 — Triage begins. Rekor query confirms unexpected
        signature.
00:15 — Confirmation: this is real.
00:20 — Begin containment.
00:30 — OIDC trust revoked.
...
24:00 — Blast-radius audit complete.
48:00 — Eradication complete.
...
```

## Quality criteria

A passing runbook:

- Has **specific commands** at each step.
- Has time bounds for each phase.
- Has a **walkthrough** of the scenario.
- Names the audit-chain integration (every step produces an
  entry).
- Acknowledges the **legal / regulatory** timelines that
  constrain communication.

A failing runbook:

- "Investigate, then contain" without specifics.
- No time bounds.
- No scenario walkthrough.
- No communication plan.

## Reflection questions

1. Which step is most likely to go wrong in a real incident at
   3 AM?
2. The Rekor public log is a public record. What's the
   reputational implication of having a confirmed compromise
   visible there?
3. Once you eradicate, how do you convince yourself the
   compromise is truly over? What's the "smoking gun" check?
