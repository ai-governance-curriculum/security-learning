# AI/ML Security & Governance Engineer — Job Requirements

**Role:** AI/ML Security & Governance Engineer
**Role ID:** `security`
**Level:** 35 (AI Governance family, hands-on engineering specialist)
**Peer packet at same level:** [`ai-evaluation-engineer-learning`](../ai-evaluation-engineer-learning/)
**Adjacent lower packet:** [`ai-risk-engineer-learning`](../ai-risk-engineer-learning/) (level 25)
**Adjacent higher packet:** [`agentic-safety-engineer-learning`](../agentic-safety-engineer-learning/) (level 40)
**Research window:** 2026-06-06 → 2026-09-04
**Postings sampled:** 32 (target ≥ 25)
**Machine-readable source:** [`.aicg/job-requirements.json`](.aicg/job-requirements.json)
**Curriculum plan:** [`.aicg/curriculum-plan.json`](.aicg/curriculum-plan.json)
**Curriculum-plan delta this cycle:** [`.aicg/curriculum-plan-delta.json`](.aicg/curriculum-plan-delta.json) — **no additions**.

---

## Research status — sampled

Live sample captured on 2026-09-04 via WebSearch and WebFetch across the five equivalent titles listed in `research_status.sampling_notes`:
`AI Security Engineer`, `ML Security Engineer`, `AI/ML Security & Governance Engineer`, `MLSecOps Engineer`, `AI Security & Compliance Engineer`.

Title-variant distribution (n=32):

| Title variant | Count |
| --- | --- |
| `ai-security-engineer` | 17 |
| `ml-security-engineer` | 5 |
| `ai-ml-security-governance` | 4 |
| `ai-security-compliance` | 3 |
| `mlsecops-engineer` | 0 |

The `MLSecOps Engineer` employer-branded title is essentially absent in-market during this window — equivalent scope is folded into `AI Security Engineer` or `Staff AI Security Engineer` postings. This is a stable observation across the 2026 cycles (see peer packet [`ai-risk-engineer-learning`](../ai-risk-engineer-learning/) for the adjacent-role picture).

Posting-date metadata was extractable for only one posting (Jobgether AI Governance Security Engineer, posted 2026-07-26); the rest are treated as in-window because the ATS surface returned an active listing on 2026-09-04 (Greenhouse / Lever / Breezy / vendor-branded careers pages typically retire postings within 30–60 days of fill).

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

Frequencies are the observed rate across the 32-posting sample. Six themes clear the 0.30 promotion threshold; the remaining seven are below-threshold in this window but are preserved as required modules because they map to distinct engineering craft that shows up in specific verticals (regulated industries for privacy, ML-platform teams for supply chain and runtime detection, Staff+ roles for leadership and lineage).

