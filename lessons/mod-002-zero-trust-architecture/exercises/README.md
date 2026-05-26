# Module 02 Exercises

Five exercises, in order. Most assume you completed Exercise 01 of
Module 01 (the SmartRecs threat model).

| # | Exercise | Output | Time |
|---|---|---|---|
| 1 | [Zero-trust gap analysis](./exercise-01-zero-trust-gap-analysis.md) | Gap analysis of SmartRecs against the 5 NIST tenets | 2 h |
| 2 | [Workload identity design](./exercise-02-workload-identity-design.md) | SPIFFE-style identity map for SmartRecs workloads | 2 h |
| 3 | [Microsegmentation plan](./exercise-03-microsegmentation-plan.md) | 3-layer segmentation plan + NetworkPolicy YAML | 2–3 h |
| 4 | [Service-mesh authorization policy](./exercise-04-service-mesh-authz.md) | Hand-authored Istio AuthorizationPolicy YAML | 1–2 h |
| 5 | [Zero-trust roadmap](./exercise-05-zero-trust-roadmap.md) | Phased adoption plan sequenced by reversibility | 2 h |

## Working notes

- **Reuse the SmartRecs system** from Module 01 across Exercises 1, 2,
  3, and 5. Exercise 4 is independent.
- Each artifact you produce here is **input** to a later module
  (cryptography, network security, secrets, policy-as-code, security ops).
- Compare to the reference solutions *after* writing your own, not
  before.

## Mistake patterns to watch for

- **Skipping the "what doesn't this solve" question.** Zero-trust is
  one architectural pattern. Exercises 1 and 5 explicitly ask what
  threats remain.
- **Allowing entire namespaces in NetworkPolicy.** A NetworkPolicy
  that allows all of namespace `feature-store` is almost certainly
  too broad — it covers future workloads that don't exist yet.
- **Conflating mesh authorization with application authorization.**
  Mesh: which identity can call which method. Application: which
  tenant's data the request is asking for. You need both.
- **Time-boxing too aggressively.** Zero-trust adoption takes
  quarters, not sprints. A 4-week plan is fiction.
