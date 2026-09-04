# Chapter 03 — EU AI Act Articles 9, 10, 14, 15, and 72 as Engineering Artefacts

> **Note on AI-assisted content.** The EU AI Act (Regulation
> (EU) 2024/1689) is binding law with staged application dates
> and further specification via delegated acts, implementing
> acts, harmonised standards, and Commission guidance. This
> chapter is *engineering translation*, not legal advice. The
> definitive text is the Official Journal publication; verify
> article numbers, dates, and thresholds against that text and
> against the AI Office's guidance before quoting to counsel
> or a regulator. See [`resources.md`](./resources.md).

---

## Why this chapter exists

The EU AI Act (in force 1 August 2024; major obligations
staged through 2 August 2027) creates the first
comprehensive risk-based AI regulation. High-risk AI systems
carry specific obligations articulated across Chapter III
Section 2, and enforcement risks include administrative fines
up to €35M or 7% of worldwide annual turnover (Article 99)
for prohibited-practice violations.

For a security engineer, the failure mode is the same one
that hits every regulation the first time:

> A team ships a hiring-decision-support system into the EU.
> Product manages "compliance" as a legal-review checkbox at
> release-gate; legal asks "have you done the Article 9 risk
> management, Article 10 data governance, Article 14 human
> oversight, Article 15 accuracy/robustness/cybersecurity,
> and Article 27 fundamental-rights impact assessment?".
> Engineering has done pieces of each but none of them are
> the *artefacts the Act calls for by name*. There is no
> Article 9 record of "the risk-management system"; there is
> no per-dataset assessment against Article 10 criteria;
> there is no Annex IV technical documentation. The system
> misses launch or ships and the team spends the next quarter
> back-filling.

This chapter is the mapping from the five Articles most
security-engineers own, plus the two closest neighbours
(Article 17 QMS and Article 27 FRIA), to the concrete
engineering artefacts a high-risk system must ship with. It
does not cover the Act's obligations for **General-Purpose AI
model providers** in depth (Articles 51–56) — those apply to
foundation-model builders; the enterprise deployer imports
their compliance evidence as supplier attestations.

You leave this chapter able to:

- State whether your system is **prohibited**, **high-risk
  (Annex III)**, **limited-risk transparency-obligated**, or
  **minimal-risk**, and cite the reason.
- Produce the seven core high-risk-system artefacts —
  Article 9 risk management, Article 10 data governance,
  Article 11/Annex IV technical documentation, Article 12
  logging, Article 14 human oversight, Article 15
  accuracy/robustness/cybersecurity, Article 72 post-market
  monitoring — as *engineering* deliverables, not lawyer
  memos.
- Attach the Article 27 Fundamental Rights Impact
  Assessment to systems that require it (public bodies,
  private deployers of Annex III systems in specified
  categories).
- Extend chapter 01's unified matrix with the EU AI Act
  Article column.

---

## First: classify the system

The Act is risk-based. Obligations depend on the tier the
system falls into. In shorthand:

- **Prohibited (Article 5).** Certain practices — social
  scoring by public authorities, real-time remote biometric
  identification in publicly-accessible spaces by law
  enforcement (with narrow exceptions), emotion inference
  in workplaces and educational institutions (with narrow
  exceptions), untargeted scraping to build facial-
  recognition databases, etc. **If a system falls here it
  cannot be placed on the market**; engineering artefacts
  are irrelevant.
- **High-risk (Article 6 + Annex I/III).** Two paths:
  - Article 6(1): AI system is a safety component of a
    product covered by EU harmonisation legislation listed
    in Annex I (medical devices, machinery, toys,
    automotive, aviation, etc.) and required to undergo
    third-party conformity assessment.
  - Article 6(2): AI system is listed in Annex III
    (biometrics; critical infrastructure; education;
    employment / worker management; access to essential
    private and public services and benefits — including
    credit-scoring and insurance risk; law enforcement;
    migration/asylum; administration of justice;
    democratic processes).
  - Article 6(3) provides a *carve-out*: an Annex III
    system is *not* high-risk if it does not pose a
    significant risk of harm — but the exemption requires
    documentation, filing with a national competent
    authority, and does not apply to profiling of natural
    persons.
