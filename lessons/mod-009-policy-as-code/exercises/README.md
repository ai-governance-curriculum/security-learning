# Module 09 Exercises

Five exercises. Several involve writing actual Rego or Kyverno
YAML — try writing real syntax (the Rego playground is your
friend).

| # | Exercise | Output | Time |
|---|---|---|---|
| 1 | [Gatekeeper vs. Kyverno choice](./exercise-01-gatekeeper-vs-kyverno.md) | Decision document for SmartRecs | 2 h |
| 2 | [Rego policy library](./exercise-02-rego-policy-library.md) | 5+ tested Rego policies | 2–3 h |
| 3 | [Conftest CI gate](./exercise-03-conftest-ci-gate.md) | CI workflow + policy set | 2 h |
| 4 | [ML-specific policy catalog](./exercise-04-ml-policy-catalog.md) | Model promotion + data governance + tenant isolation | 2–3 h |
| 5 | [Policy testing + distribution plan](./exercise-05-policy-testing-distribution.md) | Bundle + GitOps + audit-chain integration | 2 h |

## Working notes

- The Rego playground ([play.openpolicyagent.org](https://play.openpolicyagent.org/))
  is the easiest way to iterate.
- For Kyverno, `kyverno test` is the local test framework.
- Reuse the SmartRecs threat model and workload identity from
  earlier modules.
