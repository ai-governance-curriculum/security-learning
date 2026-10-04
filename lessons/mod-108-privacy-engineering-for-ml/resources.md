# Resources — mod-108-privacy-engineering-for-ml

Primary sources for every claim in chapters 01–05 and the five
exercises. Prefer the official standard, the regulator's text,
the author's preprint on arXiv, and the project's own
documentation over secondary summaries. Privacy standards,
regulator guidance, and library APIs move quickly; verify
versions, article numbers, and recogniser catalogues at time of
reading.

---

## Standards, regulations, and official guidance

### GDPR and EEA / UK supervisory authorities

- **Regulation (EU) 2016/679 — General Data Protection
  Regulation.** The consolidated OJEU text is the primary
  source. Articles 5, 6, 9, 15, 22, 25, 32, 33, 34, 35, 36,
  and Recitals 71–72 are the ones chapters 01 and 04 depend
  on.
  <https://eur-lex.europa.eu/eli/reg/2016/679/oj>
- **European Data Protection Board — Guidelines on Automated
  individual decision-making and Profiling for the purposes of
  Regulation 2016/679 (wp251rev.01, endorsed by the EDPB).**
  The reference for what "solely automated" and "meaningful
  information about the logic involved" mean in practice.
  <https://ec.europa.eu/newsroom/article29/items/612053/en>
- **EDPB — Guidelines 4/2019 on Article 25 Data Protection by
  Design and by Default.**
  <https://www.edpb.europa.eu/our-work-tools/our-documents/guidelines/guidelines-42019-article-25-data-protection-design-and_en>
- **Article 29 Working Party / EDPB — Guidelines on Data
  Protection Impact Assessment (DPIA) (wp248rev.01).**
  <https://ec.europa.eu/newsroom/article29/items/611236/en>
- **UK ICO — Guidance on AI and data protection.** Includes
  explainability, DPIA templates for AI, and the UK ICO's
  position on automated decisions post-UK GDPR.
  <https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/artificial-intelligence/guidance-on-ai-and-data-protection/>
- **UK ICO — Sample DPIA template.**
  <https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/accountability-and-governance/data-protection-impact-assessments-dpias/>
- **UK ICO + The Alan Turing Institute — *Explaining decisions
  made with AI*.** The practical reference for Article 22
  explanation methods and subject-facing language.
  <https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/artificial-intelligence/explaining-decisions-made-with-ai/>
- **CNIL — AI and GDPR dossier.** The French supervisory
  authority's engineering-oriented AI guidance.
  <https://www.cnil.fr/en/artificial-intelligence>
- **CNIL — PIA (DPIA) software and knowledge base.**
  <https://www.cnil.fr/en/privacy-impact-assessment-pia>

### HIPAA, HHS OCR, and US-federal

- **45 CFR Part 164 Subpart C — HIPAA Security Rule (§§
  164.302–318).** The regulatory text itself; eCFR is the
  authoritative live source.
  <https://www.ecfr.gov/current/title-45/subtitle-A/subchapter-C/part-164/subpart-C>
- **45 CFR Part 164 Subpart D — Breach Notification Rule
  (§§ 164.400–414).**
  <https://www.ecfr.gov/current/title-45/subtitle-A/subchapter-C/part-164/subpart-D>
- **45 CFR Part 164 Subpart E — Privacy Rule.** The
  minimum-necessary standard (§164.502(b)), designated-record-
  set (§164.501), and the de-identification safe harbor /
  expert determination (§164.514).
  <https://www.ecfr.gov/current/title-45/subtitle-A/subchapter-C/part-164/subpart-E>
- **HHS OCR — HIPAA Security Rule guidance material and
  "Summary of the Security Rule".**
  <https://www.hhs.gov/hipaa/for-professionals/security/guidance/index.html>
- **HHS OCR — Guidance on Risk Analysis Requirements under
  the HIPAA Security Rule.** The reference for
  §164.308(a)(1)(ii)(A) risk-analysis expectations.
  <https://www.hhs.gov/hipaa/for-professionals/security/guidance/guidance-risk-analysis/index.html>