- **Limited risk with transparency obligations (Article
  50).** Systems that interact with humans (users must be
  told they are interacting with AI), emotion / biometric
  categorisation systems (users must be informed), systems
  that generate synthetic content (output must be
  detectable as AI-generated; deepfakes must be labelled).
- **Minimal risk.** Everything else. Voluntary codes of
  conduct encouraged (Article 95); no specific obligations.
- **General-Purpose AI models (Articles 51–56).** Providers
  of GPAI models have their own obligations — technical
  documentation, copyright policy, training-content summary,
  and (for GPAI with systemic risk) additional evaluation,
  incident reporting, and cybersecurity obligations.

**The engineering artefact for classification.** A
`ai-act-classification.md` in the system's repo, versioned,
sign-off from Legal, produces:

```yaml
system: prod-cv-screener
classification:
  tier: high-risk
  path: Article 6(2) via Annex III paragraph 4(a)  # employment: recruitment
  carve_out_considered: false
  rationale: >
    Screens CVs against role criteria; produces a shortlist
    that materially influences hiring decisions. Does not
    fall in Article 6(3) exception because it profiles
    natural persons.
  sign_off:
    - name: J. Legal
      role: legal counsel
      date: 2026-08-15
```

The classification changes the artefact set. Everything
below assumes **high-risk** unless noted.

---

## Article 9 — Risk management system

**What the Article requires.** Establish, implement,
document, and maintain a *continuous, iterative* risk-
management system throughout the AI system lifecycle.
Identify and analyse foreseeable risks to health, safety, and
fundamental rights when the system is used in accordance with
its intended purpose. Estimate and evaluate risks under both
intended use and reasonably foreseeable misuse. Adopt
targeted risk-management measures with careful attention to
consequences for children, elderly, and other potentially
vulnerable groups.

**Engineering artefact — the risk-management file.**

```yaml
# governance/ai-act/prod-cv-screener/risk-management.yaml
system: prod-cv-screener
version: 2026.09.01
lifecycle_stages_covered:
  - design
  - training
  - validation
  - deployment
  - monitoring
  - retirement

risks:
  - id: R-001
    description: >
      Disparate impact on candidates by protected
      characteristic (Article 5 charter rights;
      Directive 2000/78/EC).
    intended_use: true
    foreseeable_misuse: false
    inherent_risk:
      likelihood: high
      severity: high
    controls:
      - id: C-001
        description: Group-fairness eval at release + monthly regression (mod-104 chapter 06)
      - id: C-002
        description: Recruiter-visible score + written explanation (Art. 14 human oversight)
    residual_risk:
      likelihood: medium
      severity: medium
      acceptable: true
      accepting_authority: Head of TA
      accepted_on: 2026-08-30
      review_due: 2027-02-28

  - id: R-002
    description: >
      Extraction of training data via query flood
      (cybersecurity; Article 15).
    ...

review:
  cadence: quarterly
  last_review: 2026-08-15
  reviewer: ML Security Lead
```

**Requirements Article 9 puts on the file.**

- **Every foreseeable risk** to health, safety, and
  fundamental rights is listed. Skipping fundamental-rights
  risks because "it's a security team" is a nonconformity.
- **Intended use *and* foreseeable misuse** are both
  covered.
- **Residual risk is judged acceptable** by a named
  authority and reviewed. Unacceptable residual risk means
  the system cannot ship.
- **Iterative.** The file is versioned and revised at each
  material change or on cadence.
- **Testing** of risk-management measures is documented —
  the file references the eval artefacts (chapter 01
  MEASURE mapping).

**Cross-ref.** Article 9 aligns closely with NIST AI RMF
MAP + MEASURE + MANAGE (chapter 01) and with ISO 42001
Clauses 6.1.2 / 8.2 (chapter 02). The same underlying risk
register produces the artefacts for all three.

