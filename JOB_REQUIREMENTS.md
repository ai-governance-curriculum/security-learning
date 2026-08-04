# AI/ML Security & Governance Engineer — Job Requirements

**Role:** AI/ML Security & Governance Engineer
**Role ID:** `security`
**Level:** 35 (AI Governance family, hands-on engineering specialist)
**Peer packet at same level:** [`ai-evaluation-engineer-learning`](../ai-evaluation-engineer-learning/)
**Adjacent lower packet:** [`ai-risk-engineer-learning`](../ai-risk-engineer-learning/) (level 25)
**Adjacent higher packet:** [`agentic-safety-engineer-learning`](../agentic-safety-engineer-learning/) (level 40)
**Research window:** 2026-05-06 → 2026-08-04
**Machine-readable source:** [`.aicg/job-requirements.json`](.aicg/job-requirements.json)
**Curriculum plan:** [`.aicg/curriculum-plan.json`](.aicg/curriculum-plan.json)

---

## Status — bootstrap session, live postings deferred

<!-- needs-research: 25+ live postings for AI/ML Security & Governance Engineer (and equivalent titles AI Security Engineer, ML Security Engineer, MLSecOps Engineer, AI Security & Compliance Engineer) sampled from the 2026-05-06 → 2026-08-04 window. -->

The `WebSearch` and `WebFetch` tools were **not authorised** in the bootstrap session that produced this packet on 2026-08-04, and a prior automated research run (`.aicg/research/runs/security/response.md`) hit the weekly rate limit before returning results. **No live postings are captured in this packet.** Every posting-derived claim below is marked with the `<!-- needs-research -->` HTML comment and every requirement-theme `frequency` in `.aicg/job-requirements.json` is set to `"needs-research"`.

The requirement catalog itself, and the ownership rule, are **not** speculation:

- The catalog is derived from the authoritative frameworks listed in [`.aicg/job-requirements.json`](.aicg/job-requirements.json) `authoritative_references[]` — OWASP ML Security Top 10, OWASP LLM Top 10 v2025, MITRE ATLAS, NIST AI 100-2 (Adversarial ML Taxonomy), NIST AI RMF 1.0, ISO/IEC 42001, EU AI Act, SLSA v1.0, NIST SP 800-207 (Zero Trust), NIST SP 800-161 (Supply Chain), and adjacent primary sources (CISA Secure AI Development guidelines, GDPR, HIPAA Security Rule, SOC 2 TSCs).
- The catalog is cross-checked against the peer packet [`ai-risk-engineer-learning/.aicg/job-requirements.json`](../ai-risk-engineer-learning/.aicg/job-requirements.json), which captured **n=26 live postings** on **2026-08-02** for the adjacent level-25 role, and whose requirement co-occurrence findings on the AI-risk-and-governance frontier are the closest available proxy for the level-35 evidence base for this role.
- The ownership rule and the peer-and-higher-level-role table cross-reference the level ladder documented in [`/home/rook/ai-infra-curriculum/ai-infra-content-generator/.aicg/ai-governance/research/2026-08/security.md`](../ai-infra-content-generator/.aicg/ai-governance/research/2026-08/security.md).

**Do not** quote posting counts, salary aggregates, or `frequency` values from this packet as fact until the live-sample cycle re-runs. Any reader who needs to cite this packet as evidence should either wait for the next cycle or open a re-research issue against `security-learning`.

## Ownership rule — where this role sits

The AI/ML Security & Governance Engineer is a **level-35 hands-on engineering specialist** at the intersection of:

- **AI security engineering** — adversarial ML defence, LLM/agent attack surface, ML supply-chain security, MLSecOps, detection engineering for AI-specific events, incident response for AI incidents.
- **AI governance engineering** — translating NIST AI RMF, ISO/IEC 42001, EU AI Act, and sector regs into enforceable engineering controls, policy-as-code, evidence packages.

This role **owns**:

- Threat models for ML/LLM systems (STRIDE adapted, ATLAS-mapped).
- Hardening the ML platform: zero-trust architecture, workload identity, secrets, network segmentation, admission-time gates.
- Adversarial-ML and LLM-attack defences at platform scale.
- ML supply-chain security: SLSA for models, cosign / sigstore signing, ML-BOM, model-file safety.
- Privacy engineering for ML: DP-SGD, PETs, inference-attack mitigation, PII/PHI DLP.
- The engineering translation of AI governance obligations into controls and evidence.
- Detection engineering and IR playbooks for AI-specific events.
- The engineering interface between the CISO organisation and the AI governance program.