- **HHS OCR — Guidance Regarding Methods for De-identification
  of Protected Health Information in Accordance with HIPAA.**
  Safe Harbor and Expert Determination.
  <https://www.hhs.gov/hipaa/for-professionals/privacy/special-topics/de-identification/index.html>
- **HHS OCR — Breach Portal ("Wall of Shame").** Current and
  historical breach notifications affecting 500+; useful
  calibration reference.
  <https://ocrportal.hhs.gov/ocr/breach/breach_report.jsf>
- **HHS OCR — Enforcement Highlights.** OCR resolution
  agreements; the exercise-05 stretch goal reads from this.
  <https://www.hhs.gov/hipaa/for-professionals/compliance-enforcement/examples/index.html>
- **NIST SP 800-66 Rev. 2 — Implementing the Health Insurance
  Portability and Accountability Act (HIPAA) Security Rule.**
  NIST's engineering-facing implementation guidance.
  <https://csrc.nist.gov/pubs/sp/800/66/r2/final>
- **42 CFR Part 2 — Confidentiality of Substance Use Disorder
  Patient Records.** The stricter regime that dominates HIPAA
  for substance-use data.
  <https://www.ecfr.gov/current/title-42/chapter-I/subchapter-A/part-2>

### NIST privacy framework and privacy engineering

- **NIST Privacy Framework 1.0 (and the AI-related community
  profile).** Govern / Identify / Govern / Control /
  Communicate / Protect categories cross-referenced in the
  chapter-04 ADR and chapter-05 risk analysis.
  <https://www.nist.gov/privacy-framework>
- **NIST IR 8053 — De-Identification of Personal Information.**
  The engineering vocabulary around de-identification and
  pseudonymisation.
  <https://nvlpubs.nist.gov/nistpubs/ir/2015/NIST.IR.8053.pdf>
- **NIST SP 800-188 — De-Identifying Government Datasets.**
  Companion to IR 8053 for structured datasets.
  <https://csrc.nist.gov/pubs/sp/800/188/ipd>
- **NIST AI 100-2 — Adversarial Machine Learning: Taxonomy
  and Terminology.** The privacy-attack taxonomy (membership
  inference, model inversion, model extraction, attribute
  inference) chapter 02 draws from.
  <https://csrc.nist.gov/pubs/ai/100/2/final>
- **NIST AI 100-1 — AI Risk Management Framework 1.0.** The
  measurement surface the chapter-04 artefacts feed into.
  <https://nvlpubs.nist.gov/nistpubs/ai/NIST.AI.100-1.pdf>
- **NIST AI 600-1 — AI RMF Generative AI Profile.** GenAI-
  specific privacy risks and controls referenced in chapter
  02 (training-data extraction) and chapter 03 (prompt
  logging).
  <https://nvlpubs.nist.gov/nistpubs/ai/NIST.AI.600-1.pdf>
- **ENISA — Privacy and Data Protection by Design.** The EU
  cybersecurity agency's engineering-oriented guidance to
  Article 25.
  <https://www.enisa.europa.eu/publications/privacy-and-data-protection-by-design>

---

## Chapter 01 — choosing the DP-SGD budget

### Differential privacy — foundational

- **Dwork and Roth — *The Algorithmic Foundations of
  Differential Privacy* (Foundations and Trends in Theoretical
  Computer Science, 2014).** The reference monograph.
  <https://www.cis.upenn.edu/~aaroth/Papers/privacybook.pdf>
- **Dwork, McSherry, Nissim, Smith — *Calibrating Noise to
  Sensitivity in Private Data Analysis* (TCC 2006).** The
  original `(ε, δ)` formulation.
  <https://link.springer.com/chapter/10.1007/11681878_14>
- **Dwork, Rothblum — *Concentrated Differential Privacy*
  (2016).** Tighter composition bounds that modern accountants
  descend from.
  <https://arxiv.org/abs/1603.01887>
