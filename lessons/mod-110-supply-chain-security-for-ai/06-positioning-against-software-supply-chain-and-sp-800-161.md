# Chapter 06 — Positioning ML Supply-Chain Security Against Software Supply-Chain and SP 800-161

> **Note on AI-assisted content.** The frameworks named below —
> NIST SP 800-161r1, NIST SSDF (SP 800-218), OWASP ML and LLM
> Top 10, MITRE ATLAS — are revised periodically. Verify
> framework versions, control identifiers, and taxonomy entries
> against the current publications before citing specific
> controls to an auditor or in a procurement document. See
> [`resources.md`](./resources.md).

---

## Why this chapter exists

Chapters 01–05 are mechanisms: SLSA, cosign, ML-BOM,
scanning, intake runbook. This chapter is the frame around
them. The two questions it answers:

1. **Where does ML supply-chain security sit relative to
   classical software supply-chain security?** What
   carries over, what breaks, and where the ML programme
   needs its own controls versus adopting the software
   programme's.
2. **How does the ML supply-chain function connect to the
   broader supply-chain-risk-management (SCRM) framework —
   NIST SP 800-161r1 in particular — that the enterprise
   already uses for its ICT suppliers?**

The failure modes this chapter is written against:

> A security team adopts SLSA for container images, signs
> with cosign, and runs Syft for SBOM across the application
> fleet. The ML platform team is told "same bar for your
> stuff". Twelve months later, every container built by the
> ML platform has a SLSA attestation; the models inside the
> containers do not. The weight files are pulled from HF in
> notebooks; the training datasets are tracked in a spread-
> sheet; the Clause 8.1-ish supplier register has no row for
> "Hugging Face Hub" because "Hugging Face is a developer
> tool, not a vendor". The SP 800-161 inventory the
> procurement team maintains lists `pytorch` as a software
> dependency but omits the base model that is the actual
> source of the deployed system's behaviour.

The symptom is that the ML programme runs *parallel* supply-
chain machinery that is invisible to the enterprise SCRM
function. The audit sees two programmes that cannot be
reconciled. The fix is to make the ML supply-chain function
a first-class contributor to the SCRM programme, with its
own supplier register, its own tiering, and its own
reporting into the governance structures the enterprise
already runs.

You leave this chapter able to:

- Enumerate what classical software supply-chain security
  (SLSA, SSDF, SBOM, in-toto, Sigstore) carries into the
  ML programme and what it does not.
- Describe the model as **owned upstream** (the parts the
  org builds) versus **consumed upstream** (the parts the
  org imports); state which controls each side needs.
- Position the ML supply-chain function within **NIST SP
  800-161r1**'s SCRM framework — controls, roles, documents,
  reporting.
- Name the ML-specific threat frames (**OWASP ML Top 10,
  OWASP LLM Top 10, MITRE ATLAS**) and locate the
  supply-chain-relevant entries in each.
- Build an **ML supplier register** and tiering model that
  parallels the enterprise supplier register.
- Set an **audit calendar** for the ML supply-chain
  programme — intake re-scans, mirror sweeps, policy
  refreshes, review-board checkpoints.

---

## What classical software supply-chain security covers

The last decade of software supply-chain practice crystallised
around four open-source efforts worth naming:

- **SLSA** (Supply-chain Levels for Software Artifacts). The
  Build track covered in chapter 01. Levels L0–L3 escalate
  from "no provenance" through "signed provenance" to
  "hardened builder that prevents build-definition
  tampering with provenance".
- **in-toto**. An attestation-envelope specification. SLSA
  predicates live inside in-toto Statements. CycloneDX
  ML-BOM attestations and scan-report attestations do too.
- **Sigstore** (Fulcio + Rekor + cosign). The signing /
  transparency-log stack covered in chapter 02.
- **SBOM** standards. **CycloneDX** (OWASP) and **SPDX**
  (Linux Foundation / ISO/IEC 5962). The two produce the
  machine-readable inventories that chapter 03 extends for
  models.
- **NIST SSDF (SP 800-218)**. Secure Software Development
  Framework. Prescribes practices for secure development
  across the SDLC — version control, dependency management,
  secure build, review, response. SSDF is implementation-
  neutral; a programme adopts it on top of its stack.
- **Executive Order 14028** and NTIA's SBOM minimum
  elements. The procurement push behind SBOM adoption.
- **PEP 740** (Python packaging attestation standards, in
  development) and the broader push to put sigstore
  attestations next to language-ecosystem releases.

