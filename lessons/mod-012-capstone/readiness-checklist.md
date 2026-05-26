# Capstone Readiness Checklist

Before starting the capstone, confirm you have all of the
following. If any line item is unchecked, revisit the relevant
module before starting.

## Foundational understanding (Module 01)

- [ ] I can produce a STRIDE+ML threat model for a small ML
      system without reference.
- [ ] I can map system designs to the OWASP ML Top 10.
- [ ] I can walk an adversary scenario through MITRE ATLAS
      tactics.

## Zero-trust + identity (Module 02)

- [ ] I can articulate the five NIST SP 800-207 tenets.
- [ ] I can design a SPIFFE-style workload identity scheme.
- [ ] I can author a Kubernetes NetworkPolicy with default-deny
      + specific allows.
- [ ] I can author an Istio AuthorizationPolicy keyed on
      workload identity.

## Cryptography (Module 03)

- [ ] I can choose appropriate encryption-at-rest patterns
      (storage / envelope / app-layer).
- [ ] I can configure TLS / mTLS safely.
- [ ] I can author a key-management plan with per-purpose
      separation.
- [ ] I can integrate Cosign keyless signing into a CI pipeline.
- [ ] I understand hash-chain audit logging.

## Network security (Module 04)

- [ ] I can write a complete NetworkPolicy set with ingress
      + egress for a multi-namespace platform.
- [ ] I can audit an Istio mesh configuration.
- [ ] I can design multi-layer rate limiting and DDoS
      protection.

## Secrets management (Module 05)

- [ ] I can choose between Vault and cloud-native secret
      managers.
- [ ] I can configure dynamic database credentials.
- [ ] I can set up keyless CI to AWS via OIDC.
- [ ] I can author a secret-rotation playbook.

## Adversarial ML (Module 06)

- [ ] I can describe the 2×3 attack-class matrix.
- [ ] I can choose between adversarial training, certified
      defenses, DP-SGD, and input validation.
- [ ] I can configure DP-SGD with a justified privacy budget.
- [ ] I can design an LLM safety pipeline (multi-layer).

## Compliance + governance (Module 07)

- [ ] I can produce a regulatory applicability matrix.
- [ ] I can map GDPR subject rights to engineering controls.
- [ ] I can plan SOC 2 readiness across 90+ days.
- [ ] I can classify an AI system under the EU AI Act.
- [ ] I can conduct a vendor risk review.

## Runtime security (Module 08)

- [ ] I can roll out Pod Security Standards with phased
      enforcement.
- [ ] I can author Falco rules tuned to a specific platform.
- [ ] I can write a container-escape response runbook.

## Policy as code (Module 09)

- [ ] I can author Rego policies with tests.
- [ ] I can author Kyverno YAML for admission control.
- [ ] I can set up Conftest CI gates.
- [ ] I can design a policy distribution + testing pipeline.

## Supply chain (Module 10)

- [ ] I can score a build pipeline against SLSA levels.
- [ ] I can design a signed-pipeline with SBOM + provenance
      attestations.
- [ ] I can author admission verification for signatures +
      attestations.
- [ ] I can vet a Hugging Face model.

## SecOps (Module 11)

- [ ] I can author Sigma rules with MITRE ATLAS / ATT&CK
      tagging.
- [ ] I can write an IR procedure with severity-tiered
      playbooks.
- [ ] I can run a tabletop exercise.
- [ ] I can write a blameless postmortem.

---

## Self-assessment scoring

Count your unchecked items:

- **0 unchecked**: ready for the capstone. Start
  [Exercise 01](./exercises/exercise-01-threat-model-and-risk-register.md).
- **1-3 unchecked**: mostly ready. Revisit the specific modules
  for those items, then start the capstone.
- **4-8 unchecked**: revisit several modules. The capstone will
  be unproductive without the prerequisites in place.
- **9+ unchecked**: complete the prior modules first.

The capstone is the synthesis of the prior 11 modules. It
tests integration, not knowledge — but it assumes the knowledge
is there.
