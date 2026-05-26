# Module 05 — Resources

> Primary sources. Verify URLs at access time.

## HashiCorp Vault

- **Vault documentation**
  [developer.hashicorp.com/vault/docs](https://developer.hashicorp.com/vault/docs)

- **Vault tutorials**
  [developer.hashicorp.com/vault/tutorials](https://developer.hashicorp.com/vault/tutorials)
  Hands-on for Kubernetes auth, dynamic database secrets, PKI.

- **Vault Kubernetes auth method**
  [developer.hashicorp.com/vault/docs/auth/kubernetes](https://developer.hashicorp.com/vault/docs/auth/kubernetes)

- **Vault JWT/OIDC auth method**
  [developer.hashicorp.com/vault/docs/auth/jwt](https://developer.hashicorp.com/vault/docs/auth/jwt)

- **Vault Database secret engine**
  [developer.hashicorp.com/vault/docs/secrets/databases](https://developer.hashicorp.com/vault/docs/secrets/databases)

- **Vault Transit secret engine**
  [developer.hashicorp.com/vault/docs/secrets/transit](https://developer.hashicorp.com/vault/docs/secrets/transit)

- **HCP Vault** (managed)
  [developer.hashicorp.com/hcp/docs/vault](https://developer.hashicorp.com/hcp/docs/vault)

## External Secrets Operator

- **ESO documentation**
  [external-secrets.io/main](https://external-secrets.io/main/)

- **ESO provider list**
  [external-secrets.io/main/provider-introduction](https://external-secrets.io/main/provider-introduction/)
  Vault, AWS SM, GCP SM, Azure Key Vault, and many more.

## Cloud-native secret managers

- **AWS Secrets Manager**
  [docs.aws.amazon.com/secretsmanager](https://docs.aws.amazon.com/secretsmanager/)

- **AWS IRSA documentation**
  [docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html)

- **GCP Secret Manager**
  [cloud.google.com/secret-manager/docs](https://cloud.google.com/secret-manager/docs)

- **Azure Key Vault**
  [learn.microsoft.com/en-us/azure/key-vault](https://learn.microsoft.com/en-us/azure/key-vault/)

## Keyless CI (OIDC trust)

- **GitHub Actions OIDC**
  [docs.github.com/en/actions/deployment/security-hardening-your-deployments](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect)

- **GitHub Actions configuring OIDC with AWS**
  [docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)

- **GitHub Actions OIDC with Vault**
  [docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-hashicorp-vault](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-hashicorp-vault)

- **GitLab CI ID tokens**
  [docs.gitlab.com/ee/ci/secrets/id_token_authentication.html](https://docs.gitlab.com/ee/ci/secrets/id_token_authentication.html)

## Secret detection

- **gitleaks**
  [github.com/gitleaks/gitleaks](https://github.com/gitleaks/gitleaks)

- **detect-secrets (Yelp)**
  [github.com/Yelp/detect-secrets](https://github.com/Yelp/detect-secrets)

- **trufflehog**
  [github.com/trufflesecurity/trufflehog](https://github.com/trufflesecurity/trufflehog)

- **GitHub Secret Scanning**
  [docs.github.com/en/code-security/secret-scanning](https://docs.github.com/en/code-security/secret-scanning)

- **trivy** (image / fs scanning, includes secrets)
  [trivy.dev/docs](https://trivy.dev/docs/)

## NIST and standards

- **NIST SP 800-57 Part 1** — key management framework (Module 03
  resources also lists this; rotation rules apply to secrets too)
  [csrc.nist.gov/pubs/sp/800/57/pt1/r5/final](https://csrc.nist.gov/pubs/sp/800/57/pt1/r5/final)

- **OWASP Secrets Management Cheat Sheet**
  [cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html)

## Tools and operational references

- **etcd encryption at rest**
  [kubernetes.io/docs/tasks/administer-cluster/encrypt-data/](https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/)

- **Kubernetes Secrets — best practices**
  [kubernetes.io/docs/concepts/security/secrets-good-practices/](https://kubernetes.io/docs/concepts/security/secrets-good-practices/)

- **Sigstore Cosign** (Module 03 resources also)
  [docs.sigstore.dev](https://docs.sigstore.dev/)

## Cross-references within this curriculum

- [`ai-infra-engineer-solutions/modules/mod-109-infrastructure-as-code/exercise-07-secret-management`](https://github.com/ai-infra-curriculum/ai-infra-engineer-solutions/tree/main/modules/mod-109-infrastructure-as-code/exercise-07-secret-management) — Vault + ESO reference implementation.

- [`ai-infra-mlops-learning/projects/project-4-governance/`](https://github.com/ai-infra-curriculum/ai-infra-mlops-learning/tree/main/projects/project-4-governance) — Audit chain that records secret-access events.

- [`ai-infra-security-solutions/projects/project-1-zero-trust/SOLUTION.md`](https://github.com/ai-infra-curriculum/ai-infra-security-solutions/blob/main/projects/project-1-zero-trust/SOLUTION.md) — How secret management integrates with the zero-trust architecture.

## Things deliberately not on this list

- Vendor whitepapers from secret-management products that don't
  cite primary security research.
- "Top 10 secret-management tools" articles older than 2023.
- Generic password-manager guidance (this module is workload
  secrets, not human-password management).
