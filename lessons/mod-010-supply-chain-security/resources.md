# Module 10 — Resources

> Primary sources for supply-chain security. Verify URLs at
> access time.

## Frameworks

- **SLSA specification v1.0**
  [slsa.dev/spec/v1.0/](https://slsa.dev/spec/v1.0/)

- **SLSA Build-L3 with GitHub Actions**
  [github.com/slsa-framework/slsa-github-generator](https://github.com/slsa-framework/slsa-github-generator)

- **in-toto specification**
  [in-toto.io/specs/](https://in-toto.io/specs/)

- **in-toto attestation framework**
  [github.com/in-toto/attestation](https://github.com/in-toto/attestation)

- **OpenSSF Best Practices**
  [openssf.org/best-practices/](https://openssf.org/best-practices/)

- **OpenSSF Scorecard** (scores OSS projects on supply-chain
  posture)
  [scorecard.dev](https://scorecard.dev/)

## SBOM formats

- **CycloneDX**
  [cyclonedx.org](https://cyclonedx.org/)

- **CycloneDX ML-BOM extension**
  [cyclonedx.org/capabilities/mlbom/](https://cyclonedx.org/capabilities/mlbom/)

- **SPDX**
  [spdx.dev](https://spdx.dev/)

- **NTIA SBOM resources**
  [ntia.gov/page/software-bill-materials](https://www.ntia.gov/page/software-bill-materials)

## Sigstore

- **Sigstore documentation**
  [docs.sigstore.dev](https://docs.sigstore.dev/)

- **Cosign**
  [github.com/sigstore/cosign](https://github.com/sigstore/cosign)

- **Fulcio**
  [github.com/sigstore/fulcio](https://github.com/sigstore/fulcio)

- **Rekor**
  [github.com/sigstore/rekor](https://github.com/sigstore/rekor)

- **Rekor search**
  [search.sigstore.dev](https://search.sigstore.dev/)

## Scanning tools

- **Trivy**
  [trivy.dev/docs/](https://trivy.dev/docs/)

- **Grype**
  [github.com/anchore/grype](https://github.com/anchore/grype)

- **Syft** (SBOM generation)
  [github.com/anchore/syft](https://github.com/anchore/syft)

- **OSV-Scanner**
  [google.github.io/osv-scanner/](https://google.github.io/osv-scanner/)

- **OSV database**
  [osv.dev](https://osv.dev/)

## Dependency management

- **Dependabot**
  [docs.github.com/en/code-security/dependabot](https://docs.github.com/en/code-security/dependabot)

- **Renovate**
  [docs.renovatebot.com](https://docs.renovatebot.com/)

- **pip-audit**
  [github.com/pypa/pip-audit](https://github.com/pypa/pip-audit)

## ML-specific

- **safetensors** (safer model checkpoint format)
  [github.com/huggingface/safetensors](https://github.com/huggingface/safetensors)

- **Hugging Face security documentation**
  [huggingface.co/docs/hub/security](https://huggingface.co/docs/hub/security)

- **MITRE ATLAS supply chain tactics**
  [atlas.mitre.org](https://atlas.mitre.org/)

## NIST and standards

- **NIST SP 800-218 — Secure Software Development Framework**
  [csrc.nist.gov/Projects/ssdf](https://csrc.nist.gov/Projects/ssdf)

- **NIST SP 800-161 — Cybersecurity Supply Chain Risk Management**
  [csrc.nist.gov/Projects/cyber-supply-chain-risk-management](https://csrc.nist.gov/Projects/cyber-supply-chain-risk-management)

- **CISA SBOM resources**
  [cisa.gov/sbom](https://www.cisa.gov/sbom)

## Notable incidents (for case-study reading)

- **2021 dependency confusion (Alex Birsan)**
  [medium.com/@alex.birsan/dependency-confusion-4a5d60fec610](https://medium.com/@alex.birsan/dependency-confusion-4a5d60fec610)

- **2024 xz-utils backdoor** (CVE-2024-3094) — the canonical
  upstream-insider attack.

- **SolarWinds supply-chain attack (2020)** — the canonical
  build-system compromise.

## Books

- **Software Supply Chain Security** by Cassie Crossley.
  Comprehensive practical text.

## Commercial reference (not endorsement)

- **Chainguard** — secure container base images.
- **Snyk** — dependency + container scanning.
- **JFrog Artifactory** — internal package mirror.

## Cross-references in this curriculum

- [`ai-infra-security-solutions/projects/project-4-secure-cicd/`](https://github.com/ai-infra-curriculum/ai-infra-security-solutions/tree/main/projects/project-4-secure-cicd) — Reference secure CI/CD pipeline.

- [`ai-infra-engineer-solutions/modules/mod-103-containerization/exercise-10-sbom-and-supply-chain`](https://github.com/ai-infra-curriculum/ai-infra-engineer-solutions/tree/main/modules/mod-103-containerization/exercise-10-sbom-and-supply-chain) — SBOM + signing reference.

- [`ai-infra-engineer-solutions/modules/mod-103-containerization/exercise-12-vulnerability-remediation`](https://github.com/ai-infra-curriculum/ai-infra-engineer-solutions/tree/main/modules/mod-103-containerization/exercise-12-vulnerability-remediation) — Vulnerability remediation workflow.

## Things deliberately not on this list

- Vendor pitches that claim "we solve supply chain security"
  without citing SLSA, Sigstore, or specific controls.
- Tutorials older than 2023 (Sigstore + SLSA matured rapidly).
