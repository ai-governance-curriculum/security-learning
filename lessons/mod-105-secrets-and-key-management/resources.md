# Resources — mod-105-secrets-and-key-management

Curated primary sources for the module. Prefer official
documentation and standards; verify version numbers, article
numbers, and API surfaces at time of reading — this material
moves quickly.

---

## Standards and frameworks

- **NIST SP 800-57 Part 1 Rev. 5** — Recommendation for Key
  Management, Part 1: General.
  <https://csrc.nist.gov/pubs/sp/800/57/pt1/r5/final>
- **NIST SP 800-57 Part 2 Rev. 1** — Best Practices for Key
  Management Organizations.
  <https://csrc.nist.gov/pubs/sp/800/57/pt2/r1/final>
- **NIST SP 800-57 Part 3 Rev. 1** — Application-Specific Key
  Management Guidance.
  <https://csrc.nist.gov/pubs/sp/800/57/pt3/r1/final>
- **NIST SP 800-63B** — Digital Identity Guidelines,
  Authenticator and Verifier Requirements (secret handling and
  authenticator management).
  <https://pages.nist.gov/800-63-3/sp800-63b.html>
- **NIST SP 800-131A Rev. 2** — Transitioning the Use of
  Cryptographic Algorithms and Key Lengths.
  <https://csrc.nist.gov/pubs/sp/800/131/a/r2/final>
- **NIST SP 800-152** — A Profile for U.S. Federal
  Cryptographic Key Management Systems.
  <https://csrc.nist.gov/pubs/sp/800/152/final>
- **NIST FIPS 140-3** — Security Requirements for
  Cryptographic Modules.
  <https://csrc.nist.gov/pubs/fips/140-3/final>
- **NIST SP 800-53 Rev. 5** — Security and Privacy Controls;
  see the SC-12 (Key Establishment), SC-28 (Protection of
  Information at Rest), IA-5 (Authenticator Management), and
  AU (Audit) families.
  <https://csrc.nist.gov/pubs/sp/800/53/r5/upd1/final>
- **OWASP Secrets Management Cheat Sheet.**
  <https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html>
- **OWASP Key Management Cheat Sheet.**
  <https://cheatsheetseries.owasp.org/cheatsheets/Key_Management_Cheat_Sheet.html>
- **OWASP Cryptographic Storage Cheat Sheet.**
  <https://cheatsheetseries.owasp.org/cheatsheets/Cryptographic_Storage_Cheat_Sheet.html>
- **CIS Critical Security Controls v8** — Control 3
  (Data Protection) and Control 6 (Access Control Management).
  <https://www.cisecurity.org/controls/v8>
- **CNCF Cloud Native Security Whitepaper.**
  <https://github.com/cncf/tag-security/tree/main/security-whitepaper>

---

## Vault (and OpenBao)

- **HashiCorp Vault documentation.**
  <https://developer.hashicorp.com/vault/docs>
- **Vault database secrets engine.**
  <https://developer.hashicorp.com/vault/docs/secrets/databases>
- **Vault Kubernetes auth method.**
  <https://developer.hashicorp.com/vault/docs/auth/kubernetes>
- **Vault AWS secrets engine.**
  <https://developer.hashicorp.com/vault/docs/secrets/aws>
- **Vault GCP secrets engine.**
  <https://developer.hashicorp.com/vault/docs/secrets/gcp>
- **Vault Azure secrets engine.**
  <https://developer.hashicorp.com/vault/docs/secrets/azure>
- **Vault PKI secrets engine.**
  <https://developer.hashicorp.com/vault/docs/secrets/pki>
- **Vault Agent Injector for Kubernetes.**
  <https://developer.hashicorp.com/vault/docs/platform/k8s/injector>
- **Vault Secrets Operator (VSO) for Kubernetes.**
  <https://developer.hashicorp.com/vault/docs/platform/k8s/vso>
- **Vault production hardening.**
  <https://developer.hashicorp.com/vault/tutorials/day-one-raft/production-hardening>
- **Vault reference architecture.**
  <https://developer.hashicorp.com/vault/tutorials/day-one-raft/raft-reference-architecture>
- **OpenBao (LF-hosted Vault fork).**
  <https://openbao.org/>

---

## Cloud KMS and envelope encryption

- **AWS KMS Cryptographic Details.**
  <https://docs.aws.amazon.com/kms/latest/cryptographic-details/intro.html>
- **AWS KMS Developer Guide — Envelope encryption.**
  <https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#enveloping>
- **AWS KMS key policies.**
  <https://docs.aws.amazon.com/kms/latest/developerguide/key-policies.html>
- **AWS KMS key rotation.**
  <https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html>
- **AWS Encryption SDK.**
  <https://docs.aws.amazon.com/encryption-sdk/latest/developer-guide/introduction.html>
- **AWS Nitro Enclaves + KMS (for high-assurance decrypt
  boundaries).**
  <https://docs.aws.amazon.com/enclaves/latest/user/kms.html>
- **GCP Cloud KMS documentation.**
  <https://cloud.google.com/kms/docs>
- **GCP Cloud KMS envelope encryption.**
  <https://cloud.google.com/kms/docs/envelope-encryption>
- **GCP Cloud KMS key rotation.**
  <https://cloud.google.com/kms/docs/key-rotation>
- **GCP customer-managed encryption keys (CMEK).**
  <https://cloud.google.com/kms/docs/cmek>
- **Azure Key Vault documentation.**
  <https://learn.microsoft.com/azure/key-vault/general/overview>
