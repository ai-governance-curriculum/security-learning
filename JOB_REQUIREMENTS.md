# AI/ML Security & Governance Engineer — Job Requirements

**Role:** AI/ML Security & Governance Engineer
**Role ID:** `security`
**Level:** 35 (AI Governance family, hands-on engineering specialist)
**Peer packet at same level:** [`ai-evaluation-engineer-learning`](../ai-evaluation-engineer-learning/)
**Adjacent lower packet:** [`ai-risk-engineer-learning`](../ai-risk-engineer-learning/) (level 25)
**Adjacent higher packet:** [`agentic-safety-engineer-learning`](../agentic-safety-engineer-learning/) (level 40)
**Research window:** 2026-08-07 → 2026-11-05
**Postings sampled:** 33 (target ≥ 25)
**Machine-readable source:** [`.aicg/job-requirements.json`](.aicg/job-requirements.json)
**Curriculum plan:** [`.aicg/curriculum-plan.json`](.aicg/curriculum-plan.json)
**Curriculum-plan delta this cycle:** [`.aicg/curriculum-plan-delta.json`](.aicg/curriculum-plan-delta.json) — **no additions**.

---

## Research status — sampled

Refresh of the 2026-10-04 cycle. Live sample captured on 2026-11-05 via WebSearch and WebFetch across the same five equivalent titles:
`AI Security Engineer`, `ML Security Engineer`, `AI/ML Security & Governance Engineer`, `MLSecOps Engineer`, `AI Security & Compliance Engineer`.

Title-variant distribution (n=33):

| Title variant | Count |
| --- | --- |
| `ai-security-engineer` | 28 |
| `ml-security-engineer` | 2 |
| `ai-ml-security-governance` | 3 |
| `ai-security-compliance` | 0 |
| `mlsecops-engineer` | 0 |

The `MLSecOps Engineer` employer-branded title remains essentially absent in-market (confirmed for a third consecutive cycle). The `AI Security & Compliance Engineer` variant is again empty; the compliance-adjacent band is covered by xAI's two GRC-branded engineering roles and the governance-architect-style roles at Aimpoint, Atlas HXM, and Cisco. Within the `ai-security-engineer` count sit a notable cluster of 6 employer-branded offensive / red-team AI roles that map cleanly into this role family (Anthropic Red Team Engineer Safeguards, Anthropic Offensive Security Research Engineer, OpenAI Offensive Security Engineer Agent Products, DeepMind Senior Security Engineer Agentic Red Team, Samsara Senior Offensive AI Security Engineer II, Bishop Fox Senior AI/LLM Penetration Tester) — scope expansion within existing req-06 and req-07, not a new theme.

Posted-date metadata was extractable for 9 of 33 postings this cycle (Anthropic Staff+ Fullstack Safeguards 2026-10-23, DeepMind Agentic Red Team 2026-07-07, Mastercard Principal 2026-09-10, JPMorgan Senior Lead AI Controls 2026-10-22, Samsara Senior AI Security 2026-11-04, Salesforce Enterprise App Eng Security 2026-11-03, GuidePoint North Central 2026-10-05, Bishop Fox Senior AI/LLM Pen Tester 2026-07-16, Atlas HXM 2026-08-12). The rest returned active ATS listings on 2026-11-05.

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

Frequencies are the observed rate across the 33-posting 2026-11 sample, computed strictly from each posting's `requirements_hit[]` field. Seven themes clear the 0.30 promotion threshold this cycle (prior cycle nine — req-01 slipped to 0.30 on the threshold boundary; req-04, req-05, and req-11 dropped on sample composition); the remaining six are below-threshold in this window but are preserved as required modules because they map to distinct engineering craft that shows up in specific verticals and sample slices.

