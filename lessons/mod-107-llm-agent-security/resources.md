# Resources — mod-107-llm-agent-security

Primary sources for every claim in chapters 01–05 and the five
exercises. Prefer the official standard, the author's preprint on
arXiv, and the project's own documentation over secondary summaries.
LLM-security tooling, benchmarks, and regulator guidance move
quickly; verify versions, article numbers, and API surfaces at time
of reading.

---

## Standards and taxonomies

- **OWASP Top 10 for LLM Applications (2025).** The canonical
  category list chapters 01, 05 and exercises 01, 05 are written
  against. The project ships the list, per-category write-ups, and
  cheat sheets.
  <https://genai.owasp.org/llm-top-10/>
- **OWASP LLM Top 10 — 2025 PDF.**
  <https://genai.owasp.org/resource/owasp-top-10-for-llm-applications-2025/>
- **NIST AI 100-2 — Adversarial Machine Learning: A Taxonomy and
  Terminology of Attacks and Mitigations.** The generative-AI
  section is the cross-reference for chapter 01. Verify revision at
  time of reading.
  <https://csrc.nist.gov/pubs/ai/100/2/final>
- **NIST AI 600-1 — Artificial Intelligence Risk Management
  Framework: Generative AI Profile.** The profile that enumerates
  GenAI-specific risks and controls that chapters 01 and 05 map to.
  <https://nvlpubs.nist.gov/nistpubs/ai/NIST.AI.600-1.pdf>
- **NIST AI RMF 1.0 — AI Risk Management Framework.** GOVERN /
  MAP / MEASURE / MANAGE; the measurement surface chapters 04 and
  05 feed into.
  <https://www.nist.gov/itl/ai-risk-management-framework>
- **MITRE ATLAS.** Adversarial-ML threat matrix with LLM-specific
  tactics and techniques (prompt injection, jailbreak, LLM data
  leakage); cross-reference for the chapter-01 mitigation map and
  the chapter-04 engagement plan.
  <https://atlas.mitre.org/>
- **ISO/IEC 42001:2023 — AI management system.** The governance
  substrate chapter 05 incidents feed records into.
  <https://www.iso.org/standard/81230.html>
- **ISO/IEC 23894:2023 — AI risk management guidance.**
  <https://www.iso.org/standard/77304.html>
- **EU AI Act — Regulation (EU) 2024/1689.** Chapter 05's
  serious-incident reporting obligations for high-risk AI
  providers; the article number in chapter 05 is a pointer, verify
  against the OJEU consolidated text and any adopted implementing
  acts at time of use.
  <https://eur-lex.europa.eu/eli/reg/2024/1689/oj>

---

## Chapter 01 — the OWASP LLM Top 10 landscape

- **OWASP LLM Top 10 (2025) overview and per-category pages.**
  Primary source for every category definition, canonical
  examples, and the OWASP-authored default mitigations.
  <https://genai.owasp.org/llm-top-10/>
- **OWASP GenAI Security Project — Prompt Injection Prevention
  cheat sheet.**
  <https://genai.owasp.org/llmrisk/llm01-prompt-injection/>
- **MITRE ATLAS — LLM tactics and techniques.** Cross-reference
  for ATLAS IDs cited in the chapter-01 mitigation map.
  <https://atlas.mitre.org/techniques>
- **NIST AI 100-2 — Section on generative-AI attack taxonomy.**
  Cross-reference for prompt-injection taxonomy, poisoning, and
  evasion as they apply to GenAI.
  <https://csrc.nist.gov/pubs/ai/100/2/final>
- **Microsoft — Failure Modes in Machine Learning.** A durable
  taxonomy that overlaps with OWASP/NIST at the engineering layer.
  <https://learn.microsoft.com/security/engineering/failure-modes-in-machine-learning>

---

## Chapter 02 — indirect prompt injection

### Foundational papers

- **Greshake et al. 2023 — *Not what you've signed up for:
  Compromising Real-World LLM-Integrated Applications with Indirect
  Prompt Injection*.** The paper that named indirect prompt
  injection and demonstrated it against production LLM apps.
  <https://arxiv.org/abs/2302.12173>
- **Perez & Ribeiro 2022 — *Ignore Previous Prompt: Attack
  Techniques for Language Models*.** Early formalisation of
  prompt-injection attacks and goals.
  <https://arxiv.org/abs/2211.09527>
- **Zou, Wang, Kolter, Fredrikson 2023 — *Universal and
  Transferable Adversarial Attacks on Aligned Language Models*
  (GCG).** The gradient-based jailbreak paper; relevant to
  chapter 02 defence design because transfer-attack payloads land
  in the input corpus.
  <https://arxiv.org/abs/2307.15043>