| ID | Requirement theme | Owner module | References (see `.aicg/job-requirements.json`) | Frequency (n=32) |
| --- | --- | --- | --- | --- |
| req-01 | Fluent working command of the four operative ML/LLM security taxonomies (OWASP ML Top 10, OWASP LLM Top 10 v2025→2026, MITRE ATLAS, NIST AI 100-2); OWASP Agentic AI Top 10 is now cited as a companion | [`mod-101-ml-security-governance-position`](lessons/mod-101-ml-security-governance-position/) | `ref-owasp-ml-top-10`, `ref-owasp-llm-top-10`, `ref-owasp-agentic-top-10`, `ref-mitre-atlas`, `ref-nist-ai-100-2` | **0.44** |
| req-02 | Threat modelling for ML/LLM systems (STRIDE adapted, ATLAS TTP mapping, attack trees, prioritised mitigations) | [`mod-102-threat-modelling-for-ai-ml-systems`](lessons/mod-102-threat-modelling-for-ai-ml-systems/) | `ref-mitre-atlas`, `ref-nist-ai-600-1`, `ref-owasp-llm-top-10`, `ref-cisa-secure-ai` | **0.75** |
| req-03 | Zero-trust architecture for ML platforms (workload identity, mTLS, network segmentation, K8s hardening, admission gates) | [`mod-103-secure-ml-platform-architecture`](lessons/mod-103-secure-ml-platform-architecture/) | `ref-nist-sp-800-207`, `ref-cis-kubernetes`, `ref-spiffe-spire`, `ref-cncf-security-whitepaper`, `ref-opa-rego`, `ref-gatekeeper`, `ref-iso-27001` | **0.47** |
| req-04 | Secrets and key management for ML (Vault dynamic secrets, KMS envelope encryption, keyless CI, ephemeral credentials, short-lived agent-tool creds) | [`mod-105-secrets-and-key-management`](lessons/mod-105-secrets-and-key-management/) | `ref-vault-docs`, `ref-sigstore` | 0.25 |
| req-05 | ML supply-chain security (SLSA for models, cosign/sigstore, ML-BOM, malicious model-file detection, HF Hub hygiene) | [`mod-110-supply-chain-security-for-ai`](lessons/mod-110-supply-chain-security-for-ai/) | `ref-slsa`, `ref-sigstore`, `ref-huggingface-security`, `ref-protect-ai-modelscan`, `ref-nist-sp-800-161`, `ref-eu-cra`, `ref-openssf-mlsecops` | 0.19 |
| req-06 | Adversarial ML defence at platform scale (evasion, poisoning, extraction, membership inference, backdoors; adversarial training; certified defences; DP-SGD; in-serving detection monitors) — 2026 tooling adds garak / PyRIT | [`mod-106-adversarial-ml-defense`](lessons/mod-106-adversarial-ml-defense/) | `ref-nist-ai-100-2`, `ref-adversarial-robustness-toolbox`, `ref-garak`, `ref-pyrit`, `ref-mitre-atlas`, `ref-owasp-ml-top-10` | 0.25 |
| req-07 | LLM and agent security engineering (OWASP LLM Top 10 mitigations, OWASP Agentic AI Top 10, indirect prompt injection, MCP-server attack surface, agent tool ACLs, red-team engineering with garak / PyRIT / Inspect) | [`mod-107-llm-agent-security`](lessons/mod-107-llm-agent-security/) | `ref-owasp-llm-top-10`, `ref-owasp-agentic-top-10`, `ref-nist-ai-600-1`, `ref-lakera-prompt-injection-taxonomy`, `ref-uk-aisi-inspect`, `ref-garak`, `ref-pyrit`, `ref-mitre-atlas` | **0.88** |
| req-08 | Privacy engineering for ML (DP-SGD, PETs, inference-attack mitigation, PII/PHI DLP, GDPR / HIPAA to controls) | [`mod-108-privacy-engineering-for-ml`](lessons/mod-108-privacy-engineering-for-ml/) | `ref-opacus`, `ref-gdpr`, `ref-hhs-hipaa-security`, `ref-nist-sp-800-53`, `ref-nist-ai-100-2` | 0.16 |
| req-09 | AI governance and compliance engineering (NIST AI RMF, ISO/IEC 42001, EU AI Act, SOC 2, sector regs; policy-as-code; audit evidence; continuous evidence pipelines) | [`mod-109-ai-governance-and-compliance-engineering`](lessons/mod-109-ai-governance-and-compliance-engineering/) | `ref-nist-ai-rmf`, `ref-nist-ai-600-1`, `ref-iso-42001`, `ref-iso-27001`, `ref-eu-ai-act`, `ref-aicpa-soc2`, `ref-nist-sp-800-53`, `ref-anthropic-rsp`, `ref-openai-preparedness`, `ref-deepmind-fsf`, `ref-eu-cra` | **0.53** |
| req-10 | Runtime security and detection engineering for ML workloads (Falco, eBPF, ML-specific detection content, agentic-workflow anomaly detection) | [`mod-111-security-operations-and-incident-response-for-ml`](lessons/mod-111-security-operations-and-incident-response-for-ml/) | `ref-falco`, `ref-mitre-atlas`, `ref-cis-kubernetes` | 0.25 |
| req-11 | Security operations and incident response for ML (SIEM integration, ATLAS-mapped detection, AI-specific IR playbooks incl. shadow-AI enforcement, SOC interface) | [`mod-111-security-operations-and-incident-response-for-ml`](lessons/mod-111-security-operations-and-incident-response-for-ml/) | `ref-mitre-atlas`, `ref-nist-ai-100-2`, `ref-uk-aisi-inspect`, `ref-c2pa`, `ref-nist-ai-100-4` | **0.47** |
| req-12 | Cross-functional leadership of the ML security & governance slice (control-library ownership, program metrics, regulator support) | [`mod-112-program-leadership-for-ml-security-governance`](lessons/mod-112-program-leadership-for-ml-security-governance/) | `ref-cisa-secure-ai`, `ref-nist-ai-rmf`, `ref-iso-42001`, `ref-eu-ai-act`, `ref-anthropic-rsp` | 0.25 (≈ 1.0 among Principal/Staff+) |
| req-13 | Data and model lineage security (signed provenance, immutable audit, ML-BOM, model-card evidence linking) | [`mod-104-data-and-model-lineage-security`](lessons/mod-104-data-and-model-lineage-security/) | `ref-slsa`, `ref-sigstore`, `ref-nist-ai-rmf`, `ref-eu-ai-act`, `ref-iso-42001` | 0.19 |

