# Exercise 04 — Certificate Management Runbook

**Estimated time**: 2 hours
**Deliverable**: A runbook (operational doc, 3–4 pages)

---

## The assignment

Write the runbook for SmartRecs' internal CA + cert-manager
deployment. The runbook will be read at 3 AM by an on-call
engineer who has never operated this system. Optimize for
**unambiguous instructions**, not for elegance.

## Architecture you're documenting

- **Root CA**: lives in HashiCorp Vault PKI engine,
  offline-style: only used to sign intermediate CAs, not
  end-entity certs.
- **Intermediate CA**: signed by root, lives in Vault PKI, signs
  end-entity certs via cert-manager Vault Issuer.
- **cert-manager**: running in `cert-manager` namespace, issues
  `Certificate` resources via the Vault Issuer.
- **End-entity certs**: 24h lifetime for service identities;
  90-day for external API certs (via separate cert-manager
  ClusterIssuer + Let's Encrypt).
- **Audit**: every issuance logged to the audit chain.

## The runbook must cover

1. **System overview** — 1 short paragraph + a diagram.
2. **How issuance normally works** — the happy path.
3. **Runbook 1: Issuance failing for a single service.**
   - Symptoms (what alert fires).
   - First three things to check.
   - Resolution steps.
   - When to escalate.
4. **Runbook 2: Vault PKI intermediate CA has expired or is
   expiring.**
   - How to detect early.
   - The signed-renewal procedure (this is rare and high-stakes;
     the runbook is the difference between a clean rotation and
     an outage).
   - Rollback if renewal fails.
5. **Runbook 3: Suspected key compromise of the intermediate CA.**
   - Containment steps.
   - Communication plan (who to notify, in what order).
   - The recovery procedure (revoke, reissue from root, redistribute
     trust bundle, rotate every end-entity cert).
   - Expected impact (what breaks during the procedure).
6. **Runbook 4: Cert-manager itself is broken** (the system
   issuing certs can't issue).
   - Detection.
   - Triage.
   - The temporary workaround if cert-manager will be down >24h.
7. **Reference**: where do logs go, where do metrics go, who owns
   the system, who to escalate to.

## Format

```
# Internal CA + cert-manager Runbook

## Last updated / owner

## System overview
(short prose + diagram)

## Happy path: how issuance normally works

## Runbook 1: Issuance failing for a single service
### Symptoms
### Probable causes
### Resolution
### When to escalate

## Runbook 2: Intermediate CA expiring
...

## Runbook 3: Suspected key compromise of intermediate CA
...

## Runbook 4: cert-manager broken
...

## Reference
- Logs: ...
- Metrics: ...
- Owner: ...
- Escalation: ...

## Audit considerations
(How certificate operations show up in the audit chain.)
```

## Quality criteria

A passing runbook:

- Has **specific commands** to run (kubectl, vault CLI), not
  pseudocode.
- Has **checks** the on-call can perform to verify each step
  worked.
- Has **rollback** options at every high-risk step.
- Names the **escalation contact** (a team, not a person — people
  rotate).
- The 3 AM test: a sleepy engineer with no context can read it
  and act.

A failing runbook:

- "Check that the Vault PKI engine is configured correctly."
  (How? With what command?)
- No rollback steps for the high-risk procedures.
- Mentions the audit log only in passing.

## Reflection questions

1. Which runbook is most likely to be needed for real?
2. Which runbook is most likely to be needed once-a-decade but
   when needed is the most consequential?
3. How do you keep this runbook from going stale?

## Save your artifact

Reusable across the rest of the track. Also: the *practice* of
writing operational runbooks is part of the role; do this
exercise even if you don't actually have a Vault deployment in
front of you.