---

## Article 10 — Data and data governance

**What the Article requires.** Training, validation, and
testing datasets are subject to data-governance and data-
management practices. The datasets are relevant, sufficiently
representative, and to the best extent possible free of
errors and complete in view of the intended purpose. Datasets
have the appropriate statistical properties for the
population on which the system is intended to be used.
Datasets take into account, to the extent required by the
intended purpose, the characteristics of the specific
geographical, contextual, behavioural, or functional setting
within which the system is intended to be used.

Article 10(5) allows processing of **special categories** of
personal data (GDPR Article 9(1)) for the purpose of bias
detection and correction — subject to strict conditions:
strictly necessary, pseudonymisation applied, data not
transmitted to other parties, deletion after bias correction,
records of processing.

**Engineering artefact — the data-governance dossier.**

```yaml
# governance/ai-act/prod-cv-screener/data-governance.yaml
system: prod-cv-screener
version: 2026.09.01

datasets:
  training:
    id: cv-training-v3
    hash: sha256:...
    source_provenance: >
      Historical CVs 2019–2024 from partner ATS; consent
      captured via ATS ToS; retention basis GDPR Art. 6(1)(b)
      + Art. 9(2)(b).
    volume: 2.4M documents
    population_scope:
      geography: [DE, FR, ES, IT, NL, IE, PT, BE, PL]
      language: [de, fr, es, it, nl, en, pt, pl]
    representativeness_assessment:
      dimensions: [gender, age band, national origin, disability status]
      method: chi-square vs population priors from Eurostat 2023
      report: reports/representativeness-2026-08.md
      gaps_identified:
        - dimension: age band 60+
          gap: 4.1% training vs 12.3% eligible workforce
          remediation: over-sample; documented
    error_and_completeness_assessment:
      report: reports/data-quality-2026-08.md
      known_issues:
        - issue: "5.7% of CVs missing employer names"
          impact: filtered from training
    intended_use_alignment: >
      Population geographical scope matches the intended
      deployment (EU-9). Language scope covers 96% of
      deployment.

  validation:
    id: cv-validation-v3
    ...

  testing:
    id: cv-testing-v3
    ...

special_category_processing:
  present: true
  purpose: bias detection and correction (Art. 10(5))
  data_categories: [ethnic_origin_self_declared]
  conditions_met:
    strictly_necessary: yes
    pseudonymisation: yes
    other_parties_transmission: none
    deletion_after_use: 30 days after fairness report signed
    processing_record: gdpr/rop/cv-screener-bias-detection.md
  justification_document: reports/special-category-justification-2026-08.md
```

**Requirements Article 10 puts on the dossier.**

- **Provenance.** Where each dataset came from, with the
  legal basis for its use.
- **Representativeness.** Documented assessment of whether
  the dataset represents the intended-use population,
  including the *dimensions* considered.
- **Errors and completeness.** Documented assessment; known
  issues remain in the dossier even after mitigation.
- **Intended-use alignment.** Explicit statement that the
  dataset's population matches the intended deployment.
- **Special-category processing** (if applicable) satisfies
  every Article 10(5) condition; the justification is
  written.

**Cross-ref.** mod-104 (data and model lineage) owns the
technical apparatus that generates dataset hashes, provenance
records, and representativeness reports. This dossier is the
Article-10-shaped view of that apparatus.

---

## Article 11 + Annex IV — Technical documentation

Article 11 requires technical documentation *before* the
high-risk system is placed on the market. Annex IV lists the
minimum contents.

The Annex IV table of contents is long; the engineering
artefact is a **technical documentation dossier** whose
structure mirrors Annex IV verbatim. Sections include:

1. General description of the AI system (intended purpose,
   provider, versions, hardware, form of the system as put
   into service).
2. Detailed description of the elements and process for
   development (methods; steps; datasets; validation;
   metrics; foreseeable unintended outcomes).