| ID | Requirement theme | Owner module | References (see `.aicg/job-requirements.json`) | Frequency (n=33) | Δ vs 2026-10 |
| --- | --- | --- | --- | --- | --- |
| req-01 | Fluent working command of the four operative ML/LLM security taxonomies (OWASP ML Top 10, OWASP LLM Top 10 v2025→2026, MITRE ATLAS, NIST AI 100-2); OWASP Agentic AI Top 10 cited as a companion | [`mod-101-ml-security-governance-position`](lessons/mod-101-ml-security-governance-position/) | `ref-owasp-ml-top-10`, `ref-owasp-llm-top-10`, `ref-owasp-agentic-top-10`, `ref-mitre-atlas`, `ref-nist-ai-100-2` | **0.30** | -0.18 |
| req-02 | Threat modelling for ML/LLM systems (STRIDE adapted, ATLAS TTP mapping, attack trees, prioritised mitigations) | [`mod-102-threat-modelling-for-ai-ml-systems`](lessons/mod-102-threat-modelling-for-ai-ml-systems/) | `ref-mitre-atlas`, `ref-nist-ai-600-1`, `ref-owasp-llm-top-10`, `ref-cisa-secure-ai` | **0.64** | -0.12 |
| req-03 | Zero-trust architecture for ML platforms (workload identity, mTLS, network segmentation, K8s hardening, admission gates, non-human-agent identity) | [`mod-103-secure-ml-platform-architecture`](lessons/mod-103-secure-ml-platform-architecture/) | `ref-nist-sp-800-207`, `ref-cis-kubernetes`, `ref-spiffe-spire`, `ref-cncf-security-whitepaper`, `ref-opa-rego`, `ref-gatekeeper`, `ref-iso-27001` | **0.33** | -0.15 |
| req-04 | Secrets and key management for ML (Vault dynamic secrets, KMS envelope encryption, keyless CI, ephemeral credentials, short-lived scoped agent-tool creds) | [`mod-105-secrets-and-key-management`](lessons/mod-105-secrets-and-key-management/) | `ref-vault-docs`, `ref-sigstore` | 0.12 (sample-skew; see notes) | -0.22 |
| req-05 | ML supply-chain security (SLSA for models, cosign/sigstore, ML-BOM, malicious model-file detection, MCP tool registry provenance) | [`mod-110-supply-chain-security-for-ai`](lessons/mod-110-supply-chain-security-for-ai/) | `ref-slsa`, `ref-sigstore`, `ref-huggingface-security`, `ref-protect-ai-modelscan`, `ref-nist-sp-800-161`, `ref-eu-cra`, `ref-openssf-mlsecops` | 0.12 (sample-skew; see notes) | -0.29 |
| req-06 | Adversarial ML defence at platform scale (evasion, poisoning, extraction, membership inference, backdoors; adversarial training; certified defences; DP-SGD; in-serving detection monitors; garak / PyRIT / UK AISI Inspect) | [`mod-106-adversarial-ml-defense`](lessons/mod-106-adversarial-ml-defense/) | `ref-nist-ai-100-2`, `ref-adversarial-robustness-toolbox`, `ref-garak`, `ref-pyrit`, `ref-mitre-atlas`, `ref-owasp-ml-top-10` | **0.48** | +0.07 |
| req-07 | LLM and agent security engineering (OWASP LLM Top 10 mitigations, OWASP Agentic AI Top 10, indirect prompt injection, MCP-server attack surface, agent tool ACLs, red-team engineering with garak / PyRIT / Inspect) | [`mod-107-llm-agent-security`](lessons/mod-107-llm-agent-security/) | `ref-owasp-llm-top-10`, `ref-owasp-agentic-top-10`, `ref-nist-ai-600-1`, `ref-lakera-prompt-injection-taxonomy`, `ref-uk-aisi-inspect`, `ref-garak`, `ref-pyrit`, `ref-mitre-atlas` | **0.91** | +0.01 |
| req-08 | Privacy engineering for ML (DP-SGD, PETs, inference-attack mitigation, PII/PHI DLP, GDPR / HIPAA to controls) | [`mod-108-privacy-engineering-for-ml`](lessons/mod-108-privacy-engineering-for-ml/) | `ref-opacus`, `ref-gdpr`, `ref-hhs-hipaa-security`, `ref-nist-sp-800-53`, `ref-nist-ai-100-2` | 0.12 | -0.09 |
| req-09 | AI governance and compliance engineering (NIST AI RMF, ISO/IEC 42001, EU AI Act, SOC 2, sector regs; policy-as-code; audit evidence; continuous evidence pipelines) | [`mod-109-ai-governance-and-compliance-engineering`](lessons/mod-109-ai-governance-and-compliance-engineering/) | `ref-nist-ai-rmf`, `ref-nist-ai-600-1`, `ref-iso-42001`, `ref-iso-27001`, `ref-eu-ai-act`, `ref-aicpa-soc2`, `ref-nist-sp-800-53`, `ref-anthropic-rsp`, `ref-openai-preparedness`, `ref-deepmind-fsf`, `ref-eu-cra` | **0.48** | -0.21 |
| req-10 | Runtime security and detection engineering for ML workloads (Falco, eBPF, ML-specific detection content, agentic-workflow anomaly detection) | [`mod-111-security-operations-and-incident-response-for-ml`](lessons/mod-111-security-operations-and-incident-response-for-ml/) | `ref-falco`, `ref-mitre-atlas`, `ref-cis-kubernetes` | **0.33** | -0.19 |
| req-11 | Security operations and incident response for ML (SIEM integration, ATLAS-mapped detection, AI-specific IR playbooks incl. shadow-AI enforcement, SOC interface) | [`mod-111-security-operations-and-incident-response-for-ml`](lessons/mod-111-security-operations-and-incident-response-for-ml/) | `ref-mitre-atlas`, `ref-nist-ai-100-2`, `ref-uk-aisi-inspect`, `ref-c2pa`, `ref-nist-ai-100-4` | 0.18 (sample-skew; see notes) | -0.23 |
| req-12 | Cross-functional leadership of the ML security & governance slice (control-library ownership, program metrics, regulator support) | [`mod-112-program-leadership-for-ml-security-governance`](lessons/mod-112-program-leadership-for-ml-security-governance/) | `ref-cisa-secure-ai`, `ref-nist-ai-rmf`, `ref-iso-42001`, `ref-eu-ai-act`, `ref-anthropic-rsp` | **0.30** | +0.27 |
| req-13 | Data and model lineage security (signed provenance, immutable audit, ML-BOM, model-card evidence linking) | [`mod-104-data-and-model-lineage-security`](lessons/mod-104-data-and-model-lineage-security/) | `ref-slsa`, `ref-sigstore`, `ref-nist-ai-rmf`, `ref-eu-ai-act`, `ref-iso-42001` | 0.12 | +0.05 |