- **Wei, Haghtalab, Steinhardt 2023 — *Jailbroken: How Does LLM
  Safety Training Fail?***.
  <https://arxiv.org/abs/2307.02483>
- **Carlini et al. 2024 — *Are aligned neural networks adversarially
  aligned?***. Robustness of alignment under adversarial inputs;
  informs the chapter-02 "the model cannot separate instructions
  from data at the token level" claim.
  <https://arxiv.org/abs/2306.15447>

### Trust-boundary / provenance design

- **Willard & Louf (various) — Simon Willison, *prompt injection*
  write-ups.** The longest-running practitioner commentary on
  prompt-injection surfaces, failure modes, and the dual-LLM /
  trust-boundary pattern.
  <https://simonwillison.net/tags/prompt-injection/>
- **Simon Willison — *The Dual LLM pattern for building AI
  assistants that can resist prompt injection*.**
  <https://simonwillison.net/2023/Apr/25/dual-llm-pattern/>
- **Anthropic — Build with Claude: tool use documentation.** The
  framework-level primitives (tool choice, tool restrictions,
  stop sequences) chapter 02's architectural pattern composes
  with.
  <https://docs.anthropic.com/en/docs/build-with-claude/tool-use>
- **OpenAI — Safety best practices and prompt-injection
  guidance.**
  <https://platform.openai.com/docs/guides/safety-best-practices>

### Input- and output-side detectors / classifiers

- **Microsoft — Azure AI Content Safety: Prompt Shields.** Managed
  input-classification service with jailbreak and indirect-prompt-
  injection detectors; useful as the "one of the layers in the
  defence-in-depth stack" chapter 02 argues for.
  <https://learn.microsoft.com/azure/ai-services/content-safety/concepts/jailbreak-detection>
- **Google — Model Armor.** Managed input/output screening and
  prompt-injection detection.
  <https://cloud.google.com/security/products/model-armor>
- **Lakera Guard.** Commercial input/output classifier for LLM
  apps; useful as an off-the-shelf reference for the chapter-02
  input-detector pattern.
  <https://www.lakera.ai/>
- **NVIDIA NeMo Guardrails.** Open-source rails for LLM apps
  (programmable guardrails, input/output rails, dialog policy).
  <https://github.com/NVIDIA/NeMo-Guardrails>
- **Meta — Llama Guard / Prompt Guard.** Open-weights
  classification models for prompt-injection and policy
  enforcement.
  <https://github.com/meta-llama/PurpleLlama>

### Public corpora and benchmarks for injection / jailbreak

- **HarmBench.** Standardised evaluation of attack and defence
  methods for LLMs.
  <https://www.harmbench.org/>
  Paper: <https://arxiv.org/abs/2402.04249>
- **JailbreakBench.** An open benchmark for jailbreak attacks and
  defences with reproducible leaderboards.
  <https://jailbreakbench.github.io/>
  Paper: <https://arxiv.org/abs/2404.01318>
- **AdvBench (companion to GCG).**
  <https://github.com/llm-attacks/llm-attacks>

---

## Chapter 03 — agent tool ACLs and HITL

### Agent / tool-use primitives

- **Model Context Protocol (MCP).** The open protocol for
  exposing tools and resources to LLM applications; chapter 03's
  tool-registry schema integrates with MCP tool descriptors.
  <https://modelcontextprotocol.io/>
  Spec and reference servers: <https://github.com/modelcontextprotocol>
- **Anthropic — tool use documentation.**
  <https://docs.anthropic.com/en/docs/build-with-claude/tool-use>
- **OpenAI — Function calling / Assistants / tools.**
  <https://platform.openai.com/docs/guides/function-calling>
  <https://platform.openai.com/docs/assistants/overview>
- **LangGraph.** Graph-based agent/orchestration library; a common
  substrate chapter 03's registry sits on top of.
  <https://github.com/langchain-ai/langgraph>

### Identity, workload identity, and dynamic credentials

- **SPIFFE / SPIRE.** Workload identity primitive the
  `caller_only` / `workload` / `delegated` identity scopes in
  chapter 03 compose with. Cross-reference to mod-103.
  <https://spiffe.io/>
- **OAuth 2.0 Token Exchange (RFC 8693).** The delegation /
  on-behalf-of pattern chapter 03 cites for identity-preserving
  tool calls.
  <https://datatracker.ietf.org/doc/html/rfc8693>
- **HashiCorp Vault — short-lived dynamic credentials.** The
  dynamic-credential pattern chapter 03 and mod-105 share.
  <https://developer.hashicorp.com/vault/docs/secrets>

### HITL and safe-interruption patterns

- **Human-in-the-Loop for LLM-based agents — practitioner
  write-ups.** General surveys of HITL patterns; useful as
  background. Verify authors and venues at time of reading.
  <!-- needs-research: pick a canonical reference HITL survey for
       agent systems; the LangChain / Anthropic / Microsoft Agent
       Framework docs each cover the pattern slightly differently. -->