3. Detailed information about monitoring, functioning, and
   control.
4. Description of the appropriateness of performance metrics
   for the specific system.
5. Detailed description of the risk-management system
   (Article 9).
6. Description of changes to the system after placement on
   the market.
7. List of harmonised standards applied.
8. Copy of the EU declaration of conformity (Article 47).
9. Detailed description of the system in operation, to allow
   monitoring by market surveillance.

**Engineering artefact.** `governance/ai-act/<system>/
technical-documentation/` with a section per Annex IV item.
Each section is either its own file or a pointer to the
canonical artefact (the model card for section 1; the risk-
management file for section 5; the fine-tuning report for
section 6).

The technical documentation dossier is what the market-
surveillance authority requests when they arrive.
Reproduction should be a `git archive` command, not a
scramble.

---

## Article 12 — Record-keeping (automatic logging)

**What the Article requires.** High-risk AI systems shall
technically allow for the automatic recording of events
(logs) over their lifetime, appropriate to the intended
purpose, and shall enable:

- Recording of events relevant to identifying situations
  that may result in risk (Article 79(1)) or lead to
  substantial modification (Article 3(23)).
- Post-market monitoring (Article 72).
- Monitoring of operation for high-risk systems used by law-
  enforcement / migration purposes.

Logs must be retained for a period appropriate to the
intended purpose — **at least 6 months** unless a different
period is required by EU or national law.

**Engineering artefact — the runtime logging spec.**

```yaml
# governance/ai-act/prod-cv-screener/logging-spec.yaml
system: prod-cv-screener

events_logged:
  - name: model_invocation
    fields: [request_id, timestamp, model_version, input_hash,
             output_summary, confidence, recruiter_id]
  - name: recruiter_override
    fields: [request_id, override_direction, reason_code, notes]
  - name: safety_flag_hit
    fields: [request_id, flag_name, action_taken]
  - name: model_deployment
    fields: [timestamp, model_version, deployer, rollout_percent]
  - name: model_rollback
    fields: [timestamp, from_version, to_version, reason]
  - name: dataset_update
    fields: [timestamp, dataset_id, from_hash, to_hash, approver]
  - name: substantial_modification
    fields: [timestamp, description, notification_authority,
             notification_ref]

retention:
  minimum: 12 months
  jurisdiction_notes: >
    Some Member States require longer retention for
    employment-related decisioning; verify per deployment.

integrity:
  storage: append-only object store; write-once bucket
  hash_chain: yes (per mod-104 lineage log)
  access_audit: yes (mod-105 auditable KMS grants)

availability_to_authorities:
  contact: dpo@example.com
  fulfillment_sla: 5 business days
```

The logging spec is version-controlled and referenced from
the risk-management file. The runtime enforces it (mod-103
observability layer). Missing logs at audit time is a
finding.

---

## Article 14 — Human oversight

**What the Article requires.** High-risk AI systems are
designed and developed to be effectively overseen by natural
persons during the period the AI system is in use. Human
oversight aims at preventing or minimising risks to health,
safety, or fundamental rights.

Design measures shall enable the natural persons to:

- (a) Properly understand the relevant capacities and
  limitations of the AI system and be able to monitor its
  operation (including automation bias awareness).
- (b) Remain aware of the possible tendency of automatically
  relying on output (automation bias).
- (c) Correctly interpret the output.
- (d) Decide not to use the output or otherwise disregard,
  override, or reverse it.
- (e) Intervene in the operation of the AI system or
  interrupt it (stop button).

For remote biometric identification systems (real-time or
post), additional constraints apply — no action or decision
based on the identification without verification and
confirmation by at least two natural persons.

**Engineering artefact — the human-oversight design record.**

