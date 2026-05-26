# Module 01 — Foundations of ML Security

> **Note on AI-assisted content.** These lecture notes were drafted
> with AI assistance and are under ongoing human review. Where a
> specific claim cites a standard, framework, or paper, verify
> against the primary source before quoting in production work.
> See [`resources.md`](./resources.md) for the source list.

---

## 1. Why ML security is different

A web application security engineer protects an API surface, an
identity boundary, a database, and a deployment pipeline. An ML
security engineer protects all of those **plus three additional
asset classes** that don't exist in a non-ML system:

1. **The model itself** — a trained set of parameters that often
   represents months of work, proprietary data, and substantial
   inference-time risk.
2. **The training data** — historical records that may contain PII,
   PHI, trade secrets, and that *cannot* be deleted from the model
   simply by deleting the file.
3. **The decision surface** — the function the model implements,
   which can be queried, reconstructed, biased, or made to produce
   harmful outputs.

A team that protects only the conventional surface and treats the
ML system as "just another service" is shipping a system whose
threat model is incomplete in ways that matter.

### 1.1 The three classes of ML-specific threats

Every ML security framework (OWASP ML, MITRE ATLAS, NIST AI RMF)
ultimately reduces to a taxonomy in three classes:

| Class | What the attacker is doing | Where in the lifecycle |
|---|---|---|
| **Evasion** | Crafting inputs that change the model's output at inference time | Inference |
| **Extraction** | Stealing the model, training data, or membership information through queries | Inference |
| **Poisoning** | Corrupting training data or the training process to install backdoors or degrade quality | Training |

These three are the *whole point* of ML-specific security. If your
team's threat model doesn't address all three, you are protecting
against a fraction of the surface.

### 1.2 What conventional security gets right (and where it stops)

The standard infrastructure security stack — IAM, network policy,
secrets management, image scanning, SIEM — covers a critical part
of an ML system's surface. **It is necessary and insufficient.**

| Control | Catches | Misses |
|---|---|---|
| API authn / authz | Unauthorized access, account takeover | Adversarial inputs from authorized users, model extraction by paying customers |
| Network policy | Lateral movement | A poisoned model serving incorrect predictions |
| Secrets management | Credential theft | Training-data exposure via model inversion |
| Image scanning | Vulnerable dependencies | Model artifacts with backdoors |
| SIEM with generic rules | Generic attacker tactics | ML-specific patterns (query-based extraction, slow poisoning) |

The pattern: conventional controls catch attackers who behave like
attackers. ML-specific threats are dangerous precisely because the
attacker can look indistinguishable from a normal user **at the
control layer** — they just happen to be sending different inputs.

### 1.3 The "model is the asset" mental shift

In a non-ML system, *data* is the highest-value asset, and the
service is a means to query it. In an ML system, the *model* often
becomes a primary asset in its own right, distinct from any single
training data record:

- A trained LLM is worth millions to tens of millions in compute
  alone, before counting the training-data licensing value.
- A high-quality recommendation model embodies years of behavioral
  data even after the underlying data is anonymized or deleted.
- A medical-imaging model trained on de-identified records can in
  principle be queried to leak identifying information about the
  records used for training (membership inference).

The model is **not** "just a file in a registry." It is a derived
data asset with its own threat surface, its own access controls, and
its own incident playbook.

---

## 2. The OWASP ML Security Top 10