**Sample-composition drops** this cycle (req-04, req-05, req-08, req-11): the 2026-11 refresh skews harder toward frontier-lab and platform-vendor offensive/red-team engineering postings (11 of 33) that assume rather than name supply-chain / secrets / IR-playbook scope. The same hiring surface at Anthropic Staff+ AppSec, Air, FanDuel, and AlphaSense that drove 2026-10 supply-chain and IR numbers is light in this sample; the themes remain core to regulated-industry and MLSecOps-branded hires. Reassess next cycle with a less red-team-weighted sample slice.

**Rebound** this cycle (req-12 from 0.03 to 0.30): the 2026-10 reading of 0.03 was explicitly flagged as a sample artefact, and the 2026-11 sample delivered the wider Principal / Staff+ / Lead slice the prior-cycle checklist called for — 11 of 33 postings are Staff+ / Principal / Senior Lead / Lead with explicit control-library-authoring, CISO interface, or program-scoping language. The theme crosses the 30% bar for the first time in this packet's history.

## What the 2026-11 sample says about the curriculum

- **All 13 required themes are cited by at least 2 postings.** No theme has fallen out of the required set; the dominance structure is unchanged.
- **req-07 (LLM/agent security) is at 0.91** — virtually every posting cites some form of LLM/agent-security scope. mod-107 remains the load-bearing module.
- **req-02 (threat modelling) at 0.64** — slight dip from 0.76 but still second-highest. The dominant framing is now "threat-model AI/agent features ahead of launch" as a *continuous* review deliverable (DoorDash, JPMorgan AI Controls, Samsara Offensive II).
- **req-06 (adversarial ML defence) rose from 0.41 to 0.48** — driven by the explosion of employer-branded offensive / red-team AI roles (Anthropic ×3, OpenAI Offensive Agent Products, DeepMind Agentic Red Team, Samsara Offensive II, Bishop Fox LLM Pentester). This is scope expansion within req-06 and req-07, not a new theme.
- **req-09 (governance + compliance engineering) at 0.48** — ISO 42001 continues as the second-most-cited framework after SOC 2; "continuous evidence pipelines" remains stock vocabulary. Clearest examples: Aimpoint, xAI GRC ×2, Mistral, Mastercard, CVS, Ripple.
- **req-10 (runtime security + detection engineering) at 0.33** — down from 0.52 but still at the threshold. Agentic-workflow anomaly detection remains standard shipped scope at platform vendors and frontier labs.
- **req-12 (cross-functional leadership) rebounded from 0.03 to 0.30** — confirming the 2026-10 reading was a sample artefact.
- Below-threshold themes are not dropped: they map to distinct engineering craft demanded by specific verticals.