- **Microsoft Semantic Kernel — AI agents and HITL guidance.**
  <https://learn.microsoft.com/semantic-kernel/overview/>
- **OWASP LLM06 — Excessive Agency.** Primary source for the
  chapter-03 category framing.
  <https://genai.owasp.org/llmrisk/llm06-excessive-agency/>

### Related research

- **Ruan et al. 2024 — *Identifying the Risks of LM Agents with an
  LM-Emulated Sandbox* (ToolEmu).** Illustrative sandbox for
  evaluating agent-tool behaviour; cross-reference for chapter 03
  "worst-case single-call" tiering.
  <https://arxiv.org/abs/2309.15817>

---

## Chapter 04 — agent red-teaming with Inspect

### UK AISI Inspect

- **UK AI Safety Institute — Inspect AI framework (`inspect_ai`).**
  The reference open-source evaluation framework chapter 04 is
  written against. Verify API surface at time of use; the solver,
  scorer, and dataset APIs move between releases.
  <https://github.com/UKGovernmentBEIS/inspect_ai>
- **Inspect AI documentation.**
  <https://inspect.aisi.org.uk/>
- **UK AI Safety Institute — publications.**
  <https://www.aisi.gov.uk/work>
- **AISI Inspect Evals (reference task collection).**
  <https://github.com/UKGovernmentBEIS/inspect_evals>

### Equivalent harnesses

- **Garak (NVIDIA).** LLM vulnerability scanner with a probe
  catalogue (prompt injection, jailbreak, PII leakage, encoding
  attacks).
  <https://github.com/NVIDIA/garak>
- **PyRIT (Microsoft).** Python risk-identification toolkit for
  generative AI with multi-turn attacker-agent support.
  <https://github.com/Azure/PyRIT>
- **Promptfoo.** Evaluation and red-teaming harness with CI
  integrations and a plugin surface.
  <https://www.promptfoo.dev/>
  <https://github.com/promptfoo/promptfoo>
- **Giskard.** Open-source test harness with LLM red-teaming
  features.
  <https://github.com/Giskard-AI/giskard>
- **DeepEval.** Evaluation framework with red-teaming features.
  <https://github.com/confident-ai/deepeval>

### Public jailbreak / injection evaluation suites

- **HarmBench.** <https://www.harmbench.org/>
- **JailbreakBench.** <https://jailbreakbench.github.io/>
- **Meta Purple Llama / CyberSecEval.** Benchmarks for LLM
  cybersecurity risks.
  <https://github.com/meta-llama/PurpleLlama>
  <https://github.com/meta-llama/PurpleLlama/tree/main/CybersecurityBenchmarks>
- **AgentHarm.** Benchmark for measuring harmful tasks for LLM
  agents.
  <https://arxiv.org/abs/2410.09024>
- **Gandalf (Lakera).** Public prompt-injection CTF; useful as
  payload inspiration, not as a benchmark.
  <https://gandalf.lakera.ai/>

### Related research on evaluation

- **AISI — early public evaluations of frontier models.**
  <https://www.aisi.gov.uk/work/advanced-ai-evaluations-may-update>
- **Anthropic — Responsible Scaling Policy.** Context for the
  "evaluation anchors release decisions" framing chapter 04
  pushes.
  <https://www.anthropic.com/responsible-scaling-policy>
- **OpenAI — Preparedness Framework.** Equivalent framing from
  OpenAI.
  <https://openai.com/safety/preparedness/>

---

## Chapter 05 — LLM/agent incident severity ladder

### Incident response — foundational references

- **NIST SP 800-61 Rev. 2 — Computer Security Incident Handling
  Guide.** The classical incident-response reference chapter 05's
  ladder specialises for LLM/agent incidents.
  <https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-61r2.pdf>
- **NIST SP 800-61 Rev. 3 (if published at time of reading).**
  Verify revision level.
  <https://csrc.nist.gov/pubs/sp/800/61/r3/final>
- **SANS Incident Response — community playbooks.**
  <https://www.sans.org/white-papers/incident-handlers-handbook/>

### Regulator / disclosure obligations

- **GDPR Article 33 — Notification of a personal data breach to
  the supervisory authority (72-hour clock).**
  <https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX:32016R0679>
  Direct article pointer: <https://gdpr-info.eu/art-33-gdpr/>
- **GDPR Article 34 — Communication of a personal data breach to
  the data subject.**
  <https://gdpr-info.eu/art-34-gdpr/>
- **EDPB — Guidelines 9/2022 on personal data breach
  notification under GDPR.** The regulator's own interpretation
  of Article 33 scope and timing.
  <https://www.edpb.europa.eu/our-work-tools/our-documents/guidelines/guidelines-92022-personal-data-breach-notification_en>