## What the 2026-09 sample says about the curriculum

- **All 13 required themes are cited by at least 5 postings.** No theme has fallen out of the required set; no theme is unrepresented in evidence. This is the target state under the continuity-bias contract.
- **req-07 (LLM/agent security) dominates at 0.88.** Every posting except Scale AI Infra, Glean, and xAI GRC cites some form of LLM/agent-security scope. mod-107 is the load-bearing module for the packet.
- **req-02 (threat modelling) is right behind at 0.75.** Almost every senior/staff role names "threat model AI features" as a review deliverable. mod-102 is the second load-bearing module.
- **req-09 (governance + compliance engineering) is at 0.53** — ISO 42001 has caught up with SOC 2 as the second-most-named framework and "continuous evidence pipelines" has become named artifact vocabulary (xAI GRC posting is the clearest example).
- **req-01 (taxonomies), req-03 (zero-trust for ML platforms), req-11 (SecOps + IR for ML)** all cluster at 0.44–0.47 — the platform-hardening + detection-content + IR-playbook triangle the mid-level packet expects.
- Below-threshold themes are not dropped: they map to distinct engineering craft demanded by specific verticals (privacy for health/insurance, supply chain for ML-platform vendors, cross-functional leadership for Principal/Staff+).

## Emerging themes below the promotion threshold

Under the continuity-bias contract (≥ 3 postings AND ≥ 0.30 frequency AND no existing module can be incrementally extended), **no theme in the 2026-09 sample clears the bar for promotion to a new module**. Every emerging theme is folded into an existing module or held below the threshold with a reassess-next-cycle note.

