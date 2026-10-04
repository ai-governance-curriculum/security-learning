# Resources — mod-112-program-leadership-for-ml-security-governance

Primary sources for every claim in chapters 01-05 and the
five exercises. Prefer the official standard, the
regulator's text, the vendor's own documentation, and the
project's own site over secondary summaries. Programme-
leadership artefacts (control catalogues, SIEM content,
metrics methodology, incident-reporting rules) revise
frequently; verify versions, article numbers, clause
identifiers, and threshold definitions at time of reading.
Where a resource is behind a paywall (ISO, BSI, AICPA),
the primary text is the authoritative source; preview
material and official summaries are useful but not
substitutes for an engagement.

---

## Chapter 01 — Owning the AI-Security Control Library

### Control catalogues and management-system standards

- **NIST SP 800-53 Rev. 5 — Security and Privacy
  Controls for Information Systems and Organizations.**
  The parent federal catalogue AI-security controls
  frequently cross-reference.
  <https://csrc.nist.gov/pubs/sp/800/53/r5/upd1/final>
- **NIST SP 800-53B — Control Baselines.**
  <https://csrc.nist.gov/pubs/sp/800/53/b/upd1/final>
- **NIST AI RMF 1.0 (NIST AI 100-1).** The AI-specific
  risk-management framework whose sub-categories feed
  AI-security control mappings.
  <https://nvlpubs.nist.gov/nistpubs/ai/NIST.AI.100-1.pdf>
- **NIST AI RMF Generative AI Profile (NIST AI
  600-1).**
  <https://nvlpubs.nist.gov/nistpubs/ai/NIST.AI.600-1.pdf>
- **NIST AI RMF Playbook.**
  <https://airc.nist.gov/AI_RMF_Knowledge_Base/Playbook>
- **ISO/IEC 27001:2022 — Information security
  management systems.** The ISMS parent.
  <https://www.iso.org/standard/27001>
- **ISO/IEC 27002:2022 — Information security
  controls.** The code of practice supporting 27001.
  <https://www.iso.org/standard/75652.html>
- **ISO/IEC 42001:2023 — Artificial intelligence
  management system.** The certifiable AIMS standard
  whose Annex A controls the AI-security section cross-
  references.
  <https://www.iso.org/standard/81230.html>
- **ISO/IEC 23894:2023 — Guidance on AI risk
  management.**
  <https://www.iso.org/standard/77304.html>
- **AICPA — Trust Services Criteria** (SOC 2
  framework; purchased via AICPA).
  <https://www.aicpa-cima.com/resources/landing/system-and-organization-controls-soc-suite-of-services>
- **CIS Critical Security Controls v8.1.** A widely-
  adopted operational-control catalogue.
  <https://www.cisecurity.org/controls>
- **MITRE ATT&CK Enterprise Matrix.** The parent
  framework ATLAS mirrors.
  <https://attack.mitre.org/>
- **MITRE ATLAS — Adversarial Threat Landscape for
  AI Systems.** The ML-attack matrix controls bind to.
  <https://atlas.mitre.org/>

### GRC and policy-as-code platforms

- **Open Policy Agent (OPA).** The CNCF-graduated
  policy engine for policy-as-code bindings between
  the library and release-gates.
  <https://www.openpolicyagent.org/>
- **OPA Gatekeeper (Kubernetes admission).**
  <https://open-policy-agent.github.io/gatekeeper/>
- **Rego language reference.**
  <https://www.openpolicyagent.org/docs/policy-language/>
- **Conftest.** Policy testing for structured
  configuration.
  <https://www.conftest.dev/>
- **Kyverno.** Native Kubernetes policy management.
  <https://kyverno.io/>
- **CNCF TAG Security — Policy-as-code white paper.**
  <https://github.com/cncf/tag-security/tree/main/community/working-groups/policy>

### Evidence pipelines and immutable stores

- **Sigstore (cosign).** Signing primitives for
  evidence artefacts.
  <https://www.sigstore.dev/>
- **in-toto attestation framework.** Supply-chain
  attestation primitives applicable to evidence.
  <https://in-toto.io/>
- **AWS S3 Object Lock in Compliance Mode.** One
  implementation of immutable retention for evidence.
  <https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lock-overview.html>
