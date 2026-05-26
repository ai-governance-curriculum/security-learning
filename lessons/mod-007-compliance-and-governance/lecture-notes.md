# Module 07 — Compliance and Governance for ML Systems

> **Note on AI-assisted content.** Drafted with AI assistance and
> under human review. Regulatory specifics (article numbers,
> deadlines, dollar amounts) change. **Always verify against
> primary sources** (the regulation itself, your auditor, your
> legal counsel) before relying on any specific claim here.
> Nothing in this module is legal advice. See
> [`resources.md`](./resources.md).

---

## 1. The shape of compliance work

Compliance is the discipline of producing **evidence** that
your system satisfies a stated set of controls. Three properties
to internalize:

1. **Compliance is evidence-driven.** Controls without evidence
   of operation fail audits. Evidence without controls is
   theater.
2. **Compliance is continuous.** A snapshot at audit time is
   easier to fake and harder to trust. Continuous evidence
   collection is the modern standard.
3. **Compliance is not security.** Passing an audit and being
   secure are correlated, not equivalent. Many compliant systems
   are insecure; many secure systems are not formally compliant.

The job of the AI security engineer in compliance is **not** to
become a lawyer. It's to:
- Translate regulatory requirements into engineering controls.
- Instrument those controls so evidence is continuous.
- Communicate effectively with auditors, legal, customers.

### 1.1 The regulatory map

| Regulation | Triggered by | Owner |
|---|---|---|
| **GDPR** | Processing personal data of EU residents | EU |
| **CCPA / CPRA** | Processing personal data of CA residents | California |
| **HIPAA** | Handling US health information | US HHS |
| **SOC 2** | Customer demand; not a law | AICPA (private framework) |
| **EU AI Act** | High-risk AI systems in EU | EU |
| **NIST AI RMF** | US federal use; widely adopted voluntarily | NIST |
| **ISO 27001** | International information-security management | ISO |
| **ISO 42001** | AI-specific management systems | ISO (newer) |
| **PCI DSS** | Card payment processing | Payment Card Industry |
| **FedRAMP** | US federal cloud use | US GSA |

Each has its own triggering conditions, its own controls, and
its own evidence expectations. The first task in any compliance
engagement is identifying *which* apply.

### 1.2 The compliance engineer's playbook

1. **Identify applicable regulations** — what does your
   business legitimately need?
2. **Map regulations to engineering controls** — a control
   catalog tied to architecture decisions.
3. **Instrument evidence collection** — every control produces
   audit-grade evidence continuously.
4. **Establish audit preparation cadence** — quarterly or
   continuous.
5. **Maintain vendor / sub-processor records** — your supply
   chain is part of your compliance posture.
6. **Train the team** — controls live in operational practice,
   not just in documents.

---

## 2. GDPR for ML systems

The General Data Protection Regulation (Regulation (EU)
2016/679) applies to processing of personal data of EU residents.
Globally relevant because: many customers are EU; fines are
substantial (up to €20M or 4% of global revenue); the principles
have inspired similar laws elsewhere.

### 2.1 The principles (Article 5)

GDPR's six processing principles:

1. **Lawfulness, fairness, transparency** — you can name the
   legal basis; you tell people what you do.
2. **Purpose limitation** — collect for stated purposes; don't
   reuse for unstated ones.
3. **Data minimization** — collect only what you need.
4. **Accuracy** — keep data correct; rectify on request.
5. **Storage limitation** — don't keep data longer than needed.
6. **Integrity and confidentiality** — protect from
   unauthorized access.

ML systems strain all of these:
- **Purpose limitation**: a model trained for one purpose is
  often reused for another. Each new use is a purpose change
  triggering new consent / lawful basis analysis.
- **Data minimization**: ML loves data. The principle pushes
  back.
- **Storage limitation**: models can themselves encode the data
  they were trained on (membership inference, ML04).
- **Accuracy**: a model's prediction about a person is, under
  GDPR, "personal data about them." Inaccurate predictions
  trigger rectification rights.