```yaml
# governance/ai-act/prod-cv-screener/human-oversight.yaml
system: prod-cv-screener

oversight_role:
  title: Recruiter
  training:
    required: yes
    curriculum: training-lms/cv-screener-recruiter-v3
    covers:
      - system capabilities and limitations (Art. 14(4)(a))
      - automation-bias awareness (Art. 14(4)(b))
      - output interpretation (Art. 14(4)(c))
      - override policy (Art. 14(4)(d))
      - escalation and stop procedure (Art. 14(4)(e))
    completion_gate: recruiter cannot access UI without completion record
  interface_design:
    output_presentation:
      - score displayed with confidence band, not point value
      - top-3 explanation features shown per candidate
      - "system recommends X; decision remains with you" copy
    override_ergonomics:
      - override button first-class, not buried
      - override reason required from a coded list + free text
    stop_procedure:
      - "pause automated screening" toggle per requisition
      - visible to any recruiter with the requisition role
      - audit-logged (Art. 12)
  policy:
    override_target: >
      A recruiter is expected to consider every shortlisted
      candidate individually; the AI shortlist is an input,
      not a decision.
    escalation:
      - to Talent Lead if recruiter disagrees with shortlist
      - to DPO for suspected fairness issue

biometric_two_person_rule:
  applies: no
  rationale: not a remote biometric identification system
```

The human-oversight record is written *before* the UI ships.
Add-on human oversight after launch is a nonconformity —
Article 14 requires design-time oversight.

**Cross-ref.** mod-107 chapter 03 (agent tool ACLs and
HITL) implements the technical primitives — approval gates,
tool-use tiers, kill switches — that human oversight requires
for LLM/agent systems.

---

## Article 15 — Accuracy, robustness, and cybersecurity

**What the Article requires.** High-risk AI systems shall be
designed and developed to achieve, in the light of their
intended purpose, an appropriate level of accuracy,
robustness, and cybersecurity, and shall perform consistently
throughout their lifecycle. Levels of accuracy and the
relevant accuracy metrics shall be declared in the
instructions of use. The Commission shall encourage the
development of benchmarks and measurement methodologies.

Robustness shall be achieved through technical and
organisational measures. Systems shall be as resilient as
possible against errors, faults, or inconsistencies. Systems
that continue to learn after being placed on the market shall
be developed in such a way that possible biased outputs due
to outputs used as inputs (feedback loops) are duly
addressed.

Cybersecurity shall be resilient against attempts to alter
use, outputs, or performance by exploiting vulnerabilities.
Measures shall be appropriate to the relevant circumstances
and the risks. Measures shall include, where appropriate,
measures to prevent, detect, respond to, resolve, and control
attacks aiming at manipulating the training dataset (data
poisoning), pre-trained components (model poisoning), inputs
designed to cause the model to make errors (adversarial
examples or model evasion), confidentiality attacks, or model
flaws.

**Engineering artefact — the accuracy/robustness/cybersecurity
report.**

```yaml
# governance/ai-act/prod-cv-screener/arc-report.yaml
system: prod-cv-screener
model_version: v3.2

accuracy:
  primary_metric:
    name: recruiter_agreement_at_top_k
    value: 0.83
    ci_95: [0.81, 0.85]
    baseline: 0.71
    dataset: eval/cv-screener-benchmark-v3
  additional_metrics:
    - name: precision_at_top_5
      value: 0.79
    - name: rank_correlation_with_expert_panel
      value: 0.72
  declared_in_instructions_of_use: yes
  metric_appropriateness_argument: >
    Recruiter agreement at top-K captures the practical
    utility of the shortlist. Point-accuracy metrics like
    accuracy@1 are inappropriate for a ranking task; PR-AUC
    would misrepresent the recruiter workflow.

robustness:
  measures_taken:
    - name: adversarial_input_defence
      description: input length + character-class validation; adversarial-prompt classifier
      eval: eval/adversarial-cv-benchmark
      score: 0.94
    - name: drift_monitor
      description: population-drift monitor on incoming CVs; alerts on KL > 0.15
      config: monitoring/drift.yaml
    - name: feedback_loop_control
      description: recruiter override signal not used for online learning; retraining uses fresh labelled data only
      cross_ref: model card retraining policy

cybersecurity:
  threat_model_reference: threat-model.md
  measures:
    - category: prevent
      measures:
        - workload identity and mTLS on model service (mod-103 ch3)
        - training-pipeline supply-chain controls (mod-110)
        - training-data DLP + provenance verification (mod-104)
    - category: detect
      measures:
        - MI-AUC monitor on prediction API (mod-108 ch2)
        - anomaly-detection on query volume per caller
    - category: respond
      measures:
        - kill switch (Art. 14 stop + Art. 20 corrective action)
        - incident-response runbook `runbooks/cv-screener-incident.md`
    - category: resolve
      measures:
        - checkpoint rollback (mod-104 lineage)
        - dataset rebuild from provenance-verified sources
    - category: control (post-attack)
      measures:
        - post-market-monitoring plan (Art. 72)
```