This role **defers up** to:

- `agentic-safety-engineer` (level 40) for frontier-agent red-team methodology and dangerous-capability evaluation depth.
- `senior-ai-governance-architect` (level 50) for control-library *architecture* and cross-jurisdiction reconciliation.
- `head-of-ai-governance` (level 60) for program leadership and board-level reporting.
- `chief-ai-officer` (level 70) for executive scope.

This role **defers sideways** to:

- `ai-evaluation-engineer` (peer, level 35) for release-assurance methodology and regulator-facing evidence packaging.
- `ai-risk-engineer` (level 25) for harm modelling and enterprise AI risk register engineering.

This role **defers down** to:

- `ai-governance-analyst` (level 15) for framework-crosswalk legwork.
- `ml-engineer` (level 20) for classical ML fundamentals.
- `ai-infra-engineer` (level 25) and `ai-infra-senior-engineer` (level 30) for general infra hardening prerequisites.

This role is **out of scope** for:

- Legal opinion (owned by counsel).
- SOC-side incident handling (owned by enterprise Security Operations). This role authors AI-specific detection content, playbooks, and severity ladder that the SOC consumes.
- Novel red-team method research (owned by `agentic-safety-engineer` and academic research).

The full deferral contract is in [`.aicg/job-requirements.json`](.aicg/job-requirements.json) `ownership_rule`.

## Requirement themes

Each theme is grounded in the authoritative references in `.aicg/job-requirements.json`; each posting-derived column below is marked `<!-- needs-research -->` pending the live sample.

| ID | Requirement theme | Owner module in this packet | References (see `.aicg/job-requirements.json`) | Frequency |
| --- | --- | --- | --- | --- |
| req-01 | Fluent working command of the four operative ML/LLM security taxonomies (OWASP ML Top 10, OWASP LLM Top 10 v2025, MITRE ATLAS, NIST AI 100-2) | `mod-101-ml-security-governance-position` | `ref-owasp-ml-top-10`, `ref-owasp-llm-top-10`, `ref-mitre-atlas`, `ref-nist-ai-100-2` | <!-- needs-research --> |
| req-02 | Threat modelling for ML/LLM systems (STRIDE adapted, ATLAS TTP mapping, attack trees, prioritised mitigations) | `mod-102-threat-modelling-for-ai-ml-systems` | `ref-mitre-atlas`, `ref-nist-ai-600-1`, `ref-owasp-llm-top-10`, `ref-cisa-secure-ai` | <!-- needs-research --> |
| req-03 | Zero-trust architecture for ML platforms (workload identity, mTLS, network segmentation, K8s hardening, admission gates) | `mod-103-secure-ml-platform-architecture` | `ref-nist-sp-800-207`, `ref-cis-kubernetes`, `ref-spiffe-spire`, `ref-cncf-security-whitepaper`, `ref-opa-rego`, `ref-gatekeeper`, `ref-iso-27001` | <!-- needs-research --> |
| req-04 | Secrets and key management for ML (Vault dynamic secrets, KMS envelope encryption, keyless CI, ephemeral credentials) | `mod-105-secrets-and-key-management` | `ref-vault-docs`, `ref-sigstore` | <!-- needs-research --> |
| req-05 | ML supply-chain security (SLSA for models, cosign / sigstore, ML-BOM, malicious model file detection, HF Hub hygiene) | `mod-110-supply-chain-security-for-ai` | `ref-slsa`, `ref-sigstore`, `ref-huggingface-security`, `ref-protect-ai-modelscan`, `ref-nist-sp-800-161`, `ref-eu-cra` | <!-- needs-research --> |
| req-06 | Adversarial ML defence at platform scale (evasion, poisoning, extraction, membership inference, backdoors; adversarial training; certified defences; DP-SGD; in-serving detection monitors) | `mod-106-adversarial-ml-defense` | `ref-nist-ai-100-2`, `ref-adversarial-robustness-toolbox`, `ref-mitre-atlas`, `ref-owasp-ml-top-10` | <!-- needs-research --> |
| req-07 | LLM and agent security engineering (OWASP LLM Top 10 mitigations, indirect prompt injection, agent tool ACLs, red-team engineering) | `mod-107-llm-agent-security` | `ref-owasp-llm-top-10`, `ref-nist-ai-600-1`, `ref-lakera-prompt-injection-taxonomy`, `ref-uk-aisi-inspect`, `ref-mitre-atlas` | <!-- needs-research --> |
| req-08 | Privacy engineering for ML (DP-SGD, PETs, inference-attack mitigation, PII/PHI DLP, GDPR / HIPAA to controls) | `mod-108-privacy-engineering-for-ml` | `ref-opacus`, `ref-gdpr`, `ref-hhs-hipaa-security`, `ref-nist-sp-800-53`, `ref-nist-ai-100-2` | <!-- needs-research --> |
| req-09 | AI governance and compliance engineering (NIST AI RMF, ISO/IEC 42001, EU AI Act, SOC 2, sector regs; policy-as-code; audit evidence) | `mod-109-ai-governance-and-compliance-engineering` | `ref-nist-ai-rmf`, `ref-nist-ai-600-1`, `ref-iso-42001`, `ref-iso-27001`, `ref-eu-ai-act`, `ref-aicpa-soc2`, `ref-nist-sp-800-53`, `ref-anthropic-rsp`, `ref-openai-preparedness`, `ref-deepmind-fsf`, `ref-eu-cra` | <!-- needs-research --> |
| req-10 | Runtime security and detection engineering for ML workloads (Falco, eBPF, ML-specific detection content) | `mod-111-security-operations-and-incident-response-for-ml` | `ref-falco`, `ref-mitre-atlas`, `ref-cis-kubernetes` | <!-- needs-research --> |
| req-11 | Security operations and incident response for ML (SIEM integration, ATLAS-mapped detection, AI-specific IR playbooks, SOC interface) | `mod-111-security-operations-and-incident-response-for-ml` | `ref-mitre-atlas`, `ref-nist-ai-100-2`, `ref-uk-aisi-inspect`, `ref-c2pa`, `ref-nist-ai-100-4` | <!-- needs-research --> |
| req-12 | Cross-functional leadership of the ML security & governance slice (control-library ownership, program metrics, regulator support) | `mod-112-program-leadership-for-ml-security-governance` | `ref-cisa-secure-ai`, `ref-nist-ai-rmf`, `ref-iso-42001`, `ref-eu-ai-act`, `ref-anthropic-rsp` | <!-- needs-research --> |
| req-13 | Data and model lineage security (signed provenance, immutable audit, ML-BOM, model-card evidence linking) | `mod-104-data-and-model-lineage-security` | `ref-slsa`, `ref-sigstore`, `ref-nist-ai-rmf`, `ref-eu-ai-act`, `ref-iso-42001` | <!-- needs-research --> |