- **Bun, Steinke — *Concentrated Differential Privacy:
  Simplifications, Extensions, and Lower Bounds* (TCC 2016).**
  <https://arxiv.org/abs/1605.02065>

### DP-SGD and the accountants

- **Abadi, Chu, Goodfellow, McMahan, Mironov, Talwar, Zhang —
  *Deep Learning with Differential Privacy* (CCS 2016).** The
  DP-SGD paper.
  <https://arxiv.org/abs/1607.00133>
- **Mironov — *Rényi Differential Privacy* (CSF 2017).** The
  RDP accountant.
  <https://arxiv.org/abs/1702.07476>
- **Mironov, Talwar, Zhang — *Rényi Differential Privacy of
  the Sampled Gaussian Mechanism* (2019).**
  <https://arxiv.org/abs/1908.10530>
- **Gopi, Lee, Wutschitz — *Numerical Composition of
  Differential Privacy* (NeurIPS 2021).** The PRV accountant.
  <https://arxiv.org/abs/2106.02848>
- **Kairouz, Oh, Viswanath — *The Composition Theorem for
  Differential Privacy* (ICML 2015).** The advanced-composition
  reference the composition section cites.
  <https://arxiv.org/abs/1311.0776>

### Opacus and the engineering surface

- **Opacus — official documentation (training, API, FAQ,
  tutorials).**
  <https://opacus.ai/>
- **Opacus — API reference.**
  <https://opacus.ai/api/>
- **Opacus — tutorials and example notebooks.**
  <https://github.com/pytorch/opacus/tree/main/tutorials>
- **TensorFlow Privacy — DP-SGD and privacy accountant.**
  <https://github.com/tensorflow/privacy>
- **Google — differential-privacy GitHub organisation (library,
  accountants, examples).**
  <https://github.com/google/differential-privacy>

### User-level DP and record definition

- **McMahan, Ramage, Talwar, Zhang — *Learning Differentially
  Private Recurrent Language Models* (ICLR 2018).** The
  foundational user-level DP paper.
  <https://arxiv.org/abs/1710.06963>
- **Jain, Rush, Smith, Song, Thakurta — *Differentially Private
  Model Personalization* (2021).** User-level DP for
  personalisation workloads.
  <https://arxiv.org/abs/2105.14196>
- **Charles, Konečný, Ponomareva — *Convergence of Federated
  Learning with User-level DP under Non-Convex Objectives*
  (2021).**
  <https://arxiv.org/abs/2104.10133>

### Industry practice and worked examples

- **Apple — *Learning with Privacy at Scale* (Apple Machine
  Learning Journal).** Industry example of per-record privacy
  budgets.
  <https://machinelearning.apple.com/research/learning-with-privacy-at-scale>
- **US Census Bureau — Disclosure Avoidance for the 2020
  Census.** A real-world large-scale DP deployment including
  budget allocation decisions.
  <https://www.census.gov/about/policies/privacy/statistical_safeguards/disclosure-avoidance-2020-census.html>
- **Dwork, Kohli, Mulligan — *Differential Privacy in Practice:
  Expose Your Epsilons!* (JPC 2019).** The paper the "name
  the record, publish the epsilon" posture descends from.
  <https://journalprivacyconfidentiality.org/index.php/jpc/article/view/689>

---

## Chapter 02 — inference-attack mitigation

### Membership inference — foundational

- **Shokri, Stronati, Song, Shmatikov — *Membership Inference
  Attacks Against Machine Learning Models* (S&P 2017).** The
  canonical MI attack paper.
  <https://arxiv.org/abs/1610.05820>
- **Yeom, Giacomelli, Fredrikson, Jha — *Privacy Risk in
  Machine Learning: Analyzing the Connection to Overfitting*
  (CSF 2018).** The confidence-gap baseline.
  <https://arxiv.org/abs/1709.01604>
