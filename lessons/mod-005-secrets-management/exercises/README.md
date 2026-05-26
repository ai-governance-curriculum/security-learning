# Module 05 Exercises

Five exercises, in order.

| # | Exercise | Output | Time |
|---|---|---|---|
| 1 | [Secrets inventory](./exercise-01-secrets-inventory.md) | Comprehensive secret catalog for SmartRecs | 2 h |
| 2 | [Vault deployment plan](./exercise-02-vault-deployment-plan.md) | Phased Vault rollout for SmartRecs | 2–3 h |
| 3 | [Secret rotation playbook](./exercise-03-secret-rotation-playbook.md) | Routine + emergency procedures | 2 h |
| 4 | [Keyless CI design](./exercise-04-keyless-ci-design.md) | OIDC-based migration from static creds | 2 h |
| 5 | [Secret-leak incident runbook](./exercise-05-secret-leak-runbook.md) | Break-glass procedure with rehearsal plan | 2 h |

## Working notes

- Reuse SmartRecs and Module 02's workload-identity output.
- Exercise 4 introduces CI/CD context — if your SmartRecs doesn't
  use GitHub Actions, substitute your CI platform.
- Exercise 5 (incident runbook) is the highest-leverage artifact;
  most teams discover they need it during the first real incident.
