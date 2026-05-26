# Module 08 Exercises

Five exercises. Most involve writing manifests / rules; if you
have a Kubernetes cluster, deploy and verify. If not, structure
matters more than syntax.

| # | Exercise | Output | Time |
|---|---|---|---|
| 1 | [Pod Security Standards baseline](./exercise-01-pss-baseline.md) | PSS rollout plan + namespace labels | 2 h |
| 2 | [Seccomp + AppArmor profiles](./exercise-02-seccomp-apparmor-profiles.md) | Concrete profiles for serving workload | 2 h |
| 3 | [Falco ruleset](./exercise-03-falco-ruleset.md) | 8+ ML-specific Falco rules | 2–3 h |
| 4 | [Behavioral baseline design](./exercise-04-behavioral-baseline-design.md) | Baseline + alerting design for serving | 2 h |
| 5 | [Container-escape response runbook](./exercise-05-container-escape-runbook.md) | Step-by-step IR procedure | 2 h |

## Working notes

- Reuse SmartRecs scenarios and the Module 02 workload-identity
  output.
- Exercise 5 is high-leverage even if no escape has ever
  happened — the practice of writing the runbook is the
  artifact.