- **MCP-server governance and agent-tool ACL depth** — 5–6/32 postings named Model Context Protocol explicitly (Ridgeline, Obsidian, Postman Offensive, Jobgether Governance, Backblaze, Anthropic Corporate). Frequency ≈ 0.16–0.19 — below the 0.30 promotion threshold. **Coverage:** folded inside `mod-107` exercise-03 (agent tool ACL + HITL) and exercise-04 (agent red-team plan with Inspect). Reassess next cycle — MCP-specific enterprise vendor tooling is expected to mature and could lift this to threshold.
- **AI-assisted-developer-tool governance (Claude Code, Cursor, Copilot, "vibe coding")** — 4/32 postings named this class of tool by name (Atlas HXM, Ridgeline, SmartRent, Anthropic Staff+ AppSec). Frequency ≈ 0.13. **Coverage:** folded inside `mod-107` exercise-03 and `mod-111` IR playbook slice. Reassess next cycle.
- **Shadow-AI detection and enforcement** — 3/32 postings (AlphaSense, Jobgether Governance, Atlas HXM) cited explicitly. Just clears the ≥ 3 posting count but is at 0.09 frequency — well below the 0.30 threshold. **Coverage:** folded inside `mod-111` IR playbook slice as a specific detection-content deliverable.
- **Agentic-workflow anomaly detection at runtime** — 5/32 postings (Databricks, OpenAI Agent Security, LTS, Spring Health, Backblaze) cited monitoring of agent behaviour as a required deliverable. Frequency ≈ 0.16. **Coverage:** folded inside `mod-107` exercise-04 (red-team with harness) and `mod-111` (IR / detection engineering).
- **Confidential computing for AI (Intel TDX, AMD SEV-SNP, NVIDIA H100 CC)** — 0/32 postings cited by name. Continue to keep out-of-scope; still aspirational. Add as an `mod-103` exercise when ≥ 3 postings cite it in a 90-day window.
- **Post-quantum readiness for ML systems** — 0/32. Still aspirational; do not add.
- **Federated-learning security at production scale** — 1/32 (xAI AppSec). Niche outside a few hyperscalers and health-sector consortia; keep out-of-scope.
- **Homomorphic-encryption-based inference** — 0/32 cited by name. Keep as an `mod-108` pointer, not a required exercise.
- **Watermarking / provenance for generative outputs** — 0/32 cited by name in this sample. C2PA / NIST AI 100-4 stay as `mod-111` references, no exercise until ≥ 3 postings cite it.

## Salary evidence

**Sample:** 17 of 32 postings disclosed a base-salary range. Salaries are base only; equity and bonus are excluded. USD anchor; the one CAD range is converted at ≈ 0.72 USD/CAD for the aggregate but retained in native currency below.

Three distinct compensation clusters emerged. Publishing one aggregate would collapse a 3.5× tier spread that hiring committees can and do distinguish; the packet publishes tiered ranges instead.

| Tier | Low (USD) | High (USD) | Median band (USD) |
| --- | --- | --- | --- |
| US Senior / Staff (AI Security Engineer, platform-adjacent) | 155,000 | 300,000 | 205,000 – 260,000 |
| US Principal / Staff+ (frontier lab / platform vendor) | 231,400 | 544,200 | 295,000 – 405,000 |
| US AI Security Compliance / GRC variant | 152,000 | 258,000 | 175,000 – 230,000 |

Non-US disclosures: Forma.ai (Toronto) Senior Security Engineer — CAD 160k–190k (≈ USD 115k–140k at 0.72). Bangalore / Germany / LATAM postings did not disclose ranges.

The tier structure is consistent with the peer packet [`ai-risk-engineer-learning`](../ai-risk-engineer-learning/) reported USD 100k–850k range across a wider level ladder. This packet's level-35 anchor sits above ai-risk-engineer (level 25) as expected.

## Postings

The full posting evidence set is in [`.aicg/job-requirements.json`](.aicg/job-requirements.json) `postings[]`. Summary index below (32 rows):