- **Sablayrolles, Douze, Schmid, Ollivier, Jégou — *White-box
  vs Black-box: Bayes Optimal Strategies for Membership
  Inference* (ICML 2019).**
  <https://arxiv.org/abs/1908.11229>
- **Carlini, Chien, Nasr, Song, Terzis, Tramèr — *Membership
  Inference Attacks From First Principles* (S&P 2022).** The
  LiRA attack and the TPR-at-low-FPR argument.
  <https://arxiv.org/abs/2112.03570>

### Attribute inference and model inversion

- **Fredrikson, Jha, Ristenpart — *Model Inversion Attacks
  that Exploit Confidence Information and Basic
  Countermeasures* (CCS 2015).** The classical model-inversion
  / attribute-inference paper.
  <https://rist.tech.cornell.edu/papers/mi-ccs.pdf>
- **Jayaraman, Evans — *Evaluating Differentially Private
  Machine Learning in Practice* (USENIX Security 2019).**
  Empirical attribute-inference study.
  <https://arxiv.org/abs/1902.08874>

### Training-data extraction from LLMs

- **Carlini, Tramèr, Wallace, Jagielski, Herbert-Voss, Lee,
  Roberts, Brown, Song, Erlingsson, Oprea, Raffel —
  *Extracting Training Data from Large Language Models*
  (USENIX Security 2021).**
  <https://arxiv.org/abs/2012.07805>
- **Carlini, Ippolito, Jagielski, Lee, Tramèr, Zhang —
  *Quantifying Memorization Across Neural Language Models*
  (ICLR 2023).**
  <https://arxiv.org/abs/2202.07646>
- **Nasr, Carlini, Hayase, Jagielski, Cooper, Ippolito,
  Choquette-Choo, Wallace, Tramèr, Lee — *Scalable Extraction
  of Training Data from (Production) Language Models* (2023).**
  <https://arxiv.org/abs/2311.17035>
- **Lee, Ippolito, Nystrom, Zhang, Eck, Callison-Burch, Carlini
  — *Deduplicating Training Data Makes Language Models Better*
  (ACL 2022).** The deduplication-reduces-memorisation finding
  cited in chapter 02.
  <https://arxiv.org/abs/2107.06499>

### Embedding and retrieval attacks

- **Song, Raghunathan — *Information Leakage in Embedding
  Models* (CCS 2020).**
  <https://arxiv.org/abs/2004.00053>
- **Morris, Kuleshov, Shmatikov, Rush — *Text Embeddings
  Reveal (Almost) as Much as Text* (EMNLP 2023).** The
  embedding-inversion result chapter 02 cites.
  <https://arxiv.org/abs/2310.06816>
- **Pan, Yang, Yan, Tramèr, Shmatikov — *Privacy Risks of
  General-Purpose Language Models* (S&P 2020).**
  <https://ieeexplore.ieee.org/document/9152761>

### Model extraction

- **Tramèr, Zhang, Juels, Reiter, Ristenpart — *Stealing
  Machine Learning Models via Prediction APIs* (USENIX
  Security 2016).**
  <https://arxiv.org/abs/1609.02943>
- **Juuti, Szyller, Marchal, Asokan — *PRADA: Protecting
  against DNN Model Stealing Attacks* (EuroS&P 2019).** The
  per-identity query-distribution detector chapter 02
  references.
  <https://arxiv.org/abs/1805.02628>

### Attack and defence benchmarks

- **ML Privacy Meter — toolkit for membership-inference
  evaluation.**
  <https://github.com/privacytrustlab/ml_privacy_meter>
- **TensorFlow Privacy — Membership Inference Attack suite.**
  <https://github.com/tensorflow/privacy/tree/master/tensorflow_privacy/privacy/privacy_tests>
- **Microsoft Counterfit — adversarial-ML assessment tool with
  privacy-attack modules.**
  <https://github.com/Azure/counterfit>

### Watermarking (LLM-specific)

- **Kirchenbauer, Geiping, Wen, Katz, Miers, Goldstein —
  *A Watermark for Large Language Models* (ICML 2023).**
  <https://arxiv.org/abs/2301.10226>