- **Google Cloud Storage Retention Policies.**
  <https://cloud.google.com/storage/docs/bucket-lock>
- **Azure Blob Storage immutability policies.**
  <https://learn.microsoft.com/en-us/azure/storage/blobs/immutable-storage-overview>

### Framework crosswalks

- **NIST AI RMF published crosswalks** (to ISO/IEC
  42001, EO 14110, OECD AI Principles).
  <https://airc.nist.gov/AI_RMF_Knowledge_Base/Crosswalks>

---

## Chapter 02 — Sizing and Scoping an Engagement

### Asset inventory and threat enumeration primary sources

- **MITRE ATLAS techniques page.** Every top-N
  threat row cites a specific technique ID from here.
  <https://atlas.mitre.org/techniques>
- **MITRE ATLAS tactics overview.**
  <https://atlas.mitre.org/tactics>
- **OWASP Top 10 for Large Language Model
  Applications.** The LLM-specific risk list the
  engagement enumeration frequently references.
  <https://owasp.org/www-project-top-10-for-large-language-model-applications/>
- **OWASP Machine Learning Security Top 10.** The
  ML-system-level risk list.
  <https://owasp.org/www-project-machine-learning-security-top-10/>
- **OWASP AI Exchange.** Richer taxonomy and
  mitigations across the ML/AI surface.
  <https://owaspai.org/>

### Sector and authority threat sources

- **CISA — Secure AI System Development guidelines
  (co-authored with NCSC, international partners).**
  <https://www.cisa.gov/resources-tools/resources/guidelines-secure-ai-system-development>
- **NCSC (UK) — Guidelines for secure AI system
  development.**
  <https://www.ncsc.gov.uk/collection/guidelines-secure-ai-system-development>
- **ENISA — Securing Machine Learning Algorithms.**
  <https://www.enisa.europa.eu/publications/securing-machine-learning-algorithms>
- **FS-ISAC — AI-related guidance (membership).**
  <https://www.fsisac.com/>
- **Health-ISAC — AI-related guidance (membership).**
  <https://h-isac.org/>
- **AI Incident Database (AIID).** Public collection
  of real AI incidents for calibration.
  <https://incidentdatabase.ai/>
- **OECD AI Incidents Monitor (AIM).**
  <https://oecd.ai/en/incidents>

### Release-gate and policy enforcement

- **Open Policy Agent documentation (see Chapter
  01).**
- **in-toto / SLSA integration patterns (see
  Chapter 05 of this file).**
- **CNCF TAG Security — Software supply chain
  security best practices.**
  <https://github.com/cncf/tag-security/>

### Cost estimation and engagement management

- **NIST SP 800-115 — Technical Guide to Information
  Security Testing and Assessment.** General
  methodology that informs engagement-sizing
  discipline.
  <https://csrc.nist.gov/pubs/sp/800/115/final>
- **PMI — Project Management Body of Knowledge
  (PMBOK Guide).** General programme-management
  practice.
  <https://www.pmi.org/pmbok-guide-standards>

---

## Chapter 03 — CISO / Legal / AI Governance Interface

### Governance structure and RACI

- **ISO/IEC 42001:2023 Clause 5 — Leadership.** The
  management-system expectations on top-management
  commitment and roles.
  <https://www.iso.org/standard/81230.html>
- **ISO/IEC 38507:2022 — Governance implications of
  the use of AI by organizations.**
  <https://www.iso.org/standard/56641.html>
- **COBIT 2019 — ISACA governance framework.** The
  parent enterprise-IT-governance framework whose
  RACI patterns inform most ML-security interfaces.
  <https://www.isaca.org/resources/cobit>
- **COSO Enterprise Risk Management (ERM) —
  Integrating with Strategy and Performance.**
  <https://www.coso.org/guidance-erm>
- **IIA — Three Lines Model (Institute of Internal
  Auditors).** The first-line / second-line /
  third-line framing of security vs. risk vs. audit.
  <https://www.theiia.org/en/content/position-papers/>

### CISO function and board reporting