## Emerging themes below the evidence threshold

These are named in the `.aicg/job-requirements.json` `emerging_themes_below_threshold[]` list and are **not** promoted to a module yet. Do not add curriculum content until sustained posting demand appears.

- **Confidential computing for AI** (Intel TDX, AMD SEV-SNP, NVIDIA H100 CC) — seen in a small number of frontier-lab / hyperscaler postings. Add as an `mod-103` exercise once ≥ 3 postings cite it in a 90-day window.
- **Post-quantum readiness for ML systems** — mostly aspirational; do not add curriculum content until a live posting cites it as a required skill.
- **Federated-learning security at production scale** — niche outside a few hyperscalers and health-sector consortia; keep out-of-scope until sustained demand appears.
- **Homomorphic-encryption-based inference** — research-adjacent; keep as an `mod-108` pointer, not a required exercise.
- **Watermarking / provenance for generative outputs** — tracked under `ref-nist-ai-100-4` and `ref-c2pa`; add as an `mod-111` exercise once ≥ 3 postings cite it.

## Salary evidence

<!-- needs-research: publish nothing until the live-sample cycle re-runs. -->

**Status:** no live postings sampled in this bootstrap session. The `salary_evidence.per_geography_ranges` array in `.aicg/job-requirements.json` is empty.

Directionally, the adjacent level-25 role (`ai-risk-engineer`) documents a US remote / metro range of **USD 100k–850k** across 13 salary-publishing postings out of 26, with a strong frontier-lab premium at the top and USD 100k–150k at the strict-IC low end. Level 35 should sit above that range, but the sample here is zero. **No headline range will be quoted** until the research cycle re-runs.

## Postings

<!-- needs-research: capture ≥ 25 in-window postings across the equivalent titles listed in research_status.sampling_notes. -->

The `postings[]` array in [`.aicg/job-requirements.json`](.aicg/job-requirements.json) is empty for the reason above.

## Authoritative references