---

## Chapter 03 — PII/PHI DLP

### Presidio and the recogniser stack

- **Microsoft Presidio — official documentation.**
  <https://microsoft.github.io/presidio/>
- **Presidio — analyzer entity catalogue (built-in
  recognisers).**
  <https://microsoft.github.io/presidio/supported_entities/>
- **Presidio — anonymizer operators.**
  <https://microsoft.github.io/presidio/anonymizer/>
- **Presidio — writing a custom recognizer.**
  <https://microsoft.github.io/presidio/analyzer/adding_recognizers/>
- **Presidio — NLP engine configuration (spaCy, transformers,
  stanza).**
  <https://microsoft.github.io/presidio/analyzer/customizing_nlp_models/>
- **Presidio — evaluation framework and metrics.**
  <https://github.com/microsoft/presidio-research>

### Alternative DLP stacks

- **Google Cloud Data Loss Prevention (Sensitive Data
  Protection).**
  <https://cloud.google.com/sensitive-data-protection/docs>
- **AWS Comprehend — PII detection.**
  <https://docs.aws.amazon.com/comprehend/latest/dg/pii.html>
- **AWS Macie — classifier types.**
  <https://docs.aws.amazon.com/macie/latest/user/data-identifiers.html>
- **Azure AI Language — PII detection.**
  <https://learn.microsoft.com/azure/ai-services/language-service/personally-identifiable-information/overview>

### NER foundations

- **spaCy — documentation (NER, pipelines, model versioning).**
  <https://spacy.io/usage>
- **Hugging Face — token-classification task page (NER
  models).**
  <https://huggingface.co/docs/transformers/tasks/token_classification>

### Entity-specific references for custom recognisers

- **ANSI / US Social Security Administration — SSN format and
  validation rules.**
  <https://www.ssa.gov/employer/randomization.html>
- **ISO/IEC 7812 — Credit-card identifier format and Luhn
  check.**
  <https://www.iso.org/standard/70484.html>
- **NHS Digital — NHS Number format and checksum.**
  <https://digital.nhs.uk/services/organisation-data-service/nhs-number>
- **ISO 13616 — IBAN structure.**
  <https://www.iso.org/standard/81090.html>

### Evaluating DLP

- **Microsoft — Presidio research: evaluation methodology and
  dataset guidance.**
  <https://github.com/microsoft/presidio-research>
- **CoNLL-2003 shared task on NER.** The reference evaluation
  format for span-level F1.
  <https://www.clips.uantwerpen.be/conll2003/ner/>
- **Hugging Face — `seqeval` package for span-level NER
  evaluation.**
  <https://github.com/chakki-works/seqeval>

---

## Chapter 04 — GDPR articles as artefacts

### Article 22 — automated decisions and explanation

- **GDPR Articles 22 and 15(1)(h), Recitals 71 and 72** —
  primary source via EUR-Lex (link above).
- **ICO + Alan Turing Institute — *Explaining decisions made
  with AI* (full guidance).** Six-chapter engineering guide to
  explanation methods, trade-offs, and subject-facing wording.
  <https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/artificial-intelligence/explaining-decisions-made-with-ai/>
- **EDPB — Guidelines on Automated individual decision-making
  (wp251rev.01).** The rubber-stamp test.
  <https://ec.europa.eu/newsroom/article29/items/612053/en>
- **Lundberg, Lee — *A Unified Approach to Interpreting Model
  Predictions* (NeurIPS 2017).** SHAP.
  <https://arxiv.org/abs/1705.07874>
- **Ribeiro, Singh, Guestrin — *"Why Should I Trust You?"
  Explaining the Predictions of Any Classifier* (KDD 2016).**
  LIME.
  <https://arxiv.org/abs/1602.04938>
- **Wachter, Mittelstadt, Russell — *Counterfactual
  Explanations without Opening the Black Box: Automated
  Decisions and the GDPR* (Harvard JOLT 2018).** The GDPR-
  oriented counterfactual-explanation argument.
  <https://arxiv.org/abs/1711.00399>