The report is versioned per model release. Regressions on
declared metrics gate the release (chapter 04).

**Cross-ref.** mod-106 (adversarial ML defence) supplies the
underlying evals and defence techniques. Article 15's
cybersecurity clause is the *statutory* form of mod-106's
technical work.

---

## Article 17 — Quality management system

**What the Article requires.** Providers of high-risk AI
systems shall put a quality-management system (QMS) in place,
documented in written policies, procedures, and instructions,
covering — as a minimum — sixteen specific areas including
regulatory-compliance strategy, design controls, quality
control, data management, risk management, post-market
monitoring, communication with authorities, record-keeping,
and resource management.

**Engineering artefact.** The QMS is essentially an **ISO
42001 AIMS** (chapter 02). Article 17(2) accepts that the
QMS obligation is met by conformance to a relevant management
system standard (26 CFR-style equivalence via harmonised
standards process). An organisation with a 42001 AIMS in
place has the Article 17 QMS in place; the SoA extension
naming Article 17 as a cross-ref is the audit-side deliverable.

---

## Article 27 — Fundamental Rights Impact Assessment (FRIA)

**What the Article requires.** For high-risk systems referred
to in Article 6(2) (Annex III), deployers that are **public
authorities**, or **private entities providing public
services**, or **operators providing certain financial
services** (Annex III 5(b)–5(c)) shall perform an assessment
of the impact on fundamental rights that the use of the
system may produce. The assessment shall include:

- Description of the deployer's processes in which the AI
  system will be used.
- Period and frequency of use.
- Categories of natural persons and groups likely to be
  affected.
- Specific risks of harm likely to have an impact on
  affected persons or groups, taking into account information
  from the provider.
- Description of the implementation of human-oversight
  measures.
- Measures to be taken in case the risks materialise,
  including internal governance and complaint mechanisms.

**Engineering artefact.** `governance/ai-act/<system>/fria.md`.
Follows the Article-27 structure verbatim. Signed by the
deployer's DPO / AI-governance lead. Notified to the market-
surveillance authority (Article 27(3)) using the AI Office
template.

For deployers who are not covered by Article 27, the
equivalent engineering artefact is the ISO 42001 Clause 6.1.4
impact assessment (chapter 02) — same substance, different
notification obligation.

---

## Article 72 — Post-market monitoring

**What the Article requires.** Providers shall establish and
document a post-market monitoring system proportionate to the
nature of the AI technologies and the risks. The system shall
actively and systematically collect, document, and analyse
relevant data on the performance of the system throughout its
lifetime, in a manner that enables evaluation of continuous
compliance with Chapter III Section 2.

The Commission shall adopt an implementing act specifying
detailed provisions for the plan and template (Article 72(3);
the AI Office publishes the harmonised template).

**Engineering artefact — the post-market monitoring plan.**

