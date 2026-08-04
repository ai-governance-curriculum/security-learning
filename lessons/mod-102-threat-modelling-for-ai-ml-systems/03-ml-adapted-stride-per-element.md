# Chapter 03 — ML-Adapted STRIDE: STRIDE-per-Element for ML Assets

> **Note on AI-assisted content.** Verify STRIDE methodology
> references against Shostack's *Threat Modeling: Designing for
> Security* and the current Microsoft Security Development Lifecycle
> documentation. STRIDE letters are stable; the *methodology* of
> applying them (per-element vs per-interaction) is worth pinning to
> a primary source. See [`resources.md`](./resources.md).

---

## Why this chapter exists

Chapter 01 argued that classical STRIDE undercounts ML-native
threats. Chapter 02 defined the five ML asset classes that must
appear as first-class elements on the DFD. This chapter runs the
STRIDE walk *per element*, per asset class, with ML-native attacks
in view.

The output is the STRIDE-per-element table — the second component
of the module's threat-model packet, and the input the ATLAS + NIST
mapping (chapter 04) consumes.

The rule this chapter is trying to install:

> For every asset in the inventory, for every STRIDE letter,
> produce either (a) a specific threat row naming the attack, the
> capability, and the sketched preventive / detective control, or
> (b) an explicit "not applicable" answer defended against the
> asset's admissible-operations envelope. Blank cells are
> forbidden.

---

## STRIDE-per-element vs STRIDE-per-interaction

Two variants of STRIDE exist in the Shostack literature:

- **STRIDE-per-element** — walk STRIDE against every element of
  the DFD (external entity, process, data store, data flow).
  Different letters apply to different element types (for example,
  Repudiation does not apply to a data flow).
- **STRIDE-per-interaction** — walk STRIDE against every
  interaction (an actor invoking a process, a process reading a
  store).

For ML systems, use **per-element as the primary pass and
per-interaction as a supplement**. Here is why: several ML-native
threats target the asset *in place*, not through an interaction on
the DFD.

- Model poisoning (OWASP ML10) tampers the model artifact at rest
  in the registry — not through a data flow.
- Data poisoning (OWASP ML02) tampers training data at ingest — a
  data flow, yes, but the *impact* is on the training-data element,
  and per-interaction misses the row unless you enumerate every
  ingest source.
- Training-data memorisation and inversion (OWASP ML03/ML04)
  disclose information about the training-data element via the
  decision-surface element — a *cross-element* information flow
  that per-interaction walks awkwardly.

STRIDE-per-element captures these cleanly because the walk is
anchored on the asset. Use per-interaction as a *supplement* to
catch classical interaction-boundary threats (authentication on the
serving process, log injection on the audit sink).

---

## Which STRIDE letters apply to which element types

Shostack's table (adapted):

| Element type | S | T | R | I | D | E |
| --- | --- | --- | --- | --- | --- | --- |
| **External entity** (user, upstream service) | ✓ | | ✓ | | | |
| **Process** (serving, training job) | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| **Data store** (registry, DB, blob store) | | ✓ | ✓* | ✓ | ✓ | |
| **Data flow** (queue, RPC, stream) | | ✓ | | ✓ | ✓ | |

`✓*` — Repudiation on a data store applies where audit trail
integrity is at issue.

For the five ML asset classes, treat each as follows:

| ML asset class | Best fit as DFD element | STRIDE letters that apply |
| --- | --- | --- |
| Training data | data store (versioned, immutable) | T, R, I, D |
| Model artifact | data store (signed, versioned, immutable) | T, R, I, D |
| Decision surface | process interface (the serving process's exposed function) | S, T, R, I, D, E |
| Prompt / tool graph | process interface (the serving process's constructed context and tool-invocation set) | S, T, R, I, D, E |
| Embedding index | data store (queryable) | T, R, I, D |

Elevation of privilege appears against the decision-surface and
prompt/tool-graph elements because these expose *capability*: an
attacker who compromises them acquires the model's decisioning
authority or the agent's tool-invocation authority. It does not
appear against training data or the model artifact directly,
though both are staging grounds for elevation elsewhere.

---

## Threat rows per asset — the concrete walk

For every (asset, STRIDE letter) pair below, the row form is:

```
THREAT-ID:  <asset-class>.<letter>.<slug>
Description: <what the attacker does and to what end>
Capability required: <NIST AI 100-2 vocabulary — see chapter 03 of mod-101>
Preventive sketch: <control class from mod-101 chapter 01, 03>
Detective sketch: <detection class from mod-101 chapter 02>
Evidence artifact: <what an admission gate can inspect>
```

The rest of this chapter walks each asset class. Rows are numbered
`THREAT-<CLASS>-<LETTER>-<N>` for cross-reference in chapters 04–06.

### Training-data asset — STRIDE walk

**T (Tampering).**

- **THREAT-TD-T-1 — Poisoning at ingest.** Attacker injects
  attacker-authored records into a data source that gets promoted
  across the training-eligible boundary. Downstream model has a
  targeted or untargeted defect. NIST family: *data poisoning*,
  training-time capability, grey-box knowledge typical. Preventive:
  signed dataset manifests + ingest-source allow-list + dedup on
  ingest. Detective: canary-set regression on trained model + ingest
  outlier detection. Evidence: signed manifest, ingest audit,
  canary-set delta attached to model card. Maps to OWASP ML02.
- **THREAT-TD-T-2 — Backdoor / trigger insertion.** Attacker
  supplies records containing a trigger pattern that causes
  targeted misclassification when the trigger appears at inference.
  Preventive: activation-clustering / spectral-signature scans
  where the model's blast radius warrants the cost. Detective:
  behavioural test against a suspicious-input corpus at
  registration. Evidence: signed scan report. Maps to OWASP ML02
  and OWASP ML07 (transfer-learning variant).
- **THREAT-TD-T-3 — Label-flip attack.** Attacker corrupts labels
  in a supervised labelling pipeline. Preventive: per-annotator
  reputation + inter-annotator agreement thresholds + audit trail
  from label to annotator. Detective: label-distribution drift
  monitors. Evidence: labelling audit log.

**R (Repudiation).**

- **THREAT-TD-R-1 — Ingest actor deniability.** No cryptographic
  binding of ingest events to their author; a bad ingest cannot be
  attributed. Preventive: signed ingest events, non-repudiable
  actor identity (SPIFFE workload ID for machine ingest, OIDC for
  human ingest). Evidence: signed ingest log entries.

**I (Information disclosure).**

- **THREAT-TD-I-1 — Bulk exfiltration.** Read access from the
  training-data store leaks the corpus. Preventive: per-record ACLs
  at the store, KMS-envelope encryption at rest, per-role
  read-audit. Detective: unusual volume / velocity of reads.
  Evidence: KMS access log, per-role read audit. Maps to classical
  data-breach threat models.
- **THREAT-TD-I-2 — Inversion via decision surface.** Attacker
  reconstructs representative training records by score-based
  optimisation queries to the decision surface (not the store).
  This row is *duplicated* on the decision-surface asset (see below)
  — that is fine; both assets carry the row, and mitigation lands
  on both (DP-SGD at the training-data end, score-truncation and
  query monitoring at the surface end). Maps to OWASP ML03.
- **THREAT-TD-I-3 — Membership inference via decision surface.**
  Same shape as I-2; leaks per-record training-set membership.
  Maps to OWASP ML04.

**D (Denial of service).**

- **THREAT-TD-D-1 — Corpus poisoning to force retraining stall.**
  Attacker inserts records that cause the training pipeline to fail
  or the resulting model to fail acceptance criteria, blocking
  retraining. Preventive: canary set gates retraining acceptance
  independently of ingest content. Detective: retraining acceptance
  failure with poison-shape signature.

### Model-artifact asset — STRIDE walk

**T (Tampering).**

- **THREAT-MA-T-1 — Artifact substitution.** Attacker replaces the
  file at the registry path or in transit to the serving process.
  Preventive: signed artifacts verified at load; WORM registry
  storage; pod-security preventing write to model-file paths in
  serving pods. Detective: signature verification failure alert;
  file-integrity monitoring on the registry backing store. Evidence:
  cosign signature verified at load, verification log line.
  Maps to OWASP ML10.
- **THREAT-MA-T-2 — Weight tampering via training pipeline
  compromise.** Attacker gains access to the training job and
  substitutes weights before signing. Preventive: hermetic
  training with SLSA v1.0 provenance; signing key held only by the
  attested build environment; two-person integrity on training-job
  code changes. Evidence: SLSA provenance attestation binding
  weights to the build environment.
- **THREAT-MA-T-3 — Compromise of a linked adapter / LoRA.**
  Attacker publishes a malicious LoRA that the serving process
  loads on top of a signed base model. Preventive: adapter-signing
  and adapter-provenance identical to base-model requirements.
  Maps to OWASP LLM03:2025.

**R (Repudiation).**

- **THREAT-MA-R-1 — Registry write deniability.** No non-repudiable
  audit of who registered a model version. Preventive: registry
  write requires signed request with the caller's workload
  identity; audit log signed and append-only. Evidence: registry
  audit chain.

**I (Information disclosure).**

- **THREAT-MA-I-1 — Artifact exfiltration.** Attacker reads the
  model file from the registry, or a serving-pod memory dump. Full
  offline access follows. Preventive: read ACLs on the registry;
  KMS-envelope encryption at rest; pod-security preventing
  process-memory reads across workloads. Detective: unusual read
  volume from registry; unusual memory-dump requests. Evidence:
  registry access log. Maps to OWASP ML05 (indirect — extraction
  via queries is the surface-side variant).

**D (Denial of service).**

- **THREAT-MA-D-1 — Registry unavailability.** Attacker makes the
  model file unfetchable by serving pods. Preventive: redundancy,
  regional replication, cached local copy with signature
  verification at load. Detective: fetch-failure spike alert.

### Decision-surface asset — STRIDE walk

**S (Spoofing).**

- **THREAT-DS-S-1 — Client / tenant spoofing.** Attacker
  authenticates as another tenant and queries the decision surface
  under that identity. Preventive: mutually authenticated tenant
  identity at the endpoint (SPIFFE / OIDC), no shared credentials.
  Detective: cross-tenant query anomaly. Evidence: authenticated
  request log.

**T (Tampering).**

- **THREAT-DS-T-1 — Evasion.** Attacker crafts an input that flips
  the output at inference. NIST family: *evasion*, inference-time
  capability. Preventive: adversarial training (PGD, TRADES);
  certified robustness (randomised smoothing) where robustness is
  contractual. Detective: in-serving detectors on activation-space
  distance to nearest training example; output-distribution KL
  divergence. Evidence: adversarial-training report attached to
  model registry entry. Maps to OWASP ML01.
- **THREAT-DS-T-2 — Adversarial-patch / physical-world attack.**
  Attacker applies a physical trigger (adversarial patch, sticker)
  in a vision system to force misclassification of a captured
  image. Preventive: multi-view / multi-sensor cross-check;
  adversarial training with physical-perturbation datasets.
  Detective: cross-sensor disagreement alert.

**R (Repudiation).**

- **THREAT-DS-R-1 — Decision deniability.** A consumer downstream
  denies a decision it acted on; the ML system cannot prove it
  emitted the decision. Preventive: signed decision receipts on
  high-stakes decisions (see mod-101 chapter 01 §ML09). Evidence:
  the receipt.

**I (Information disclosure).**

- **THREAT-DS-I-1 — Model extraction / stealing.** Attacker
  reconstructs a functionally equivalent model by iterated queries.
  NIST family: *model extraction*, inference-time capability,
  black-box. Preventive: per-tenant query budgets keyed on
  authenticated identity; watermarking (detective, not preventive);
  score-truncation to top-1. Detective: extraction-pattern detector
  on query embeddings (unusual coverage of decision surface by one
  tenant in a short window). Evidence: watermark-recovery test
  where used; rate-limit config in code. Maps to OWASP ML05.
- **THREAT-DS-I-2 — Model inversion.** As TD-I-2. Preventive:
  DP-SGD on training + score-truncation on inference. Detective:
  optimisation-shaped query stream detector. Maps to OWASP ML03.
- **THREAT-DS-I-3 — Membership inference.** As TD-I-3. Preventive:
  DP-SGD + reduced-confidence surface. Detective: membership-
  inference risk score computed on red-team held-out set,
  tracked per model version. Maps to OWASP ML04.
- **THREAT-DS-I-4 — Attribute inference.** Attacker infers a
  sensitive attribute of a queried record from the model's output.
  Preventive: fairness / calibration constraints (owner is
  `ai-risk-engineer` level 25 — the security intersection is that
  attribute inference can be a *symptom* of poisoning). Detective:
  fairness regression tests.
- **THREAT-DS-I-5 — Side-channel disclosure via latency / token
  count.** Attacker distinguishes classes by latency or by
  tokens-generated. Preventive: constant-time serving where the
  side channel is exploitable at scale; latency jitter; token-count
  normalisation on high-sensitivity outputs.

**D (Denial of service).**

- **THREAT-DS-D-1 — Compute-exhaustion via crafted input.**
  Attacker sends inputs that maximise compute (adversarial input
  triggers worst-case attention on a transformer; multi-hop RAG
  triggers a max-token generation). Preventive: per-tenant token
  and time budgets; maximum-output-token caps; maximum agent-loop
  iterations. Detective: cost-per-request outlier. Maps to OWASP
  LLM10:2025.
- **THREAT-DS-D-2 — Query flooding.** Classical rate-limit / DDoS
  threat on the endpoint. Preventive + detective from the
  application-security baseline.

**E (Elevation of privilege).**

- **THREAT-DS-E-1 — Escalation via decision-surface authority.**
  A tenant obtains decisions that trigger downstream actions they
  are not authorised for (a model decision opens a credit line, and
  attacker exploits the decision-authoring path to force an
  approval). Preventive: authorisation on the *action*, not on the
  decision — the model's output is advice, not authority.

### Prompt / tool-graph asset — STRIDE walk

**S (Spoofing).**

- **THREAT-PT-S-1 — User-turn spoofing via prompt injection.**
  Attacker's tokens in retrieved content or tool output cause the
  model to act as if the attacker's instruction came from a
  legitimate user turn. Preventive: separate trust levels of every
  context source (see mod-101 chapter 01 §LLM01); do not
  concatenate. Detective: prompt-injection scanner on retrieved
  content and user input. Evidence: retrieval allow-list config,
  scanner rule config. Maps to OWASP LLM01:2025.
- **THREAT-PT-S-2 — Tool identity spoofing.** Attacker causes the
  model to invoke a tool with attacker-controlled arguments as if
  they came from the legitimate user. Preventive: tool ACLs bound
  to the user session identity, not the agent's service account.
  Maps to OWASP LLM06:2025.

**T (Tampering).**

- **THREAT-PT-T-1 — Indirect prompt injection via retrieval.**
  Attacker plants tokens in a document that the retrieval layer
  later returns to the model; those tokens are treated as
  instructions. Preventive: retrieval-source allow-lists; content
  sanitisation of retrieved HTML / DOM; delimiter hygiene on prompt
  composition. Detective: prompt-injection scanner on retrieved
  content. Maps to OWASP LLM01:2025 (indirect).
- **THREAT-PT-T-2 — System-prompt override via jailbreak.**
  Attacker's user-turn tokens override the system prompt via a
  jailbreak pattern. Preventive: no security-critical secrets in
  the system prompt; downstream authorisation on tool calls
  independent of the system prompt. Detective: known-jailbreak
  pattern scanner.

**R (Repudiation).**

- **THREAT-PT-R-1 — Tool-call deniability.** A tool call happens;
  the audit trail cannot reconstruct the full prompt/tool graph
  that produced it. Preventive: log the full prompt/tool graph per
  turn with tenant + identity metadata (see mod-111 for the log
  schema). Evidence: signed session log entry.

**I (Information disclosure).**

- **THREAT-PT-I-1 — System-prompt leakage.** Attacker recovers the
  system-prompt text and enumerates guardrails or extracts secrets.
  Preventive: no secrets in the prompt; do not depend on prompt
  secrecy. Detective: similarity-match monitor on outputs. Maps to
  OWASP LLM07:2025.
- **THREAT-PT-I-2 — Sensitive-information disclosure via response.**
  Model reveals PII / secrets / internal document contents in the
  response. Preventive: PII/PHI DLP on retrieval index + on
  response; per-tenant retrieval isolation; redaction of secrets
  before they can enter the context. Detective: output DLP; tenant-
  isolation regression tests. Maps to OWASP LLM02:2025.
- **THREAT-PT-I-3 — Improper output handling leading to XSS / SSRF
  / SQLi at the consumer.** Preventive: structured-output schemas
  parsed with a strict validator; downstream sinks with the same
  parameterisation the web app requires. Maps to OWASP LLM05:2025.

**D (Denial of service).**

- **THREAT-PT-D-1 — Unbounded consumption.** Same as DS-D-1 at the
  agent-loop level: prompt-injection causes the agent to loop or
  spend uncontrolled tokens. Preventive: agent-loop iteration cap;
  per-session token budget. Maps to OWASP LLM10:2025.

**E (Elevation of privilege).**

- **THREAT-PT-E-1 — Excessive agency via tool ACL bypass.**
  Attacker's injection causes the agent to invoke a tool outside
  its intended envelope (send an email to the CFO's account,
  transfer money outside the user's authorised set). Preventive:
  per-tool ACL bound to user session; human-in-the-loop
  confirmation on irreversible actions; least-privilege scoping.
  Detective: tool-call sequence detector. Maps to OWASP LLM06:2025.
- **THREAT-PT-E-2 — Sandbox escape from a code-execution tool.**
  Attacker's tool-call produces code that escapes the tool's
  sandbox. Preventive: dedicated container, no outbound network,
  ephemeral filesystem, seccomp. Maps to OWASP LLM06:2025.

### Embedding-index asset — STRIDE walk

**T (Tampering).**

- **THREAT-EI-T-1 — Vector-store poisoning.** Attacker ingests
  documents whose embeddings will be retrieved into future prompts;
  the documents carry an injection payload or biased content.
  Preventive: ingest-source allow-list; content review at ingest;
  index rebuild only from signed sources. Detective: unexpected
  ingest volume from a source; content-classifier flag on ingest.
  Maps to OWASP LLM08:2025.
- **THREAT-EI-T-2 — Embedding-collision poisoning.** Attacker
  crafts documents whose embeddings are near a target query's
  embedding so the poisoned document is retrieved. Preventive:
  hybrid retrieval (dense + sparse) so a single-embedding target is
  insufficient; source diversity requirement in retrieval.

**R (Repudiation).**

- **THREAT-EI-R-1 — Ingest actor deniability.** Same as TD-R-1
  applied to the index.

**I (Information disclosure).**

- **THREAT-EI-I-1 — Cross-tenant retrieval leak.** Tenant A's
  query retrieves tenant B's document. Preventive: per-tenant
  namespaces with hard ACLs at retrieval; tenant-isolation
  regression tests. Detective: retrieval anomaly detection
  (cross-namespace hits). Evidence: retrieval ACL config in code.
  Maps to OWASP LLM02:2025 + LLM08:2025.
- **THREAT-EI-I-2 — Similarity-query exfiltration.** Attacker
  reconstructs indexed document content by iterated similarity
  queries. Preventive: per-tenant retrieval budgets; return
  document IDs, not raw content, where the tenant is not authorised
  to see the content directly. Maps to OWASP LLM08:2025.

**D (Denial of service).**

- **THREAT-EI-D-1 — Index bloat via ingest.** Attacker floods the
  ingest path with documents to inflate the index and degrade
  retrieval performance. Preventive: per-source ingest quotas;
  ingest rate limits.

---

## Handling ML-native threats that STRIDE undercovers

STRIDE misses two shapes cleanly:

1. **Abuse-violation threats** (NIST AI 100-2 GenAI extension) —
   the LLM produces prohibited content, or the agent takes
   prohibited actions. Some abuse threats fit awkwardly under E
   (excessive agency in tool actions); others fit under I
   (disclosure of prohibited content) or T (tampered output
   distribution). Where the fit is awkward, add an explicit
   **A (abuse)** column to the STRIDE table for the LLM assets and
   note the fit-back to STRIDE letters in the row body. Do not
   pretend STRIDE covers abuse cleanly — it does not.
2. **Fairness / bias regressions as poisoning symptoms.** Fairness
   is not a STRIDE row; the security intersection is that a
   fairness regression can be a *symptom* of poisoning or skewing.
   Cross-reference the row (e.g., THREAT-DS-I-4) to the peer
   `ai-risk-engineer` (level 25) who owns fairness in the ladder;
   the security-owned row is the detection linking a fairness
   regression to a poisoning root-cause hypothesis.

The rest of the module treats "STRIDE + A" as the operating table
for LLM/agent systems. For classical-ML systems, STRIDE alone is
usually sufficient.

---

## Producing the STRIDE-per-element table

The output of this chapter and exercise 02 is one table:

| Threat ID | Asset ID (from Ex. 01) | Asset class | STRIDE letter | Attack (concise) | NIST AI 100-2 vocabulary | Preventive sketch | Detective sketch | Evidence sketch | Owner |

Populated for the target system, this table is the input to chapter
04 (ATLAS + NIST mapping produces the IR-consumable inventory) and
chapter 06 (mitigation prioritisation scorecard).

Two discipline notes:

- **No blank cells.** Every (asset, letter) pair either produces a
  row or explicitly declares "not applicable" against the asset's
  admissible-operations envelope from chapter 02.
- **Duplicate rows across assets are expected.** Inversion appears
  on both training-data and decision-surface rows — the mitigation
  lands on both. Do not delete duplicates; the ATLAS mapping needs
  them.

---

## The mistakes this chapter is trying to prevent

- **Doing STRIDE only per-interaction on ML.** Half the ML-native
  threats target assets in place. Use per-element as the primary.
- **Skipping the "not applicable" defence.** A blank cell is a
  missed row until proved otherwise. Force the defence.
- **Treating the model artifact and the decision surface as the
  same asset.** They share threats (extraction hits both), but the
  mitigations are different (artifact ACLs vs query monitors) and
  the STRIDE walk must cover both.
- **Compressing abuse violations into E.** For LLM apps, abuse
  deserves its own column. STRIDE's letters were not written for
  it.
- **Skipping duplicate rows.** Inversion needs to appear against
  training-data *and* decision-surface. The two rows drive two
  different mitigations.

---

## Summary

- Use STRIDE-per-element as the primary walk for ML systems.
  Per-interaction is a supplement, not a substitute.
- Every asset from chapter 02's inventory gets its own STRIDE walk.
  Blank cells are forbidden; each cell is a threat row or a
  defended not-applicable.
- Elevation of privilege sits on decision-surface and prompt/tool-
  graph assets because they expose capability; T + I + D sit on the
  data-store-shaped assets.
- Add an A (abuse) column for LLM assets; STRIDE letters alone
  undercount NIST AI 100-2 abuse-violation threats.
- The output is the STRIDE-per-element table, input to the ATLAS +
  NIST mapping in chapter 04.