### Article 25 — data protection by design

- **EDPB Guidelines 4/2019 on Article 25** (link above).
- **ENISA — *Pseudonymisation Techniques and Best Practices*
  (2019).** The technical catalogue the ADR cites for
  pseudonymisation choices.
  <https://www.enisa.europa.eu/publications/pseudonymisation-techniques-and-best-practices>
- **ENISA — *Data Pseudonymisation: Advanced Techniques &
  Use Cases* (2021).**
  <https://www.enisa.europa.eu/publications/data-pseudonymisation-advanced-techniques-and-use-cases>

### Article 35 — DPIA

- **Article 29 WP / EDPB — *Guidelines on Data Protection
  Impact Assessment* (wp248rev.01)** (link above).
- **ICO — Sample DPIA template** (link above).
- **CNIL — PIA tool (open-source DPIA software).**
  <https://www.cnil.fr/en/open-source-pia-software-helps-carry-out-data-protection-impact-assesment>
- **CNIL — PIA knowledge base and methodology.**
  <https://www.cnil.fr/sites/cnil/files/atoms/files/cnil-pia-1-en-methodology.pdf>
- **European Commission — list of national DPIA-required
  lists under Article 35(4) and 35(5).**
  <https://edpb.europa.eu/our-work-tools/consistency-findings/opinions_en>

### Cross-border transfer (Chapter V)

- **EDPB — Recommendations 01/2020 on measures that supplement
  transfer tools.** The post-*Schrems II* transfer-impact-
  assessment framework.
  <https://edpb.europa.eu/our-work-tools/our-documents/recommendations/recommendations-012020-measures-supplement-transfer_en>
- **European Commission — Standard Contractual Clauses for
  international data transfers.**
  <https://commission.europa.eu/law/law-topic/data-protection/international-dimension-data-protection/standard-contractual-clauses-scc_en>

---

## Chapter 05 — HIPAA security rule as ML controls

### Primary HIPAA text and OCR guidance

(See the HIPAA section at the top of this file for all primary
regulatory text and OCR guidance links.)

### NIST implementation guidance

- **NIST SP 800-66 Rev. 2 — Implementing the HIPAA Security
  Rule** (link above).
- **NIST SP 800-53 Rev. 5 — Security and Privacy Controls for
  Information Systems and Organizations.** The parent control
  catalogue that §164.308 / 310 / 312 cross-reference in
  practice.
  <https://csrc.nist.gov/pubs/sp/800/53/r5/upd1/final>
- **NIST SP 800-30 Rev. 1 — Guide for Conducting Risk
  Assessments.** The methodology the §164.308(a)(1)(ii)(A)
  risk analysis draws from.
  <https://csrc.nist.gov/pubs/sp/800/30/r1/final>
- **NIST SP 800-171 Rev. 3 — Protecting Controlled
  Unclassified Information in Nonfederal Systems.** Common
  cross-reference for business associates with federal
  customers.
  <https://csrc.nist.gov/pubs/sp/800/171/r3/final>

### HITRUST, SOC 2, provider BAAs

- **HITRUST CSF.** The de-facto healthcare-industry framework
  mapping HIPAA Security Rule to specific controls.
  <https://hitrustalliance.net/product-tool/hitrust-csf/>
- **AICPA — SOC 2 trust service criteria.** Cloud provider
  attestations typically rely on SOC 2 for the physical-
  safeguards column of the matrix.
  <https://www.aicpa-cima.com/resources/landing/system-and-organization-controls-soc-suite-of-services>
- **AWS — HIPAA Eligible Services Reference.**
  <https://aws.amazon.com/compliance/hipaa-eligible-services-reference/>
- **Microsoft Azure — HIPAA / HITECH compliance offering.**
  <https://learn.microsoft.com/compliance/regulatory/offering-hipaa-hitech>
- **Google Cloud — HIPAA compliance (BAA + eligible services
  list).**
  <https://cloud.google.com/security/compliance/hipaa>

