# Module 03 Exercises

Five exercises. Each produces an artifact reusable in later
modules (especially Modules 05, 07, 10).

| # | Exercise | Output | Time |
|---|---|---|---|
| 1 | [Key management plan](./exercise-01-key-management-plan.md) | KEK hierarchy + IAM model for SmartRecs | 2 h |
| 2 | [TLS / mTLS configuration audit](./exercise-02-tls-mtls-audit.md) | Audit report with prioritized fixes | 2 h |
| 3 | [Signed-artifact rollout plan](./exercise-03-signed-artifact-rollout.md) | Phased plan to introduce Cosign signing without an outage | 2 h |
| 4 | [Certificate management runbook](./exercise-04-certificate-runbook.md) | Operational runbook for internal CA + cert-manager | 2 h |
| 5 | [Encryption-in-use decision](./exercise-05-encryption-in-use-decision.md) | Decision document for a regulated workload | 2 h |

## Working notes

- Reuse the SmartRecs system from Modules 01–02 where applicable.
- Exercise 04 is a *runbook* — written for a teammate to follow at
  3 AM. Optimize for unambiguous instructions.
- Exercise 05 is a *decision document* — the audience is a
  stakeholder review (CTO, CISO, possibly auditor).
