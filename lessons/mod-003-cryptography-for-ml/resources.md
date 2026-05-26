# Module 03 — Resources

> Primary sources for cryptography references. Verify URLs at
> time of access.

## NIST publications (the authoritative baseline)

- **NIST SP 800-57 Part 1 Rev. 5 — Recommendation for Key Management**
  [csrc.nist.gov/pubs/sp/800/57/pt1/r5/final](https://csrc.nist.gov/pubs/sp/800/57/pt1/r5/final)
  The most important key-management reference. Read at least the
  parts relevant to your KMS choice.

- **NIST SP 800-38D — Recommendation for Block Cipher Modes of Operation: GCM**
  [csrc.nist.gov/pubs/sp/800/38/d/final](https://csrc.nist.gov/pubs/sp/800/38/d/final)
  AES-GCM specification.

- **NIST SP 800-131A Rev. 2 — Transitioning the Use of Cryptographic Algorithms**
  [csrc.nist.gov/pubs/sp/800/131/a/r2/final](https://csrc.nist.gov/pubs/sp/800/131/a/r2/final)
  What's deprecated, what's still acceptable.

- **NIST FIPS 140-3 — Security Requirements for Cryptographic Modules**
  [csrc.nist.gov/pubs/fips/140-3/final](https://csrc.nist.gov/pubs/fips/140-3/final)
  Cryptographic-module validation. Mostly matters for regulated
  industries.

- **NIST Post-Quantum Cryptography**
  [csrc.nist.gov/projects/post-quantum-cryptography](https://csrc.nist.gov/projects/post-quantum-cryptography)
  Track the migration; act when your data has 10+ year
  confidentiality requirements.

## RFCs

- **RFC 8446 — TLS 1.3**
  [datatracker.ietf.org/doc/html/rfc8446](https://datatracker.ietf.org/doc/html/rfc8446)
  The TLS 1.3 specification.

- **RFC 8996 — Deprecating TLS 1.0 and TLS 1.1**
  [datatracker.ietf.org/doc/html/rfc8996](https://datatracker.ietf.org/doc/html/rfc8996)
  The reason "no TLS 1.1" isn't optional.

- **RFC 8032 — Edwards-Curve Digital Signature Algorithm (EdDSA)**
  [datatracker.ietf.org/doc/html/rfc8032](https://datatracker.ietf.org/doc/html/rfc8032)
  Ed25519 / Ed448 specification.

- **RFC 8439 — ChaCha20 and Poly1305**
  [datatracker.ietf.org/doc/html/rfc8439](https://datatracker.ietf.org/doc/html/rfc8439)

- **RFC 5869 — HMAC-based Extract-and-Expand Key Derivation Function (HKDF)**
  [datatracker.ietf.org/doc/html/rfc5869](https://datatracker.ietf.org/doc/html/rfc5869)

- **RFC 3161 — Internet X.509 Public Key Infrastructure Time-Stamp Protocol**
  [datatracker.ietf.org/doc/html/rfc3161](https://datatracker.ietf.org/doc/html/rfc3161)
  External timestamping for hash-chain anchoring.

## Practical configuration

- **Mozilla SSL Configuration Generator**
  [ssl-config.mozilla.org](https://ssl-config.mozilla.org/)
  The right default for TLS configuration. Use the
  "intermediate" profile.

- **OWASP Cryptographic Storage Cheat Sheet**
  [cheatsheetseries.owasp.org/cheatsheets/Cryptographic_Storage_Cheat_Sheet.html](https://cheatsheetseries.owasp.org/cheatsheets/Cryptographic_Storage_Cheat_Sheet.html)

- **OWASP Transport Layer Security Cheat Sheet**
  [cheatsheetseries.owasp.org/cheatsheets/Transport_Layer_Security_Cheat_Sheet.html](https://cheatsheetseries.owasp.org/cheatsheets/Transport_Layer_Security_Cheat_Sheet.html)

## Tools and platforms

- **HashiCorp Vault**
  [vaultproject.io/docs](https://www.vaultproject.io/docs)
  Key/secret/PKI/transit management.

- **cert-manager**
  [cert-manager.io/docs](https://cert-manager.io/docs/)
  Kubernetes certificate lifecycle.

- **SPIFFE / SPIRE**
  [spiffe.io/docs](https://spiffe.io/docs/)
  See also Module 02 resources.

- **Sigstore / Cosign**
  [docs.sigstore.dev](https://docs.sigstore.dev/)
  Keyless signing, Rekor, Fulcio.

- **External Secrets Operator (ESO)**
  [external-secrets.io/main](https://external-secrets.io/main/)
  Brings external secret stores into Kubernetes.

## Cloud KMS docs

- **AWS KMS**
  [docs.aws.amazon.com/kms](https://docs.aws.amazon.com/kms/)

- **GCP Cloud KMS**
  [cloud.google.com/kms/docs](https://cloud.google.com/kms/docs)

- **Azure Key Vault**
  [learn.microsoft.com/en-us/azure/key-vault](https://learn.microsoft.com/en-us/azure/key-vault/)

## Confidential computing

- **Confidential Computing Consortium**
  [confidentialcomputing.io](https://confidentialcomputing.io/)

- **AWS Nitro Enclaves**
  [docs.aws.amazon.com/enclaves](https://docs.aws.amazon.com/enclaves/)

- **GCP Confidential VMs**
  [cloud.google.com/confidential-computing](https://cloud.google.com/confidential-computing)

- **Azure Confidential Computing**
  [learn.microsoft.com/en-us/azure/confidential-computing](https://learn.microsoft.com/en-us/azure/confidential-computing/)

## ML-specific cryptography research (for context)

- **Microsoft SEAL / Concrete-ML / OpenFHE** — production-grade
  HE libraries. Worth knowing they exist; not for everyday use.

- **TensorFlow Privacy** (DP-SGD reference implementation)
  [github.com/tensorflow/privacy](https://github.com/tensorflow/privacy)

- **Opacus** (DP-SGD for PyTorch)
  [opacus.ai](https://opacus.ai/)

## Books

- **Bulletproof TLS and PKI** by Ivan Ristić.
  The practical reference for TLS configuration and PKI ops.

- **Cryptography Engineering** by Ferguson, Schneier, Kohno.
  A solid introduction without going to Katz/Lindell depth.

- **Real-World Cryptography** by David Wong.
  The current-decade primer; the chapters on TLS, certs, and
  signing are immediately useful.

## Cross-references within this curriculum

- [`ai-infra-engineer-solutions/modules/mod-109-infrastructure-as-code/exercise-07-secret-management`](https://github.com/ai-infra-curriculum/ai-infra-engineer-solutions/tree/main/modules/mod-109-infrastructure-as-code/exercise-07-secret-management) — Vault + ESO reference.

- [`ai-infra-engineer-solutions/modules/mod-103-containerization/exercise-10-sbom-and-supply-chain`](https://github.com/ai-infra-curriculum/ai-infra-engineer-solutions/tree/main/modules/mod-103-containerization/exercise-10-sbom-and-supply-chain) — Cosign + SBOM pipeline reference.

- [`ai-infra-mlops-learning/projects/project-4-governance/src/audit/log.py`](https://github.com/ai-infra-curriculum/ai-infra-mlops-learning/tree/main/projects/project-4-governance/src/audit) — Hash chain audit-log implementation.

## Things deliberately not on this list

- Cryptography "primers" from vendors selling cryptographic
  products. Cite NIST.
- "Cryptography for AI" blog posts older than 2022; the field
  has moved.
- HE / FHE marketing material that conflates research benchmarks
  with production deployments.
