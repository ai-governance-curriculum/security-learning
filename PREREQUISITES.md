# Prerequisites — AI/ML Security & Governance Engineer track

**Role level:** 35 (hands-on engineering specialist, AI Governance family)
**Track:** `security-learning`

This track is a hands-on engineering specialty at the intersection of AI security engineering and AI governance engineering. It assumes the learner arrives with senior infrastructure engineering, ML fundamentals, general-application security literacy, and either the risk-engineering or governance-analyst legwork already fluent. Fundamentals are **not** re-taught here — the modules step directly onto threat modelling for ML, secure ML platform architecture, adversarial-ML defence at scale, LLM/agent security, and translating governance obligations into enforceable engineering controls.

## Assumed lower-level curriculum

Complete or be practically fluent in the equivalent of these lower-level tracks before starting:

- **[`ai-infra-junior-engineer-learning`](https://github.com/ai-infra-curriculum/ai-infra-junior-engineer-learning) — level 10** — engineering-craft prerequisites (Linux, Git, Python packaging, HTTP APIs, unit testing, logging, docker basics). If you cannot ship a small Python service and instrument it, start here.
- **[`ml-engineer-learning`](https://github.com/ml-engineering-curriculum/ml-engineer-learning) — level 20** — classical ML with scikit-learn, deep learning with PyTorch and Hugging Face Transformers, evaluation with standard sklearn / HF metrics, packaging with FastAPI + Docker, experiment tracking with MLflow / Weights & Biases. If you cannot ship a fine-tuned classifier and defend the eval, start here.
- **[`ai-infra-engineer-learning`](https://github.com/ai-infra-curriculum/ai-infra-engineer-learning) — level 25** and **[`ai-infra-senior-engineer-learning`](https://github.com/ai-infra-curriculum/ai-infra-senior-engineer-learning) — level 30** — Kubernetes for ML (CKA-level), model serving, cluster hardening, cloud IAM, secrets basics. This track adds *AI-security-specific* depth on top of that infrastructure baseline and does not re-teach Kubernetes or cloud IAM primitives.
- **[`ai-governance-analyst-learning`](https://github.com/ai-governance-curriculum/ai-governance-analyst-learning) — level 15** — operational analyst work in the AI Governance family: AI use-case intake and triage, model / AI-system inventory maintenance, NIST AI RMF / ISO/IEC 42001 / EU AI Act framework crosswalks, first-draft impact assessments, reading eval / audit evidence. This track consumes those artifacts and adds security-engineering depth on top.

**Strongly recommended (either one clears the bar):**

- **[`ai-risk-engineer-learning`](https://github.com/ai-governance-curriculum/ai-risk-engineer-learning) — level 25** — the harm-modelling, risk quantification, guardrail engineering, and LLM red-team engineering peer track. This role consumes ai-risk-engineer harm models and red-team datasets as input to threat modelling and detection engineering.

## Assumed working knowledge

Even without holding the equivalent role formally, you should be practically fluent in:

- **Python** — packaging (`pyproject.toml`, uv / poetry, virtualenvs), unit testing (pytest, hypothesis), typed code (mypy / pyright), and CI (GitHub Actions).
- **Kubernetes at the CKA level** — Deployments, Services, Ingress, NetworkPolicy, ConfigMaps / Secrets, RBAC, kubectl fluency. This track assumes you can debug a broken Pod without help and reason about admission-controller behaviour.
- **Cloud IAM** in at least one of AWS / GCP / Azure — roles, policies, workload identity / IRSA / Workload Identity Federation, KMS basics, short-lived credentials.
- **Application security literacy** — OWASP Top 10 for Web at working depth, TLS / mTLS mental model, secrets-handling hygiene, threat-modelling with STRIDE at working depth. This track adds ML-specific security *on top of* that baseline.
- **PyTorch + Hugging Face Transformers** — enough to fine-tune a classifier, load a Hugging Face model, and run inference; enough to instrument a model with ART / Opacus.
- **Data engineering basics** — pandas, SQL, columnar formats, dataset lineage.
- **HTTP APIs + LLM providers** — comfortable calling OpenAI / Anthropic / Google / open-source (vLLM / TGI) inference APIs from Python.
- **Reading the primary literature** — you should be able to open a paper on arXiv (e.g., Shokri MIA, Carlini LiRA, GCG jailbreak, Spectral Signatures backdoor detection) and translate the method into runnable code within a working day.

## Not assumed, taught here

You do **not** need prior experience with:

- Any specific ML/LLM security taxonomy — OWASP ML Top 10, OWASP LLM Top 10 v2025, MITRE ATLAS, NIST AI 100-2. Mod-101 covers the mapping to engineering controls.
- Any specific AI governance framework — NIST AI RMF, ISO/IEC 42001, EU AI Act Articles 9–15, SR 11-7, FDA GMLP + PCCP, HIPAA Security Rule, SOC 2 TSCs, EU CRA. Mod-101 covers the framing and mod-109 covers the engineering translation.
- Any specific zero-trust primitive — SPIFFE / SPIRE, service-mesh authorisation, OPA / Gatekeeper, CIS Kubernetes Benchmark. Mod-103 covers the working suite.
- Any specific secrets / KMS platform — HashiCorp Vault dynamic secrets, cloud KMS envelope encryption, keyless CI. Mod-105 covers the working suite.
- Any specific adversarial-ML library — Adversarial Robustness Toolbox (ART), CleverHans, TextAttack. Mod-106 covers the working suite.
- Any specific LLM/agent-security tool — Lakera prompt-injection taxonomy, UK AISI Inspect, Promptfoo red-team. Mod-107 covers the working suite.
- Any specific privacy library — Opacus for DP-SGD, Presidio for PII/PHI DLP. Mod-108 covers the working suite.
- Any specific policy-as-code engine — Open Policy Agent / Rego, Gatekeeper constraint templates. Mod-109 covers the working suite.
- Any specific supply-chain-security tool — SLSA levels, cosign / sigstore, Protect AI ModelScan, Hugging Face Hub scanning. Mod-110 covers the working suite.
- Any specific runtime-security tool — Falco, eBPF-based detection engines. Mod-111 covers the working suite.
- SIEM operations at the enterprise SOC tier — this role authors AI-specific detection content and IR playbooks; SOC-side incident handling stays with enterprise Security Operations.

## Out-of-scope on purpose

- **Novel red-team method research** — belongs to `agentic-safety-engineer` (level 40) and academic research.
- **Control-library architecture** — belongs to `senior-ai-governance-architect` (level 50). This role owns the *security section* of the library, not the framework it plugs into.
- **Board-level reporting and regulator engagement** — belongs to `head-of-ai-governance` (level 60). This role produces the metrics package that feeds up.
- **Legal opinion** — belongs to counsel. This role produces engineering evidence to support legal review.
- **SOC-side incident response** — belongs to enterprise Security Operations. This role authors the AI-specific playbooks the SOC executes.

## Recommended reading before starting

- **[NIST AI RMF 1.0 (AI 100-1)](https://nvlpubs.nist.gov/nistpubs/ai/NIST.AI.100-1.pdf)** — the framework this role reads as an engineer.
- **[NIST AI 100-2e2023 — Adversarial Machine Learning: A Taxonomy and Terminology](https://nvlpubs.nist.gov/nistpubs/ai/NIST.AI.100-2e2023.pdf)** — the working vocabulary for adversarial-ML defence.
- **[OWASP Top 10 for LLM Applications (2025)](https://genai.owasp.org/llm-top-10/)** — the working catalogue for LLM/agent-security.
- **[MITRE ATLAS](https://atlas.mitre.org/)** — the living TTP catalogue.
- **[EU AI Act (Regulation (EU) 2024/1689)](https://eur-lex.europa.eu/eli/reg/2024/1689/oj)** — at least Articles 9, 10, 14, 15, 55, 72 for high-risk-system security-engineering context.
- **[CISA Guidelines for Secure AI System Development](https://www.cisa.gov/resources-tools/resources/guidelines-secure-ai-system-development)** — the joint-international framing this role's programs align to.
- **[NIST SP 800-207 Zero Trust Architecture](https://csrc.nist.gov/pubs/sp/800/207/final)** — background for mod-103.