- **NIST Cybersecurity Framework (CSF) 2.0 — GOVERN
  Function.** Added in CSF 2.0; the governance
  function most CISOs operate against.
  <https://www.nist.gov/cyberframework>
- **ISACA — Reporting Cybersecurity Risks to the
  Board.**
  <https://www.isaca.org/>
- **NACD — Director's Handbook on Cyber-Risk
  Oversight.** Board-of-directors-facing guidance
  frequently referenced by CISO reporting designs.
  <https://www.nacdonline.org/>

### Legal and privacy counsel interface

- **IAPP — Resources on privacy / AI legal counsel
  working with technical teams.**
  <https://iapp.org/>
- **Sedona Conference — Guidance on cooperation,
  attorney-client privilege, and discovery issues.**
  <https://thesedonaconference.org/>
- **ACC — Association of Corporate Counsel
  resources.**
  <https://www.acc.com/>

### AI governance body patterns

- **Singapore IMDA / AI Verify Foundation —
  Governance toolkit and case studies.**
  <https://aiverifyfoundation.sg/>
- **Partnership on AI — Deployment governance
  resources.**
  <https://partnershiponai.org/>
- **OECD.AI — Responsible AI resources.**
  <https://oecd.ai/>

---

## Chapter 04 — ML-Security Metrics Package

### Metric methodology and SRE/security measurement

- **NIST SP 800-55 Rev. 2 — Measurement Guide for
  Information Security.**
  <https://csrc.nist.gov/pubs/sp/800/55/r2/final>
- **FIRST — Common Vulnerability Scoring System
  (CVSS) v3.1 / v4.0.** The parent severity scale
  for vulnerability burn-down mappings.
  <https://www.first.org/cvss/>
- **CISA — Stakeholder-Specific Vulnerability
  Categorization (SSVC).** Alternative prioritisation
  framework for vulnerability treatment.
  <https://www.cisa.gov/stakeholder-specific-vulnerability-categorization-ssvc>
- **Google — Site Reliability Engineering (SRE)
  book.** Chapters on service-level objectives and
  measurement discipline that generalise to security
  metrics.
  <https://sre.google/books/>

### Incident-response measurement (MTTD / MTTR)

- **NIST SP 800-61 Rev. 2 — Computer Security
  Incident Handling Guide.**
  <https://csrc.nist.gov/pubs/sp/800/61/r2/final>
- **NIST SP 800-61 Rev. 3 (draft) — Incident
  Response Recommendations and Considerations for
  Cybersecurity Risk Management.** The in-progress
  update; check for current status.
  <https://csrc.nist.gov/pubs/sp/800/61/r3/draft>
- **SANS Institute — Incident Handler's Handbook.**
  <https://www.sans.org/white-papers/>
- **ENISA — Reference Incident Classification
  Taxonomy.**
  <https://www.enisa.europa.eu/publications/reference-incident-classification-taxonomy>

### Supply-chain attainment (SLSA)

- **SLSA — Supply-chain Levels for Software
  Artifacts.**
  <https://slsa.dev/>
- **SLSA Specification v1.0.**
  <https://slsa.dev/spec/v1.0/>
- **in-toto attestation framework (see Chapter 01).**
- **Sigstore / cosign (see Chapter 01).**
- **CNCF TAG Security — Software Supply Chain
  Security Paper.**
  <https://github.com/cncf/tag-security/blob/main/supply-chain-security/supply-chain-security-paper/sscsp.md>

### ATLAS coverage reporting

- **MITRE ATLAS matrix and tactic/technique pages
  (see Chapter 02).**
- **MITRE ATT&CK Navigator.** The pattern many
  programmes adapt for ATLAS coverage visualisation.
  <https://mitre-attack.github.io/attack-navigator/>

### Board-level security reporting references

- **ISACA — IT Audit and Reporting resources.**
  <https://www.isaca.org/resources/isaca-journal>
- **IIA — Audit Executive Center and reporting
  guidance.**
  <https://www.theiia.org/en/content/>

---

## Chapter 05 — Regulator Support and Evidence Coordination

### US — HIPAA

- **45 CFR Part 164 Subpart C — HIPAA Security
  Rule.** Primary regulatory text (eCFR).
  <https://www.ecfr.gov/current/title-45/subtitle-A/subchapter-C/part-164/subpart-C>