- **HIPAA Breach Notification Rule — 45 CFR §§ 164.400–.414.**
  <https://www.ecfr.gov/current/title-45/subtitle-A/subchapter-C/part-164/subpart-D>
- **HHS — HIPAA breach notification guidance (overview).**
  <https://www.hhs.gov/hipaa/for-professionals/breach-notification/>
- **PCI DSS v4.x — Requirement 12.10 (incident response).**
  Primary source: PCI SSC documents library.
  <https://www.pcisecuritystandards.org/document_library/>
- **US state breach-notification laws — NCSL index.** State-by-
  state reference for the US patchwork.
  <https://www.ncsl.org/technology-and-communication/security-breach-notification-laws>
- **EU AI Act Article on serious-incident reporting
  (Regulation (EU) 2024/1689).** Verify the specific article
  number and the definition of "serious incident" against the
  OJEU consolidated text and any adopted implementing acts; the
  chapter-05 pointer is approximate.
  <https://eur-lex.europa.eu/eli/reg/2024/1689/oj>
- **UK ICO — Personal data breach guidance.**
  <https://ico.org.uk/for-organisations/report-a-breach/personal-data-breach/>

### Agent-specific incidents (public write-ups)

- **MITRE ATLAS — Case studies.** The ATLAS case-study registry
  is the best public catalogue of real-world ML/LLM attacks;
  useful as both corpus input and incident-shape reference.
  <https://atlas.mitre.org/studies>
- **AI Incident Database.** Community-maintained incident
  registry; chapter 05 recommends scanning it for LLM/agent
  shapes.
  <https://incidentdatabase.ai/>

---

## Agent / tool-use frameworks (cross-chapter)

- **Model Context Protocol (MCP).**
  <https://modelcontextprotocol.io/>
  <https://github.com/modelcontextprotocol>
- **LangChain / LangGraph.**
  <https://github.com/langchain-ai/langchain>
  <https://github.com/langchain-ai/langgraph>
- **Microsoft Semantic Kernel / Agent Framework.**
  <https://learn.microsoft.com/semantic-kernel/overview/>
- **LlamaIndex — Agents.**
  <https://docs.llamaindex.ai/en/stable/module_guides/deploying/agents/>
- **Hugging Face — Transformers Agents / smolagents.**
  <https://github.com/huggingface/smolagents>

---

## Observability / trajectory capture

- **OpenTelemetry — Semantic conventions for GenAI.** The emerging
  cross-vendor telemetry standard for LLM/agent trajectories;
  cross-reference for chapter-05's trajectory-record schema.
  <https://opentelemetry.io/docs/specs/semconv/gen-ai/>
- **Langfuse.** Open-source LLM observability (trace capture,
  evaluation, dataset management).
  <https://github.com/langfuse/langfuse>
- **Arize Phoenix.** Open-source LLM observability and
  evaluation.
  <https://github.com/Arize-ai/phoenix>
- **Humanloop / LangSmith / Helicone — commercial observability
  references.** Named as examples of the "every tool call
  recorded, every trajectory replayable" primitive chapter 05
  depends on.
  <https://smith.langchain.com/>
  <https://helicone.ai/>

---

## Cross-module references

- **mod-102 — Threat Modelling for AI/ML Systems.** The threat-
  model artefact the chapter-01 mitigation map plugs into.
- **mod-103 — Secure ML Platform Architecture.** Workload
  identity (SPIFFE/OIDC), tenancy, and admission-gate primitives
  chapters 03 and 05 depend on.
- **mod-104 — Data and Model Lineage Security.** Signed lineage
  for retrieval-store content (chapter 02), fine-tuning data
  (chapter 01 LLM04), and the evidence surface for incidents
  (chapter 05).
- **mod-105 — Secrets and Key Management.** Per-caller dynamic
  credentials for the tool layer (chapter 03) and identity
  revocation in SEV-1/2 runbooks (chapter 05).
- **mod-106 — Adversarial ML Defense.** Classical adversarial-ML
  taxonomy inherited by chapter 01; the serving-layer detection
  pipeline chapter 01 LLM04 defers to.
- **mod-108 — Privacy Engineering for ML.** DSAR / erasure
  surfaces that an LLM02 or SEV-1 privacy incident activates.
- **mod-109 — AI Governance and Compliance Engineering.** The
  governance-evidence surface every chapter's artefacts feed
  into; chapter 05 incident records are a primary input.
- **mod-110 — Supply Chain Security for AI.** Signed base
  models, adapters, embedding models, and tokenizers behind
  LLM03 (chapter 01).
- **mod-111 — Security Operations and Incident Response for
  ML.** The platform the chapter-05 ladder fills with content.
