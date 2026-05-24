# Project 4: Secure ML CI/CD Pipeline

**Duration**: 100 hours

## Goal

CI/CD pipeline for ML that's secure end-to-end:
- Source: signed commits + branch protection
- Build: SLSA L2 (cosign, signed provenance)
- Image scan: Trivy + Grype; fail on HIGH/CRITICAL
- SBOM: cyclonedx attached to every image
- Admission: Kyverno verifies signatures + SBOM
- Model artifacts: signed in registry; verified at serving startup
- Deploy: GitOps via ArgoCD; promotion is git-only
- Audit: every action recorded; immutable

## Cross-references

- engineer-solutions/mod-103 ex-10 (SBOM + supply chain)
- engineer-solutions/mod-103 ex-12 (vulnerability remediation)
- engineer-solutions/mod-109 ex-06 (GitOps with ArgoCD)
- engineer-solutions/mod-109 ex-08 (policy as code)

## Deliverables

- `.github/workflows/` (or equivalent) — full CI
- `kyverno/` — admission policies
- `argocd/` — GitOps app-of-apps
- `tests/` — try to bypass each gate; all must fail