- **45 CFR Part 164 Subpart D — HIPAA Breach
  Notification Rule.**
  <https://www.ecfr.gov/current/title-45/subtitle-A/subchapter-C/part-164/subpart-D>
- **HHS OCR — Breach Notification Rule overview and
  reporting portal.**
  <https://www.hhs.gov/hipaa/for-professionals/breach-notification/index.html>
- **HHS OCR — Risk Analysis Guidance.**
  <https://www.hhs.gov/hipaa/for-professionals/security/guidance/guidance-risk-analysis/index.html>
- **NIST SP 800-66 Rev. 2 — Implementing the HIPAA
  Security Rule.**
  <https://csrc.nist.gov/pubs/sp/800/66/r2/final>

### EU — AI Act, GDPR, DSA, NIS2

- **Regulation (EU) 2024/1689 — Artificial
  Intelligence Act (consolidated OJEU text).**
  <https://eur-lex.europa.eu/eli/reg/2024/1689/oj>
- **European Commission AI Office — official page.**
  <https://digital-strategy.ec.europa.eu/en/policies/ai-office>
- **Regulation (EU) 2016/679 — GDPR.**
  <https://eur-lex.europa.eu/eli/reg/2016/679/oj>
- **EDPB — Guidelines and opinions on AI, GDPR
  interaction.**
  <https://www.edpb.europa.eu/>
- **Directive (EU) 2022/2555 — NIS2 Directive.**
  <https://eur-lex.europa.eu/eli/dir/2022/2555/oj>

### US — Securities regulation and critical
infrastructure

- **US SEC — Cybersecurity Risk Management,
  Strategy, Governance, and Incident Disclosure
  Rule (17 CFR 229, 232, 239, 240, 249).** The
  "material cybersecurity incident" Form 8-K rule.
  <https://www.sec.gov/corpfin/announcement/cybersecurity-faq-management-strategy-governance>
- **CIRCIA — Cyber Incident Reporting for Critical
  Infrastructure Act of 2022 (CISA implementing
  rulemaking).** Verify current implementing-rule
  status.
  <https://www.cisa.gov/topics/cyber-threats-and-advisories/information-sharing/cyber-incident-reporting-critical-infrastructure-act-2022-circia>

### Financial-services model risk

- **Federal Reserve SR 11-7 / OCC 2011-12 / FDIC
  FIL-22-2017 — Supervisory Guidance on Model Risk
  Management.**
  <https://www.federalreserve.gov/supervisionreg/srletters/sr1107.htm>
- **OCC — Model Risk Management handbook / examiner
  guidance.**
  <https://www.occ.treas.gov/>
- **Bank of England — Prudential Regulation
  Authority — Model risk management principles.**
  <https://www.bankofengland.co.uk/prudential-regulation>

### Medical devices (FDA / EU MDR)

- **FDA — Good Machine Learning Practice for Medical
  Device Development (October 2021).**
  <https://www.fda.gov/medical-devices/software-medical-device-samd/good-machine-learning-practice-medical-device-development-guiding-principles>
- **FDA — Marketing Submission Recommendations for
  a Predetermined Change Control Plan for AI/ML-
  Enabled Device Software Functions (December 2024
  final guidance).**
  <https://www.fda.gov/regulatory-information/search-fda-guidance-documents/marketing-submission-recommendations-predetermined-change-control-plan-artificial>
- **FDA — AI/ML-Enabled Medical Devices list.**
  <https://www.fda.gov/medical-devices/software-medical-device-samd/artificial-intelligence-and-machine-learning-aiml-enabled-medical-devices>
- **IMDRF — SaMD framework series.**
  <https://www.imdrf.org/working-groups/software-medical-device-samd>
- **EU — Medical Device Regulation (EU) 2017/745
  (MDR) and IVDR 2017/746.**
  <https://eur-lex.europa.eu/eli/reg/2017/745/oj>

### Certification regimes

- **AICPA — SOC 2 and SSAE 18 attestation
  resources.**
  <https://www.aicpa-cima.com/resources/landing/system-and-organization-controls-soc-suite-of-services>
