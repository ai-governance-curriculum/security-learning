# AI/ML Security & Governance Engineer — Job Requirements

**Role:** AI/ML Security & Governance Engineer
**Role ID:** `security`
**Level:** 35 (AI Governance family, hands-on engineering specialist)
**Peer packet at same level:** [`ai-evaluation-engineer-learning`](../ai-evaluation-engineer-learning/)
**Adjacent lower packet:** [`ai-risk-engineer-learning`](../ai-risk-engineer-learning/) (level 25)
**Adjacent higher packet:** [`agentic-safety-engineer-learning`](../agentic-safety-engineer-learning/) (level 40)
**Research window:** 2026-07-04 → 2026-10-04
**Postings sampled:** 29 (target ≥ 25)
**Machine-readable source:** [`.aicg/job-requirements.json`](.aicg/job-requirements.json)
**Curriculum plan:** [`.aicg/curriculum-plan.json`](.aicg/curriculum-plan.json)
**Curriculum-plan delta this cycle:** [`.aicg/curriculum-plan-delta.json`](.aicg/curriculum-plan-delta.json) — **no additions**.

---

## Research status — sampled

Refresh of the 2026-09-04 cycle. Live sample captured on 2026-10-04 via WebSearch and WebFetch across the same five equivalent titles:
`AI Security Engineer`, `ML Security Engineer`, `AI/ML Security & Governance Engineer`, `MLSecOps Engineer`, `AI Security & Compliance Engineer`.

Title-variant distribution (n=29):

| Title variant | Count |
| --- | --- |
| `ai-security-engineer` | 24 |
| `ml-security-engineer` | 3 |
| `ai-ml-security-governance` | 2 |
| `ai-security-compliance` | 0 |
| `mlsecops-engineer` | 0 |

The `MLSecOps Engineer` employer-branded title remains essentially absent in-market (confirmed for a second cycle). The `AI Security & Compliance Engineer` variant is empty this cycle — the prior cycle's xAI GRC Frameworks & AI Governance posting has filled, and the compliance-adjacent band is partly absorbed into the Aimpoint governance-architect role.

Posted-date metadata was extractable for 6 postings this cycle (Xerox 2026-09-30, Spring Health 2026-06-03, Snorkel 2026-08-20, DoorDash 2026-08-24, FanDuel 2026-09-14, Samsara 2026-10-01). The rest returned active ATS listings on 2026-10-04 (Greenhouse / Lever / Breezy / Avature / vendor-branded careers pages typically retire postings within 30–60 days of fill).

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

Frequencies are the observed rate across the 29-posting 2026-10 sample, computed strictly from each posting's `requirements_hit[]` field. Nine themes clear the 0.30 promotion threshold this cycle (up from six last cycle); the remaining four are below-threshold in this window but are preserved as required modules because they map to distinct engineering craft that shows up in specific verticals (privacy for health/insurance/finance, cross-functional leadership for Principal/Staff+, data-and-model lineage for regulator-facing readiness).