OWASP maintains a Top 10 list specifically for ML systems
(separate from the application-security and API-security Top 10s).
The latest published version at time of writing is the **OWASP ML
Security Top 10 (2023)**. Verify the current version at
[owasp.org/www-project-machine-learning-security-top-10](https://owasp.org/www-project-machine-learning-security-top-10/)
before quoting specific item numbers — the list updates.

The Top 10 (2023) is:

| ID | Title | Class |
|---|---|---|
| ML01 | Input Manipulation Attack | Evasion |
| ML02 | Data Poisoning Attack | Poisoning |
| ML03 | Model Inversion Attack | Extraction |
| ML04 | Membership Inference Attack | Extraction |
| ML05 | Model Theft | Extraction |
| ML06 | AI Supply Chain Attacks | Lifecycle |
| ML07 | Transfer Learning Attack | Lifecycle |
| ML08 | Model Skewing | Poisoning |
| ML09 | Output Integrity Attack | Evasion / post-inference |
| ML10 | Model Poisoning | Poisoning |

### 2.1 Reading the Top 10 productively

The Top 10 is *not* a checklist; treating it as one leads to
checkbox security. The productive way to use it:

1. **Inventory your ML assets.** For each model in production: where
   did it come from, what did it train on, who can query it, who
   sees its outputs?
2. **Walk each Top-10 item against the inventory.** "Is ML01
   applicable to this model? Yes. What controls do we have? None
   adequate. What is the mitigation?"
3. **Produce a per-model coverage matrix.** Not "we addressed
   ML05" — "for *this* model, our controls against ML05 are X, Y,
   Z, and the gaps are A, B."

The coverage matrix is the artifact that survives. A spreadsheet
that says "ML05: Mitigated" with no detail is not a security
artifact; it's a comfort blanket.

### 2.2 Item-by-item: what each Top-10 entry actually means

#### ML01 — Input Manipulation Attack

An attacker crafts inputs that cause the model to produce an output
the system designer didn't intend. The classical examples are
adversarial examples in image classification (perturbations
imperceptible to humans that flip the model's prediction) and
prompt injection in LLMs (instructions embedded in input that
override the system prompt).

Why it matters: a model that can be tricked into producing the
wrong output reliably is **worse than no model**, because users
have placed trust in it.

Where to defend:
- Input validation appropriate to the modality.
- Adversarial training (covered in Module 06).
- Output monitoring for distributions that diverge from training.

#### ML02 — Data Poisoning Attack

An attacker corrupts the training data so that the resulting model
has a subtle, controllable defect. The defect can be:

- **Targeted backdoor**: the model behaves correctly on normal inputs
  but produces an attacker-chosen output when a trigger pattern is
  present.
- **Untargeted degradation**: model quality drops on the segment of
  inputs the attacker cares about.

Where to defend:
- Data provenance and signed datasets.
- Outlier detection on training data.
- Differential privacy at training time (which bounds the influence
  of any single training example).

#### ML03 — Model Inversion Attack

An attacker, given query access to a model, reconstructs the
training data — or representative examples of it. For a face
recognition model trained on identifiable photos, this means an
attacker can recover faces.

Where to defend:
- Differential privacy at training time.
- Output rounding / noise (the smaller the gradient, the less
  information leaks).
- Strict rate limits on query access.

#### ML04 — Membership Inference Attack

An attacker, given a candidate record and query access, determines
whether that record was in the training set. For a model trained
on medical records, this means an attacker can learn that a
specific person was a patient.

Where to defend:
- Differential privacy.
- Limit confidence-score disclosure.
- Restrict access to per-record predictions.

#### ML05 — Model Theft

An attacker reconstructs the *model itself* through queries, or
gains direct access to the model file. Reconstructed models can
then be used to enable other attacks (ML01, ML04) offline, where
defenses no longer apply.

Where to defend:
- Per-tenant rate limits keyed on identity.
- Model artifact signing and signature verification at load.
- Watermarking (detection, not prevention).
- Restrict the model file's network surface and access controls.

#### ML06 — AI Supply Chain Attacks

A vulnerability or backdoor enters the system through a dependency:
a poisoned pretrained model from a public hub, a malicious package
in the training stack, a tampered base image.

Where to defend:
- SBOM + image signing + signed model artifacts.
- Pin versions, vendor critical components.
- Internal registry mirror with scanning at ingress.
- See Module 10 for full coverage.

#### ML07 — Transfer Learning Attack

A pretrained model contains a backdoor (intentional or accidental
from ML02-style poisoning of *its* training data). When fine-tuned,
the backdoor survives in the new model.

Where to defend:
- Vendor / provenance verification of pretrained models.
- Behavioral testing of fine-tuned models against suspicious-input
  corpora.
- Differential testing across multiple pretrained candidates.

#### ML08 — Model Skewing

An attacker manipulates the model's *production environment* —
shifting the input distribution, or injecting feedback that
becomes future training data — to skew the model over time. Most
relevant for models that retrain on production feedback (search
ranking, recommendation, fraud detection).

Where to defend:
- Distinguish "training-eligible feedback" from "all feedback".
- Outlier detection on retraining datasets.
- Human review on systemic distribution shifts.

#### ML09 — Output Integrity Attack

An attacker intercepts and modifies the model's output *between*
the model and the consumer. The model is fine; the channel is the
problem.

Where to defend:
- mTLS between model service and consumers.
- Output signing for high-stakes decisions.
- Treat the model's output as untrusted by the consumer until
  verified.

#### ML10 — Model Poisoning

An attacker modifies the model *itself* — either the artifact in
the registry or the weights in memory — to produce specific
malicious behavior. Distinct from ML02 (which poisons via data)
and ML06 (which poisons via supply chain).

Where to defend:
- Model artifact signing.
- Read-only model artifact storage with audit.
- Memory protections appropriate to the deployment platform.

### 2.3 The Top 10's structural blind spots

The OWASP ML Top 10 is the best public catalog, but it has gaps
that production teams must address from other sources:

- **LLM-specific risks**: prompt injection, jailbreaks, indirect
  prompt injection. OWASP maintains a *separate* LLM Top 10. If
  you operate LLMs, you need both.
- **Output harms**: bias, toxicity, hallucination. These are
  safety concerns adjacent to security; the Top 10 covers them
  thinly.
- **Operational threats**: insider threats, regulatory
  non-compliance, fairness violations. Covered in Modules 07 and
  11.

---

## 3. MITRE ATLAS: ML-specific adversary tactics

MITRE ATLAS (Adversarial Threat Landscape for AI Systems) is the
ML-specific analogue of MITRE ATT&CK. Where ATT&CK catalogs
adversary tactics against enterprise systems, ATLAS catalogs
adversary tactics against AI/ML systems.

ATLAS is maintained at [atlas.mitre.org](https://atlas.mitre.org/).
Verify current tactic IDs at the source — like ATT&CK, ATLAS
evolves.

### 3.1 The ATLAS tactic chain

ATLAS organizes adversary behavior into a sequence of **tactics**
(the high-level "why") with **techniques** (the specific "how")
under each. The tactic chain (current at time of writing) is:

1. **Reconnaissance** — adversary learns about the ML system
   (architecture, training data sources, deployment).
2. **Resource Development** — adversary builds capabilities
   (proxy models, attack datasets, infrastructure).
3. **Initial Access** — adversary gains access to ML system
   components (via supply chain, valid credentials, or
   web-application weaknesses).
4. **ML Model Access** — adversary obtains access to query or
   inspect the model.
5. **Execution** — adversary runs adversary-controlled code in
   the ML environment.
6. **Persistence** — adversary maintains foothold across
   restarts and retraining.
7. **Defense Evasion** — adversary avoids detection (rate limit
   evasion, prompt injection that hides intent).
8. **Discovery** — adversary maps the system's defenses.
9. **Collection** — adversary gathers data of interest (model
   artifacts, training data, predictions).
10. **ML Attack Staging** — adversary prepares the actual ML
    attack (crafts adversarial examples, embedded backdoor).
11. **Exfiltration** — adversary moves data out.
12. **Impact** — adversary realizes the goal (model degradation,
    decision manipulation, data theft).

### 3.2 Why this matters operationally

Two reasons:

1. **Detection engineering.** Your SIEM rules and Sigma
   detections should map to ATLAS tactics, the same way
   non-ML detections map to ATT&CK tactics. Module 11 covers
   detection authoring in depth.
2. **Tabletop exercises.** A realistic ATLAS-driven scenario
   walks an attacker through the chain — reconnaissance to
   impact — and lets you spot which tactics your team has *no*
   coverage for.

### 3.3 An example tactic chain

A model-extraction scenario, mapped through ATLAS tactics:

| Stage | Adversary action |
|---|---|
| Reconnaissance | Read public papers, blog posts about the target's recommender model |
| Resource Development | Build a query-budget script that simulates many user accounts |
| Initial Access | Sign up as a normal user, possibly buy a paid tier |
| ML Model Access | Query the recommender API at scale |
| Discovery | Probe rate limits; find tier with highest budget |
| Collection | Log queries + responses |
| ML Attack Staging | Train a surrogate model on the logged query/response pairs |
| Exfiltration | Move the surrogate out of the environment |
| Impact | Use the surrogate to enable downstream attacks (adversarial example crafting) offline |

Notice that none of the individual steps look unambiguously like an
attack to a non-ML-aware detection system. The user is logged in,
paying, querying within rate limits. The ML-aware view is what
makes this visible.

---

## 4. Threat modeling for ML systems

Threat modeling is the discipline of asking "what could go wrong"
in a structured way. For ML systems, the conventional frameworks
(STRIDE, PASTA, attack trees) work but need extension.

### 4.1 STRIDE, adapted for ML

STRIDE's six threat categories — Spoofing, Tampering, Repudiation,
Information disclosure, Denial of service, Elevation of privilege —
all apply to ML systems. They miss the ML-specific surface unless
extended:

| STRIDE category | Classical example | ML-specific extension |
|---|---|---|
| **Spoofing** | Attacker impersonates a user | Attacker submits an adversarial input that "impersonates" a different class to the model |
| **Tampering** | Attacker modifies stored data | Attacker poisons training data, or modifies the model artifact |
| **Repudiation** | User denies an action | A model's decision producer denies the basis for the decision (no audit trail) |
| **Information disclosure** | Attacker reads a confidential file | Model inversion / membership inference leaks training data |
| **Denial of service** | Attacker exhausts resources | Adversarial DoS via expensive prompts; model unavailable due to drift |
| **Elevation of privilege** | Attacker gains admin rights | Attacker who can submit training data gains influence over future model behavior |

Each row should be in your threat model **for every model in
production.**

### 4.2 ML-specific threat categories STRIDE doesn't catch

Three categories of risk are not really STRIDE shapes:

#### Model quality degradation as a security event

A model whose accuracy silently drops from 95% to 70% over six
months **is** a security event — the system is no longer
trustworthy — even if no traditional security control failed. This
is why ML monitoring (drift, performance regression) is part of
the security surface.

#### Bias / fairness failures as a security event

A model that performs measurably worse on a protected subgroup
than on the majority is, in many jurisdictions, a regulatory
event. Where it intersects with security: the *change* in fairness
metrics can be the symptom of an attack (model skewing in ML08).

#### Decision authority overreach

A model that is making decisions outside the scope it was approved
for — or whose outputs are being used by a system the model owner
didn't agree to support — is a governance failure that maps to
security in the long run.

### 4.3 The threat-modeling workflow

For each ML asset (model, training pipeline, inference service,
feature store), the workflow is:

1. **Inventory.** What is this thing? Who built it, who owns it,
   what does it depend on?
2. **Trust boundaries.** Where does data crossing this asset's
   boundary become trusted? Who enforces that trust?
3. **Threats per STRIDE+ML.** Walk each category against the
   asset. Be concrete: "attacker A wants outcome B by doing C".
4. **Existing controls.** What's already in place?
5. **Gaps.** Where are existing controls insufficient?
6. **Mitigation priority.** Rank by likelihood × impact.

The deliverable is a written threat model, reviewed by the
platform and security teams, kept current as the system evolves.

Exercise 1 walks you through producing one of these for a real
small ML system.

---

## 5. Security architecture principles for ML

Six principles that recur across well-architected ML security
designs:

### 5.1 Least privilege at the *workload* identity, not the *node*
identity

Workloads — training jobs, serving pods, batch inference jobs —
should each have their own identity (SPIFFE / SPIRE in
Kubernetes, IAM roles for service accounts in cloud-native
deployments). Sharing a node's identity across workloads means a
compromise of one workload grants the others' privileges.

### 5.2 Defense in depth across the *ML lifecycle*

The lifecycle has stages — data ingest, feature engineering,
training, evaluation, registration, deployment, inference,
monitoring — each with its own threat surface. A single layer of
control (e.g., "we sign images") catches threats at one stage and
misses them at others. Strong designs apply controls at every
stage.

A useful framing: every model in production passes through this
chain. The chain is only as strong as its weakest link.

### 5.3 Provenance for everything that becomes a decision input

If a piece of data, code, or weight contributed to a production
decision, it must be traceable back to where it came from. This
is the basis of incident response ("which decisions were affected
by the poisoned dataset?") and of regulatory compliance
("explain how this decision was made").

### 5.4 Detection presumes prevention will fail

Preventive controls (admission policies, signature verification,
rate limits) will eventually fail. The architecture must include
detective controls (audit logs, anomaly detection, behavior
monitoring) that fire when prevention is bypassed.

### 5.5 Make the safe path the easy path

Engineers and data scientists are not adversaries of security.
They are users of the platform. A security architecture that
makes the secure workflow harder than an insecure one will lose
to the insecure one over time. The control plane should make
"signed, attested, audited" the *default*.

### 5.6 Compliance is a *consequence* of security, not a substitute
for it

A system designed to pass an audit will pass that audit and fail
its actual threats. A system designed against its threats will
pass most audits, occasionally need adjustment, and stand up to
incidents. Design for threats; document for audits.

---

## 6. Defense in depth across the ML lifecycle

Concrete: where does each control category apply?

### 6.1 Data ingest

- **Threats**: poisoning (ML02, ML10), supply chain (ML06).
- **Controls**: signed datasets, schema validation, outlier
  detection, source attestation.

### 6.2 Feature engineering

- **Threats**: poisoning (skew between training and serving),
  governance failure (PII in features).
- **Controls**: feature store with signed feature definitions,
  point-in-time correctness, automated PII scanning.

### 6.3 Training

- **Threats**: poisoning, supply chain, model theft (training
  job has access to the trained model before it's protected).
- **Controls**: isolated training infrastructure, signed code,
  differential privacy, training-job provenance attestation.

### 6.4 Evaluation

- **Threats**: hidden quality regressions, hidden bias
  regressions, hidden adversarial-input fragility.
- **Controls**: regression tests on quality, fairness metrics,
  adversarial robustness checks.

### 6.5 Registration

- **Threats**: tampered artifacts (ML10), unsanctioned models
  reaching production.
- **Controls**: signed model artifacts, registry promotion gates
  tied to evaluation evidence.

### 6.6 Deployment

- **Threats**: misconfiguration, lateral movement, exposed
  endpoints.
- **Controls**: admission policies (signature + attestation
  verification), network policies, identity-based authorization.

### 6.7 Inference

- **Threats**: evasion (ML01), extraction (ML04, ML05).
- **Controls**: input validation, output filtering, per-tenant
  rate limits, query auditing.

### 6.8 Monitoring

- **Threats**: silent degradation, slow attacks (long-running
  extraction, gradual poisoning via skewing).
- **Controls**: drift detection, prediction-quality monitoring,
  per-tenant query analytics.

### 6.9 Decommission

- **Threats**: old model still serving while team thinks it's
  been retired; stale weights reused.
- **Controls**: model lifecycle audit, deletion attestation.

---

## 7. Where the ML security role fits in the org

Three patterns are common in real orgs:

### 7.1 Embedded model

A security engineer with ML knowledge embedded in the ML platform
team. Strong on day-to-day controls, weaker on enterprise-wide
policy. Most common at smaller orgs.

### 7.2 Federated model

A central security function (CISO's org) with a specialized "AI
security" lead who works across multiple ML teams. Strong on
policy and audit, weaker on hands-on controls in any one team.

### 7.3 Hybrid model

Embedded security engineers in each major ML platform team,
reporting dotted-line to a central AI security function. Most
common at large orgs that have mature ML investments.

### What you should expect to do day-to-day

Independent of the org model, an AI infrastructure security
engineer in a real org spends time on:

- **Threat modeling** new systems before they ship.
- **Policy authoring** (OPA/Kyverno/admission policies).
- **Tooling integration** (signing, attestation, scanning).
- **Incident response** for ML-specific incidents (suspected
  extraction, suspected poisoning, fairness regression).
- **Cross-team education** — bringing ML engineers up the
  security curve so they make good decisions without you in
  the room.
- **Compliance evidence** for audits.
- **Vendor risk** assessment for ML tooling, model hubs,
  managed services.

You are *not* primarily writing CUDA kernels. You are *not*
primarily training models. You are writing prose, policy, and
glue code, and the prose matters more than the code.

---

## 8. What you should be able to do after this module

A working checklist:

- [ ] Explain why ML security is not a subset of general
      infrastructure security to a senior engineer in five
      minutes.
- [ ] Map a real ML system to the OWASP ML Top 10 and produce a
      coverage matrix with concrete gaps.
- [ ] Walk a model-extraction scenario through the MITRE ATLAS
      tactic chain.
- [ ] Produce a written threat model for a small ML system using
      STRIDE+ML.
- [ ] Identify which of the six security architecture principles
      is being violated in a given proposed design.
- [ ] Describe defense-in-depth across the full ML lifecycle
      from data ingest to decommission.

The five exercises in this module each correspond to one or two
items on that list.

---

## 9. What this module deliberately doesn't cover

Each of these is its own module later in the track:

- **Adversarial ML techniques in depth** — Module 06.
- **Cryptography choices for ML** — Module 03.
- **Network security implementations** — Module 04.
- **Secrets management** — Module 05.
- **Compliance frameworks (GDPR, HIPAA, SOC 2) in depth** —
  Module 07.
- **Runtime security tooling** — Module 08.
- **Policy as code** — Module 09.
- **Supply chain controls in depth** — Module 10.
- **Security operations (SIEM, detection rules, incident
  response)** — Module 11.

This module installs vocabulary and frameworks. Skills come from
the following 11 modules and the 5 projects.

---

## 10. Suggested reading order outside this module

Once you finish this module:

1. Read the project READMEs in
   [`ai-infra-security-learning/projects/`](../../projects/). These
   are what the track is *for*; everything else exists to make you
   capable of building them.
2. Read the `SOLUTION.md` files in
   [`ai-infra-security-solutions/projects/`](https://github.com/ai-infra-curriculum/ai-infra-security-solutions/tree/main/projects).
   Each one names the threat model and the controls that respond
   to it.
3. Move to **Module 02: Zero-Trust Architecture**.

---

## Appendix A — A glossary you can quote

- **Adversarial example**: An input crafted to cause a model
  to produce an output the system designer didn't intend.
- **Backdoor**: A model defect such that a trigger pattern in
  the input produces an attacker-controlled output.
- **Differential privacy**: A property of an algorithm that
  bounds the influence of any single training example on the
  output, with a quantifiable privacy budget.
- **Drift**: A measurable change in the distribution of inputs
  or predictions over time; usually a symptom, not a cause.
- **Evasion**: A class of attacks against an inference-time
  system using crafted inputs.
- **Extraction**: A class of attacks that reconstruct a
  protected asset (model, training data, decision boundary)
  through queries.
- **Hash chain**: An append-only log where each entry's hash
  includes the previous entry's hash, providing
  tamper-evidence under an adversarial-insider threat model.
- **Membership inference**: Determining whether a specific
  record was in a model's training set.
- **Model inversion**: Reconstructing training-set examples
  from a trained model's outputs.
- **Poisoning**: A class of attacks against the *training*
  process, via corrupted data or corrupted code.
- **SBOM**: Software Bill of Materials — a structured
  inventory of the components in an artifact.
- **SLSA**: Supply-chain Levels for Software Artifacts — a
  framework for measuring the integrity of a software supply
  chain.
- **SPIFFE / SPIRE**: A workload-identity framework that
  issues short-lived identity documents to workloads, attested
  by node and pod selectors.

## Appendix B — Common misconceptions

| Misconception | Reality |
|---|---|
| "We use TLS, so we're secure" | TLS protects the channel, not the model. ML01/02/03/04/05 are unaffected by TLS. |
| "We don't expose the model" | A model behind a paid API is still extractable. ML05. |
| "Our training data is anonymized" | Anonymization is necessary, not sufficient. ML03 and ML04 can leak from anonymized data. |
| "We don't use open source models" | You probably do — your dependencies include them. ML06. |
| "Adversarial examples are a research problem" | They're a production problem for every system that takes user input. ML01. |
| "Our auditor said we're compliant" | Auditors check controls, not threats. Compliance ≠ security. |
| "ML security is the ML team's job" | ML security is the security team's job, with the ML team as users of the controls. |

---

*Continue to the [exercises](./exercises/) when you are ready to
apply this material to a real system. The exercises produce
artifacts you'll reuse in every subsequent module.*