- **ISO/IEC 42001 certification body guidance
  (IAF MD 23:2024).**
  <https://iaf.nu/en/iaf-documents/>
- **HITRUST CSF.**
  <https://hitrustalliance.net/product-tool/hitrust-csf/>

### Litigation hold and e-discovery

- **Sedona Conference — Commentary on Legal Holds
  and Information Governance.**
  <https://thesedonaconference.org/>
- **The EDRM — Electronic Discovery Reference
  Model.**
  <https://edrm.net/>

### US state AI / privacy regimes (growing surface)

- **Colorado SB24-205 — Consumer Protections for
  Artificial Intelligence Act.**
  <https://leg.colorado.gov/bills/sb24-205>
- **California — AB-2013 (AI training-data
  transparency), SB-942 (AI content provenance),
  and related measures. Verify current status.**
  <https://leginfo.legislature.ca.gov/>
- **New York City — Local Law 144 (Automated
  Employment Decision Tools).**
  <https://www.nyc.gov/site/dca/about/automated-employment-decision-tools.page>

---

## Supporting frameworks and crosswalks

- **OECD — AI Principles.** Referenced by many
  national AI strategies and the EU AI Act preamble.
  <https://oecd.ai/en/ai-principles>
- **UNESCO — Recommendation on the Ethics of
  Artificial Intelligence.**
  <https://www.unesco.org/en/articles/recommendation-ethics-artificial-intelligence>
- **G7 — Hiroshima AI Process code of conduct and
  guiding principles.**
  <https://www.mofa.go.jp/ecm/ec/page5e_000076.html>

---

## Cross-module references within this curriculum

- **mod-101 — ML Security Governance Position.**
  Role boundaries this module's chapter 01 (control-
  library section ownership) and chapter 03 (sibling-
  function interface) build on.
- **mod-102 — Threat Modelling for AI/ML Systems.**
  Threat-model artefacts feed engagement scoping
  (chapter 02) and the standing evidence pack
  (chapter 05).
- **mod-103 — Secure ML Platform Architecture.**
  Platform primitives feed the asset-inventory data
  class in chapter 02.
- **mod-104 — Data and Model Lineage Security.**
  Model cards and lineage records feed the standing
  evidence pack (chapter 05) and the engagement
  inventory (chapter 02).
- **mod-105 — Secrets and Key Management.** KMS
  primitives feed the evidence-signing contract in
  chapter 01.
- **mod-106 — Adversarial ML Defence.** Robustness
  evals feed the AISEC-ADV cluster and chapter 02
  threat enumeration.
- **mod-107 — LLM / Agent Security.** HITL, tool-
  tier, retrieval-provenance controls feed the
  AISEC-LLM cluster.
- **mod-108 — Privacy Engineering for ML.** DP
  posture, DPIA, DLP artefacts feed the AISEC-PRIV
  cluster and chapter 05 evidence pack.
- **mod-109 — AI Governance & Compliance
  Engineering.** Policy-as-code pipeline is where
  this module's controls bind to the release-gate.
- **mod-110 — Supply-Chain Security for AI.**
  SLSA attainment, model-signing, ML-BOM feed
  chapter 04 metric family 4 and the AISEC-SC
  cluster.
- **mod-111 — Security Operations and Incident
  Response for ML.** ATLAS coverage map, IR
  playbooks, severity ladder feed chapter 04 metric
  families 2 and 3 and chapter 05 incident-response
  artefacts.

---

## Caveats

- NIST frameworks, ISO standards, EU regulations, US
  federal and state law, sector regulator guidance,
  and vendor platforms all evolve. Verify every
  citation at time of use.
- No link above substitutes for the organisation's
  General Counsel, CISO, Model Risk Officer, Chief
  Privacy Officer, Clinical Affairs lead, or an
  accredited certifier. This resource list is
  reading support; regulatory determinations and
  certification outcomes belong to accountable
  humans.
- Where a resource is behind a paywall (ISO, BSI,
  ANSI, AICPA, IEEE), the paywalled text is the
  authoritative one; previews and summaries on
  vendor sites are useful but non-authoritative.
- Nothing in this file or in the chapters is legal
  advice. The programme-lead's role is to supply
  evidence; counsel renders opinion.