| ID | Requirement theme | Owner module | References (see `.aicg/job-requirements.json`) | Frequency (n=29) | Δ vs 2026-09 |
| --- | --- | --- | --- | --- | --- |
| req-01 | Fluent working command of the four operative ML/LLM security taxonomies (OWASP ML Top 10, OWASP LLM Top 10 v2025→2026, MITRE ATLAS, NIST AI 100-2); OWASP Agentic AI Top 10 cited as a companion | [`mod-101-ml-security-governance-position`](lessons/mod-101-ml-security-governance-position/) | `ref-owasp-ml-top-10`, `ref-owasp-llm-top-10`, `ref-owasp-agentic-top-10`, `ref-mitre-atlas`, `ref-nist-ai-100-2` | **0.48** | +0.04 |
| req-02 | Threat modelling for ML/LLM systems (STRIDE adapted, ATLAS TTP mapping, attack trees, prioritised mitigations) | [`mod-102-threat-modelling-for-ai-ml-systems`](lessons/mod-102-threat-modelling-for-ai-ml-systems/) | `ref-mitre-atlas`, `ref-nist-ai-600-1`, `ref-owasp-llm-top-10`, `ref-cisa-secure-ai` | **0.76** | +0.01 |
| req-03 | Zero-trust architecture for ML platforms (workload identity, mTLS, network segmentation, K8s hardening, admission gates, non-human-agent identity) | [`mod-103-secure-ml-platform-architecture`](lessons/mod-103-secure-ml-platform-architecture/) | `ref-nist-sp-800-207`, `ref-cis-kubernetes`, `ref-spiffe-spire`, `ref-cncf-security-whitepaper`, `ref-opa-rego`, `ref-gatekeeper`, `ref-iso-27001` | **0.48** | +0.01 |
| req-04 | Secrets and key management for ML (Vault dynamic secrets, KMS envelope encryption, keyless CI, ephemeral credentials, short-lived scoped agent-tool creds) | [`mod-105-secrets-and-key-management`](lessons/mod-105-secrets-and-key-management/) | `ref-vault-docs`, `ref-sigstore` | **0.34** | +0.09 |
| req-05 | ML supply-chain security (SLSA for models, cosign/sigstore, ML-BOM, malicious model-file detection, MCP tool registry provenance) | [`mod-110-supply-chain-security-for-ai`](lessons/mod-110-supply-chain-security-for-ai/) | `ref-slsa`, `ref-sigstore`, `ref-huggingface-security`, `ref-protect-ai-modelscan`, `ref-nist-sp-800-161`, `ref-eu-cra`, `ref-openssf-mlsecops` | **0.41** | +0.22 |
| req-06 | Adversarial ML defence at platform scale (evasion, poisoning, extraction, membership inference, backdoors; adversarial training; certified defences; DP-SGD; in-serving detection monitors; garak / PyRIT) | [`mod-106-adversarial-ml-defense`](lessons/mod-106-adversarial-ml-defense/) | `ref-nist-ai-100-2`, `ref-adversarial-robustness-toolbox`, `ref-garak`, `ref-pyrit`, `ref-mitre-atlas`, `ref-owasp-ml-top-10` | **0.41** | +0.16 |
| req-07 | LLM and agent security engineering (OWASP LLM Top 10 mitigations, OWASP Agentic AI Top 10, indirect prompt injection, MCP-server attack surface, agent tool ACLs, red-team engineering with garak / PyRIT / Inspect) | [`mod-107-llm-agent-security`](lessons/mod-107-llm-agent-security/) | `ref-owasp-llm-top-10`, `ref-owasp-agentic-top-10`, `ref-nist-ai-600-1`, `ref-lakera-prompt-injection-taxonomy`, `ref-uk-aisi-inspect`, `ref-garak`, `ref-pyrit`, `ref-mitre-atlas` | **0.90** | +0.02 |
| req-08 | Privacy engineering for ML (DP-SGD, PETs, inference-attack mitigation, PII/PHI DLP, GDPR / HIPAA to controls) | [`mod-108-privacy-engineering-for-ml`](lessons/mod-108-privacy-engineering-for-ml/) | `ref-opacus`, `ref-gdpr`, `ref-hhs-hipaa-security`, `ref-nist-sp-800-53`, `ref-nist-ai-100-2` | 0.21 | +0.05 |
| req-09 | AI governance and compliance engineering (NIST AI RMF, ISO/IEC 42001, EU AI Act, SOC 2, sector regs; policy-as-code; audit evidence; continuous evidence pipelines) | [`mod-109-ai-governance-and-compliance-engineering`](lessons/mod-109-ai-governance-and-compliance-engineering/) | `ref-nist-ai-rmf`, `ref-nist-ai-600-1`, `ref-iso-42001`, `ref-iso-27001`, `ref-eu-ai-act`, `ref-aicpa-soc2`, `ref-nist-sp-800-53`, `ref-anthropic-rsp`, `ref-openai-preparedness`, `ref-deepmind-fsf`, `ref-eu-cra` | **0.69** | +0.16 |
| req-10 | Runtime security and detection engineering for ML workloads (Falco, eBPF, ML-specific detection content, agentic-workflow anomaly detection) | [`mod-111-security-operations-and-incident-response-for-ml`](lessons/mod-111-security-operations-and-incident-response-for-ml/) | `ref-falco`, `ref-mitre-atlas`, `ref-cis-kubernetes` | **0.52** | +0.27 |
| req-11 | Security operations and incident response for ML (SIEM integration, ATLAS-mapped detection, AI-specific IR playbooks incl. shadow-AI enforcement, SOC interface) | [`mod-111-security-operations-and-incident-response-for-ml`](lessons/mod-111-security-operations-and-incident-response-for-ml/) | `ref-mitre-atlas`, `ref-nist-ai-100-2`, `ref-uk-aisi-inspect`, `ref-c2pa`, `ref-nist-ai-100-4` | **0.41** | -0.06 |
| req-12 | Cross-functional leadership of the ML security & governance slice (control-library ownership, program metrics, regulator support) | [`mod-112-program-leadership-for-ml-security-governance`](lessons/mod-112-program-leadership-for-ml-security-governance/) | `ref-cisa-secure-ai`, `ref-nist-ai-rmf`, `ref-iso-42001`, `ref-eu-ai-act`, `ref-anthropic-rsp` | 0.03 (sample-skew; see notes) | -0.22 |
| req-13 | Data and model lineage security (signed provenance, immutable audit, ML-BOM, model-card evidence linking) | [`mod-104-data-and-model-lineage-security`](lessons/mod-104-data-and-model-lineage-security/) | `ref-slsa`, `ref-sigstore`, `ref-nist-ai-rmf`, `ref-eu-ai-act`, `ref-iso-42001` | 0.07 (sample-skew; see notes) | -0.12 |