- **Azure Managed HSM.**
  <https://learn.microsoft.com/azure/key-vault/managed-hsm/overview>
- **Google Tink cryptographic library.**
  <https://developers.google.com/tink>
- **Tink KMS envelope AEAD.**
  <https://developers.google.com/tink/client-side-encryption>

---

## Keyless CI, OIDC, and federated identity

- **OpenID Connect Core 1.0.**
  <https://openid.net/specs/openid-connect-core-1_0.html>
- **RFC 8693 — OAuth 2.0 Token Exchange.**
  <https://www.rfc-editor.org/rfc/rfc8693>
- **RFC 7519 — JSON Web Token (JWT).**
  <https://www.rfc-editor.org/rfc/rfc7519>
- **GitHub Actions — OIDC.**
  <https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect>
- **GitHub Actions — Configuring OpenID Connect in AWS.**
  <https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services>
- **GitHub Actions — Configuring OpenID Connect in GCP.**
  <https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-google-cloud-platform>
- **GitHub Actions — Configuring OpenID Connect in Azure.**
  <https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-azure>
- **GitLab CI — ID tokens.**
  <https://docs.gitlab.com/ee/ci/secrets/id_token_authentication.html>
- **AWS IAM — OIDC federation.**
  <https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_oidc.html>
- **GCP Workload Identity Federation.**
  <https://cloud.google.com/iam/docs/workload-identity-federation>
- **Azure federated identity credentials.**
  <https://learn.microsoft.com/entra/workload-id/workload-identity-federation>
- **SPIFFE / SPIRE (workload identity in the mesh, used by
  mod-103 chapter 03).**
  <https://spiffe.io/docs/latest/spiffe-about/overview/>

---

## Sigstore, cosign, Fulcio, Rekor

- **Sigstore documentation.**
  <https://docs.sigstore.dev/>
- **Cosign.**
  <https://docs.sigstore.dev/cosign/overview>
- **Fulcio (certificate authority for signing).**
  <https://docs.sigstore.dev/fulcio/overview/>
- **Rekor (transparency log).**
  <https://docs.sigstore.dev/logging/overview/>
- **Cosign verification policies.**
  <https://docs.sigstore.dev/cosign/verifying/verify/>
- **Sigstore private deployment (running your own instance).**
  <https://docs.sigstore.dev/system_config/installation/>

---

## Secret scanning and detection

- **gitleaks.** <https://github.com/gitleaks/gitleaks>
- **detect-secrets.** <https://github.com/Yelp/detect-secrets>
- **trufflehog.** <https://github.com/trufflesecurity/trufflehog>
- **GitHub secret scanning and push protection.**
  <https://docs.github.com/en/code-security/secret-scanning/about-secret-scanning>
- **GitLab secret detection.**
  <https://docs.gitlab.com/ee/user/application_security/secret_detection/>
- **AWS GuardDuty — credential-abuse findings.**
  <https://docs.aws.amazon.com/guardduty/latest/ug/guardduty_finding-types-iam.html>
- **GCP Security Command Center.**
  <https://cloud.google.com/security-command-center/docs>
- **Microsoft Defender for Cloud.**
  <https://learn.microsoft.com/azure/defender-for-cloud/>

---

## Regulatory references (for the notification-SLA row)

Verify article and section numbers against the primary source
before quoting; the numbering here is a lookup pointer, not an
authority.

- **GDPR (Regulation (EU) 2016/679) — Article 33** (personal
  data breach notification to the supervisory authority within
  72 hours).
  <https://eur-lex.europa.eu/eli/reg/2016/679/oj>
- **UK GDPR** — see the UK ICO's guidance on personal-data
  breach reporting.
  <https://ico.org.uk/for-organisations/report-a-breach/>
- **HIPAA Breach Notification Rule** (45 CFR §§ 164.400 to
  164.414).
  <https://www.hhs.gov/hipaa/for-professionals/breach-notification/index.html>
- **PCI DSS v4.x** — see the incident response and reporting
  requirements (Requirement 12 in v4.x).
  <https://www.pcisecuritystandards.org/document_library>
- **EU AI Act (Regulation (EU) 2024/1689)** — Article 73 on
  reporting of serious incidents by providers of high-risk AI
  systems (verify the article number against the OJEU
  consolidated text; the numbering is provisional in some
  early copies).
  <https://eur-lex.europa.eu/eli/reg/2024/1689/oj>
- **US state data-breach notification laws** — a
  jurisdiction-by-jurisdiction lookup; the NCSL maintains a
  reference index.
  <https://www.ncsl.org/technology-and-communication/security-breach-notification-laws>

---

## ML-adjacent references

- **OWASP Machine Learning Security Top 10** — includes ML06
  (AI Supply Chain Attacks) which relates to signing-key
  compromise.
  <https://owasp.org/www-project-machine-learning-security-top-10/>
- **OWASP LLM Top 10 (2025)** — LLM07 (System Prompt Leakage)
  and LLM08 (Vector and Embedding Weaknesses) intersect with
  external-API key handling and judge-model credential design.
  <https://genai.owasp.org/llm-top-10/>
- **NIST AI RMF 1.0** — the MAP function (context) and MANAGE
  function (governance) touch model-signing-key custody and
  incident response.
  <https://www.nist.gov/itl/ai-risk-management-framework>
- **MITRE ATLAS** — adversarial-ML techniques, including
  supply-chain attacks (T0010).
  <https://atlas.mitre.org/>
- **SLSA v1.0** — provenance levels; signing-key requirements
  at each level.
  <https://slsa.dev/spec/v1.0/>