## Emerging themes — threshold tracker

Under the continuity-bias contract, a theme is promoted to a new module only if ALL of: ≥ 3 postings cite it in the 90-day window, frequency ≥ 0.30, AND no existing module / exercise can be incrementally extended.

**No theme crosses both numeric thresholds this cycle AND is net-new:**

- **MCP-server governance and agent-tool ACL depth** pulled back slightly (2026-10: 0.34; 2026-11: 0.21–0.24). Still broadly cited (Ripple "MCP server security, tool poisoning"; GuidePoint "MCP client/server architecture vs. agentic skills"; DoorDash "MCP Gateways"; GitLab Staff Architect "Duo Agent Platform"; Palo Alto SWE "unsafe workspace mutations"; Databricks "agent/tool catalog"; OpenAI Agent Security "Agent Infrastructure"; DeepMind Agentic Red Team "tool escalation"). **Coverage:** req-07's theme text explicitly lists "MCP-server attack surface" as in-scope; mod-107 lesson 03 (`agent-tool-ACLs-and-HITL`) and lesson 04 (`red-teaming-with-Inspect`) continue to own it. **Action:** next content-refresh of mod-107 lessons 03–04 should deepen tool-registry admission control, tool-poisoning threat model, and tool-call provenance logging (carried over from 2026-10 cycle's content-refresh queue). Content edit, not curriculum-plan-delta.
- **Red-team / offensive security as an employer-branded role family** — 10 of 33 postings (0.30). But 100% of its scope is already owned by req-06 (adversarial ML defence) and req-07 (LLM/agent security). This is scope *expansion within existing requirements*, not a new theme. No curriculum change.

**Three themes rose but remain below the 0.30 frequency threshold:**

- **AI-assisted-developer-tool governance (Claude Code, Cursor, Copilot, Codex, GitLab Duo, "vibe coding")** — 8/33 postings (0.24, unchanged from prior cycle). OpenAI Codex Security, OpenAI Offensive Security Engineer Agent Products (tests Codex and Operator), GitLab Sr AI Product Security Researcher + Staff AI Product Security Architect (GitLab Duo Agent Platform), Atlas HXM ("guardrails for AI-assisted development, including AI-generated code, vibe coding, AI agents"), Cisco, Aimpoint, Samsara Offensive II, Palo Alto SWE. Folded inside mod-107 exercise-03 and mod-111 IR playbook slice. Expected to cross 0.30 within 1–2 cycles as GitLab Duo Agent Platform, Anthropic Claude Code, and OpenAI Codex drive enterprise role creation.
- **Agentic-workflow anomaly detection at runtime** — 6–7/33 (0.18–0.21, slightly below prior 0.24). Absorbed into mod-111 scope via req-10 which cleared 0.30 last cycle.
- **Shadow-AI detection and enforcement** — 4/33 (0.12, slightly below prior 0.17). Palo Alto Senior Enterprise AI Security, Ripple, GuidePoint "Shadow AI Discovery", ServiceNow Staff AI Safeguards. Vendor-side framing (Palo Alto, Ripple) continues to be a signal this is becoming enterprise-standard; folded inside mod-111 IR playbook slice.

**Genuinely new themes (not in the existing 13 or tracked lists):**

- **Confidential computing for AI (Intel TDX, AMD SEV-SNP, NVIDIA H100 CC)** — 0/33 cited by name. Still aspirational for a third consecutive cycle.
- **Post-quantum readiness for ML systems** — 0/33. Still aspirational.
- **Federated-learning security at production scale** — 0/33 (prior cycle Mastercard mention absent from refreshed JD). Keep out-of-scope.
- **Homomorphic-encryption-based inference** — 0/33 cited by name.
- **Watermarking / provenance for generative outputs (C2PA, NIST AI 100-4)** — 0/33 cited by name.
- **EU AI Act Article 55 systemic-risk obligations named explicitly** — 0/33. The EU AI Act is cited generically in ~5 postings (xAI GRC, Aimpoint, Mistral, xAI GRC Sales, Salesforce) but no posting named Article 55 by number. August 2026 GPAI operational start-date has passed, yet JDs still frame the EU AI Act as a horizontal compliance obligation rather than carving out Article 55. Architecture-depth stays with senior-ai-governance-architect (level 50).