```yaml
# governance/ai-act/prod-cv-screener/post-market-monitoring.yaml
system: prod-cv-screener

data_collection:
  performance_metrics:
    - name: recruiter_agreement_at_top_k
      frequency: monthly
      cohorted_by: [region, hiring_manager_seniority]
      alert_threshold: -0.03 vs baseline
    - name: override_rate
      frequency: monthly
      alert_threshold: > 0.20
  fairness_metrics:
    - name: shortlist_composition_by_gender
      frequency: monthly
      alert_threshold: statistical parity delta > 0.10 vs applicant pool
    - name: shortlist_composition_by_age_band
      frequency: monthly
  safety_metrics:
    - name: safety_classifier_hit_rate
      frequency: weekly
  operational_metrics:
    - name: uptime
    - name: latency_p95

feedback_channels:
  users:
    channel: in-product override reason
    volume_tracking: yes
  recruiters:
    channel: quarterly survey + incident escalation
  candidates:
    channel: contact form + statutory data-subject-request handling
  employee_representatives:
    channel: works-council briefing on system usage every 6 months

incident_reporting:
  serious_incident_definition: >
    Any incident meeting Article 3(49) definition;
    additionally, any complaint alleging discrimination
    upheld by the labour authority.
  serious_incident_report_route: >
    Article 73 notification to competent market-surveillance
    authority within 15 days; immediately if widespread or
    involving critical infrastructure.
  triage_owner: ML Security Lead

review_and_update:
  cadence: quarterly
  outputs:
    - update to risk-management (Art. 9)
    - update to technical documentation (Art. 11)
    - re-evaluation of accuracy claims (Art. 15)
```

Post-market monitoring is not an afterthought. Article 72
requires it *from the moment of placing on the market*.
Retrofitting is a nonconformity.

**Cross-ref.** mod-111 (security operations and IR for ML)
owns the runbooks, on-call, and severity ladder. Article 72
is the statutory framing for mod-111's ML-monitoring output.

---

## Article 73 — Serious incident reporting

**What the Article requires.** Providers shall report any
**serious incident** to the market-surveillance authorities
of the Member State where the incident occurred. Article
3(49) defines "serious incident" as any incident or
malfunctioning that directly or indirectly leads to:

- Death of a person or serious harm to a person's health.
- Serious and irreversible disruption of the management or
  operation of critical infrastructure.
- Infringement of obligations under EU law intended to
  protect fundamental rights.
- Serious harm to property or environment.

Notification within **15 days** of awareness (immediate for
widespread infringements or critical-infrastructure
disruption; 10 days for widespread; 2 days for death or
critical infrastructure).

**Engineering artefact.** The incident-response runbook
(mod-111) includes an Article 73 branch: on incident triage,
if the incident meets the serious-incident definition, a
notification is drafted from a template within 24 hours and
sent within the statutory clock.

---

## Extending the chapter 01 matrix

The EU AI Act extension slots into the unified matrix:

```yaml
- id: NIST-AI-RMF.MG-2.3
  function: MANAGE
  ...
  cross_refs:
    iso_42001:
      clauses: [9.1, 8.2]
    eu_ai_act:
      articles: [72, 12]
      annex_references: [Annex IV]
    generative_delta: >
      For GAI systems, monitoring adds jailbreak-attempt
      rate, safety-classifier hit rate, tool-abuse
      indicators (mod-107 chapter 04).
```

Every high-risk-system row will typically carry references
to *multiple* Articles. Article 9 (risk management) touches
almost every MAP/MEASURE row; Article 10 touches every data-
related row; Article 15 touches every eval and every
cybersecurity control.

---

## Timeline the artefacts have to survive