### Breach-notification practice

- **HHS — Breach Notification Rule overview and sample
  notice.**
  <https://www.hhs.gov/hipaa/for-professionals/breach-notification/index.html>
- **HHS — Guidance to Render Unsecured PHI Unusable,
  Unreadable, or Indecipherable** (the safe-harbor
  encryption guidance for breach-notification purposes).
  <https://www.hhs.gov/hipaa/for-professionals/breach-notification/guidance/index.html>

### State and sector-specific regimes

- **California Confidentiality of Medical Information Act
  (CMIA).** Civ. Code §§ 56–56.37.
  <https://leginfo.legislature.ca.gov/faces/codes_displayexpandedbranch.xhtml?tocCode=CIV&division=1.&title=&part=2.6.&chapter=&article=>
- **Texas HB 300 — Medical Records Privacy Act.**
  <https://statutes.capitol.texas.gov/Docs/HS/htm/HS.181.htm>
- **Washington My Health My Data Act (RCW 19.373).**
  <https://app.leg.wa.gov/RCW/default.aspx?cite=19.373>

---

## Cross-module reference

- **mod-102 — threat modelling.** The STRIDE / LINDDUN
  scaffolding the chapter-02 attacker profiles plug into.
- **mod-103 — secure platform architecture.** The workload-
  identity, tenancy, and admission-gate primitives referenced
  across every chapter.
- **mod-104 — data and model lineage.** The audit log and
  model-card template the chapter-01 budget record, the
  chapter-03 DLP coverage, and the chapter-05 §164.312(b)
  audit control write to.
- **mod-105 — secrets and key management.** The KMS behind
  encryption at rest / in transit for PHI and the key
  reference for recoverable-redaction operators in chapter 03.
- **mod-106 — adversarial ML defence.** Chapter 06 of mod-106
  configures DP-SGD with Opacus; this module (chapter 01) sets
  the budget. Chapter 05 of mod-106 provides the serving-side
  detectors the chapter-02 MI-AUC monitor extends.
- **mod-107 — LLM / agent security.** The prompt / trajectory
  logging surface chapter 03 scrubs; the HITL patterns
  chapter 04 Article 22 depends on; the LLM-specific
  severity ladder chapter 05 incident response references.
- **mod-109 — AI governance.** The governance-evidence
  surface every artefact in this module (privacy budget,
  DPIA, HIPAA matrix, DLP coverage) feeds.
- **mod-110 — supply chain.** The imported-model and
  imported-dataset provenance whose privacy claims (or lack
  of them) feed the DPIA and the tier map.
- **mod-111 — security operations and incident response.** The
  breach-clock and DSAR mechanics the chapter-04 and
  chapter-05 incident paths plug into.

---

## Books and long reads

- **Dwork, Roth — *The Algorithmic Foundations of Differential
  Privacy*** (link above).
- **Narayanan, Shmatikov — collected privacy-engineering
  writings and the Robust De-anonymization line.**
  <https://cs.princeton.edu/~arvindn/>
- **Garfinkel, Abowd, Powazek — *Issues Encountered Deploying
  Differential Privacy* (WPES 2018).** The practitioner-
  oriented challenges paper.
  <https://arxiv.org/abs/1809.02201>
- **Vadhan — *The Complexity of Differential Privacy* (2017).**
  The theoretical companion for anyone going deeper than
  Dwork–Roth.
  <https://privacytools.seas.harvard.edu/files/privacytools/files/complexityprivacy_1.pdf>

---

## Caveats

- Regulatory text, EDPB / ICO / CNIL / OCR guidance, standards,
  and library APIs change over time. Verify every citation at
  time of use.
- No link above substitutes for the org's DPO, Security
  Officer, or counsel. This resource list is reading support;
  compliance determinations belong to accountable humans.
- Where a resource is behind a paywall or a login (ACM,
  Springer, IEEE), the author's preprint on arXiv is often
  available and canonically equivalent for the technical
  content.