The drops in **req-12** (0.25 → 0.03) and **req-13** (0.19 → 0.07) are sample-composition artefacts, not market signals — this cycle skewed toward hands-on engineering postings (Anthropic engineering, Databricks engineering, platform-vendor security) and had fewer explicit Principal / Staff+ control-library-authoring or signed-provenance postings than the prior cycle. Among this cycle's Staff+ / Principal / Lead postings — Anthropic Staff+ ×2, Databricks Staff, Ripple Sr Staff, FanDuel Staff, Aimpoint Lead, Rithum Staff — cross-functional-leadership scope is still present in prose but not called out in the `key_quotes[]` fields. Both themes are preserved as required modules.

## What the 2026-10 sample says about the curriculum

- **All 13 required themes are cited by at least 2 postings.** No theme has fallen out of the required set; the dominance structure is unchanged.
- **req-07 (LLM/agent security) is at 0.90** — virtually every posting except the pure-infrastructure Zscaler Tokyo/Federal roles and the compliance-adjacent Mastercard posting cites some form of LLM/agent-security scope. mod-107 remains the load-bearing module.
- **req-02 (threat modelling) at 0.76** — now effectively tied with the prior cycle. 2026-10 postings increasingly name "threat model AI/agent features" as a *continuous review deliverable*, not a one-off design-time exercise.
- **req-09 (governance + compliance engineering) at 0.69** — ISO 42001 is now the second-most-cited framework after SOC 2 and "continuous evidence pipelines" / "auditor-facing control evidence" has become stock vocabulary. Clearest examples: AlphaSense, Aimpoint, FanDuel, Databricks, Ripple.
- **req-10 (runtime security + detection engineering) jumped from 0.25 to 0.52** — driven by *agentic-workflow anomaly detection* becoming standard shipped scope at platform vendors and frontier labs (Databricks "agentic workflow anomaly detection", Anthropic Cyber Evals "layered abuse-detection architecture", Spring Health "near real-time anomalous model behavior", Air "runtime monitoring for agentic workloads").
- **req-05 (ML supply chain) jumped from 0.19 to 0.41** — the vendor-consolidation hypothesis from last cycle is confirmed. "AI/ML supply chain", "SBOM for models", "secure dependencies for AI tools", and "MCP tool registry provenance" are now routine shipped deliverables.
- **req-06 (adversarial ML defence) rose from 0.25 to 0.41** — frontier-lab + platform-vendor red-team / safeguards engineering postings are the drivers (Anthropic ×3, Databricks, Cloudflare, ServiceNow).
- Below-threshold themes are not dropped: they map to distinct engineering craft demanded by specific verticals.

## Emerging themes — threshold tracker

Under the continuity-bias contract, a theme is promoted to a new module only if ALL of: ≥ 3 postings cite it in the 90-day window, frequency ≥ 0.30, AND no existing module / exercise can be incrementally extended.

**One theme crosses both numeric thresholds this cycle for the first time — but is NOT promoted because an existing module already covers it:**