**Zero genuinely new themes cross ≥ 3 postings AND ≥ 0.30 frequency — identical conclusion to the prior two cycles.**

## Salary evidence

**Sample:** 21 of 33 postings disclosed a base-salary range. Salaries are base only; equity and bonus are excluded. USD anchor. Three distinct compensation clusters emerged, consistent with the prior two cycles' shape.

| Tier | Low (USD) | High (USD) | Median band (USD) | Postings |
| --- | --- | --- | --- | --- |
| US Senior / Staff AI Security Engineer (platform-adjacent) | 145,000 | 300,000 | 180,000 – 240,000 | 8 (Palo Alto SWE, Snorkel, JPMorgan ×2, Samsara ×2, xAI GRC, Aimpoint) |
| US Principal / Staff+ / Sr Staff (frontier lab / platform vendor) | 174,000 | 485,000 | 290,000 – 400,000 | 8 (Anthropic ×3, DeepMind Agentic, Databricks, Ripple, ServiceNow, DoorDash) |
| US regulated-industry / mid-market | 100,000 | 288,400 | 150,000 – 200,000 | 5 (CVS, Cisco, GuidePoint, xAI GRC Sales, GitLab Research) |

Non-US disclosures: none this cycle. Mistral (Paris), DeepMind Serving Layer (London), Atlas HXM (Canada), ServiceNow (Toronto/Montreal splits), Snowflake, Zscaler, Snorkel, Salesforce, Palo Alto Senior Enterprise AI, Anthropic Offensive Research, GitLab Staff AI Product Security Architect, Bishop Fox, OpenAI (×3), Mistral Offensive, Zscaler Sr Staff did not disclose.

The tier structure is consistent with the peer packet [`ai-risk-engineer-learning`](../ai-risk-engineer-learning/) reported USD 100k–850k range across a wider level ladder.

## Postings

The full posting evidence set is in [`.aicg/job-requirements.json`](.aicg/job-requirements.json) `postings[]`. Summary index below (33 rows):