The full list of frameworks, standards, and open-source tools that ground this packet is in [`.aicg/job-requirements.json`](.aicg/job-requirements.json) `authoritative_references[]`. Top-tier sources include:

- **NIST AI RMF 1.0** — [`NIST.AI.100-1`](https://nvlpubs.nist.gov/nistpubs/ai/NIST.AI.100-1.pdf) and the [GenAI Profile (AI 600-1)](https://airc.nist.gov/AI_RMF_Knowledge_Base/AI_RMF/Uses/GenAI-Profile).
- **NIST AI 100-2e2023** — [Adversarial ML: A Taxonomy and Terminology of Attacks and Mitigations](https://nvlpubs.nist.gov/nistpubs/ai/NIST.AI.100-2e2023.pdf).
- **OWASP Machine Learning Security Top 10** — [owasp.org project page](https://owasp.org/www-project-machine-learning-security-top-10/).
- **OWASP Top 10 for LLM Applications (2025)** — [genai.owasp.org/llm-top-10](https://genai.owasp.org/llm-top-10/).
- **MITRE ATLAS** — [atlas.mitre.org](https://atlas.mitre.org/).
- **ISO/IEC 42001:2023** — [AI Management System](https://www.iso.org/standard/81230.html).
- **EU AI Act (Regulation (EU) 2024/1689)** — [EUR-Lex OJ](https://eur-lex.europa.eu/eli/reg/2024/1689/oj).
- **NIST SP 800-207** — [Zero Trust Architecture](https://csrc.nist.gov/pubs/sp/800/207/final).
- **NIST SP 800-161r1** — [Cybersecurity Supply Chain Risk Management Practices](https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-161r1.pdf).
- **SLSA v1.0** — [slsa.dev spec](https://slsa.dev/spec/v1.0/).
- **CISA Guidelines for Secure AI System Development** — [CISA joint international](https://www.cisa.gov/resources-tools/resources/guidelines-secure-ai-system-development).
- **UK AI Safety Institute Inspect** — [Inspect Evaluation Framework](https://ukgovernmentbeis.github.io/inspect_ai/).
- **Frontier-lab safety frameworks** — [Anthropic RSP](https://www.anthropic.com/rsp), [OpenAI Preparedness Framework](https://openai.com/index/updating-our-preparedness-framework/), [DeepMind Frontier Safety Framework](https://deepmind.google/discover/blog/introducing-the-frontier-safety-framework/).
- **Sector regs** — [GDPR](https://eur-lex.europa.eu/eli/reg/2016/679/oj), [HIPAA Security Rule](https://www.hhs.gov/hipaa/for-professionals/security/index.html), [AICPA SOC 2 TSCs](https://www.aicpa-cima.com/topic/audit-assurance/audit-and-assurance-greater-than-soc-2), [EU Cyber Resilience Act](https://eur-lex.europa.eu/eli/reg/2024/2847/oj).
- **Open-source tools** — [HashiCorp Vault](https://developer.hashicorp.com/vault/docs), [OPA / Rego](https://www.openpolicyagent.org/docs/latest/), [OPA Gatekeeper](https://open-policy-agent.github.io/gatekeeper/website/docs/), [SPIFFE / SPIRE](https://spiffe.io/docs/latest/), [Falco](https://falco.org/docs/), [Sigstore / cosign](https://docs.sigstore.dev/), [Adversarial Robustness Toolbox](https://adversarial-robustness-toolbox.readthedocs.io/), [Opacus](https://opacus.ai/), [Protect AI ModelScan](https://github.com/protectai/modelscan), [Hugging Face Hub security](https://huggingface.co/docs/hub/security).

## Next research cycle checklist

Once WebSearch / WebFetch are re-authorised:

1. Sample ≥ 25 in-window postings across the five equivalent titles listed in `research_status.sampling_notes`.
2. Fill `.aicg/job-requirements.json` `postings[]`, `research_status.phase → "sampled"`, and each `requirement_themes[].frequency` with the observed rate.
3. Populate `salary_evidence.per_geography_ranges` with the concrete numbers.
4. Recompute `emerging_themes_below_threshold[]` — promote any theme that now clears the 3-postings / 30% threshold into a curriculum-plan-delta.
5. Verify against the [ownership contract](.aicg/job-requirements.json) that no new theme duplicates a lower-level owner; if it does, link out rather than adding new coverage.
6. Refresh this file — replace every `<!-- needs-research -->` marker with the sampled number.