- **MCP-server governance and agent-tool ACL depth** — 10/29 postings (0.34) named MCP by name or near-synonyms: Xerox "MCP servers", GitLab "Secure Model Context Protocol (MCP) Implementations", Ripple "MCP tool registry", FanDuel "AI gateway, MCP tool registry, and agent orchestration", DoorDash "MCP server security", Perplexity "self-hosted models, LLM APIs, agents, MCPs", Air "tool abuse / memory poisoning", Databricks "agent/tool catalog", GuidePoint "agentic coding assistants", Zscaler Federal/Tokyo. **Coverage:** req-07's theme text explicitly lists "MCP-server attack surface" as in-scope; mod-107 lesson 03 (`agent-tool-ACLs-and-HITL`) already has 11 MCP-adjacent references and lesson 04 (`red-teaming-with-Inspect`) covers agent-tool red-team methodology. **Action:** next content-refresh of mod-107 lessons 03–04 should deepen tool-registry admission control, tool-poisoning threat model, and tool-call provenance logging. This is a content edit, not a curriculum-plan-delta.

**Three themes rose this cycle but remain below the 0.30 frequency threshold:**

- **AI-assisted-developer-tool governance (Claude Code, Cursor, Copilot, Codex, "vibe coding")** — 7/29 postings (0.24, up from 0.13). Atlas HXM "guardrails for Claude, Copilot, and AI agents"; GuidePoint "operational experience with agentic coding assistants (Claude, Cursor, Codex)"; Rithum; Aimpoint; Appier; GitLab Enterprise AI; Anthropic Staff+ AppSec. Folded inside mod-107 exercise-03 and mod-111 IR playbook slice. Expected to cross 0.30 within 1–2 cycles.
- **Agentic-workflow anomaly detection at runtime** — 7/29 (0.24, up from 0.16). Absorbed into mod-111 scope via req-10 which already crossed to 0.52; the agentic-anomaly sub-theme folds inside existing lesson scope.
- **Shadow-AI detection and enforcement** — 5/29 (0.17, up from 0.09). Zscaler Principal Tokyo/Federal, Ripple "Shadow AI detection capability", GitLab Enterprise AI, AlphaSense. Vendor-side framing is a signal this is becoming enterprise-standard; folded inside mod-111 IR playbook slice.

**Genuinely new themes (not in the existing 13 or 4 tracked lists):**

- **Confidential computing for AI (Intel TDX, AMD SEV-SNP, NVIDIA H100 CC)** — 0/29 cited by name. Still aspirational.
- **Post-quantum readiness for ML systems** — 0/29. Still aspirational.
- **Federated-learning security at production scale** — 1/29 (Mastercard, paired with differential privacy). Keep out-of-scope until ≥ 3 cite.
- **Homomorphic-encryption-based inference** — 0/29 cited by name.
- **Watermarking / provenance for generative outputs (C2PA, NIST AI 100-4)** — 0/29 cited by name in this sample.
- **EU AI Act Article 55 systemic-risk obligations named explicitly** — 0/29. The EU AI Act is cited generically in ~4 postings but no posting named Article 55 by number. Architecture-depth stays with senior-ai-governance-architect (level 50).

**Zero genuinely new themes cross ≥ 3 postings AND ≥ 0.30 frequency — identical conclusion to the prior cycle.**

## Salary evidence

**Sample:** 18 of 29 postings disclosed a base-salary range. Salaries are base only; equity and bonus are excluded. USD anchor; the 2026-10 refresh contained no non-USD disclosures. Three distinct compensation clusters emerged, consistent with the prior cycle shape.

| Tier | Low (USD) | High (USD) | Median band (USD) | Postings |
| --- | --- | --- | --- | --- |
| US Senior / Staff AI Security Engineer (platform-adjacent) | 158,000 | 280,000 | 180,000 – 240,000 | 9 (Spring Health, Zscaler Federal, Rithum, AlphaSense, Lightning, Cloudflare, Perplexity, Samsara, FanDuel) |
| US Principal / Staff+ / Sr Staff (frontier lab / platform vendor) | 193,000 | 485,000 | 290,000 – 400,000 | 7 (Anthropic ×4, Databricks, Ripple, ServiceNow) |
| US regulated-industry / mid-market | 115,000 | 240,000 | 150,000 – 200,000 | 2 (Mastercard, GitLab) |

Non-US disclosures: none this cycle. Xerox (India), Zscaler (Tokyo), Atlas HXM (Canada), and Appier (Taipei) did not disclose ranges.