| Employer | Title | Location | Salary (USD unless noted) | URL |
| --- | --- | --- | --- | --- |
| Anthropic | Red Team Engineer, Safeguards | SF, CA | 320,000 – 405,000 | https://job-boards.greenhouse.io/anthropic/jobs/5320469008 |
| Anthropic | Security Engineer, Corporate Security | SF/Seattle/NYC/DC | 320,000 – 405,000 | https://job-boards.greenhouse.io/anthropic/jobs/5397319008 |
| Anthropic | Staff+ Application Security Engineer | SF/Seattle/NYC | 320,000 – 485,000 | https://job-boards.greenhouse.io/anthropic/jobs/4502508008 |
| OpenAI | Security Engineer, Agent Security | San Francisco, CA | undisclosed | https://openai.com/careers/security-engineer-agent-security-san-francisco/ |
| OpenAI | Machine Learning Engineer, Integrity | San Francisco, CA | undisclosed | https://openai.com/careers/machine-learning-engineer-integrity-san-francisco/ |
| Databricks | Staff Security Software Engineer, AI Security Engineering | Remote USA | 231,400 – 397,650 | https://www.databricks.com/company/careers/security/staff-security-software-engineer-ai-security-engineering--7882009002 |
| xAI | Application Security Engineer | Palo Alto, CA | 100,000 – 258,000 | https://job-boards.greenhouse.io/xai/jobs/4559147007 |
| xAI | Sr. Security Engineer - GRC Frameworks & AI Governance | PA / NYC / DC | 152,000 – 258,000 | https://job-boards.greenhouse.io/xai/jobs/5007261007 |
| Isomorphic Labs | Senior Security Engineer (AI Safety) | London; Lausanne | undisclosed | https://job-boards.greenhouse.io/isomorphiclabs/jobs/6100340004 |
| Veeam Software | Staff AI Security Engineer | San Jose, CA | 293,100 – 544,200 | https://job-boards.greenhouse.io/veeamsoftware/jobs/4939102101 |
| Backblaze | Sr. AI Security Engineer | Remote LATAM | undisclosed | https://job-boards.greenhouse.io/backblaze/jobs/5213833008 |
| Atlas HXM | Senior Security Engineer, AI & DevSecOps | Canada / USA (Remote) | undisclosed | https://job-boards.greenhouse.io/atlasxhm/jobs/8637023002 |
| Lightning AI | Senior Application Security Engineer, AI and Machine Learning | SF / Seattle (Hybrid) | 180,000 – 220,000 | https://job-boards.greenhouse.io/lightningai/jobs/7687112003 |
| LTS | Agentic AI Security Engineer | USA Remote | undisclosed | https://job-boards.greenhouse.io/lts/jobs/4340457009 |
| Forma.ai | Senior Security Engineer | Toronto, Canada | CAD 160,000 – 190,000 | https://job-boards.greenhouse.io/formaaiinc/jobs/4723179005 |
| Obsidian Security | Software Engineer - AI Security Product | Palo Alto, CA | 155,000 – 180,000 | https://job-boards.greenhouse.io/obsidiansecurity/jobs/5290880008 |
| Snorkel AI | Software Engineer — Security | NYC / SF (Hybrid) | 220,000 – 300,000 | https://job-boards.greenhouse.io/snorkelai/jobs/6148995004 |
| Ridgeline | Staff Security Engineer - AI Security & Platforms | San Ramon / Reno (Hybrid) | 205,000 – 256,000 | https://job-boards.greenhouse.io/ridgeline/jobs/7814814003 |
| GuidePoint Security | AI Security Engineer - Mid-Atlantic | Remote Mid-Atlantic | undisclosed | https://job-boards.greenhouse.io/guidepointsecurity/jobs/6030474004 |
| SmartRent | Application Security Engineer | Phoenix, AZ (Remote OK) | undisclosed | https://job-boards.greenhouse.io/smartrent/jobs/6151079004 |
| Aimpoint Digital | Lead AI Security Architect | Atlanta, GA (Remote) | undisclosed | https://aimpoint-digital.breezy.hr/p/86c221c3a8a3-lead-ai-security-architect-2026-us |
| Postman | Principal Offensive Security Engineer | San Francisco, CA | 275,000 – 300,000 | https://job-boards.greenhouse.io/postman/jobs/7721349003 |
| Postman | AI Engineer Internship (Summer 2026) | Berkeley / SF | undisclosed | https://job-boards.greenhouse.io/postman/jobs/7823417003 |
| Ethos Life | Principal Security Engineer | Bangalore, India | undisclosed | https://job-boards.greenhouse.io/ethoslife/jobs/8570932002 |
| The Quality Group | AI Security Engineer (gn) | Germany (Remote) | undisclosed | https://job-boards.greenhouse.io/thequalitygroupgmbh2/jobs/4890993101 |
| AlphaSense | AI Security Analyst | Remote - India | undisclosed | https://job-boards.greenhouse.io/alphasense/jobs/8634067002 |
| Spring Health | Staff AI Security Engineer | Seattle, WA (Hybrid) | 208,000 – 251,022 | https://job-boards.greenhouse.io/springhealth66/jobs/4702460005 |
| Scale AI | Security Engineer, Infrastructure | NYC / SF / Seattle / DC | 237,600 – 297,000 | https://job-boards.greenhouse.io/scaleai/jobs/4646888005 |
| Zscaler | Senior Software Engineer - AI Security (Network/Rust) | San Jose / Bellevue | 132,000 – 165,000 | https://job-boards.greenhouse.io/zscaler/jobs/5146136007 |
| Glean | Application Security Engineer | Remote USA | 185,000 – 260,000 | https://job-boards.greenhouse.io/gleanwork/jobs/4728513005 |
| Jobgether (anon client) | AI Governance Security Engineer | Remote (posted 2026-07-26) | undisclosed | https://jobs.lever.co/jobgether/3fc6bbff-61c4-43f6-bd26-627efc6bf5cf |
| Greenhouse | Senior Product Security Engineer (AI/ML) | Remote USA | undisclosed | https://job-boards.greenhouse.io/greenhouse/jobs/7538639 |