| Employer | Title | Location | Salary (USD unless noted) | URL |
| --- | --- | --- | --- | --- |
| Anthropic | Red Team Engineer, Safeguards | San Francisco, CA (Remote-Friendly) | 320,000 – 405,000 | https://job-boards.greenhouse.io/anthropic/jobs/5320469008 |
| Anthropic | Staff+ Fullstack Software Engineer, Safeguards Engineering | SF / NYC | 405,000 – 485,000 | https://job-boards.greenhouse.io/anthropic/jobs/5369710008 |
| Anthropic | Offensive Security Research Engineer, Safeguards | San Francisco, CA | 320,000 – 405,000 | https://job-boards.greenhouse.io/anthropic/jobs/5123011008 |
| OpenAI | Security Engineer, Agent Security | San Francisco, CA | undisclosed | https://openai.com/careers/security-engineer-agent-security-san-francisco/ |
| OpenAI | Offensive Security Engineer, Agent Products | San Francisco, CA | undisclosed | https://openai.com/careers/offensive-security-engineer-agent-products-san-francisco/ |
| Google DeepMind | Senior Security Engineer, Agentic Red Team | Mountain View, CA / NYC / Zurich | 174,000 – 253,000 | https://www.google.com/about/careers/applications/jobs/results/139489025168679622-senior-security-engineer-agentic-red-team-deepmind |
| Google DeepMind | Senior Security Engineer, Serving Layer and Platform Security | Mountain View, CA / London, UK | undisclosed | https://www.google.com/about/careers/applications/jobs/results/99523482064167622-senior-security-engineer-serving-layer-and-platform-security-deepmind |
| Databricks | Staff Security Software Engineer, AI Security Engineering | Remote USA | 231,400 – 397,650 | https://www.databricks.com/company/careers/security/staff-security-software-engineer-ai-security-engineering--7882009002 |
| Palo Alto Networks | Senior Enterprise AI Security Engineer | Santa Clara, CA | undisclosed | https://jobs.paloaltonetworks.com/en/search-jobs/security/47263/1 |
| Palo Alto Networks | Senior Software Engineer - AI Security | Santa Clara, CA | 145,000 – 236,000 | https://jobs.paloaltonetworks.com/en/search-jobs/security/47263/1 |
| Cisco | AI Security Engineer | Research Triangle Park, NC | 150,000 – 270,000 | https://careers.cisco.com/global/en/job/CISCISGLOBAL2024998EXTERNALENGLOBAL/AI-Security-Engineer |
| xAI | Security Engineer - Governance Risk Compliance | Not specified | 152,000 – 258,000 | https://job-boards.greenhouse.io/xai/jobs/5007261007 |
| xAI | Security Engineer, GRC Sales | Palo Alto, CA / NYC / DC | 100,000 – 228,000 | https://job-boards.greenhouse.io/xai/jobs/5205879007 |
| GitLab | Senior AI Product Security Researcher | Remote | 124,000 – 266,400 | https://job-boards.greenhouse.io/gitlab/jobs/8146219002 |
| GitLab | Staff AI Product Security Architect | Remote | undisclosed | https://job-boards.greenhouse.io/gitlab/jobs/8146217002 |
| Snorkel AI | Sr. Software Engineer — Security | NYC (Hybrid) / SF (Hybrid) | 220,000 – 300,000 | https://job-boards.greenhouse.io/snorkelai/jobs/6148995004 |
| Zscaler | Sr. Staff Software Development Engineer - AI Security (Network, Security, LLM) | San Jose, CA (Hybrid) | undisclosed | https://job-boards.greenhouse.io/zscaler |
| Mistral AI | CyberSecurity, Platform Security Engineer | Paris, France | undisclosed | https://www.indexventures.com/startup-jobs/mistral/cybersecurity-platform-security-engineer/ |
| Mastercard | Principal, AI Security Engineer | O'Fallon, MO | undisclosed | https://careers.mastercard.com/us/en/job/R-282644/Principal-AI-Security-Engineer |
| ServiceNow | Senior Staff AI Security Engineer | Chicago, IL / San Diego, CA / Toronto / Montreal (Hybrid) | 178,000 – 311,500 | https://careers.servicenow.com/jobs/744000140412599/senior-staff-ai-security-engineer/ |
| ServiceNow | Staff Security Engineer, AI Safeguards | California, USA | undisclosed | https://zapply.jobs/jobs/9fdb4159-f8d6-4bab-b3d5-f9d4b8bdd2d8/ |
| JPMorgan Chase | Senior Lead Security Engineer, AI Controls | Wilmington, DE | 152,000 – 225,000 | https://www.dreamworkhq.com/job/9d311ab1-d0f8-40cd-ae74-387f05aa94c0 |
| JPMorgan Chase | Senior Lead AI Security Engineer | Columbus, OH | 195,000 – 235,000 | https://www.dreamworkhq.com/job/d2746a49-0fc4-4368-b5cf-0c1f88cad829 |
| CVS Health | Principal Application Security Engineer – AI & Agentic Systems | Providence, RI (WAH) | 144,200 – 288,400 | https://jobs.cvshealth.com/us/en/job/R0842786/Principal-Application-Security-Engineer-AI-Agentic-Systems |
| DoorDash | Staff Security Engineer, Proactive Security - AI | Remote, United States | 193,800 – 285,000 | https://careersatdoordash.com/jobs/staff-security-engineer-proactive-security---ai/8154315/ |
| Samsara | Senior AI Security Engineer | Remote / Seattle, WA | 238,500 | https://www.samsara.com/company/careers/roles/8264748?gh_jid=8264748 |
| Samsara | Sr Offensive AI Security Engineer II | Remote US (ex. SF Bay / NYC Metro / DC Metro) | 158,000 – 239,000 | https://www.samsara.com/company/careers/roles/8247424?gh_jid=8247424 |
| Ripple | Senior Staff Security Engineer, AI Security | New York, NY | 224,000 – 300,000 | https://ripple.com/careers/all-jobs/job/7961914 |
| Salesforce | Enterprise Application Engineer (Enterprise Security - Security AI) | San Francisco, CA (+ 6 more) | undisclosed | https://zapply.jobs/jobs/0d7800f7-f962-4282-8f28-df075f35d7b5/ |
| GuidePoint Security | AI Security Engineer - North Central Region | Remote – United States | 85,904 – 159,536 | https://www.remotesource.com/jobs/4YRc8BDHyYUzirQPY6NIO-ai-security-engineer-remote-in-the-us-at-guidepoint-security |
| Bishop Fox | Senior AI/LLM Penetration Tester | Remote – United States | undisclosed | https://www.remotesource.com/jobs/to_N3Af8ZRG4l4HNGAH_J-senior-aillm-penetration-tester-at-bishop-fox |
| Aimpoint Digital | Lead AI Security Architect 2026 | Remote US / Atlanta GA | 155,000 – 189,000 | https://jobright.ai/jobs/info/6a2897a640ac8e32932a2928 |
| Atlas HXM | Senior Security Engineer, AI & DevSecOps | United States / Canada (Remote) | undisclosed | https://freehire.me/jobs/senior-security-engineer-ai-devsecops-atlas-hxm-66hof3fx |