The tier structure is consistent with the peer packet [`ai-risk-engineer-learning`](../ai-risk-engineer-learning/) reported USD 100k–850k range across a wider level ladder.

## Postings

The full posting evidence set is in [`.aicg/job-requirements.json`](.aicg/job-requirements.json) `postings[]`. Summary index below (29 rows):

| Employer | Title | Location | Salary (USD unless noted) | URL |
| --- | --- | --- | --- | --- |
| Anthropic | Cyber Evaluations Engineer | Remote US / SF / DC | 300,000 – 405,000 | https://job-boards.greenhouse.io/anthropic/jobs/5406367008 |
| Anthropic | Staff+ Software Engineer, Safeguards | SF / NYC | 320,000 – 485,000 | https://job-boards.greenhouse.io/anthropic/jobs/4951844008 |
| Anthropic | Red Team Engineer, Safeguards | SF, CA (Remote-Friendly) | 320,000 – 405,000 | https://job-boards.greenhouse.io/anthropic/jobs/5320469008 |
| Anthropic | Staff+ Application Security Engineer | SF / Seattle / NYC | 320,000 – 485,000 | https://job-boards.greenhouse.io/anthropic/jobs/4502508008 |
| Databricks | Staff Security Software Engineer, Agentic Security Engineering | Remote USA | 231,400 – 397,650 | https://www.databricks.com/company/careers/security/staff-security-software-engineer-agentic-security-engineering--7882009002 |
| Ripple | Senior Staff Security Engineer, AI Security | San Francisco, CA | 232,000 – 290,000 | https://ripple.com/careers/all-jobs/job/7961902 |
| ServiceNow | Senior Staff AI/ML Product Security Engineer | Kirkland, WA / Santa Clara, CA | 193,000 – 328,000 | https://builtin.com/job/senior-staff-aiml-product-security-engineer/4197570 |
| Spring Health | Staff AI Security Engineer | Seattle, WA (Hybrid) | 208,000 – 251,000 | https://job-boards.greenhouse.io/springhealth66/jobs/4675797005 |
| FanDuel | Staff AI Security Engineer | New York, NY | 184,000 – 242,000 | https://freehire.me/jobs/staff-ai-security-engineer-fanduel-hdn2uljz |
| Perplexity | AI Security Engineer | NYC / SF (Hybrid) | 200,000 – 280,000 | https://talents.vaia.com/companies/perplexity-ai-inc/ai-security-engineer-new-york-city-san-francisco-32088933/ |
| AlphaSense | Senior Product Security Engineer | US Remote | 182,000 – 228,000 | https://job-boards.greenhouse.io/alphasense/jobs/8435357002 |
| Lightning AI | Senior Application Security Engineer, AI and Machine Learning | SF / Seattle (Hybrid) | 180,000 – 220,000 | https://job-boards.greenhouse.io/lightningai/jobs/7687112003 |
| Zscaler | Principal AI Security Specialist - Federal | McLean, VA / Remote DC | 176,000 – 251,000 | https://job-boards.greenhouse.io/zscaler/jobs/5174765007 |
| Rithum | Staff Information Security Engineer - AI First | US Remote | 170,000 – 220,000 | https://job-boards.greenhouse.io/rithum/jobs/8016565 |
| Cloudflare | AI Security Research & Red Team Engineer | Austin / NYC (Hybrid) | 166,000 – 208,000 | https://job-boards.greenhouse.io/cloudflare/jobs/8097321 |
| Samsara | Senior AI Security Engineer | US Remote | 158,000 – 239,000 | https://zapply.jobs/jobs/acf85a0c-d821-4d56-9491-d0d66b280c84/ |
| GitLab | Senior Security Engineer - Enterprise AI Security | US multi-location / Remote | 124,000 – 240,000 | https://builtin.com/job/senior-security-engineer-enterprise-ai-security/7291335 |
| Mastercard | Senior AI Security Engineer | O'Fallon, MO (Hybrid) | 115,000 – 184,000 | https://builtin.com/job/senior-ai-security-engineer/7326238 |
| Zscaler | Senior Software Engineer - AI Security (Network/Rust) | San Jose / Bellevue (Hybrid) | undisclosed | https://job-boards.greenhouse.io/zscaler/jobs/5146136007 |
| Zscaler | Principal AI Security Specialist | Tokyo, Japan | undisclosed | https://job-boards.greenhouse.io/zscaler/jobs/5174751007 |
| Snorkel AI | Software Engineer — Security | New York, NY | undisclosed | https://zapply.jobs/jobs/d7406c08-446b-45f1-833c-4de4c0d97a45/ |
| DoorDash | Staff Security Engineer, Proactive Security - AI | US Remote | undisclosed | https://zapply.jobs/jobs/fae02356-da8a-4a00-bf06-974510262987/ |
| Aimpoint Digital | Lead AI Security Architect 2026 | Atlanta / Remote US | undisclosed | https://aimpoint-digital.breezy.hr/p/86c221c3a8a3-lead-ai-security-architect-2026-us |
| Atlas HXM | Senior Security Engineer, AI & DevSecOps | Canada (onsite) | undisclosed | https://www.goodvibecode.com/jobs/senior-security-engineer-ai-devsecops-atlas-hxm-995963 |
| GuidePoint Security | AI Security Engineer - Mid-Atlantic | Remote (VA/MD/PA/NC/DE/NJ/DC) | undisclosed | https://job-boards.greenhouse.io/guidepointsecurity/jobs/6030474004 |
| Air | Senior AI Engineer, Security Infrastructure | Arlington, VA / Pittsburgh, PA / Remote | undisclosed | https://job-boards.greenhouse.io/air/jobs/4394418009 |
| 66degrees | Security Operations AI Engineer (Contract) | US Remote | undisclosed | https://job-boards.greenhouse.io/66degrees/jobs/6206846004 |
| Xerox | Staff Security Engineer - Cloud & AI Security | India (Remote) | undisclosed | https://xerox.avature.net/en_US/careers/JobDetail?jobId=47814 |
| Appier | Senior AI Security Engineer | Taipei, Taiwan | undisclosed | https://job-boards.greenhouse.io/appier/jobs/7949831 |

