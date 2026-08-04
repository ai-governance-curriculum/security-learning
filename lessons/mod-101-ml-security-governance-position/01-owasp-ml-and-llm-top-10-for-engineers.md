# Chapter 01 — OWASP ML Top 10 and OWASP LLM Top 10 v2025 for Engineers

> **Note on AI-assisted content.** These lecture chapters were drafted
> with AI assistance and are under human review. Verify every framework
> version, article number, and control claim against the primary source
> before quoting in production work. See [`resources.md`](./resources.md).

---

## Why this chapter exists

A staff-level AI/ML Security & Governance Engineer is expected to open
either OWASP list at a design review and, for any item, name the
concrete platform control that mitigates it, the concrete detection
that would fire if the control is bypassed, and the concrete evidence
artifact a peer `ai-evaluation-engineer` (level 35) or auditor should
be handed. If you cannot do this reflex-fast for all 20 items across
the two lists, the ML/LLM design review will stall on your desk.

This chapter installs that reflex. It does **not** teach the deep
mitigation for every item — subsequent modules do that. It teaches how
to read the lists *as an engineer* rather than as a checklist author.

The two lists you must be fluent in:

- **OWASP Machine Learning Security Top 10** — the OWASP project page
  and the current list are at
  [owasp.org/www-project-machine-learning-security-top-10](https://owasp.org/www-project-machine-learning-security-top-10/).
  <!-- needs-research: confirm the current release version and release date on the OWASP project page at the time this content is published. The 2023 release lists ML01…ML10; verify no newer numbered release has replaced it before quoting item numbers. -->
- **OWASP Top 10 for LLM Applications, v2025** — the GenAI project
  page and the v2025 release are at
  [genai.owasp.org/llm-top-10](https://genai.owasp.org/llm-top-10/).
  v2025 renamed several v1.x items and consolidated others; use the
  v2025 identifiers (LLM01:2025 … LLM10:2025) when writing tickets,
  policy, or detection content.

The rule for every risk in either list:

> A risk is not "covered" by naming it. A risk is covered when there
> is (a) at least one **preventive control** that stops it, (b) at
> least one **detective control** that fires when the preventive
> control is bypassed, and (c) at least one **evidence artifact** that
> a release gate can inspect to confirm both are in place.

The rest of this chapter is that structure — preventive, detective,
evidence — applied to both lists.

---

## Part A — OWASP ML Security Top 10

The ML Top 10 is the classical-ML catalogue: input manipulation, data
poisoning, model extraction, model theft, supply chain, transfer
learning, output integrity. It applies to every non-LLM ML system your
platform runs (fraud models, ranking, recommendation, medical imaging,
speech, computer vision).

### Reading the list as an engineer, not a checkbox author

The failure mode this chapter is written to prevent is **checkbox
security** — a compliance-flavoured mapping that says "ML05: Mitigated"
with no artifact to prove it. Every entry in your Top 10 coverage
matrix must have four columns filled in:

| Column | What good looks like |
| --- | --- |
| **Preventive control** | A specific engineering artifact that runs at training, admission, or serving time and blocks the class of attack. "Deploy Vault" is not a preventive control; "mint 15-minute JWTs from Vault for the training job's data-store role" is. |
| **Detective control** | A named alert with a query, a threshold, and a runbook. "Monitor for extraction" is not a detective control; "alert when a single tenant's query embeddings cover >30% of the model's decision surface in 24h, runbook `IR-ML-EXTRACT-01`" is. |
| **Evidence artifact** | A file, signature, log line, or SBOM entry that an admission policy can inspect to confirm the control ran. If no artifact exists, the release gate cannot enforce the control at scale. |
| **Owner** | The team the control routes to when it fails. If it routes to nobody, the control does not exist. |

The remainder of Part A walks each item with this framing.

### ML01 — Input Manipulation Attack (evasion / adversarial examples)

**Attacker goal.** Craft an input that flips the model's output at
inference time, either untargeted (any misclassification) or targeted
(a specific desired class).

**Preventive controls.**

- Modality-appropriate input validation (schema, range, invariant
  checks) at the API boundary.
- Adversarial training as part of the standard training pipeline (see
  mod-106) — PGD or TRADES against the model's normal training loop.
- Certified defences (randomised smoothing) where a robustness
  certificate is required by contract or by EU AI Act Article 15
  robustness obligations.

**Detective controls.**

- In-serving detectors that flag inputs whose activation-space
  distance to any training example exceeds a threshold.
- Output-distribution monitors that fire when predicted-class ratios
  diverge from the training distribution by more than a set KL
  divergence.

**Evidence artifacts.**

- The adversarial-training report attached to the model artifact
  (attack success rate at ε ∈ {2/255, 8/255, 16/255} pre- and
  post-training).
- The signed evaluation run that produced those numbers, linked to
  the model registry entry.

**Owner.** ML platform team writes the training-pipeline hook; this
role authors the required-evidence policy at admission time.

### ML02 — Data Poisoning Attack

**Attacker goal.** Corrupt training data so the resulting model has a
subtle, controllable defect — targeted backdoor with a trigger
pattern, or untargeted degradation on a segment the attacker cares
about.

**Preventive controls.**

- Signed datasets (cosign, in-toto attestations) with a required
  publisher list at admission time.
- Deduplication and near-duplicate detection on ingest to raise the
  cost of a targeted backdoor.
- Data-plane isolation between "training-eligible" and "everything
  else" so that unvetted user feedback never becomes a training
  gradient.

**Detective controls.**

- Ingest-time outlier detection on new data batches.
- Cross-run comparison of model outputs on a held-out canary set;
  a canary regression is the poisoning tripwire.
- Backdoor-triggering pattern scans on the training data (activation
  clustering, spectral signature methods) where the model's blast
  radius warrants the cost.

**Evidence artifacts.**

- Data-lineage graph linking every training record to a signed
  ingest event (see mod-104).
- Ingest-quarantine log entries showing which batches were held.

**Owner.** Data platform + MLOps own the ingest pipeline; this role
owns the required-signature policy and the canary-regression
threshold.

### ML03 — Model Inversion Attack

**Attacker goal.** Given query access to the model, reconstruct
representative training-data records (canonical example: recovering
face images from a face-recognition model).

**Preventive controls.**

- Differential privacy at training time (DP-SGD via Opacus; see
  mod-108) with a defensible (ε, δ) budget.
- Confidence-score truncation on the inference path — reveal the top
  class, not the full probability vector, for high-sensitivity
  models.
- Per-tenant query budgets that make inversion economically
  infeasible.

**Detective controls.**

- Query-pattern monitors that flag optimisation-shaped query streams
  (small perturbations exploring the decision boundary).
- Aggregate-similarity monitors on queries within a tenant.

**Evidence artifacts.**

- DP-SGD training log with the accountant's ε, δ per epoch.
- Signed model card entry declaring the privacy budget and the
  associated data-sensitivity tier.

**Owner.** ML platform team runs DP-SGD; this role sets the required
privacy tier per data-sensitivity classification and owns the
detection content.

### ML04 — Membership Inference Attack

**Attacker goal.** Determine whether a specific record was in the
model's training set — a direct GDPR/HIPAA problem for medical,
financial, and behavioural models.

**Preventive controls.**

- Differential privacy (same lever as ML03).
- Reducing the disclosed-confidence surface (top-1 only, no
  softmax vector).
- Larger training set or stronger regularisation to shrink the
  memorisation gap.

**Detective controls.**

- Membership-inference risk score computed on a red-team held-out
  set post-training, tracked over model versions.
- Alert on tenants whose query-set intersection with known
  training-set members exceeds chance.

**Evidence artifacts.**

- Membership-inference test report signed and attached to the model
  registry entry.
- Model card declaration of measured advantage.

**Owner.** This role owns the evaluation methodology and the
required-report policy; the ML team runs the numbers.

### ML05 — Model Theft (Extraction)

**Attacker goal.** Reconstruct the model — or a functionally
equivalent surrogate — through queries, then use it offline where
defences no longer apply.

**Preventive controls.**

- Per-tenant rate limits keyed on authenticated identity, tightened
  when input embeddings cluster in an unusual region.
- Watermarking (detection, not prevention — but useful as evidence
  post-facto).
- Query-cost pricing that makes extraction economically expensive
  for the model's value tier.
- Access controls on the raw model artifact — read-only registry
  with signed access logs.

**Detective controls.**

- Extraction-pattern detector on query embeddings (unusual coverage
  of decision surface by one tenant in a short window).
- Cross-tenant anomaly detection on query-response entropy.

**Evidence artifacts.**

- Watermark-recovery test result if the platform uses watermarking.
- Rate-limit configuration checked in as code; admission-time policy
  fails builds that ship a serving surface without one.

**Owner.** Platform serving team owns the rate limits; this role owns
the extraction detection content and the required-artifact policy.

### ML06 — AI Supply Chain Attacks

**Attacker goal.** Insert a vulnerability or backdoor via a
dependency: a poisoned pretrained model from a public hub, a
malicious PyPI package, a tampered base image, a rogue container in
the training stack.

**Preventive controls.**

- SLSA v1.0 provenance attestations for every model artifact (see
  mod-110 and project-101).
- Cosign / sigstore signing for model artifacts and container images
  with keyless CI signing (Fulcio + OIDC).
- ML-BOM (AI-BOM) covering datasets, base models, fine-tuning
  components, third-party dependencies.
- Internal mirror of Hugging Face / model hubs with ingress scanning
  by ModelScan for malicious pickle payloads; enforce `safetensors`
  where the model format allows.

**Detective controls.**

- Continuous re-scan of the ML-BOM against CVE feeds and
  model-hub advisories.
- Runtime monitors (Falco, eBPF) for suspicious behaviour from an
  ML container — outbound connections, unexpected filesystem
  writes, `pickle.loads` in serving pods.

**Evidence artifacts.**

- The provenance attestation, the cosign signature, the ML-BOM, and
  the ModelScan clean report — all required at admission time.

**Owner.** This role owns the required-evidence set; mod-110 covers
the implementation depth.

### ML07 — Transfer Learning Attack

**Attacker goal.** Place a backdoor into a pretrained model such that
downstream fine-tuning preserves the backdoor in the resulting
production model.

**Preventive controls.**

- Vendor / provenance verification of pretrained models — signed
  publisher, expected publisher list, cryptographic hash pinned in
  the training config.
- Fine-tuning with adversarial training on the downstream task to
  raise the cost of backdoor persistence.
- Consumption of pretrained models only from the internal mirror,
  never direct from a public hub.

**Detective controls.**

- Behavioural testing of every fine-tuned candidate against a
  suspicious-input corpus (candidate backdoor triggers) before
  registration.
- Differential testing against a second pretrained candidate — a
  systematic gap is a poisoning symptom.

**Evidence artifacts.**

- Pretrained model provenance chain up to the registered artifact.
- Behavioural-testing report attached to the fine-tuned model.

**Owner.** This role owns the required-provenance policy and the
suspicious-input corpus; the ML team runs the tests.

### ML08 — Model Skewing

**Attacker goal.** Manipulate the model's *production environment* to
skew the model over time — inject feedback that becomes future
training data, shift the input distribution, corrupt online learning.

**Preventive controls.**

- Explicit "training-eligible" label on production feedback; only
  vetted feedback flows to retraining.
- Human-in-the-loop review on systemic distribution shifts that
  cross a threshold.
- Rate limits and identity requirements on the feedback surface,
  same shape as the inference surface.

**Detective controls.**

- Drift monitors on production input distributions with alerts on
  KL divergence beyond a set threshold.
- Feedback-source diversity monitors — an unusual share of feedback
  from a small set of tenants is a skewing tripwire.

**Evidence artifacts.**

- Feedback-labelling audit log — for each retraining run, which
  records were eligible and why.
- Distribution-monitor dashboards linked from the model card.

**Owner.** Data platform owns the feedback surface; this role owns
the eligibility policy and the alert thresholds.

### ML09 — Output Integrity Attack

**Attacker goal.** Intercept and modify the model's output between
the model and its consumer. The model is fine; the channel is the
problem.

**Preventive controls.**

- mTLS between model service and every downstream consumer.
- SPIFFE / SPIRE workload identity so both sides authenticate on the
  workload, not the node (see mod-103).
- Output signing for high-stakes decisions — the consumer verifies a
  signature that only the model service could have produced.

**Detective controls.**

- Signature-verification failure alerts at the consumer.
- End-to-end integrity checks on a sampled fraction of decisions,
  replayed by an independent verifier.

**Evidence artifacts.**

- Certificate rotation logs, SPIRE issuance records.
- Signed decision receipts on high-stakes traffic.

**Owner.** Platform networking + this role — mod-103 owns the
zero-trust implementation.

### ML10 — Model Poisoning (artifact tampering)

**Attacker goal.** Modify the model artifact itself — the file in the
registry, or the weights loaded in memory — to produce
attacker-chosen behaviour. Distinct from ML02 (poison-by-data) and
ML06 (poison-by-supply-chain-component).

**Preventive controls.**

- Signed model artifacts, verified at load time.
- Read-only, WORM-style registry storage with append-only access
  audit.
- Pod-security enforcement that blocks writes to model-file paths in
  serving containers.

**Detective controls.**

- File-integrity monitoring on the registry backing store.
- Runtime detection (Falco) of process-memory writes to model
  memory regions in serving pods.

**Evidence artifacts.**

- The artifact signature; the verification log line at model load;
  the registry access audit.

**Owner.** Platform + this role. The signature scheme and the
verification hook are the deliverables.

### Structural blind spots in the ML Top 10

The ML Top 10 is the best public catalogue for *classical* ML systems.
It has gaps you must fill from other sources:

- **LLM-specific risks** are in the OWASP LLM Top 10, covered in
  Part B.
- **Output harms** — bias, toxicity, hallucination — are treated only
  thinly in the ML Top 10. Bias/fairness ownership sits with
  `ai-risk-engineer` (level 25); the security intersection is that
  fairness regressions can be *symptoms* of a poisoning or skewing
  attack (ML02 / ML08).
- **Governance obligations** — data-subject rights, right-to-erasure
  implications for trained models, human-oversight requirements —
  live in NIST AI RMF, ISO/IEC 42001, and EU AI Act. Chapter 04 is
  the crosswalk.

---

## Part B — OWASP Top 10 for LLM Applications, v2025

The LLM Top 10 is the newer catalogue for GenAI and agent
applications. v2025 is the version to author against; v1.x
identifiers appear in older documentation and older detection content
and should be treated as legacy strings, not current risk IDs.

The v2025 list is:

<!-- needs-research: confirm each v2025 title, order, and identifier against the current genai.owasp.org/llm-top-10 page at the time this content is published. The list below matches the v2025 release. Update if OWASP has re-numbered or re-titled. -->

| ID | Title (v2025) |
| --- | --- |
| LLM01:2025 | Prompt Injection |
| LLM02:2025 | Sensitive Information Disclosure |
| LLM03:2025 | Supply Chain |
| LLM04:2025 | Data and Model Poisoning |
| LLM05:2025 | Improper Output Handling |
| LLM06:2025 | Excessive Agency |
| LLM07:2025 | System Prompt Leakage |
| LLM08:2025 | Vector and Embedding Weaknesses |
| LLM09:2025 | Misinformation |
| LLM10:2025 | Unbounded Consumption |

Two structural notes on v2025 before the per-item walk:

1. **Prompt injection is item one for a reason.** In a v2025-aware
   architecture, every source of tokens the LLM can see — the user,
   retrieved documents, tool responses, other agents — is a potential
   injection surface. "The user cannot inject prompts" is not a
   defence; indirect prompt injection via retrieved content is the
   dominant real-world variant.
2. **Excessive Agency (LLM06) is where agentic apps go wrong.** The
   preventive control is not "prompt the model to be careful"; it is
   agent-tool ACLs, capability bounding, and human-in-the-loop
   enforcement (see mod-107).

### LLM01:2025 — Prompt Injection

**Attacker goal.** Insert instructions into the LLM's context that
override the system prompt or the developer's intent. Two variants
matter operationally:

- **Direct** injection — the attacker is a user of the app.
- **Indirect** injection — attacker-controlled content reaches the
  LLM via retrieval (RAG), a browser tool, an email tool, or a
  document-processing pipeline. The attacker is not authenticated to
  the app.

**Preventive controls.**

- Separate the trust levels of every context source: system prompt,
  user turn, retrieved content, tool output. Do not concatenate
  them into a single trust boundary.
- Constrain the model's response format (structured output schemas,
  tool-call schemas) so the injection cannot easily route to a
  privileged operation.
- For indirect injection: retrieval-source allow-lists, hostname
  pinning, sanitisation of retrieved HTML/DOM elements, delimiter
  hygiene.
- Downstream authorisation on tool calls — a successful prompt
  injection that asks the LLM to email the CFO's inbox still hits an
  ACL that refuses without human approval.

**Detective controls.**

- Prompt-injection scanners on retrieved content and on user input
  (Lakera, model-based classifiers, regex + heuristic ensembles).
- Behavioural anomaly detection on tool-call sequences — an unusual
  sequence of tools called in one turn is a jailbreak/injection
  tripwire.
- Logging of every tool call with the natural-language rationale
  the LLM produced, replayable in an incident.

**Evidence artifacts.**

- The system prompt version, checked in as code with a signed hash.
- The retrieval allow-list configuration.
- Injection-scan results per tenant, retained for the IR retention
  window.

**Owner.** LLM application team + this role. This role owns the
required-scanner policy and the tool-ACL enforcement pattern; the
depth is in mod-107.

### LLM02:2025 — Sensitive Information Disclosure

**Attacker goal.** Cause the LLM to reveal information that should
not have been in the context — PII from other users, training-data
memorisation, upstream system secrets, internal document contents.

**Preventive controls.**

- PII/PHI DLP on both prompt logging and retrieval indexes
  (Presidio-based, or equivalent — see mod-108).
- Per-tenant retrieval isolation — a document indexed for tenant A
  is not retrievable by tenant B, enforced at the vector-store ACL
  layer.
- Redaction of secrets and credentials from any log line the LLM
  can see back (system logs, error traces, tool outputs).

**Detective controls.**

- Output DLP — scan responses for PII/PHI/secret patterns before
  they leave the app boundary.
- Tenant-isolation regression tests as part of CI.

**Evidence artifacts.**

- The DLP configuration, checked in as code.
- The tenant-isolation test suite results, attached to the release.

**Owner.** LLM application team + this role, with mod-108 owning the
privacy-engineering depth.

### LLM03:2025 — Supply Chain

**Attacker goal.** Same as ML06, applied to the LLM stack — poisoned
base models, malicious fine-tuning adapters, tampered vector stores,
compromised plugins/tools.

**Preventive controls, detective controls, evidence artifacts.** Same
shape as ML06 in Part A, plus:

- Signed adapters (LoRA, QLoRA outputs) with published fine-tuning
  provenance.
- Vector-store schema and content signing where retrieval feeds
  a production LLM.
- Tool/plugin allow-list at the agent framework layer.

### LLM04:2025 — Data and Model Poisoning

**Attacker goal.** Same as ML02 and ML10 applied to LLM training,
fine-tuning, and RLHF data — bias a fine-tune with attacker-chosen
patterns, backdoor the model with a trigger phrase, corrupt the
preference data an RLHF pipeline consumes.

**Preventive / detective / evidence.** Same shape as ML02 and ML10,
with additional pieces:

- RLHF preference-data provenance and per-annotator provenance
  where relevant.
- Trigger-phrase scans on fine-tuning corpora.

### LLM05:2025 — Improper Output Handling

**Attacker goal.** The LLM produces output that the consuming system
executes without validation, leading to XSS, SQL injection, SSRF,
command execution, or downstream template rendering issues.

**Preventive controls.**

- Treat every LLM response as untrusted user input at the boundary
  it exits.
- Structured-output schemas (tool-call JSON, function-call schemas)
  parsed with a strict validator before use.
- Downstream sinks (SQL, shell, HTML, template engines) with the
  same parameterisation, escaping, and CSP that a normal web
  application requires.

**Detective controls.**

- Output-parser failure metrics — parser rejections are a
  jailbreak/injection tripwire.
- Downstream WAF or content-security policies at the consuming
  service.

**Evidence artifacts.**

- The output schema, checked in as code.
- The downstream sanitiser configuration.

### LLM06:2025 — Excessive Agency

**Attacker goal.** Get an agent to do more than it should — write to
resources it shouldn't touch, call tools it shouldn't have access to,
spend money outside a budget, or take actions the human user did not
intend.

**Preventive controls.**

- Agent-tool ACLs bound to the *authenticated user session*, not the
  agent's own service account.
- Human-in-the-loop confirmation for irreversible actions above a
  configurable threshold (money moved, records deleted, external
  messages sent).
- Least-privilege scoping of each tool — a "search" tool cannot
  write, a "send email" tool has a per-session outbound budget.
- Sandboxing for code-execution tools (dedicated container, no
  outbound network, ephemeral filesystem).

**Detective controls.**

- Tool-call sequence detectors — flag sequences that combine
  read-only tools followed by irreversible writes in an unusual
  pattern.
- Budget monitors on every consumable resource (tokens, API calls,
  external spend).

**Evidence artifacts.**

- The tool ACL configuration, checked in as code, versioned.
- The human-in-the-loop threshold configuration.
- The sandbox policy for code-execution tools.

**Owner.** Agent-framework team + this role. This role owns the
required-ACL policy shape; mod-107 owns the depth.

### LLM07:2025 — System Prompt Leakage

**Attacker goal.** Recover the system prompt (or fine-tuning
instructions) and use its contents to defeat downstream guardrails or
to enumerate the app's guardrails and tools.

**Preventive controls.**

- Do not put secrets in the system prompt (this is the single most
  common failure).
- Do not depend on system-prompt secrecy as a security boundary;
  assume a determined attacker will recover it.
- Where system-prompt contents must be kept from users, place the
  guarded content in retrieval or in a tool response, not in the
  prompt.

**Detective controls.**

- Similarity-match monitors on outputs that overlap heavily with the
  known system-prompt contents.

**Evidence artifacts.**

- The system prompt itself, versioned in code, with a "no secrets"
  lint that fails builds on obvious credential patterns.

### LLM08:2025 — Vector and Embedding Weaknesses

**Attacker goal.** Manipulate the RAG retrieval layer — poison the
vector store, exploit embedding collisions, exfiltrate documents via
similarity queries.

**Preventive controls.**

- Per-tenant vector-store namespaces with hard ACLs at retrieval.
- Ingest-time content review for retrieval sources (see LLM01
  indirect-injection controls; the same content that carries
  injection payloads carries LLM08 payloads).
- Embedding-index signing where the index is built offline.

**Detective controls.**

- Retrieval anomaly detection — a tenant retrieving cross-tenant
  namespaces is an ACL failure.
- Similarity-query pattern detectors for cross-document
  exfiltration.

**Evidence artifacts.**

- Vector-store ACL config, checked in as code.
- Ingest audit log.

### LLM09:2025 — Misinformation

**Attacker goal.** Cause the LLM to produce confident but incorrect
output that downstream users trust and act on, including via
prompt-injection (LLM01) and via training-data poisoning (LLM04).

**Preventive controls.**

- Grounding constraints — force citations from retrieved documents
  where factuality matters.
- Confidence-calibration filters at the app layer.
- User-visible provenance on any factual claim in the response.

**Detective controls.**

- Hallucination monitors on grounded outputs — where a cited
  document does not support the claim, flag.
- Per-domain factuality evaluation runs on the release candidate.

**Evidence artifacts.**

- Grounding-check test suite results attached to the release.

**Owner.** LLM app team plus `ai-evaluation-engineer` (level 35
peer). This role owns the security-intersection detections; the peer
owns release-time evaluation depth.

### LLM10:2025 — Unbounded Consumption

**Attacker goal.** Cost, denial-of-service, or resource exhaustion —
force the LLM to consume tokens, compute, or third-party API budget
in ways the app cannot afford.

**Preventive controls.**

- Per-tenant, per-session, per-endpoint token budgets enforced
  before generation begins.
- Maximum output tokens, maximum tool-call chains, maximum agent
  loop iterations.
- Concurrency and rate limits.

**Detective controls.**

- Token-consumption dashboards with per-tenant alerts.
- Cost-per-request outliers.

**Evidence artifacts.**

- The budget configuration, checked in as code.
- The alerting rules.

---

## Cross-reading the two lists

Every ML system in production probably falls into one of two shapes,
so the coverage discipline is:

- **Classical ML surface** (fraud, ranking, recommendation, imaging,
  speech) → OWASP ML Top 10 is the primary catalogue; NIST AI 100-2
  is the technical vocabulary (chapter 03); MITRE ATLAS is the TTP
  catalogue for detection content (chapter 02).
- **LLM / agent surface** (chat, RAG, agent, plugin) → OWASP LLM Top
  10 v2025 is the primary catalogue; the ML Top 10 items on supply
  chain and poisoning (ML02 / ML06 / ML10) still apply; ATLAS and
  NIST AI 100-2 still apply because a fine-tuned LLM is an ML model.

Where a single system spans both surfaces — an LLM ranking service
that consumes a classical embedding model — you owe **two coverage
matrices**, joined at the shared assets. Do not paper over the seam.

---

## The output artifact this chapter is training you to produce

By the end of this chapter and Exercise 01, you should be able to
hand the ML platform team, the LLM application team, and your peer
`ai-evaluation-engineer` a **coverage matrix** with the following
columns per row:

| Field | Contents |
| --- | --- |
| Risk ID | OWASP ML ID or OWASP LLM v2025 ID |
| Applies? | YES/NO with one-sentence justification |
| Preventive control | Specific artifact + owner |
| Detective control | Specific alert with query + runbook ID |
| Evidence artifact | File/signature/log line + admission-time gate |
| Owner | Team responsible |
| Coverage | Adequate / Partial / Inadequate |
| Remediation ticket | Link to the ticket that closes any gap |

A matrix with those columns is a working document — you can walk it
into a design review, a release gate, an audit interview, or an IR
tabletop and it holds up. A matrix that only says "ML05: mitigated"
does not.

---

## Summary

- OWASP ML Top 10 covers classical ML; OWASP LLM Top 10 v2025 covers
  GenAI/agent apps. Both lists apply to any system that spans both
  surfaces.
- Every risk in either list is *covered* only when it has a
  preventive control, a detective control, an evidence artifact, and
  an owner — never on a name-mapping alone.
- Prompt injection (LLM01:2025) and excessive agency (LLM06:2025) are
  the two v2025 items where most agent apps fail; both require
  architectural controls, not prompt-level heuristics.
- The coverage matrix is the deliverable this chapter trains you to
  produce; Exercise 01 walks you through building one.
