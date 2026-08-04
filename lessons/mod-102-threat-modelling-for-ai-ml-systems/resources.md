# Resources — mod-102 (Threat Modelling for AI/ML Systems)

> Primary sources for the threat-modelling method (STRIDE, attack
> trees), the ML-specific taxonomies (OWASP ML/LLM, MITRE ATLAS,
> NIST AI 100-2), and the adversarial-ML literature the chapters
> cite. Verify every URL and version at time of access; the field
> moves and links rot. Where a citation pins to a specific edition,
> the pinned version is called out.

---

## Threat-modelling method — primary references

- **Adam Shostack — *Threat Modeling: Designing for Security***
  (Wiley, 2014). ISBN 978-1-118-80999-0.
  [shostack.org/books/threat-modeling-book](https://shostack.org/books/threat-modeling-book)
  The practitioner reference for STRIDE-per-element,
  STRIDE-per-interaction, and DFD-based modelling. Chapter 03 is
  built on the STRIDE walk this book codifies.

- **Bruce Schneier — *Attack Trees*** (Dr. Dobb's Journal, December
  1999).
  [schneier.com/academic/archives/1999/12/attack_trees.html](https://www.schneier.com/academic/archives/1999/12/attack_trees.html)
  The founding paper on attack-tree methodology. Chapter 05 uses
  its AND/OR node semantics.

- **OWASP — Threat Modeling Cheat Sheet.**
  [cheatsheetseries.owasp.org/cheatsheets/Threat_Modeling_Cheat_Sheet.html](https://cheatsheetseries.owasp.org/cheatsheets/Threat_Modeling_Cheat_Sheet.html)
  Practitioner-facing summary; useful for teams new to STRIDE.

- **Microsoft — Threat Modeling Tool documentation.**
  [learn.microsoft.com/en-us/azure/security/develop/threat-modeling-tool](https://learn.microsoft.com/en-us/azure/security/develop/threat-modeling-tool)
  The tool ships with STRIDE templates; the documentation is a
  good source for the letter-per-element-type table.

- **OWASP Threat Dragon.**
  [github.com/OWASP/threat-dragon](https://github.com/OWASP/threat-dragon)
  Open-source threat-modelling tool with DFD + STRIDE support.

- **IriusRisk — threat-modelling platform.**
  [iriusrisk.com](https://www.iriusrisk.com/)
  Commercial threat-modelling platform with model + attack-tree
  first-class support.

- **NIST — *Guide to Attack Tree Analysis* / SP 800-30r1 (Guide for
  Conducting Risk Assessments).**
  [csrc.nist.gov/pubs/sp/800/30/r1/final](https://csrc.nist.gov/pubs/sp/800/30/r1/final)
  Federal-scope risk-assessment guidance; the *impact* /
  *likelihood* scoring rubric used in chapters 05 and 06 is
  compatible with SP 800-30's approach.

- **Ross Anderson — *Security Engineering* (3rd edition, 2020).**
  ISBN 978-1-119-64281-7.
  [cl.cam.ac.uk/~rja14/book.html](https://www.cl.cam.ac.uk/~rja14/book.html)
  The foundational text on security-engineering method. Its
  chapters on threat modelling and adversarial thinking underpin
  the approach in this module.

---

## OWASP — ML and LLM taxonomies

- **OWASP Machine Learning Security Top 10.**
  [owasp.org/www-project-machine-learning-security-top-10](https://owasp.org/www-project-machine-learning-security-top-10/)
  Classical-ML risk taxonomy — the ML01–ML10 identifiers used in
  the STRIDE table.

- **OWASP Top 10 for Large Language Model Applications, v2025.**
  [genai.owasp.org/llm-top-10](https://genai.owasp.org/llm-top-10/)
  LLM/GenAI risk taxonomy — the LLM01:2025 … LLM10:2025
  identifiers used in the STRIDE table (LLM assets).

- **OWASP AI Security & Privacy Guide.**
  [owasp.org/www-project-ai-security-and-privacy-guide](https://owasp.org/www-project-ai-security-and-privacy-guide/)
  Controls-first companion reading; useful for the mitigation
  scorecard sources in exercise 05.

- **OWASP Application Security Verification Standard (ASVS).**
  [owasp.org/www-project-application-security-verification-standard](https://owasp.org/www-project-application-security-verification-standard/)
  Generic application security baseline; necessary but not
  sufficient for ML systems.

---

## MITRE ATLAS — ML-specific TTP catalogue

- **MITRE ATLAS — Adversarial Threat Landscape for AI Systems.**
  [atlas.mitre.org](https://atlas.mitre.org/)
  The primary source for the ATLAS tactic and technique IDs used
  in chapter 04's IR-consumable inventory. Verify every AML.T####
  identifier here before quoting.

- **MITRE ATT&CK.**
  [attack.mitre.org](https://attack.mitre.org/)
  The general enterprise TTP catalogue; used for the
  enterprise-generic stages (Initial Access via web exploit, valid-
  account credential abuse, DNS exfil) that appear in ML attack
  chains.

- **MITRE — ATLAS case studies index.**
  [atlas.mitre.org/studies](https://atlas.mitre.org/studies)
  Real-world incidents mapped to the ATLAS tactic chain. Useful for
  the tabletop-drill stretch goals in exercises 03–04.

---

## NIST — AI adversarial-ML and risk-management publications

- **NIST AI 100-2 e2023 — *Adversarial Machine Learning: A Taxonomy
  and Terminology of Attacks and Mitigations*.**
  [csrc.nist.gov/pubs/ai/100/2/e2023/final](https://csrc.nist.gov/pubs/ai/100/2/e2023/final)
  The pinned edition for the vocabulary used in chapter 04
  (attacker goal / capability / knowledge / lifecycle stage; the
  attack families). Includes the GenAI extension.

- **NIST AI RMF 1.0.**
  [nist.gov/itl/ai-risk-management-framework](https://www.nist.gov/itl/ai-risk-management-framework)
  Primary document:
  [nvlpubs.nist.gov/nistpubs/ai/NIST.AI.100-1.pdf](https://nvlpubs.nist.gov/nistpubs/ai/NIST.AI.100-1.pdf)
  Referenced from chapter 06 for the mitigation-source overlay.

- **NIST AI 600-1 — Generative AI Profile.**
  [airc.nist.gov/AI_RMF_Knowledge_Base/AI_RMF/Uses/GenAI-Profile](https://airc.nist.gov/AI_RMF_Knowledge_Base/AI_RMF/Uses/GenAI-Profile)
  GenAI overlay to AI RMF.

- **NIST SP 800-30r1 — *Guide for Conducting Risk Assessments*.**
  [csrc.nist.gov/pubs/sp/800/30/r1/final](https://csrc.nist.gov/pubs/sp/800/30/r1/final)
  Foundational risk-assessment methodology; the impact / likelihood
  scoring rubric used in chapters 05 and 06 aligns with this.

- **NIST SP 800-207 — *Zero Trust Architecture*.**
  [csrc.nist.gov/pubs/sp/800/207/final](https://csrc.nist.gov/pubs/sp/800/207/final)
  Trust-boundary vocabulary referenced from chapter 01.

- **NIST SP 800-53 rev 5 — *Security and Privacy Controls*.**
  [csrc.nist.gov/pubs/sp/800/53/r5/upd1/final](https://csrc.nist.gov/pubs/sp/800/53/r5/upd1/final)
  Control catalogue that mitigation-scorecard rows can cross-
  reference for federal-adjacent systems.

- **NIST SP 800-218 — *Secure Software Development Framework (SSDF)*.**
  [csrc.nist.gov/Projects/ssdf](https://csrc.nist.gov/Projects/ssdf)
  General secure-development guidance applicable to ML training
  pipelines.

- **NIST SP 800-161r1 — *Cybersecurity Supply Chain Risk Management
  Practices*.**
  [nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-161r1.pdf](https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-161r1.pdf)
  Referenced from the STRIDE model-artifact and supply-chain rows
  (ML06 / LLM03 / ML10).

- **NIST AI 100-4 — *Reducing Risks Posed by Synthetic Content*.**
  [csrc.nist.gov/pubs/ai/100/4/final](https://csrc.nist.gov/pubs/ai/100/4/final)
  Referenced from LLM09 / abuse-violation rows.

---

## ISO / IEC — AI management-system and risk-management standards

- **ISO/IEC 42001:2023 — AI Management System (AIMS).**
  [iso.org/standard/81230.html](https://www.iso.org/standard/81230.html)
  Cross-referenced from the mitigation scorecard for governance-
  derived controls.

- **ISO/IEC 27001:2022 — Information Security Management System.**
  [iso.org/standard/27001](https://www.iso.org/standard/27001)
  The ISMS spine AIMS builds on.

- **ISO/IEC 23894:2023 — Guidance on AI Risk Management.**
  [iso.org/standard/77304.html](https://www.iso.org/standard/77304.html)
  Companion risk-management guidance to ISO/IEC 42001.

- **ISO/IEC 15408 series — Common Criteria for Information
  Technology Security Evaluation.**
  [iso.org/standard/72891.html](https://www.iso.org/standard/72891.html)
  The formal threat-analysis tradition attack-tree methodology
  descends from.

---

## EU AI Act, CRA, and related regulation

- **Regulation (EU) 2024/1689 — the EU AI Act.**
  [eur-lex.europa.eu/eli/reg/2024/1689/oj](https://eur-lex.europa.eu/eli/reg/2024/1689/oj)
  Article 15 (cybersecurity + robustness) is a mitigation-source
  for many rows in chapter 06.

- **EU AI Office (European Commission).**
  [digital-strategy.ec.europa.eu/en/policies/ai-office](https://digital-strategy.ec.europa.eu/en/policies/ai-office)
  Implementing guidance and delegated acts.

- **EU Cyber Resilience Act (Regulation (EU) 2024/2847).**
  [eur-lex.europa.eu/eli/reg/2024/2847/oj](https://eur-lex.europa.eu/eli/reg/2024/2847/oj)
  Cybersecurity requirements for products with digital elements,
  including AI-enabled products.

- **GDPR — Regulation (EU) 2016/679.**
  [eur-lex.europa.eu/eli/reg/2016/679/oj](https://eur-lex.europa.eu/eli/reg/2016/679/oj)
  Data-subject rights, DPIA, and automated-decisions provisions
  that drive the blast-radius fields in exercise 01.

---

## National / cross-national practitioner guidance

- **CISA — *Guidelines for Secure AI System Development* (joint
  international).**
  [cisa.gov/resources-tools/resources/guidelines-secure-ai-system-development](https://www.cisa.gov/resources-tools/resources/guidelines-secure-ai-system-development)
  Cross-national practitioner-facing secure-AI guidance.

- **UK National Cyber Security Centre — *Machine Learning
  security principles*.**
  [ncsc.gov.uk/collection/machine-learning](https://www.ncsc.gov.uk/collection/machine-learning)
  UK-focused practitioner guidance on securing ML systems.

- **UK AI Safety Institute — Inspect Evaluation Framework.**
  [ukgovernmentbeis.github.io/inspect_ai](https://ukgovernmentbeis.github.io/inspect_ai/)
  Reproducible evaluation harness — mentioned as the evaluation-
  handshake reference to the peer `ai-evaluation-engineer` role.

---

## Frontier-lab safety-and-security frameworks

- **Anthropic Responsible Scaling Policy (RSP).**
  [anthropic.com/rsp](https://www.anthropic.com/rsp)

- **OpenAI Preparedness Framework.**
  [openai.com/index/updating-our-preparedness-framework](https://openai.com/index/updating-our-preparedness-framework/)

- **DeepMind Frontier Safety Framework (FSF).**
  [deepmind.google/discover/blog/introducing-the-frontier-safety-framework](https://deepmind.google/discover/blog/introducing-the-frontier-safety-framework/)

- **Google Secure AI Framework (SAIF).**
  [safety.google/cybersecurity-advancements/saif](https://safety.google/cybersecurity-advancements/saif/)

Cross-reference these when the target system operates at a
frontier-capability tier; their gating shapes inform the coverage
axis in chapter 06.

---

## Supply-chain / signing / provenance

- **SLSA v1.0.** [slsa.dev/spec/v1.0](https://slsa.dev/spec/v1.0/)
- **Sigstore / cosign.** [docs.sigstore.dev](https://docs.sigstore.dev/)
- **in-toto.** [in-toto.io](https://in-toto.io/)
- **CycloneDX ML-BOM.** [cyclonedx.org/capabilities/mlbom](https://cyclonedx.org/capabilities/mlbom/)
- **Protect AI ModelScan.** [github.com/protectai/modelscan](https://github.com/protectai/modelscan)
- **safetensors.** [github.com/huggingface/safetensors](https://github.com/huggingface/safetensors)

Cross-referenced from THREAT-MA-T (model-artifact tampering),
THREAT-MA-I (artifact exfiltration), and OWASP ML06 / LLM03 rows.

---

## Adversarial-ML literature (canonical reference attacks)

The papers the STRIDE and inventory rows cite by author-year.

### Evasion

- **Szegedy et al. 2013** — *Intriguing properties of neural
  networks*. [arxiv.org/abs/1312.6199](https://arxiv.org/abs/1312.6199)
- **Goodfellow et al. 2014** — *Explaining and Harnessing
  Adversarial Examples* (FGSM).
  [arxiv.org/abs/1412.6572](https://arxiv.org/abs/1412.6572)
- **Madry et al. 2018** — *Towards Deep Learning Models Resistant
  to Adversarial Attacks* (PGD, adversarial training).
  [arxiv.org/abs/1706.06083](https://arxiv.org/abs/1706.06083)
- **Zhang et al. 2019** — *Theoretically Principled Trade-off
  between Robustness and Accuracy* (TRADES).
  [arxiv.org/abs/1901.08573](https://arxiv.org/abs/1901.08573)
- **Chen et al. 2020** — *HopSkipJumpAttack: A Query-Efficient
  Decision-Based Attack*.
  [arxiv.org/abs/1904.02144](https://arxiv.org/abs/1904.02144)
- **Cohen et al. 2019** — *Certified Adversarial Robustness via
  Randomized Smoothing*.
  [arxiv.org/abs/1902.02918](https://arxiv.org/abs/1902.02918)
- **Brendel et al. 2018** — *Decision-Based Adversarial Attacks*.
  [arxiv.org/abs/1712.04248](https://arxiv.org/abs/1712.04248)

### Poisoning and backdoor

- **Biggio et al. 2012** — *Poisoning Attacks against Support
  Vector Machines*. [arxiv.org/abs/1206.6389](https://arxiv.org/abs/1206.6389)
- **Gu et al. 2017** — *BadNets: Identifying Vulnerabilities in the
  Machine Learning Model Supply Chain*.
  [arxiv.org/abs/1708.06733](https://arxiv.org/abs/1708.06733)
- **Chen et al. 2017** — *Targeted Backdoor Attacks on Deep
  Learning Systems Using Data Poisoning*.
  [arxiv.org/abs/1712.05526](https://arxiv.org/abs/1712.05526)
- **Wallace et al. 2021** — *Concealed Data Poisoning Attacks on
  NLP Models*. [arxiv.org/abs/2010.12563](https://arxiv.org/abs/2010.12563)

### Model extraction / stealing

- **Tramèr et al. 2016** — *Stealing Machine Learning Models via
  Prediction APIs*.
  [arxiv.org/abs/1609.02943](https://arxiv.org/abs/1609.02943)
- **Jagielski et al. 2020** — *High Accuracy and High Fidelity
  Extraction of Neural Networks*.
  [arxiv.org/abs/1909.01838](https://arxiv.org/abs/1909.01838)

### Membership inference, inversion, attribute inference

- **Shokri et al. 2017** — *Membership Inference Attacks Against
  Machine Learning Models*.
  [arxiv.org/abs/1610.05820](https://arxiv.org/abs/1610.05820)
- **Fredrikson et al. 2015** — *Model Inversion Attacks that
  Exploit Confidence Information and Basic Countermeasures* (ACM
  CCS 2015).
  [cs.cmu.edu/~mfredrik/papers/fjr2015ccs.pdf](https://www.cs.cmu.edu/~mfredrik/papers/fjr2015ccs.pdf)
- **Carlini et al. 2021** — *Extracting Training Data from Large
  Language Models*.
  [arxiv.org/abs/2012.07805](https://arxiv.org/abs/2012.07805)
- **Nasr et al. 2018** — *Comprehensive Privacy Analysis of Deep
  Learning*. [arxiv.org/abs/1812.00910](https://arxiv.org/abs/1812.00910)

### Prompt injection and LLM security

- **Greshake et al. 2023** — *Not what you've signed up for:
  Compromising Real-World LLM-Integrated Applications with
  Indirect Prompt Injection*.
  [arxiv.org/abs/2302.12173](https://arxiv.org/abs/2302.12173)
- **Perez & Ribeiro 2022** — *Ignore Previous Prompt: Attack
  Techniques For Language Models*.
  [arxiv.org/abs/2211.09527](https://arxiv.org/abs/2211.09527)
- **Zou et al. 2023** — *Universal and Transferable Adversarial
  Attacks on Aligned Language Models*.
  [arxiv.org/abs/2307.15043](https://arxiv.org/abs/2307.15043)

### Differential privacy

- **Dwork & Roth 2014** — *The Algorithmic Foundations of
  Differential Privacy* (textbook).
  [cis.upenn.edu/~aaroth/Papers/privacybook.pdf](https://www.cis.upenn.edu/~aaroth/Papers/privacybook.pdf)
- **Abadi et al. 2016** — *Deep Learning with Differential
  Privacy* (DP-SGD).
  [arxiv.org/abs/1607.00133](https://arxiv.org/abs/1607.00133)

---

## Tools referenced in the exercises

Not required reading for mod-102, but exercise 03 and 05 sample
downstream tools:

- **Adversarial Robustness Toolbox (ART).**
  [adversarial-robustness-toolbox.readthedocs.io](https://adversarial-robustness-toolbox.readthedocs.io/)
  Attack + defence library used by mod-106 for evasion / poisoning
  experiments.
- **Opacus — DP-SGD for PyTorch.** [opacus.ai](https://opacus.ai/)
  DP training library used by mod-108.
- **Microsoft Presidio.**
  [microsoft.github.io/presidio](https://microsoft.github.io/presidio/)
  PII/PHI DLP for prompt/tool-graph rows.
- **Lakera.** [lakera.ai](https://www.lakera.ai/)
  Commercial prompt-injection scanner for retrieval / input rows.
- **Sigma.** [github.com/SigmaHQ/sigma](https://github.com/SigmaHQ/sigma)
  SIEM-agnostic detection-rule format used in the ATLAS-tagged
  Sigma stubs.

---

## Cross-references within this curriculum

- The [module plan](../../CURRICULUM.md) and the [job-requirements
  packet](../../JOB_REQUIREMENTS.md) at the repository root.
- Sibling modules mod-101 (installs vocabulary this module
  consumes) and mod-103 … mod-112 (consume this module's
  artifacts).
- The paired solutions repo (linked from the top-level README).

---

## Things deliberately not on this list

- Vendor whitepapers positioned as primary sources. Vendor
  documents describe products; cite standards and primary research.
- Fear-of-AI general-audience books; the vocabulary they use is
  not the vocabulary the standards use.
- Consultant-authored threat-model templates behind a paywall; the
  primary sources on this list are sufficient to construct any
  template a client would ask for.