## Authoritative references

The full list of frameworks, standards, and open-source tools that ground this packet is in [`.aicg/job-requirements.json`](.aicg/job-requirements.json) `authoritative_references[]`. No new references added this cycle — the four picked up in the 2026-09 cycle (`ref-owasp-agentic-top-10`, `ref-openssf-mlsecops`, `ref-garak`, `ref-pyrit`) remain cited and will be woven into existing module lecture text on the next content-refresh cycle. OWASP Agentic AI Top 10 is now cited by name in more postings this cycle (GuidePoint, Databricks, Air, Rithum, in addition to prior-cycle Backblaze).

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

**No additions.** See [`.aicg/curriculum-plan-delta.json`](.aicg/curriculum-plan-delta.json). Every strongly-cited theme is already owned by an existing module. MCP-server governance crossed both numeric thresholds for the first time this cycle but is not promoted because req-07's theme text explicitly lists MCP as in-scope and mod-107 lessons 03–04 already cover it (11 MCP-adjacent references in lesson 03 alone). The three other emerging themes (AI-assisted-dev-tool governance, agentic-workflow anomaly detection, shadow-AI detection) remain below the 0.30 threshold. Deepening mod-107 MCP coverage (tool-registry admission control, tool-poisoning threat model, tool-call provenance logging) is scheduled as a content-refresh action in the next cycle — content edit, not curriculum-plan-delta.

## Next research cycle checklist

1. Re-sample ≥ 25 postings across the same five equivalent titles; watch for `MLSecOps Engineer` employer branding gaining traction (still absent for a second cycle).
2. Watch **AI-assisted-developer-tool governance** (now at 0.24) for crossing 0.30 — expected within 1–2 cycles.
3. Watch **shadow-AI detection and enforcement** (now at 0.17) — the Zscaler / Ripple vendor framing suggests this will keep rising.
4. Watch for **confidential computing / TEEs** to appear by name — still at 0/29 but trade press is pushing it hard; could jump suddenly.
5. Watch for **EU AI Act Article 55 systemic-risk obligations named explicitly** — August 2026 is the operational start date for GPAI obligations, so JDs may start citing Article 55 by number as deployments mature.
6. Reassess **req-12 (cross-functional leadership)** and **req-13 (lineage security)** with a wider Principal / Staff+ sample slice to confirm the 2026-10 drops were sample-composition artefacts and not real market movement.
7. Verify salary tier structure. If Principal / Staff+ tier median moves > 10% year-over-year, add a delta note.
8. Refresh this file — replace every posting URL with the newest active listing per employer where possible.