What a mature software-supply-chain programme carries into
ML without modification:

- **SLSA Build track mechanics.** The Build-track levels
  and the in-toto predicate are the same; chapter 01 is
  the ML translation.
- **Sigstore signing.** Chapter 02's cosign commands,
  policy-controller admission, and Rekor transparency are
  the same primitives.
- **SBOM for software layers.** The container-image SBOM,
  the Python dependency SBOM, and the OS-package SBOM are
  the same; chapter 03's ML-BOM references them.
- **SSDF practices.** Version control, dependency pinning,
  secure build, vulnerability-response — the SSDF
  practices apply to ML pipeline code without special
  cases.
- **Security-advisory monitoring and CVE triage.** The
  software-side CVE inventory covers CUDA, Python,
  Transformers library, model-serving framework.

What classical practice does **not** cover directly:

- **Datasets.** No SBOM taxonomy for "the training corpus".
  Chapter 03's ML-BOM dataset components are new.
- **Weight-file threat surface.** Chapter 04's deserialise-
  to-execute attacks are ML-specific. ClamAV / software
  malware scanners do not understand pickle.
- **Weight-space backdoors.** No parallel in software
  supply-chain. Behavioural evaluation (mod-106) is the
  ML programme's answer; the software programme has no
  analogue.
- **Model licences.** OpenRAIL / RAIL / community licences
  do not map to SPDX identifiers; the SPDX licence list is
  centred on software.
- **Dataset origin claims.** No general "where did this
  training data come from" SBOM concept.
- **Capability growth across revisions.** A library's
  revision set changes feature; a model revision set can
  change capability tier (chapter 06 of mod-109). The
  supply-chain controls stack must account for this.

The programme-level implication: **adopt the software
primitives wholesale; add the ML-specific controls as a
layer**. Do not try to force dataset components through
software SBOM tooling that does not understand them, and
do not reinvent SLSA for models.

---

## Owned-upstream versus consumed-upstream

A useful decomposition of the ML supply-chain:

- **Owned upstream.** The parts of the pipeline the
  organisation builds and controls — the training code,
  the pipeline, the internal datasets, the evaluation
  bundles, the serving stack. SLSA, cosign, ML-BOM, and
  SBOM apply as the organisation's own practices.
- **Consumed upstream.** The parts that come from outside
  — base models, public datasets, open-source libraries,
  vendor APIs. Here, the organisation is the *consumer*
  in SLSA terms; the primary tool is the chapter-05 intake
  runbook, plus whatever provenance the upstream chooses
  to publish.

Classical software supply-chain also has an owned /
consumed split (your Go source + your module cache), but
the balance is different for ML programmes:

- A software product may own 80% of its binary surface
  and consume 20% (dependencies).
- A fine-tuning programme may consume 95% of its
  behavioural surface from the base model and own 5%
  (the adapter). The capability it ships is upstream's,
  shaped slightly.

This asymmetry is why the chapter-05 intake runbook is so
much of the chapter-110 content: for consumed-upstream
components, the organisation does not control the build.
Its control is the **gate**: *decide what crosses the
perimeter*.

For consumed-upstream components the SLSA conversation
inverts:

- **The upstream may or may not emit provenance.** Where
  it does — frontier labs with internal signing, HF Spaces
  with Hub-signed artefacts — the consumer verifies and
  records. Where it does not — the common case for
  community models — the consumer's intake pipeline *is*
  the provenance, and the mirror's attestations are what
  the next consumer verifies.