## Authoritative references

The full list of frameworks, standards, and open-source tools that ground this packet is in [`.aicg/job-requirements.json`](.aicg/job-requirements.json) `authoritative_references[]`. New this cycle: `ref-owasp-agentic-top-10` (OWASP Agentic AI Top 10 — cited by name in Backblaze), `ref-openssf-mlsecops` (OpenSSF MLSecOps Whitepaper — referenced by 2026 vendor-consolidation coverage), `ref-garak` and `ref-pyrit` (LLM red-team automation harnesses now the de facto pair alongside UK AISI Inspect). All new references are woven inside existing modules; none warrant a new module.

Top-tier sources include:

- **NIST AI RMF 1.0** — [`NIST.AI.100-1`](https://nvlpubs.nist.gov/nistpubs/ai/NIST.AI.100-1.pdf) and the [GenAI Profile (AI 600-1)](https://airc.nist.gov/AI_RMF_Knowledge_Base/AI_RMF/Uses/GenAI-Profile).
- **NIST AI 100-2e2023** — [Adversarial ML: A Taxonomy and Terminology of Attacks and Mitigations](https://nvlpubs.nist.gov/nistpubs/ai/NIST.AI.100-2e2023.pdf).
- **OWASP Machine Learning Security Top 10** — [owasp.org project page](https://owasp.org/www-project-machine-learning-security-top-10/).
- **OWASP Top 10 for LLM Applications (2025 → 2026 refresh)** — [genai.owasp.org/llm-top-10](https://genai.owasp.org/llm-top-10/).
- **OWASP Agentic AI Top 10 (2026)** — [OWASP GenAI Agentic Security Initiative](https://genai.owasp.org/initiatives/agentic-security-initiative/).
- **MITRE ATLAS** — [atlas.mitre.org](https://atlas.mitre.org/).
- **ISO/IEC 42001:2023** — [AI Management System](https://www.iso.org/standard/81230.html).
- **EU AI Act (Regulation (EU) 2024/1689)** — [EUR-Lex OJ](https://eur-lex.europa.eu/eli/reg/2024/1689/oj).
- **NIST SP 800-207** — [Zero Trust Architecture](https://csrc.nist.gov/pubs/sp/800/207/final).
- **NIST SP 800-161r1** — [Cybersecurity Supply Chain Risk Management Practices](https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-161r1.pdf).
- **SLSA v1.0** — [slsa.dev spec](https://slsa.dev/spec/v1.0/).
- **CISA Guidelines for Secure AI System Development** — [CISA joint international](https://www.cisa.gov/resources-tools/resources/guidelines-secure-ai-system-development).
- **UK AI Safety Institute Inspect** — [Inspect Evaluation Framework](https://ukgovernmentbeis.github.io/inspect_ai/).
- **NVIDIA garak** — [github.com/NVIDIA/garak](https://github.com/NVIDIA/garak) and **Microsoft PyRIT** — [github.com/Azure/PyRIT](https://github.com/Azure/PyRIT).
- **OpenSSF MLSecOps** — [openssf.org/technical-initiatives/ai-ml-security](https://openssf.org/technical-initiatives/ai-ml-security/).
- **Frontier-lab safety frameworks** — [Anthropic RSP](https://www.anthropic.com/rsp), [OpenAI Preparedness Framework](https://openai.com/index/updating-our-preparedness-framework/), [DeepMind Frontier Safety Framework](https://deepmind.google/discover/blog/introducing-the-frontier-safety-framework/).
- **Sector regs** — [GDPR](https://eur-lex.europa.eu/eli/reg/2016/679/oj), [HIPAA Security Rule](https://www.hhs.gov/hipaa/for-professionals/security/index.html), [AICPA SOC 2 TSCs](https://www.aicpa-cima.com/topic/audit-assurance/audit-and-assurance-greater-than-soc-2), [EU Cyber Resilience Act](https://eur-lex.europa.eu/eli/reg/2024/2847/oj).
- **Open-source tools** — [HashiCorp Vault](https://developer.hashicorp.com/vault/docs), [OPA / Rego](https://www.openpolicyagent.org/docs/latest/), [OPA Gatekeeper](https://open-policy-agent.github.io/gatekeeper/website/docs/), [SPIFFE / SPIRE](https://spiffe.io/docs/latest/), [Falco](https://falco.org/docs/), [Sigstore / cosign](https://docs.sigstore.dev/), [Adversarial Robustness Toolbox](https://adversarial-robustness-toolbox.readthedocs.io/), [Opacus](https://opacus.ai/), [Protect AI ModelScan](https://github.com/protectai/modelscan), [Hugging Face Hub security](https://huggingface.co/docs/hub/security).

## Curriculum-plan delta this cycle

**No additions.** See [`.aicg/curriculum-plan-delta.json`](.aicg/curriculum-plan-delta.json). Every strongly-cited theme is already owned by an existing module; every weakly-cited emerging theme (MCP, AI-assisted-developer-tools, shadow AI, agentic-workflow anomaly detection) either fails the ≥ 0.30 frequency bar or is already covered incrementally by an existing `mod-107` or `mod-111` exercise. New authoritative references (`ref-owasp-agentic-top-10`, `ref-garak`, `ref-pyrit`, `ref-openssf-mlsecops`) are added to `authoritative_references[]` and will be woven into existing module lecture text on the next content-refresh cycle — that is a content edit, not a curriculum-plan-delta.

## Next research cycle checklist

1. Re-sample ≥ 25 postings across the same five equivalent titles; watch for `MLSecOps Engineer` employer branding gaining traction (still absent as of 2026-09).
2. Track the four below-threshold emerging themes for movement: MCP-server governance, AI-assisted-developer-tool governance, shadow-AI enforcement, agentic-workflow anomaly detection. Promote to `mod-107` / `mod-111` exercise if any clears ≥ 3 postings AND ≥ 0.30 frequency.
3. Watch the vendor-consolidation wave (Palo Alto/Protect AI, Cisco/Robust Intelligence, F5/CalypsoAI) for impact on req-05 (ML supply-chain security) frequency — 0.19 this cycle, expected to rise.
4. Re-verify salary tier structure. If Principal/Staff+ tier ceiling moves > 20% year-over-year, add a delta note.
5. Refresh this file — replace every posting URL with the newest active listing per employer where possible.
