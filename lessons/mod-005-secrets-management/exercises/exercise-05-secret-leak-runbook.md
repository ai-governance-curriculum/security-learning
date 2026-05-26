# Exercise 05 — Secret-Leak Incident Runbook

**Estimated time**: 2 hours
**Deliverable**: A runbook + tabletop scenario script

---

## The assignment

Write the break-glass runbook for a confirmed secret leak at
SmartRecs. The runbook will be used at 3 AM by an on-call
engineer with broad context but no recent practice. Optimize for
unambiguous instructions and bounded blast radius.

## The runbook must cover

### Detection paths

Before the procedure, document **how secret leaks get detected**
at SmartRecs:

- GitHub Secret Scanning alert.
- Internal scanner (gitleaks in CI, image scan in
  pipeline).
- External notification (someone tells you).
- Audit-log anomaly (Vault access from unexpected location).
- Customer report.

For each, describe what triage looks like *before* you start the
runbook — confirm the leak is real, identify the secret class.

### The main runbook

For each secret class in your inventory (Exercise 01), have a
section with:

1. **Identification** — figuring out exactly which secret leaked,
   not just "an AWS key."
2. **Revocation** — specific command / UI path.
3. **Blast-radius audit** — what was the secret used for between
   suspected leak and revocation?
4. **Dependent rotation** — what other secrets must rotate
   because they could have been accessed via the leaked one?
5. **Stakeholder notification** — who to tell, in what order,
   with what message.
6. **Recovery verification** — how to confirm the leak is
   contained.
7. **Post-mortem inputs** — what data the team needs to write
   the post-mortem.

At minimum cover:
- AWS IAM credentials.
- LLM provider API key (OpenAI / Anthropic).
- Cosign signing identity.
- Database password.
- Customer-managed encryption key (the hardest case).

### The tabletop scenario

Write a short scenario (1 page) that simulates a leak. Used to
run drills:

- **Scenario setup** — what alert fires, what's the initial
  evidence.
- **Inject events** — what additional evidence appears as the
  drill progresses.
- **Decision points** — what choices the on-call faces.
- **Expected outcomes** — what a correctly-run drill achieves.
- **Common mistakes** — what to listen for when grading the
  drill.

Pick a class: I recommend the **OpenAI API key** leak as the
tabletop scenario (relatively low-stakes consequences for
practice, but realistic shape).

## Format

```
# Secret-Leak Incident Runbook: SmartRecs

## Last updated / owner / on-call rotation

## Detection paths
(How leaks get reported.)

## General incident structure
(Timeline: confirm → contain → audit → rotate dependents →
notify → recover → post-mortem.)

## Per-class procedures

### AWS IAM credential leak
- Identification
- Revocation (specific aws cli or console steps)
- Blast-radius audit (which CloudTrail logs, how to filter)
- Dependent rotation
- Stakeholder notification
- Recovery verification
- Post-mortem inputs

### LLM provider API key leak
- ...

### Cosign signing identity leak
- ...

### Database password leak
- ...

### Customer-managed encryption key leak
- ... (the hardest — re-encryption may be required)

## Audit-chain integration
(How each step shows up in the audit log; how the post-mortem
artifact links to the chain.)

---

# Tabletop Scenario: OpenAI API key leak

## Scenario setup
## Inject events (timeline)
## Decision points
## Expected outcomes
## Common mistakes
## Grading rubric
```

## Quality criteria

A passing runbook:

- Each class has **specific commands** (aws cli, vault cli, etc.)
  rather than "revoke the key."
- Includes a **blast-radius audit** step for each class.
- Names **dependent secrets** to rotate.
- Has a **tabletop scenario** that's realistic and runnable.
- Acknowledges the **hardest case** — customer-managed key leak
  may require re-encrypting data.

A failing runbook:

- Generic "revoke and rotate" with no specifics.
- No blast-radius audit (you don't know what the attacker did).
- No tabletop scenario.
- Treats every class identically.

## Reflection questions

1. Which class is hardest to revoke quickly? Why?
2. Which class has the largest blast radius if exploited?
3. What's the difference between containing a leak and
   recovering from one? Where in the runbook does that
   distinction matter?

## Practice

Run the tabletop with a colleague (or solo, walking through
each step in writing). The first time you run it, the runbook
will reveal gaps. Update it.

## Save your artifact

This is the highest-leverage artifact in this module. Many teams
operate for years without one and feel it only during the first
real incident. Don't be one of those teams.