Application dates (from the Act's Article 113):

- **2 February 2025** — Chapters I and II (prohibited
  practices) apply.
- **2 August 2025** — Chapter V (general-purpose AI) and
  Chapter III Section 4 (notifying authorities) apply.
- **2 August 2026** — most provisions apply; high-risk
  Article 6(2) obligations for Annex III systems.
- **2 August 2027** — Article 6(1) high-risk (safety-
  component of harmonised-legislation products) applies.

**Existing systems**: high-risk systems placed on the market
before 2 August 2026 must comply with the Regulation by 2
August 2030 (Article 111), *unless* they undergo substantial
modifications after 2 August 2026, in which case immediate
compliance is required. The exception is narrower than it
looks: any material retraining, feature addition, or
architectural change likely counts as substantial
modification (Article 3(23)).

Engineering implication: **do not treat the delayed
enforcement date as a delayed engineering date**. Post-
market monitoring, technical documentation, and logging must
be in place *when the system starts producing evidence* — not
retroactively.

---

## Standard failure modes

- **Classification skipped.** No `ai-act-classification.md`.
  Fix: classification is a design-review artefact; missing
  it blocks release.
- **Annex IV documentation as a marketing document.** The
  file is written for lawyers, not for market surveillance;
  the sections do not track Annex IV's structure. Fix:
  Annex IV table of contents is the file's table of
  contents.
- **Article 10 dossier without a representativeness
  report.** Provenance is documented; representativeness is
  hand-waved. Fix: representativeness is a required
  section, with a named method and a dated report.
- **Special-category processing without justification.**
  The organisation ingested self-declared ethnicity data
  "just in case"; there is no Article 10(5) justification.
  Fix: SpC processing gate on data-ingest; the pipeline
  refuses SpC data without an approved justification.
- **Article 12 logs that don't include model version.** The
  logs exist but cannot be used to reconstruct which model
  version served which request. Fix: logging spec is
  reviewed against Article 12(2) requirements; model
  version, dataset hash, and safety-flag events all
  present.
- **Article 14 as a training slide only.** No stop button,
  no override ergonomics, no HITL structure. Fix: human-
  oversight design record is written before the UI; UI
  reviews trace to the record.
- **Article 15 accuracy metric that fits the model, not the
  intended purpose.** Fix: metric_appropriateness_argument
  is required; primary metric maps to the use-case
  behaviour, not the training loss.
- **FRIA collapsed into DPIA.** The Article 27 assessment
  is fundamental-rights-centric, broader than GDPR's
  Article 35 DPIA. Fix: FRIA follows the Article 27
  structure; DPIA is a section in the FRIA if applicable.
- **Post-market monitoring that starts at first incident.**
  Fix: PMM plan committed at first deployment; monitors
  live from day 1.
- **Serious-incident reporting clock missed.** Fix: on-call
  runbook has the 15-day (and shorter) clocks written in;
  incident tracker calculates elapsed time.
- **GPAI obligations conflated with deployer obligations.**
  Enterprise deployers of a GPAI model do not have GPAI-
  provider obligations; they *do* have obligations under
  Article 25 (obligations along the value chain) to convey
  necessary information to their deployers. Fix: read the
  role explicitly — provider vs deployer vs distributor vs
  importer — per Article 3 definitions, and act to that
  role.

---

## Summary

- The EU AI Act is a **binding, risk-based regulation**. The
  first engineering artefact is the *classification*, which
  determines everything else.
- High-risk systems ship with a *set* of documents named by
  the Act — **Article 9 risk management**, **Article 10 data
  governance**, **Article 11 + Annex IV technical
  documentation**, **Article 12 logging spec**, **Article 14
  human-oversight design record**, **Article 15
  accuracy/robustness/cybersecurity report**, **Article 72
  post-market monitoring plan** — and, where applicable, an
  **Article 27 FRIA** and **Article 17 QMS** (satisfied by a
  42001 AIMS).
- Every artefact is engineered, not lawyered: it points at
  the CI job, the runbook, the monitor, the checkpoint
  hash. The Act's structure is the *table of contents*;
  the platform's runtime and lineage systems produce the
  *content*.
- The unified control matrix gains an `eu_ai_act.articles`
  block per row. One row often maps to several Articles.
- **Serious-incident reporting** (Article 73) is on a
  short statutory clock — 15 days, 10 days, or 2 days
  depending on severity. The incident-response runbook has
  the clocks written in.
- Post-market monitoring, logging, and technical
  documentation must be in place **at first deployment**, not
  retroactively. Delayed enforcement dates are not delayed
  engineering dates.
