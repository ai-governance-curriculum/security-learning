# Resources — mod-101 (Frameworks, Position on the Ladder, and Working Vocabulary)

> Primary sources for every framework, standard, and cross-reference
> cited in the module. Verify all URLs and version numbers at time
> of access — the field moves and links rot. Where a citation is
> pinned to a specific edition (NIST AI 100-2e2023, OWASP LLM Top 10
> v2025, ISO/IEC 42001:2023, EU Regulation 2024/1689) the pinned
> version is called out explicitly.

---

## OWASP

- **OWASP Machine Learning Security Top 10** — project page.
  [owasp.org/www-project-machine-learning-security-top-10](https://owasp.org/www-project-machine-learning-security-top-10/)
  The canonical Top-10 catalogue for classical ML systems. Chapter
  01 §Part A references the 2023 release; confirm the current
  release before quoting item numbers.

- **OWASP Top 10 for Large Language Model Applications, v2025** —
  GenAI Security Project page.
  [genai.owasp.org/llm-top-10](https://genai.owasp.org/llm-top-10/)
  The current LLM Top 10; v2025 identifiers (LLM01:2025 …
  LLM10:2025) are the ones to author against.

- **OWASP AI Security & Privacy Guide** —
  [owasp.org/www-project-ai-security-and-privacy-guide](https://owasp.org/www-project-ai-security-and-privacy-guide/)
  The OWASP AI Exchange complementary reading — controls-first view.

- **OWASP Application Security Verification Standard (ASVS)** —
  [owasp.org/www-project-application-security-verification-standard](https://owasp.org/www-project-application-security-verification-standard/)
  Generic application security baseline. Necessary, not sufficient
  for ML systems.

## MITRE

- **MITRE ATLAS — Adversarial Threat Landscape for AI Systems** —
  [atlas.mitre.org](https://atlas.mitre.org/)
  The ML-specific TTP catalogue chapter 02 is built on.

- **MITRE ATT&CK** —
  [attack.mitre.org](https://attack.mitre.org/)
  The general enterprise TTP catalogue. Used for the enterprise-
  generic stages of an ATLAS attack chain (Initial Access,
  Persistence, Defense Evasion).

## NIST

- **NIST AI RMF 1.0** — official page.
  [nist.gov/itl/ai-risk-management-framework](https://www.nist.gov/itl/ai-risk-management-framework)
  and the primary document at
  [nvlpubs.nist.gov/nistpubs/ai/NIST.AI.100-1.pdf](https://nvlpubs.nist.gov/nistpubs/ai/NIST.AI.100-1.pdf).
  The GOVERN / MAP / MEASURE / MANAGE spine chapter 04 walks.

- **NIST AI 600-1 — Generative AI Profile** — Knowledge Base entry.
  [airc.nist.gov/AI_RMF_Knowledge_Base/AI_RMF/Uses/GenAI-Profile](https://airc.nist.gov/AI_RMF_Knowledge_Base/AI_RMF/Uses/GenAI-Profile)
  The GenAI overlay for AI RMF; read alongside AI RMF 1.0.

- **NIST AI 100-2 — Adversarial Machine Learning: A Taxonomy and
  Terminology of Attacks and Mitigations** — final e2023.
  [csrc.nist.gov/pubs/ai/100/2/e2023/final](https://csrc.nist.gov/pubs/ai/100/2/e2023/final)
  The taxonomy chapter 03 is built on. GenAI extensions are in this
  edition.

- **NIST SP 800-207 — Zero Trust Architecture** —
  [csrc.nist.gov/pubs/sp/800/207/final](https://csrc.nist.gov/pubs/sp/800/207/final)
  Referenced from chapter 04 §Article 15 for the cybersecurity
  obligation's foundation.

- **NIST SP 800-161r1 — Cybersecurity Supply Chain Risk Management
  Practices** —
  [nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-161r1.pdf](https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-161r1.pdf)
  The supply-chain framework mod-110 builds on.

- **NIST SP 800-218 — Secure Software Development Framework (SSDF)** —
  [csrc.nist.gov/Projects/ssdf](https://csrc.nist.gov/Projects/ssdf)
  General software-supply-chain hygiene; applies to ML training
  pipelines.

- **NIST SP 800-53 — Security and Privacy Controls for Information
  Systems and Organizations** —
  [csrc.nist.gov/pubs/sp/800/53/r5/upd1/final](https://csrc.nist.gov/pubs/sp/800/53/r5/upd1/final)
  Catalog of controls the crosswalk lands on for federal-adjacent
  systems.

- **NIST AI 100-4 — Reducing Risks Posed by Synthetic Content** —
  [csrc.nist.gov/pubs/ai/100/4/final](https://csrc.nist.gov/pubs/ai/100/4/final)
  Referenced from mod-111 for provenance / watermarking of
  generative outputs.

## ISO / IEC

- **ISO/IEC 42001:2023 — AI Management System (AIMS)** —
  [iso.org/standard/81230.html](https://www.iso.org/standard/81230.html)
  The AIMS clause spine chapter 04 walks. Access is paywalled;
  authoritative language must be read from the standard directly.

- **ISO/IEC 27001:2022 — Information Security Management System** —
  [iso.org/standard/27001](https://www.iso.org/standard/27001)
  The ISMS spine the AIMS builds on; the two integrate in practice.

- **ISO/IEC 23894:2023 — Guidance on AI Risk Management** —
  [iso.org/standard/77304.html](https://www.iso.org/standard/77304.html)
  Companion risk-management guidance to ISO/IEC 42001.

## EU AI Act and related regulation

- **Regulation (EU) 2024/1689 — the EU AI Act** — consolidated OJ.
  [eur-lex.europa.eu/eli/reg/2024/1689/oj](https://eur-lex.europa.eu/eli/reg/2024/1689/oj)
  Articles 9–15 are the operative security-engineering slice
  chapter 04 walks. Verify staged application dates before treating
  an obligation as active.

- **EU AI Office (European Commission)** — implementing guidance.
  [digital-strategy.ec.europa.eu/en/policies/ai-office](https://digital-strategy.ec.europa.eu/en/policies/ai-office)
  Where the practical guidance and delegated acts are published.

- **EU Cyber Resilience Act (Regulation (EU) 2024/2847)** —
  [eur-lex.europa.eu/eli/reg/2024/2847/oj](https://eur-lex.europa.eu/eli/reg/2024/2847/oj)
  Cybersecurity requirements for products with digital elements,
  including AI-enabled products.

- **GDPR — Regulation (EU) 2016/679** —
  [eur-lex.europa.eu/eli/reg/2016/679/oj](https://eur-lex.europa.eu/eli/reg/2016/679/oj)
  Articles 22 (automated decisions), 25 (DP by design), and 35
  (DPIA) referenced from mod-108.

## Sector regulation

- **HIPAA Security Rule — HHS** —
  [hhs.gov/hipaa/for-professionals/security/index.html](https://www.hhs.gov/hipaa/for-professionals/security/index.html)
  Administrative, physical, and technical safeguards for ePHI.
  Referenced by mod-108 for ML platforms training on PHI.

- **Federal Reserve SR 11-7 — Guidance on Model Risk Management** —
  [federalreserve.gov/supervisionreg/srletters/sr1107.htm](https://www.federalreserve.gov/supervisionreg/srletters/sr1107.htm)
  Requires effective challenge and validation of models; this role
  produces the security dimensions of the validation record.

- **FDA — Good Machine Learning Practice (GMLP) guiding principles** —
  [fda.gov/medical-devices/software-medical-device-samd/good-machine-learning-practice-medical-device-development-guiding-principles](https://www.fda.gov/medical-devices/software-medical-device-samd/good-machine-learning-practice-medical-device-development-guiding-principles)
  Applies to regulated medical device software.

- **FDA — Predetermined Change Control Plan (PCCP) guidance** —
  [fda.gov/regulatory-information/search-fda-guidance-documents/marketing-submission-recommendations-predetermined-change-control-plan-artificial-intelligence](https://www.fda.gov/regulatory-information/search-fda-guidance-documents/marketing-submission-recommendations-predetermined-change-control-plan-artificial-intelligence)
  How AI-enabled medical devices document planned modifications.

- **AICPA SOC 2 — Trust Services Criteria** —
  [aicpa-cima.com/topic/audit-assurance/audit-and-assurance-greater-than-soc-2](https://www.aicpa-cima.com/topic/audit-assurance/audit-and-assurance-greater-than-soc-2)
  The Security, Availability, and Confidentiality criteria used in
  chapter 04.

## National / cross-national guidance

- **CISA — Guidelines for Secure AI System Development (joint
  international)** —
  [cisa.gov/resources-tools/resources/guidelines-secure-ai-system-development](https://www.cisa.gov/resources-tools/resources/guidelines-secure-ai-system-development)
  Cross-national practitioner-facing secure-AI guidance.

- **UK AI Safety Institute — Inspect Evaluation Framework** —
  [ukgovernmentbeis.github.io/inspect_ai](https://ukgovernmentbeis.github.io/inspect_ai/)
  Reproducible evaluation harness used in mod-107 for red-team
  engagements.

- **UK National Cyber Security Centre — AI security guidance** —
  [ncsc.gov.uk/collection/machine-learning](https://www.ncsc.gov.uk/collection/machine-learning)
  UK-focused practitioner guidance on securing ML systems.

## Frontier-lab safety-and-security frameworks

- **Anthropic Responsible Scaling Policy (RSP)** —
  [anthropic.com/rsp](https://www.anthropic.com/rsp)
  The deployment-tier gating framework enterprises can mirror.

- **OpenAI Preparedness Framework** —
  [openai.com/index/updating-our-preparedness-framework](https://openai.com/index/updating-our-preparedness-framework/)
  Preparedness / evaluation / mitigation framework.

- **DeepMind Frontier Safety Framework (FSF)** —
  [deepmind.google/discover/blog/introducing-the-frontier-safety-framework](https://deepmind.google/discover/blog/introducing-the-frontier-safety-framework/)
  Frontier-scale safety framework covering critical capability
  levels.

- **Google Secure AI Framework (SAIF)** —
  [safety.google/cybersecurity-advancements/saif](https://safety.google/cybersecurity-advancements/saif/)
  Google's published enterprise-facing AI security framework.

## Supply chain

- **SLSA v1.0** —
  [slsa.dev/spec/v1.0](https://slsa.dev/spec/v1.0/)
  Supply-chain Levels for Software Artifacts. Foundation for
  mod-110.

- **Sigstore / cosign** —
  [docs.sigstore.dev](https://docs.sigstore.dev/)
  Keyless signing and verification for container images, model
  artifacts, and arbitrary blobs.

- **in-toto** —
  [in-toto.io](https://in-toto.io/)
  Supply-chain attestation framework used in provenance capture.

- **Protect AI ModelScan** —
  [github.com/protectai/modelscan](https://github.com/protectai/modelscan)
  Scanner for malicious code in serialised model files.

- **Hugging Face Hub security** —
  [huggingface.co/docs/hub/security](https://huggingface.co/docs/hub/security)
  Hub-side security documentation and safetensors format guidance.

- **safetensors format** —
  [github.com/huggingface/safetensors](https://github.com/huggingface/safetensors)
  Safe alternative to pickle for model weight serialisation.

- **CycloneDX ML-BOM** —
  [cyclonedx.org/capabilities/mlbom](https://cyclonedx.org/capabilities/mlbom/)
  ML Bill of Materials format for AI/ML system components.

## Foundational adversarial-ML research

The literature that established the attack taxonomies chapter 03
uses.

### Evasion

- **Szegedy et al. 2013** — *Intriguing properties of neural
  networks*. [arxiv.org/abs/1312.6199](https://arxiv.org/abs/1312.6199)
- **Goodfellow et al. 2014** — *Explaining and Harnessing Adversarial
  Examples* (FGSM). [arxiv.org/abs/1412.6572](https://arxiv.org/abs/1412.6572)
- **Madry et al. 2018** — *Towards Deep Learning Models Resistant to
  Adversarial Attacks* (PGD, adversarial training).
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

### Poisoning and backdoor

- **Biggio et al. 2012** — *Poisoning Attacks against Support Vector
  Machines*. [arxiv.org/abs/1206.6389](https://arxiv.org/abs/1206.6389)
- **Gu et al. 2017** — *BadNets: Identifying Vulnerabilities in the
  Machine Learning Model Supply Chain*.
  [arxiv.org/abs/1708.06733](https://arxiv.org/abs/1708.06733)

### Extraction, inversion, membership inference

- **Tramèr et al. 2016** — *Stealing Machine Learning Models via
  Prediction APIs*. [arxiv.org/abs/1609.02943](https://arxiv.org/abs/1609.02943)
- **Shokri et al. 2017** — *Membership Inference Attacks Against
  Machine Learning Models*.
  [arxiv.org/abs/1610.05820](https://arxiv.org/abs/1610.05820)
- **Fredrikson et al. 2015** — *Model Inversion Attacks that Exploit
  Confidence Information and Basic Countermeasures* (ACM CCS 2015).
  [cs.cmu.edu/~mfredrik/papers/fjr2015ccs.pdf](https://www.cs.cmu.edu/~mfredrik/papers/fjr2015ccs.pdf)
- **Carlini et al. 2021** — *Extracting Training Data from Large
  Language Models*. [arxiv.org/abs/2012.07805](https://arxiv.org/abs/2012.07805)

### Prompt injection and LLM security

- **Greshake et al. 2023** — *Not what you've signed up for:
  Compromising Real-World LLM-Integrated Applications with Indirect
  Prompt Injection*.
  [arxiv.org/abs/2302.12173](https://arxiv.org/abs/2302.12173)
- **Perez & Ribeiro 2022** — *Ignore Previous Prompt: Attack
  Techniques For Language Models*.
  [arxiv.org/abs/2211.09527](https://arxiv.org/abs/2211.09527)

### Differential privacy

- **Dwork & Roth 2014** — *The Algorithmic Foundations of
  Differential Privacy* (textbook).
  [cis.upenn.edu/~aaroth/Papers/privacybook.pdf](https://www.cis.upenn.edu/~aaroth/Papers/privacybook.pdf)
- **Abadi et al. 2016** — *Deep Learning with Differential Privacy*
  (DP-SGD). [arxiv.org/abs/1607.00133](https://arxiv.org/abs/1607.00133)

## Tools referenced in later modules

Not required reading for mod-101, but the sources chapter references
point to:

- **HashiCorp Vault** — [developer.hashicorp.com/vault/docs](https://developer.hashicorp.com/vault/docs) (mod-105)
- **SPIFFE / SPIRE** — [spiffe.io/docs/latest](https://spiffe.io/docs/latest/) (mod-103)
- **Open Policy Agent / Rego** — [openpolicyagent.org/docs/latest](https://www.openpolicyagent.org/docs/latest/) (mod-109)
- **OPA Gatekeeper** — [open-policy-agent.github.io/gatekeeper/website/docs](https://open-policy-agent.github.io/gatekeeper/website/docs/) (mod-109)
- **Kyverno** — [kyverno.io](https://kyverno.io/) (mod-109 alternative)
- **Falco** — [falco.org/docs](https://falco.org/docs/) (mod-111)
- **Adversarial Robustness Toolbox (ART)** — [adversarial-robustness-toolbox.readthedocs.io](https://adversarial-robustness-toolbox.readthedocs.io/) (mod-106)
- **Opacus (DP-SGD for PyTorch)** — [opacus.ai](https://opacus.ai/) (mod-108)
- **Microsoft Presidio (PII/PHI DLP)** — [microsoft.github.io/presidio](https://microsoft.github.io/presidio/) (mod-108)
- **Lakera (prompt-injection scanning)** — [lakera.ai](https://www.lakera.ai/) (mod-107)
- **CIS Kubernetes Benchmark** — [cisecurity.org/benchmark/kubernetes](https://www.cisecurity.org/benchmark/kubernetes) (mod-103)

## Cross-references within this curriculum

- The [module plan](../../CURRICULUM.md) and the [job-requirements
  packet](../../JOB_REQUIREMENTS.md) at the repository root.
- Legacy modules `mod-001-ml-security-foundations` …
  `mod-012-capstone` from an earlier framing of the track — reusable
  reference material; the mod-101 … mod-112 sequence supersedes them
  as the current curriculum.
- The paired solutions repo (linked from the top-level README).

## Things deliberately not on this list

- Vendor whitepapers positioned as primary sources. Vendor documents
  describe products; cite standards and primary research instead.
- AI-safety-adjacent material focused on existential / alignment
  topics — outside the scope of this track's operational security
  slice.
- Books that pre-date the OWASP LLM Top 10 or NIST AI 100-2 e2023
  work; the vocabulary they use is out of date for this role.
