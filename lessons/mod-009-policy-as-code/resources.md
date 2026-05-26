# Module 09 — Resources

> Primary sources for policy as code. Verify URLs at access time.

## OPA and Rego

- **OPA documentation**
  [openpolicyagent.org/docs/latest](https://www.openpolicyagent.org/docs/latest/)

- **Rego language reference**
  [openpolicyagent.org/docs/latest/policy-language](https://www.openpolicyagent.org/docs/latest/policy-language/)

- **Rego playground**
  [play.openpolicyagent.org](https://play.openpolicyagent.org/)
  Hands-on Rego learning environment.

- **OPA testing**
  [openpolicyagent.org/docs/latest/policy-testing](https://www.openpolicyagent.org/docs/latest/policy-testing/)

- **OPA bundles**
  [openpolicyagent.org/docs/latest/management-bundles](https://www.openpolicyagent.org/docs/latest/management-bundles/)

## Gatekeeper

- **Gatekeeper documentation**
  [open-policy-agent.github.io/gatekeeper](https://open-policy-agent.github.io/gatekeeper/website/)

- **Gatekeeper Library** (pre-built ConstraintTemplates)
  [open-policy-agent.github.io/gatekeeper-library](https://open-policy-agent.github.io/gatekeeper-library/)

- **Gatekeeper Mutation**
  [open-policy-agent.github.io/gatekeeper/website/docs/mutation](https://open-policy-agent.github.io/gatekeeper/website/docs/mutation)

## Kyverno

- **Kyverno documentation**
  [kyverno.io/docs](https://kyverno.io/docs/)

- **Kyverno Policy Library**
  [kyverno.io/policies](https://kyverno.io/policies/)

- **Kyverno image verification** (Cosign integration)
  [kyverno.io/docs/writing-policies/verify-images](https://kyverno.io/docs/writing-policies/verify-images/)

## Conftest

- **Conftest documentation**
  [conftest.dev](https://www.conftest.dev/)

- **Conftest examples**
  [github.com/open-policy-agent/conftest](https://github.com/open-policy-agent/conftest)

## Kubernetes admission

- **Kubernetes admission controllers**
  [kubernetes.io/docs/reference/access-authn-authz/admission-controllers](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/)

- **Validating + Mutating admission webhooks**
  [kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers](https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/)

## Cross-references in this curriculum

- [`ai-infra-engineer-solutions/modules/mod-109-infrastructure-as-code/exercise-08-policy-as-code/kyverno`](https://github.com/ai-infra-curriculum/ai-infra-engineer-solutions/tree/main/modules/mod-109-infrastructure-as-code/exercise-08-policy-as-code) — Reference Kyverno + OPA setup.

- [`ai-infra-security-solutions/projects/project-4-secure-cicd/SOLUTION.md`](https://github.com/ai-infra-curriculum/ai-infra-security-solutions/blob/main/projects/project-4-secure-cicd/SOLUTION.md) — Admission policies that verify signed artifacts.

## Books / courses

- **Policy as Code** by Jimmy Ray (O'Reilly, 2024-ish). A
  practical text on OPA, Gatekeeper, Conftest.

- **OPA By Example** (online, free)
  [styra.com/learn](https://www.styra.com/learn/)

## Commercial reference (not endorsement)

- **Styra DAS** — OPA management platform.
- **Snyk IaC** — OPA-based IaC scanning.

## Things deliberately not on this list

- "Policy as code" tutorials older than 2022 (pre-Kyverno
  maturity).
- Sentinel-specific tutorials (Sentinel is HashiCorp-specific;
  the principles transfer but the syntax doesn't).
- Tutorials that conflate Kubernetes RBAC with policy as code
  (RBAC is identity authorization; policy as code is broader).