- **Trust is on the identity, not the artefact.** For a
  dependency without upstream provenance, the consumer
  trusts the publishing organisation (or doesn't).
  Chapter 06's supplier register captures this: suppliers
  are the unit of trust decision.
- **Scanning compensates for missing provenance.** For
  consumed-upstream artefacts, ModelScan + safetensors
  conversion + behavioural evaluation substitute for the
  SLSA attestation chain the organisation would have had
  from an owned-upstream build.

The programme sets its posture per supplier tier (below).

---

## NIST SP 800-161r1 and the SCRM framing

**NIST SP 800-161r1 — Cybersecurity Supply Chain Risk
Management Practices for Systems and Organizations** is the
US federal reference for ICT supply-chain security. It
provides:

- A **C-SCRM programme model** with executive, programme,
  and operational layers.
- A **control overlay on SP 800-53** (the "SR" family and
  others) that lists SCRM-specific control enhancements.
- Guidance on **supplier assessment, tiering, and ongoing
  monitoring**.
- Guidance on **inherited components** (sub-tier
  suppliers, open-source contributors, service providers).
- Templates for **SBOMs, supplier questionnaires, risk
  responses**.

A programme already running under SP 800-161r1 has a surface
the ML function can plug into:

- The **supplier register** — SP 800-161 Table-F or
  equivalent — gets rows for the ML supply suppliers:
  Hugging Face, model vendors (OpenAI, Anthropic,
  Mistral, etc.), eval-vendor services, labelling
  providers.
- The **supplier assessment** process gets an ML-specific
  questionnaire (below).
- The **tiering** (critical / high / moderate / low) is
  the same taxonomy; the criteria extend to cover ML-
  specific concerns.
- The **continuous monitoring** process gets the mirror-
  sweep job and the intake re-scan cadence.
- The **inherited-component** section accommodates data-
  origin claims and base-model origin claims that go
  deeper than any single supplier.

For organisations without an existing SP 800-161 programme,
the framework still provides a reasonable control vocabulary.
Public-sector contractors, FedRAMP-adjacent organisations,
and critical-infrastructure operators are generally bound to
it; private-sector enterprises often adopt it as reference.

The key SP 800-161 control families worth naming (the
section identifiers are from the 800-53 Rev. 5 SR family
that SP 800-161 extends):

- **SR-2 — Supply chain risk management plan.** The ML
  programme contributes a sub-plan; it does not stand
  alone.
- **SR-3 — Supply chain controls and processes.** The
  intake runbook and the scanning pipeline populate this.
- **SR-4 — Provenance.** SLSA + signing + ML-BOM are the
  evidence here.
- **SR-5 — Acquisition strategies, tools, and methods.**
  How the org buys / acquires model and dataset services;
  the chapter-05 intake runbook is one such acquisition
  method.
- **SR-6 — Supplier assessments and reviews.** The ML
  supplier questionnaire; the review board; the periodic
  reassessment.
- **SR-7 — Supply chain operations security.** How the
  intake pipeline, mirror, and signing identities are
  themselves protected.
- **SR-8 — Notification agreements.** Hugging Face
  takedowns, upstream licence changes, vendor security
  advisories — how the organisation is notified and
  how notifications flow to action.
- **SR-9 — Tamper resistance and detection.** Chapter
  02's signing + Rekor + chapter-04's scanning.
- **SR-10 — Inspection of systems or components.** The
  periodic re-scan / re-eval of mirror entries.
- **SR-11 — Component authenticity.** Signed provenance +
  intake attestation verification.
- **SR-12 — Component disposal.** Mirror retention,
  attestation retention, retirement of models and
  datasets.

A programme-level matrix maps the chapters-01–05 controls
to these SR-family controls so an auditor walking SP 800-
161 can trace to the ML-side evidence:

| SP 800-161 / SR | ML-side evidence | Chapter |
| --- | --- | --- |
| SR-4 Provenance | SLSA Provenance v1 attestation; cosign-verified at admission | 01, 02 |
| SR-6 Supplier assessment | Chapter-05 intake runbook; supplier register row | 05, 06 |
| SR-9 Tamper resistance | Signed artefacts, mirror, Rekor | 02, 05 |
| SR-10 Inspection | Mirror sweep; re-scan; re-eval | 04, 05, 06 |
| SR-11 Authenticity | Intake attestation chain; admission policy | 02, 03, 05 |
| SR-12 Disposal | Mirror retention; attestation retention; retirement | 05, 06 |

For regulated programmes (US federal, DoD, FedRAMP), the SR
family carries into the system security plan (SSP) directly.
For enterprise programmes, the matrix is the artefact a
chapter-109 ISO 42001 / SOC 2 / internal-audit reviewer uses.

---

## OWASP, MITRE ATLAS, and the ML-threat frames

Several ML-specific threat taxonomies name the attacks
chapter 04 and 05 defend against. Worth having them cited
in the programme documentation:

- **OWASP Machine Learning Security Top 10** (and
  **OWASP LLM Top 10** for generative systems). ML-specific
  top-10 lists; the supply-chain-relevant entries are
  "ML05 Model Theft" / "ML06 AI Supply Chain Attacks" /
  "ML07 Transfer Learning Attack" (ML Top 10) and
  "LLM05 Supply Chain Vulnerabilities" / "LLM03 Training
  Data Poisoning" (LLM Top 10). Entry names and numbers
  change between revisions; cite the version.
- **MITRE ATLAS** (Adversarial Threat Landscape for AI
  Systems). The ATT&CK-shaped matrix of adversary
  techniques against AI. Supply-chain-relevant tactics
  include **Resource Development** (acquiring or
  developing resources) and **Initial Access** techniques
  that target the ML supply chain (poisoned open-source
  models, backdoored pre-trained models, poisoned
  training data).
- **NIST AI 100-2 — Adversarial Machine Learning:
  Taxonomy and Terminology.** The reference taxonomy for
  attack classes. The supply-chain-relevant classes:
  "poisoning attack during training", "backdoor attack",
  "model-extraction attack".
- **ENISA — Multilayer Framework for Good Cybersecurity
  Practices for AI**. European perspective; aligns with
  ENISA's broader threat-landscape work.

Programme use:

- **Mapping evidence**. Each intake-runbook gate names
  which ATLAS tactic or OWASP entry it addresses. The
  mapping is small but defensible: a supplier
  questionnaire that cites `ATLAS AML.T0010 Supply Chain
  Compromise` and `OWASP LLM05` reads back to the
  framework an auditor already knows.
- **Threat-modelling input**. The ML programme's threat
  model (mod-102) uses these taxonomies as a starting
  checklist for supply-chain-adjacent threats.
- **Incident-response cross-reference**. The incident
  playbooks (mod-111) classify incidents against the
  taxonomies so trend reporting is possible across
  programmes.

These are references, not standards. SP 800-161 is the
authoritative US-federal reference; OWASP and ATLAS are
community resources whose main utility is a shared
vocabulary.

---

## The ML supplier register and tiering

The output of positioning ML supply-chain within the
enterprise SCRM is a *supplier register* — a controlled
list of suppliers, their tier, their risk disposition, and
their reassessment cadence.

### Register shape

Minimum columns per row:

- **Supplier name**. The upstream entity: Hugging Face,
  the specific model-publishing organisation, OpenAI,
  Anthropic, the labelling vendor, the dataset vendor.
- **Supply type**. Model weights; dataset; API-only
  service; infrastructure; evaluation service; labelling
  service.
- **Tier**. Critical / high / moderate / low. Criteria
  below.
- **Scope of use**. Which products / deployments consume
  this supplier.
- **Last assessment date**. When the chapter-05 runbook
  (for a model/dataset) or the equivalent vendor
  assessment (for an API / service) last ran.
- **Next assessment due**. Based on tier cadence.
- **Risk disposition**. Accepted / with-mitigations /
  under-review / declined.
- **Approvers**. Named roles who signed off.
- **Related artefacts**. Links to intake attestations,
  licence attestations, DPIAs (mod-108), contract
  references.
- **Notifications**. How the supplier notifies the org of
  security / licence / takedown events (chapter 06
  SP 800-161 SR-8).

### Tiering criteria

A workable rubric; adapt to the organisation:

- **Critical**. Supplier whose compromise or revocation
  halts a line of business. Example: the frontier model
  behind a customer-facing LLM product; the labelling
  vendor whose work gates FDA / clinical pipelines.
- **High**. Supplier whose compromise materially affects a
  production system but does not halt it. Example: a
  base model for a non-critical fine-tune; a dataset
  vendor for a non-regulated classifier.
- **Moderate**. Supplier whose compromise could affect
  internal / staging systems; whose licence terms could
  create legal exposure if violated.
- **Low**. Supplier whose outputs are used in sandboxes,
  research, non-production experimentation only.

Tier drives:

- **Reassessment cadence**. Critical: annual, with
  continuous monitoring. High: annual. Moderate:
  biennial. Low: on change.
- **Scope of safety-evaluation**. Critical and high
  suppliers' models get the full eval suite (mod-106);
  moderate and low get the baseline.
- **Depth of licence review**. Critical: full counsel
  review; high: internal legal checklist; moderate /
  low: platform-team runbook.
- **Required attestations at admission**. Critical:
  full attestation stack (provenance + licence + eval +
  additional capability-tier eval if the model is at
  frontier chapter-06 tiers in mod-109); low: baseline.

The tier is a *dynamic* attribute. A model imported for
research (low) that gets promoted to a customer-facing
product (high / critical) triggers a re-run of the intake
runbook at the higher tier before admission.

### Example rows

```yaml
# ml-supplier-register.yaml  (example)
suppliers:
  - name: "Hugging Face Hub"
    supply_type: "model-and-dataset-registry"
    tier: critical
    scope: "All consumed-upstream model fetches route through HF Hub."
    last_assessment: 2026-07-15
    next_assessment: 2027-07-15
    risk_disposition: "accepted-with-mitigations"
    mitigations:
      - "Intake runbook chapter-05 for every artefact."
      - "Internal mirror; no production egress to huggingface.co."
    approvers:
      - "ML Platform Lead"
      - "Head of Security"
      - "Procurement"
    related_artefacts:
      - "intake-runbook.md"
      - "contract-ref: SaaS-2026-074"
    notifications:
      - "Hugging Face takedown notifications; weekly sweep job."
      - "HF scanner result RSS."

  - name: "meta/llama"
    supply_type: "base-model"
    tier: high
    scope: "Backbone for internal summarisation assistant (staging only)."
    last_assessment: 2026-09-02
    next_assessment: 2027-09-02
    risk_disposition: "accepted-with-mitigations"
    mitigations:
      - "Meta Llama community licence reviewed; see licence-attestation hash."
      - "Monthly re-scan; monthly eval re-run."
    approvers:
      - "ML Platform Lead"
      - "Product Counsel"
    related_artefacts:
      - "licence-attestation: sha256:abcd..."
      - "intake-provenance: sha256:ef01..."

  - name: "VendorA Labelling Services"
    supply_type: "data-labelling-service"
    tier: critical
    scope: "Labelled training data for the fraud classifier."
    last_assessment: 2026-06-01
    next_assessment: 2027-06-01
    risk_disposition: "accepted"
    related_artefacts:
      - "DPA 2026-04-17"
      - "SOC 2 Type II 2026 report"
      - "DPIA ref: dpia-2026-fraud-v3"
```

The register is a living artefact. Chapter-109 Clause 9.1 /
SOC 2 CC9.2 / Article 25 reviewers reach for it; the
chapter-06 review board processes changes to it.

---

## The ML-specific supplier questionnaire

A short questionnaire reusable per supplier, applied at
onboarding and reassessment:

1. **Identity and authority.** Legal name of supplier,
   publisher identity on the hub(s) they publish from,
   authoritative signer identity (if they publish signed
   artefacts).
2. **Provenance.** Do they publish SLSA attestations,
   model cards, dataset cards, licence texts? Where?
3. **Dataset origin.** For model suppliers: do they
   disclose training data? How specifically?
4. **Licence terms.** Which licence(s)? Are the terms
   stable or does the supplier reserve the right to change
   them unilaterally?
5. **Security practice.** Do they run security scanning on
   their published artefacts? Is a security contact
   published? Do they commit to a disclosure timeline for
   security issues?
6. **Takedown / revocation.** If they remove an artefact,
   how do they notify consumers? What is their takedown
   history?
7. **Compliance context.** For data vendors: what
   consent / DPIA / HIPAA / GDPR posture do they claim?
   For model vendors: do they claim training on
   consented / licensed data only?
8. **Capability claims.** For model suppliers at
   near-frontier scale: do they publish capability-
   evaluation results? What evaluation framework?
9. **Contract / SLA.** For paid suppliers: contract
   reference, SLA on availability, security-event
   notification SLA (SP 800-161 SR-8).
10. **Sub-tier suppliers.** Does the supplier itself depend
    on other suppliers that would be material to the
    consuming programme? (A frontier-lab model trained
    partly on data from an upstream data vendor is a
    four-tier chain.)

The questionnaire is not a certification. It is an input
to the risk-disposition decision; the output of each
question drives either an accept / mitigate / decline for
that aspect.

---

## The audit calendar

Supply-chain controls decay silently. A programme-level
calendar keeps the cadence explicit:

- **Weekly.** Mirror sweep against upstream status
  (takedowns, flag changes). Intake pipeline health check.
  New-CVE triage against the current scanner and loader
  versions.
- **Monthly.** Re-scan of a sampled subset of mirror
  entries at the current scanner version. Mirror-wide
  sweep for licence-text drift on upstream licence URLs.
  Review of new intake requests batched for review-board
  signal.
- **Quarterly.** Re-eval of mirror entries used in
  critical and high production tiers. Review of exceptions
  granted in the last quarter. Supplier-register sweep
  for assessment-due dates.
- **Annually.** Full supplier reassessment for critical
  and high suppliers. Full policy-pack review (mod-109
  chapter 04). Full intake-runbook review against the
  current framework versions (SLSA, CycloneDX, SP 800-
  161, OWASP, ATLAS). Capability-tier re-review of
  frontier models in use (chapter 06 of mod-109).
- **Event-driven.** Any upstream security advisory;
  licence change; takedown; capability-tier promotion of
  a model; data-subject erasure request; incident
  (chapter mod-111 playbooks).

The calendar is itself an evidence artefact: Clause 9.1 /
SR-10 inspection cadence is auditable from the completed
runs, not from the policy that says they should happen.

---

## Standard failure modes

- **ML supply-chain function running parallel to
  enterprise SCRM.** Two supplier registers, two sets of
  controls, no reconciliation. Fix: single supplier
  register with an ML-specific overlay; a single reporting
  path into the SCRM function.
- **SBOM programme that excludes datasets and base
  models.** The container SBOM is beautiful; the model
  under the container has no SBOM. Fix: chapter 03's ML-
  BOM is on the same chain as the container SBOM; the
  mirror holds both.
- **"We signed with cosign" treated as sufficient
  provenance.** Signing without the SLSA-level
  requirements chapter 01 lays out (hosted platform,
  isolated build, platform-generated provenance) does
  not meet SR-4. Fix: the SLSA level is claimed with
  evidence; chapter 01's requirement bundle is the
  template.
- **Supplier questionnaire treated as a one-time
  intake.** The questionnaire runs at onboarding; nothing
  re-runs it. Fix: tier-driven reassessment cadence; the
  calendar.
- **ATLAS / OWASP cited in policy, not in evidence.** The
  policy document references the framework; no mapping
  exists from any specific control to the framework
  entry. Fix: each policy-pack rule carries a `taxonomy`
  cross-ref (mod-109 chapter 04 pattern).
- **Supplier register in a spreadsheet owned by one
  person.** Compromises everything the register is
  for. Fix: the register is in version control, change-
  reviewed, and consumed by admission policies as data
  (chapter-109 chapter 04 `data.suppliers.*`).
- **Mirror retention shorter than the regulatory floor.**
  Entries deleted before SOC 2 or HIPAA retention expires.
  Fix: retention floors from mod-109 chapter 05; the
  mirror enforces them.
- **ML supply-chain owner has no reporting line to the
  SCRM function.** Policy owners name "ML Platform
  Lead" but no formal pipe to the CISO's SCRM programme.
  Fix: a monthly SCRM report line that the ML programme
  contributes to; sign-off on changes to critical-tier
  dispositions by SCRM leadership.
- **Classical software supply-chain machinery accepts ML
  surfaces by default.** Container-SBOM tooling emits a
  Python package list and nothing else; the model inside
  the container is invisible to the pipeline. Fix: the
  build pipeline emits ML-BOM as a separate attestation
  bound to the same artefact digest.
- **No DR for the intake pipeline.** The intake pipeline
  is a single point. Fix: SR-7 supply-chain-operations
  security; redundancy and recovery drills on the intake
  pipeline itself.

---

## Summary

- Classical software supply-chain controls — **SLSA,
  SBOM, sigstore, SSDF** — carry wholesale into the ML
  programme at the layers they cover (code, builds,
  containers, dependencies). ML-specific layers —
  **datasets, base models, weight-file threat surface,
  weight-space backdoors, licence composition, capability
  growth** — require additional controls.
- The ML supply-chain decomposes into **owned upstream**
  (where SLSA / cosign / ML-BOM apply as the organisation's
  practice) and **consumed upstream** (where the intake
  runbook of chapter 05 is the primary control). For most
  fine-tuning programmes, consumed-upstream dominates the
  behavioural surface and the control burden.
- **NIST SP 800-161r1** is the SCRM framework the ML
  programme plugs into. The SR-family controls (SR-2
  through SR-12) map onto the chapters-01–05 mechanisms.
  Reporting into the SCRM function keeps the ML
  programme auditable alongside the enterprise programme.
- **OWASP ML Top 10, OWASP LLM Top 10, MITRE ATLAS, and
  NIST AI 100-2** are the ML-threat taxonomies. The
  intake-runbook gates and the policy pack reference them
  so the programme's controls are legible in the
  taxonomies auditors and threat-intel teams already use.
- The **ML supplier register** carries the suppliers, the
  tier, the risk disposition, and the reassessment
  cadence. Admission policies read it as data.
- The **audit calendar** — weekly mirror sweep, monthly
  re-scan, quarterly re-eval, annual full reassessment,
  event-driven on supplier changes — is itself the
  evidence that the controls still run.