### 2.2 Lawful bases (Article 6)

Processing requires a lawful basis. The six:

| Basis | When applicable | Examples |
|---|---|---|
| **Consent** | Individual freely consents | Marketing emails, optional personalization |
| **Contract** | Necessary to perform a contract with the data subject | Order processing |
| **Legal obligation** | Required by law | Tax records |
| **Vital interests** | Protecting someone's life | Emergency medical |
| **Public task** | Public interest tasks | Public-sector use |
| **Legitimate interests** | Balanced against subject's rights | Fraud detection (often) |

For ML systems, **consent** and **legitimate interests** are
the most common. Both have constraints: consent must be
freely given (a bundled "agree to everything" doesn't count);
legitimate interests requires a balancing assessment that
documents the tradeoff.

### 2.3 Subject rights (Articles 12-22)

The rights every data subject has:

- **Right to access (Art 15)** — tell me what you have.
- **Right to rectification (Art 16)** — fix incorrect data.
- **Right to erasure / "right to be forgotten" (Art 17)** —
  delete my data.
- **Right to restrict processing (Art 18)** — stop using my
  data without deleting it.
- **Right to data portability (Art 20)** — give me a portable
  copy.
- **Right to object (Art 21)** — stop processing for stated
  purposes (especially direct marketing).
- **Right not to be subject to automated decision-making (Art 22)**
  — if a decision is automated and significantly affects the
  subject, they have rights to human intervention and
  explanation.

**Article 22** is the article that affects ML systems most
directly. If your model makes decisions that significantly
affect people (credit, employment, insurance), GDPR gives
subjects rights to:
- Know that automated decision-making is happening.
- Receive an explanation of the logic involved.
- Contest the decision and get human review.

### 2.4 What this means for ML architecture

To satisfy GDPR for an ML system, you need:

- **Lawful basis recorded** for every training dataset and
  every processing operation.
- **Subject-request handlers** for access, rectification,
  erasure, portability, restriction, objection. Module 03's
  hash chain audit-log is the substrate; the subject-request
  API (Module 03's Project 4 governance) is the implementation.
- **Erasure that actually erases.** This is the hard part for
  ML — deleting a training record doesn't remove its influence
  on the trained model. Practical compliance interpretations
  vary; some accept that retraining is sufficient.
- **Article 22 controls** for automated significant decisions:
  notification, explanation, human-review channel.
- **Data Protection Impact Assessment (DPIA)** for high-risk
  processing (Article 35). Most ML deployments processing
  personal data trigger DPIA.

### 2.5 Cross-border transfer

GDPR restricts transferring personal data outside the EU
unless adequate safeguards exist. The mechanisms:

- **Adequacy decisions** — some countries are deemed adequate
  by the European Commission (UK, Japan, Korea, etc.).
- **Standard Contractual Clauses (SCCs)** — contractual
  protections approved by the Commission.
- **Binding Corporate Rules (BCRs)** — internal corporate
  policies for multinational groups.
- **Derogations** — narrow exceptions for specific cases.

After the *Schrems II* ruling (2020), transfers to the US use
the Data Privacy Framework (DPF) or SCCs with additional
safeguards (encryption, supplementary measures). The landscape
shifts; verify with counsel.

### 2.6 Breach notification (Article 33-34)

If personal data is breached:
- Notify the supervisory authority **within 72 hours** unless
  the breach is unlikely to result in risk.
- Notify affected subjects "without undue delay" if high risk.

For ML systems, "breach" includes scenarios like:
- A trained model that leaks training data via inversion is
  exposed.
- A poisoning attack changes model behavior in a way that
  produces incorrect personal data.
- Unauthorized access to a feature store containing PII.

The 72-hour clock starts when you become aware. Detection
mechanisms (Modules 08, 11) determine when that is.

---

## 3. HIPAA for ML systems

The Health Insurance Portability and Accountability Act (US,
1996) regulates handling of protected health information (PHI).
Relevant for ML systems that touch healthcare data — increasingly
many.

### 3.1 The two relevant rules

- **Privacy Rule** (45 CFR Part 164 Subpart E): how PHI can be
  used and disclosed.
- **Security Rule** (45 CFR Part 164 Subpart C): how PHI must be
  technically and administratively protected.

The Security Rule's **technical safeguards** are the engineering
ones:

| Safeguard | Requirement | ML implementation |
|---|---|---|
| Access control | Unique user IDs, automatic logoff, encryption/decryption | Workload identity (Module 02), session timeouts |
| Audit controls | Hardware/software/procedural mechanisms recording activity | Hash-chain audit log (Module 03) |
| Integrity | Authentication of ePHI | Signing (Module 03), integrity monitoring |
| Person/entity authentication | Verify identity | OIDC + MFA for humans, workload identity for systems |
| Transmission security | Integrity + encryption in transit | mTLS (Modules 02, 04) |

The Security Rule is **flexible** — you choose the implementation
that satisfies the requirement. There is no certified product
list; you produce an analysis showing why your controls satisfy
the requirements.

### 3.2 Business Associate Agreements (BAAs)

Anyone you give PHI to is a **Business Associate**. They sign a
BAA agreeing to HIPAA terms.

For ML systems:
- Your **cloud provider** must sign a BAA. AWS, GCP, Azure all
  offer them; you must explicitly request it and follow their
  HIPAA-eligible-service list.
- Your **ML vendor** (LLM provider, observability vendor) needs
  a BAA before you send them PHI. OpenAI offers BAAs for
  enterprise tiers; Anthropic offers BAAs for enterprise tiers.
- **You as a vendor** — if you process PHI for customers, you
  sign BAAs with them.

The BAA is a contractual control. Engineering enforces it via
the technical controls (encryption, audit, access control).

### 3.3 ML-specific HIPAA concerns

- **De-identification**. HIPAA defines two methods: Safe Harbor
  (remove 18 specified identifiers) and Expert Determination (a
  qualified statistician certifies the de-identification is
  effective). De-identified data is no longer PHI.
- **Re-identification risk**. If de-identified data, when
  combined with other data, identifies someone, you've
  effectively re-identified them. Models trained on
  de-identified data may still leak via membership inference.
- **Minimum necessary**. Use only the PHI necessary for the
  purpose. ML's data appetite strains this.

### 3.4 Breach notification

HIPAA requires:
- Notification within **60 days** of discovery for breaches
  affecting >500 individuals.
- Notification to HHS for any breach.
- Notification to affected individuals "without unreasonable
  delay."

(Note: HIPAA's 60 days vs. GDPR's 72 hours — different
timelines for different jurisdictions. A multi-jurisdictional
incident triggers all the applicable clocks simultaneously.)

---

## 4. SOC 2

SOC 2 is a **private compliance framework** maintained by the
AICPA. It's not a law; it's a customer-driven framework. Many
B2B SaaS customers refuse to buy from vendors without SOC 2.

### 4.1 The Trust Services Criteria

SOC 2 audits against five Trust Services Criteria:

1. **Security** — protection of system resources. Mandatory
   for any SOC 2.
2. **Availability** — system is available for operation.
3. **Processing integrity** — processing is complete, valid,
   accurate, timely, authorized.
4. **Confidentiality** — confidential info is protected.
5. **Privacy** — personal information is handled per the
   Privacy Notice.

The **Security** criterion is required; the others are added
based on what you commit to and what customers care about.

### 4.2 Type 1 vs. Type 2

- **Type 1**: an attestation of controls in place at a point in
  time.
- **Type 2**: an attestation of controls operating effectively
  over a period (typically 6-12 months).

Most enterprise customers want Type 2. Type 2 means evidence
across the audit period, not just at the audit moment.

### 4.3 What a SOC 2 audit actually looks like

The auditor (a CPA firm) reviews:

- **Policies** — written documents stating what you do.
- **Controls** — operational mechanisms that implement the
  policies.
- **Evidence** — proof the controls operated.

For each control, they sample evidence across the audit period.
A typical Type 2 audit:

- 6-12 months of evidence collection.
- 2-4 weeks of auditor on-site / on-call work.
- The Statement of Applicability (which controls in scope).
- The System Description (what the system does).
- The Management Assertion (you state what you did).
- The auditor's Report.

### 4.4 Common controls (illustrative, not exhaustive)

Security:
- Background checks for hires with sensitive access.
- Documented onboarding/offboarding for access management.
- Encryption at rest + in transit.
- Logging and monitoring.
- Change management (PR review, deploy approvals).
- Incident response plan + rehearsal evidence.
- Penetration testing or equivalent.
- Risk assessment (annual at minimum).
- Vendor risk reviews.

Confidentiality:
- Data classification (public / internal / confidential /
  restricted).
- Access controls keyed to classification.
- Retention policies enforced.

Each control needs **evidence of operation** across the period.
A policy that says "we do X" without logs of X happening fails.

### 4.5 ML-specific SOC 2 considerations

- **Model registry as a change-management surface**: each model
  promotion needs approval evidence.
- **Training data classification**: regulated data classes need
  the right access controls.
- **Output monitoring**: production model behavior is part of
  the "processing integrity" attestation.
- **Vendor risk for LLM providers**: each external model API
  is a sub-processor.

---

## 5. EU AI Act

Regulation (EU) 2024/1689. The first comprehensive AI-specific
law. Phased timeline; verify current dates with counsel.

### 5.1 The risk-based structure

The AI Act categorizes AI systems by risk:

1. **Prohibited** — banned outright (social scoring, real-time
   biometric surveillance with narrow exceptions, exploiting
   vulnerable groups).
2. **High-risk** — heavy obligations (Article 6 + Annex III).
   Examples: critical infrastructure, education, employment,
   credit scoring, law enforcement, justice.
3. **Limited risk** — transparency obligations (chatbots,
   deepfakes).
4. **Minimal risk** — most AI; no specific obligations.

The classification matters: high-risk systems require:

- A Quality Management System.
- Conformity assessment before market.
- Technical documentation.
- Risk management throughout the lifecycle.
- Data governance (training data quality, bias mitigation).
- Logging.
- Transparency (system documentation).
- Human oversight.
- Accuracy, robustness, cybersecurity.

### 5.2 Article 15 — accuracy, robustness, cybersecurity

The article that connects directly to this curriculum.
High-risk systems must:

- Have accuracy levels appropriate to their purpose, declared
  in documentation.
- Be resilient against errors, faults, inconsistencies, and
  adversarial attacks.
- Have cybersecurity controls protecting against unauthorized
  alteration.

Modules 04-06 of this track produce many of the controls Article
15 envisions. The compliance work is documenting that they're in
place.

### 5.3 General-Purpose AI (GPAI) obligations

Foundation models / general-purpose AI systems have specific
obligations beyond the risk classification:

- Documentation of training data.
- Compliance with EU copyright (training data sources).
- Cybersecurity evaluation.
- Energy consumption disclosure.
- For "systemic risk" GPAI (very large models): additional
  obligations including red-teaming, incident reporting.

### 5.4 Timeline (verify current dates)

- **6 months after entry into force**: prohibited AI bans take
  effect.
- **12 months**: GPAI obligations apply.
- **24 months**: high-risk AI obligations apply.
- **36 months**: high-risk AI in regulated sectors.

If you're building anything that might be classified high-risk,
the planning starts now. Compliance work takes longer than
engineering work.

---

## 6. ISO 27001 and ISO 42001

International management-system standards.

### 6.1 ISO 27001 — Information Security Management System

ISO/IEC 27001:2022. The international counterpart of SOC 2, with
different emphasis: more management-system, less attestation-of-
controls.

Certification involves:
- An ISMS scope and policy.
- Risk assessment and treatment.
- Statement of Applicability (which Annex A controls apply).
- Management review.
- Internal audits.
- External certification audit.

ISO 27001 is more common outside the US; SOC 2 is more common
in the US. Many companies do both because customer requirements
vary by region.

### 6.2 ISO 42001 — AI Management System

ISO/IEC 42001:2023. The newer AI-specific standard. Defines an
AI Management System (AIMS) — analogous to ISMS but for AI.

Notable elements:
- AI risk identification and treatment.
- AI impact assessments.
- Data governance for AI training.
- Resource management (compute, data, models).
- Lifecycle controls (training → deployment → monitoring →
  decommission).

Adoption is early; if you build to ISO 42001 today, you're
ahead of most peers. The framework will likely become a
default within a few years.

---

## 7. NIST AI Risk Management Framework

NIST AI RMF 1.0 (2023) is the US baseline for AI risk
management. Not a law, but referenced by other US regulations
and standards.

### 7.1 The four functions

The AI RMF organizes work into four functions:

1. **Govern** — institutional policies, roles, processes.
2. **Map** — categorize AI systems and risks.
3. **Measure** — quantitative risk metrics (accuracy, bias,
   robustness, etc.).
4. **Manage** — risk treatment, monitoring, response.

Each function has subcategories with specific actions.

### 7.2 Why it matters

NIST AI RMF is the **vocabulary** much of the US regulatory
landscape uses. EU AI Act maps to it. SOC 2 increasingly maps
to it. ISO 42001 has overlap with it.

Engineers don't usually need to read AI RMF cover-to-cover.
Knowing it exists and what the four functions are is sufficient
for most compliance conversations.

---

## 8. Audit-chain integration

The hash-chain audit log (Module 03 §8) is the compliance
substrate.

### 8.1 What goes in the chain

For compliance purposes, the audit chain records:

- **Subject requests** (access, rectification, erasure,
  portability).
- **Model promotions** (with the approval signature).
- **Configuration changes** (policy changes, network policy
  changes).
- **Authentication events** (especially failed ones and
  privileged ones).
- **Data access** (especially to regulated classes).
- **Security incidents** (with timeline, severity,
  remediation).
- **Vendor changes** (when a new sub-processor is added).

Each entry is signed by the producing workload's identity.
Each entry's hash includes the previous entry's hash. The
chain is anchored periodically to an external timestamp
service.

### 8.2 Per-regulation evidence packs

A defensible compliance posture produces, on a schedule:

- **Quarterly GDPR pack**: subject requests processed,
  consent updates, breach incidents, DPIAs in progress.
- **Quarterly HIPAA pack**: BAAs in place, access reviews,
  PHI breach incidents.
- **Annual SOC 2 evidence**: per-control evidence sampled
  across the year.
- **EU AI Act technical documentation**: kept current as
  high-risk systems evolve.

The audit chain is the source. The packs are derived views.

### 8.3 Producing for the auditor

When the audit happens, the team:

- Provides the relevant evidence pack(s).
- Demonstrates control operation with sampled examples.
- Walks through the architecture and the audit chain.
- Answers control-by-control questions.

If the team has been producing the packs continuously, the
audit is a review of existing artifacts. If not, the audit
becomes a panic.

---

## 9. Compliance automation

The shift from "audit panic week" to "evidence is continuous"
is the work of automation.

### 9.1 Continuous control monitoring

For each control, automated checks confirm operation:

- **Encryption in transit**: TLS scan against every service.
- **Encryption at rest**: KMS access log review.
- **Access controls**: IAM policy diffs vs. baseline.
- **Logging**: presence of audit-log entries from every
  production service.
- **Patching**: image vulnerability scan results.
- **Backup**: backup completion status.

Tools: Drata, Vanta, Secureframe (vendor-managed); or
self-built with rego policies + a job that runs and posts
results.

### 9.2 Continuous control attestation

Each control's evidence stream feeds an attestation:

- "TLS 1.3 is enforced on all external endpoints" (evidence:
  weekly TLS scans).
- "Access reviews happen quarterly" (evidence: scheduled jobs
  + reviewer sign-off in the audit chain).
- "Model promotion requires approval" (evidence: model
  registry events + signature).

The attestation is a queryable artifact; the underlying
evidence is the audit chain.

### 9.3 What can't (easily) be automated

- **Risk assessments** — judgment calls about applicability,
  severity, likelihood.
- **Vendor risk reviews** — reading SOC 2 reports, asking
  follow-up questions, judging adequacy.
- **Training records** — onboarding, compliance training.
- **Penetration testing** — periodic, scheduled, third-party.
- **Incident response rehearsals** — tabletops.

These require humans on a cadence.

---

## 10. Vendor risk

Your supply chain is part of your compliance posture.

### 10.1 The categories

| Vendor type | Examples | Compliance touch |
|---|---|---|
| **Cloud provider** | AWS, GCP, Azure | BAA, DPA, sub-processor of regulated data |
| **Foundation model API** | OpenAI, Anthropic, Cohere | Data flow; BAA if PHI; DPA if EU personal data |
| **Observability** | Datadog, Honeycomb, New Relic | Logs may contain regulated data |
| **Identity / SSO** | Okta, Auth0 | Authentication on regulated assets |
| **CI/CD platform** | GitHub Actions, GitLab | Pipeline access to production systems |
| **Storage / messaging** | S3, Kafka-as-a-service | Possibly regulated data at rest |

For each vendor:
- Is regulated data flowing to them? (If yes, contract terms
  required.)
- What evidence do they provide (SOC 2 report, ISO cert)?
- Are they in your DPF / SCC chain (for GDPR)?
- What's the dependency-failure plan?

### 10.2 Vendor review cadence

A defensible cadence:

- **At onboarding**: full review of their compliance posture,
  contract terms, sub-processors.
- **Annually**: confirm SOC 2 / ISO is renewed, review
  sub-processor list for changes, refresh contract terms if
  needed.
- **On incident**: if the vendor has a security incident, review
  blast radius for your data.

### 10.3 Sub-processor lists

Some regulations (GDPR, HIPAA) require maintaining lists of
sub-processors and notifying customers when sub-processors
change.

Maintain:
- **The list itself** — every vendor that processes regulated
  data on your behalf.
- **Notification process** — how customers learn about
  changes.
- **Contract terms** — that allow the sub-processor relationship.

---

## 11. The "compliance ≠ security" tension

A theme worth repeating. The tension between compliance and
security shows up most often in three patterns:

### 11.1 Over-investing in checkbox controls

A control catalog says "encryption in transit." Your team
implements TLS 1.2 because that's what the standard says.
TLS 1.0 is still enabled because nobody told you to disable it.
Compliance passes; security suffers.

Mitigation: implement controls that satisfy *current security
posture*, not minimum compliance. Document deviations from
common interpretations and why your interpretation is stronger.

### 11.2 Under-investing in non-compliance security work

Adversarial-input defense isn't a compliance requirement under
most frameworks. Module 06's controls aren't on any audit
checklist. A team optimizing only for compliance may de-prioritize
them.

Mitigation: keep a separate security backlog. Don't let the
compliance roadmap define the security roadmap.

### 11.3 Compliance theater

"We have SOC 2." Implied: "therefore we're secure." Reality:
SOC 2 attests to control operation; it doesn't guarantee the
controls were *the right ones*.

Mitigation: don't let compliance claims replace honest threat
modeling.

---

## 12. The role of the AI security engineer in compliance

In a typical org:

- **Legal / Compliance** owns the regulatory interpretation
  and the audit relationships.
- **Engineering** owns the controls.
- **Security** owns the threat-to-control mapping and the
  evidence pipeline.

The AI security engineer is the bridge:

- Translating regulatory text into engineering specs.
- Designing the controls that satisfy the spec.
- Instrumenting the controls so evidence is continuous.
- Speaking the language of both engineering and compliance to
  resolve disputes.

The role is heavy on **writing**: control narratives,
compliance evidence narratives, audit responses, risk
analyses.

---

## 13. What you should be able to do after this module

- [ ] Identify which regulations apply to a given ML system
      based on its data, users, deployment, customer mix.
- [ ] Map GDPR subject rights to engineering controls in the
      ML platform.
- [ ] Read a HIPAA Security Rule technical safeguard and design
      the engineering control that satisfies it.
- [ ] Assess SOC 2 Type 2 readiness: gap-list controls and
      identify evidence requirements per control.
- [ ] Categorize an AI system under the EU AI Act risk tiers
      and identify obligations.
- [ ] Design the audit-chain entries for a given control to
      produce continuous evidence.
- [ ] Conduct a vendor risk review.
- [ ] Explain to a non-engineer why "we have SOC 2" is not
      the same as "we are secure."

---

## 14. What this module deliberately doesn't cover

- **Legal advice.** Always engage counsel for regulatory
  interpretation in your specific context.
- **Industry-specific frameworks** (FedRAMP, PCI DSS,
  industry-specific HIPAA-equivalents in other countries) —
  the patterns transfer but the specifics differ.
- **Detailed implementation of audit-chain or governance code**
  — that's covered in [`projects/project-2-compliance/`](../../projects/project-2-compliance/)
  and in [`mlops-learning/projects/project-4-governance/`](https://github.com/ai-infra-curriculum/ai-infra-mlops-learning/tree/main/projects/project-4-governance).

---

## 15. Suggested reading order

After this:

1. Skim the GDPR's [Articles 5-22](https://gdpr-info.eu/).
2. Skim the [NIST AI RMF 1.0](https://www.nist.gov/itl/ai-risk-management-framework).
3. Read at least the abstract of the [EU AI Act](https://eur-lex.europa.eu/eli/reg/2024/1689/oj).
4. Move to **Module 08: Runtime Security**.

---

## Appendix A — Glossary

- **AICPA**: American Institute of Certified Public Accountants
  (maintains SOC 2).
- **BAA**: Business Associate Agreement (HIPAA contract).
- **CCPA / CPRA**: California Consumer Privacy Act / California
  Privacy Rights Act.
- **DPA**: Data Processing Agreement (GDPR contract).
- **DPF**: Data Privacy Framework (US-EU transfer mechanism).
- **DPIA**: Data Protection Impact Assessment (GDPR).
- **ePHI**: electronic Protected Health Information (HIPAA).
- **GDPR**: General Data Protection Regulation (EU).
- **HIPAA**: Health Insurance Portability and Accountability Act (US).
- **ISMS**: Information Security Management System (ISO 27001).
- **AIMS**: AI Management System (ISO 42001).
- **NIST AI RMF**: NIST AI Risk Management Framework.
- **PHI**: Protected Health Information (HIPAA).
- **SCC**: Standard Contractual Clauses (GDPR transfer mechanism).
- **SOC 2**: Service Organization Control 2 (AICPA framework).
- **Sub-processor**: a vendor your processor uses to perform
  the processing on your behalf.

---

## Appendix B — Common misconceptions

| Misconception | Reality |
|---|---|
| "SOC 2 means we're secure." | SOC 2 means the controls described in your description operated as described. The controls may not be the right ones. |
| "GDPR doesn't apply because we're US-based." | If you process EU residents' data, GDPR applies regardless of where you are. |
| "We anonymized the data, so it's no longer personal data." | Effective anonymization is hard. Many "anonymized" datasets are re-identifiable in combination with other data. |
| "We have ISO 27001, so we have GDPR." | ISO 27001 is information security management; GDPR is data protection. Overlapping but not equivalent. |
| "Compliance work doesn't affect security." | Done well, compliance forces evidence collection that improves security. Done badly, it diverts resources to checkbox work. |
| "We don't process personal data; GDPR doesn't apply." | IP addresses are personal data. So are user IDs in many cases. Check the definition. |
| "We're not high-risk under the AI Act because we're not in a regulated sector." | The high-risk classification is by use case, not sector. Hiring tools, credit scoring, education are high-risk regardless of sector. |

---

*Continue to the [exercises](./exercises/) when you're ready.*