## Authoritative references

The full list of frameworks, standards, and open-source tools that ground this packet is in [`.aicg/job-requirements.json`](.aicg/job-requirements.json) `authoritative_references[]`. No new references added this cycle — the four picked up in the 2026-09 cycle (`ref-owasp-agentic-top-10`, `ref-openssf-mlsecops`, `ref-garak`, `ref-pyrit`) remain cited and will be woven into existing module lecture text on the next content-refresh cycle. OWASP Agentic AI Top 10 continues to grow in JD citation (GuidePoint explicitly names it this cycle alongside the prior-cycle Backblaze, Databricks, Air, Rithum observations).

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

**No additions.** See [`.aicg/curriculum-plan-delta.json`](.aicg/curriculum-plan-delta.json). Every strongly-cited theme is already owned by an existing module. The red-team / offensive security role-family expansion (11/33 postings) is scope *within existing* req-06 and req-07, not a new theme. MCP-server governance pulled back from last cycle's crossing event (0.34 → 0.21–0.24) but is still folded inside req-07; the mod-107 lessons 03–04 content-refresh queued in the prior cycle carries over to the next refresh. The three other emerging themes (AI-assisted-dev-tool governance at 0.24, agentic-workflow anomaly detection at 0.18–0.21, shadow-AI detection at 0.12) remain below the 0.30 threshold.

## Next research cycle checklist

1. Re-sample ≥ 25 postings across the same five equivalent titles; watch for `MLSecOps Engineer` employer branding gaining traction (still absent for a third consecutive cycle).
2. Watch **AI-assisted-developer-tool governance** (holding at 0.24) for crossing 0.30 — GitLab Duo Agent Platform, OpenAI Codex, and Anthropic Claude Code are driving enterprise role creation.
3. Watch **shadow-AI detection and enforcement** (now at 0.12, down from 0.17) — vendor-side framing (Palo Alto, Ripple) suggests this will persist even if the frequency oscillates with sample composition.
4. Watch for **confidential computing / TEEs** to appear by name — 0/33 for a third cycle; trade press continues to push the topic without market uptake in JDs.
5. Watch for **EU AI Act Article 55 systemic-risk obligations named explicitly** — August 2026 GPAI operational start-date has passed; expect JDs at GPAI-model providers (Anthropic, OpenAI, Mistral, Meta, DeepMind, xAI) to start citing Article 55 by number as enforcement matures.
6. Confirm **req-12 (cross-functional leadership)** rebound with a second consecutive cycle above 0.30 — this cycle's 0.33 may be partially attributable to the Staff+ / Principal / Lead-heavy sample composition.
7. Reassess **req-04, req-05, and req-11** (dropped on sample skew this cycle) with a wider platform-engineering / MLSecOps slice to confirm the drops were sample-composition artefacts.
8. Watch **MCP-server governance** — now oscillating around the 0.30 bar (0.34 in 2026-10, 0.21–0.24 in 2026-11). Still folded inside req-07 regardless; the oscillation may argue for promoting mod-107 lesson 03 into a dedicated exercise rather than a new module.
9. Refresh this file — replace every posting URL with the newest active listing per employer where possible.
