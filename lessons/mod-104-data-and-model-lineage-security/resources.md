# Resources — mod-104 (Data and Model Lineage Security)

> Primary sources for the six topic areas the module covers:
> end-to-end ML provenance (chapter 01), keyless artifact signing
> with Sigstore / cosign (chapter 02), SLSA v1.0 and in-toto
> provenance attestations for ML builds (chapter 03), CycloneDX
> ML-BOM authoring (chapter 04), model / system card evidence
> linking (chapter 05), and immutable / tamper-evident audit-log
> architecture (chapter 06). Verify every URL and version at time
> of access; the field moves and links rot. Where a citation
> pins to a specific edition, the pinned version is called out.

---

## Sigstore, cosign, Fulcio, Rekor — keyless signing and transparency

- **Sigstore project.** [sigstore.dev](https://www.sigstore.dev/)
  Umbrella project for the keyless-signing stack referenced across
  chapters 02, 03, and 06.

- **Sigstore documentation.**
  [docs.sigstore.dev](https://docs.sigstore.dev/)
  Component index: cosign (signing), Fulcio (short-lived cert
  authority), Rekor (transparency log). The private-deployment
  guide lives here.

- **cosign.**
  [github.com/sigstore/cosign](https://github.com/sigstore/cosign)
  The signer / verifier binary chapter 02 walks in depth
  (`cosign sign`, `cosign sign-blob`, `cosign attest`,
  `cosign verify-attestation`) and that mod-103's admission gate
  invokes.

- **cosign — key management, keyless signing, and OIDC flows.**
  Section-level docs at
  [docs.sigstore.dev/signing/overview](https://docs.sigstore.dev/signing/overview/)
  and
  [docs.sigstore.dev/cosign/openid_signing](https://docs.sigstore.dev/cosign/openid_signing/).
  Covers the OIDC → Fulcio → ephemeral-key → Rekor flow that
  chapter 02 depends on.

- **Fulcio — short-lived certificate authority.**
  [docs.sigstore.dev/certificate_authority/overview](https://docs.sigstore.dev/certificate_authority/overview/)
  Certificate profile, OIDC identity claims embedded in
  extensions, root and intermediate rotation policy.

- **Rekor — transparency log.**
  [docs.sigstore.dev/logging/overview](https://docs.sigstore.dev/logging/overview/)
  Entry types (`hashedrekord`, `intoto`, `dsse`), inclusion
  proofs, tree-head format. Chapter 06 pattern A uses
  `hashedrekord` as the hash-only audit entry type.

- **Rekor API reference.**
  [docs.sigstore.dev/logging/rekor-api](https://docs.sigstore.dev/logging/rekor-api/)
  and OpenAPI at
  [github.com/sigstore/rekor/tree/main/openapi.yaml](https://github.com/sigstore/rekor/blob/main/openapi.yaml).

- **Sigstore trust root and public-good service.**
  [docs.sigstore.dev/trust_the_root](https://docs.sigstore.dev/trust_the_root/)
  The community-run instance (`fulcio.sigstore.dev`,
  `rekor.sigstore.dev`) and the guidance on when to run
  private Fulcio / Rekor instead.

- **DSSE — Dead Simple Signing Envelope.**
  [github.com/secure-systems-lab/dsse](https://github.com/secure-systems-lab/dsse)
  The envelope format Sigstore uses to carry in-toto attestations
  and DSSE-signed audit records (chapter 06 pattern B).

- **OpenSSF Model Signing (`model-transparency`).**
  [github.com/sigstore/model-transparency](https://github.com/sigstore/model-transparency)
  Sigstore-adjacent library for signing ML model artifacts
  (multi-file directory trees, safetensors, checkpoints). Useful
  when the artifact is not naturally a single OCI blob.

---

## SLSA and in-toto — provenance attestations

- **SLSA — Supply-chain Levels for Software Artifacts (v1.0,
  April 2023).**
  [slsa.dev/spec/v1.0](https://slsa.dev/spec/v1.0/)
  The provenance-attestation schema and the build-track levels
  chapter 03 authors against. Section links:
  - Provenance model:
    [slsa.dev/spec/v1.0/provenance](https://slsa.dev/spec/v1.0/provenance)
  - Build tracks (L0–L3):
    [slsa.dev/spec/v1.0/levels](https://slsa.dev/spec/v1.0/levels)
  - Verifying artifacts:
    [slsa.dev/spec/v1.0/verifying-artifacts](https://slsa.dev/spec/v1.0/verifying-artifacts)

- **SLSA provenance predicate JSON Schema.**
  [github.com/slsa-framework/slsa/tree/main/docs/spec/v1.0](https://github.com/slsa-framework/slsa/tree/main/docs/spec/v1.0)
  The `buildDefinition` + `runDetails` structure that chapter 03
  populates.

- **in-toto — supply-chain metadata framework.**
  [in-toto.io](https://in-toto.io/)
  and specification repository at
  [github.com/in-toto/attestation](https://github.com/in-toto/attestation).
  The attestation envelope format Sigstore uses to carry SLSA
  provenance, ML-BOM, evaluation reports, and other predicates.

- **in-toto attestation predicates.**
  [github.com/in-toto/attestation/tree/main/spec/predicates](https://github.com/in-toto/attestation/tree/main/spec/predicates)
  Registered predicate types (SLSA provenance, SPDX, CycloneDX,
  test-result). Chapter 03 and exercise 04 pin these types
  explicitly.

- **in-toto test-result predicate
  (`https://in-toto.io/attestation/test-result/v0.1`).**
  [github.com/in-toto/attestation/blob/main/spec/predicates/test-result.md](https://github.com/in-toto/attestation/blob/main/spec/predicates/test-result.md)
  The predicate exercise 04's eval-run attestation uses.

- **SLSA GitHub Generator.**
  [github.com/slsa-framework/slsa-github-generator](https://github.com/slsa-framework/slsa-github-generator)
  Reference builder producing SLSA-compliant provenance from
  GitHub Actions; the substrate chapter 03 walks through for the
  training-pipeline example.

- **Witness — attestation collector.**
  [github.com/testifysec/witness](https://github.com/testifysec/witness)
  Alternative provenance-emitting toolchain that wraps arbitrary
  build steps and emits in-toto attestations.

- **GUAC — Graph for Understanding Artifact Composition.**
  [guac.sh](https://guac.sh/)
  and
  [github.com/guacsec/guac](https://github.com/guacsec/guac).
  OpenSSF project that ingests SLSA attestations and SBOMs into a
  queryable graph — useful for reasoning about upstream ML supply
  chains at scale.

- **OpenSSF SLSA + Sigstore joint reference.**
  [openssf.org/blog](https://openssf.org/blog/)
  (search "SLSA"). Community write-ups of the two-standard
  integration.

---

## CycloneDX ML-BOM (AI-BOM) and SBOM standards

- **CycloneDX — main site.**
  [cyclonedx.org](https://cyclonedx.org/)
  The umbrella specification with SBOM, ML-BOM (AI-BOM), SaaSBOM,
  HBOM (hardware) profiles.

- **CycloneDX — machine-learning bill of materials (ML-BOM).**
  [cyclonedx.org/capabilities/mlbom](https://cyclonedx.org/capabilities/mlbom/)
  The AI/ML profile: `component.type: machine-learning-model`,
  `component.modelCard`, dataset components, framework
  components, provenance claims. The primary source for chapter
  04.

- **CycloneDX specification (JSON Schema and normative text).**
  [github.com/CycloneDX/specification](https://github.com/CycloneDX/specification)
  Pin `spec/1.6/bom-1.6.schema.json` when quoting a field; the
  spec advances one minor version at a time and older schemas
  remain valid.

- **CycloneDX Authoritative Guide to SBOMs / xBOMs.**
  [cyclonedx.org/guides](https://cyclonedx.org/guides/)
  Freely downloadable authoring guides — the AI-BOM guide is the
  right long-form read alongside chapter 04.

- **SPDX 3.0 — Software Package Data Exchange.**
  [spdx.dev](https://spdx.dev/)
  Alternative BOM format with an AI profile
  ([spdx.github.io/spdx-spec/v3.0.1/model/AI/AI](https://spdx.github.io/spdx-spec/v3.0.1/model/AI/AI/)).
  Chapter 04 notes SPDX as a valid alternative for orgs already
  standardised on it.

- **Package URL (purl) specification.**
  [github.com/package-url/purl-spec](https://github.com/package-url/purl-spec)
  The `pkg:...` identifier scheme every CycloneDX component
  entry in chapter 04 uses.

- **CycloneDX cli / bom tooling.**
  [github.com/CycloneDX/cyclonedx-cli](https://github.com/CycloneDX/cyclonedx-cli)
  Validate, merge, convert CycloneDX documents; used in exercise
  03's acceptance checks.

- **Syft — SBOM generator.**
  [github.com/anchore/syft](https://github.com/anchore/syft)
  Generates SBOMs (CycloneDX or SPDX) from container images and
  filesystem trees. Chapter 04 uses `syft` output as a starting
  point for the training-container components of the ML-BOM.

- **Trivy — SBOM + vulnerability scanner.**
  [aquasecurity.github.io/trivy](https://aquasecurity.github.io/trivy/)
  Emits CycloneDX / SPDX SBOMs and cross-references CVE
  databases. Chapter 04 references it for the vulnerability
  overlay on the ML-BOM.

- **Grype — vulnerability scanner.**
  [github.com/anchore/grype](https://github.com/anchore/grype)
  Consumes SBOMs / images and cross-references CVE data. Cited
  in chapter 04 alongside Trivy.

- **VEX — Vulnerability Exploitability eXchange.**
  [github.com/openvex/spec](https://github.com/openvex/spec)
  and CycloneDX VEX profile at
  [cyclonedx.org/capabilities/vex](https://cyclonedx.org/capabilities/vex/).
  Companion format for stating that a component-CVE match is
  not exploitable in the given deployment context.

- **NTIA — *The Minimum Elements For a Software Bill of
  Materials (SBOM)*** (July 2021).
  [ntia.gov/report/2021/minimum-elements-software-bill-materials-sbom](https://www.ntia.gov/report/2021/minimum-elements-software-bill-materials-sbom)
  Baseline SBOM requirements the US federal government references.
  Useful as the floor a compliant ML-BOM must clear.

- **CISA — SBOM guidance.**
  [cisa.gov/sbom](https://www.cisa.gov/sbom)
  Ongoing SBOM work at CISA, including AI-BOM discussions.

- **Protect AI ModelScan.**
  [github.com/protectai/modelscan](https://github.com/protectai/modelscan)
  Model-artifact scanner (pickle / TF / Keras / ONNX) whose
  output is a natural evidence attachment to an ML-BOM
  provenance claim.

- **Hugging Face `safetensors`.**
  [github.com/huggingface/safetensors](https://github.com/huggingface/safetensors)
  Safer weight-serialisation format; referenced as a
  ML-BOM-component property (`serialisation-format: safetensors`).

---

## Model cards, system cards, data cards, datasheets

- **Mitchell et al. — *Model Cards for Model Reporting*** (FAT*
  2019).
  [arxiv.org/abs/1810.03677](https://arxiv.org/abs/1810.03677)
  The canonical model-card paper. Chapter 05's model-card
  section list follows this template.

- **Gebru et al. — *Datasheets for Datasets*** (2018; CACM
  2021).
  [arxiv.org/abs/1803.09010](https://arxiv.org/abs/1803.09010)
  The dataset-documentation analogue chapter 05 references for
  the "training data" section of a model card.

- **Google — Model Card Toolkit.**
  [github.com/tensorflow/model-card-toolkit](https://github.com/tensorflow/model-card-toolkit)
  Python library and JSON schema for generating model cards.
  Chapter 05 references it as one of the two publishing
  conventions.

- **Hugging Face — model repository README front-matter and
  card conventions.**
  - Overview:
    [huggingface.co/docs/hub/model-cards](https://huggingface.co/docs/hub/model-cards)
  - Front-matter specification:
    [huggingface.co/docs/hub/model-card-annotated](https://huggingface.co/docs/hub/model-card-annotated)
  - Model index (metrics with `verified` flag):
    [huggingface.co/docs/hub/model-cards#model-card-metadata](https://huggingface.co/docs/hub/model-cards#model-card-metadata)
  The publishing surface exercise 04 targets.

- **Google — Data Cards Playbook.**
  [sites.research.google/datacardsplaybook](https://sites.research.google/datacardsplaybook/)
  Extended dataset-documentation guidance drawn on for chapter
  05's data-provenance narrative.

- **Meta — System cards for AI systems.**
  [ai.meta.com/tools/system-cards](https://ai.meta.com/tools/system-cards/)
  Meta's system-card programme; representative of the
  system-card-vs-model-card split chapter 05 walks.
  <!-- needs-research: confirm the current landing page slug;
  Meta occasionally reorganises the AI system-card index -->

- **OpenAI — System cards for GPT-family releases.**
  [openai.com/research](https://openai.com/research/)
  Search "system card". The `gpt-4` and successor system cards
  are the reference the "system card" vocabulary in chapter 05
  descends from.

- **Anthropic — Model / system-card style content.**
  [anthropic.com/news](https://www.anthropic.com/news)
  Model announcements accompanied by capability and safety
  documentation resembling the model-card + system-card split.

- **Partnership on AI — About ML: Annotation and Benchmarking
  on Understanding and Transparency of Machine Learning
  Lifecycles.**
  [partnershiponai.org/workstream/about-ml](https://partnershiponai.org/workstream/about-ml/)
  Multi-organisation project on ML documentation standards.
  <!-- needs-research: confirm the current status of the ABOUT
  ML v2 report and its canonical URL -->

---

## Immutable / WORM storage — cloud-provider primitives

### AWS

- **Amazon S3 Object Lock.**
  [docs.aws.amazon.com/AmazonS3/latest/userguide/object-lock.html](https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lock.html)
  The primary source for the two retention modes chapter 06
  uses: `GOVERNANCE` (bypassable) and `COMPLIANCE`
  (non-bypassable, including by root). The chapter's audit-sink
  recipe pins `COMPLIANCE`.

- **S3 Object Lock — how it works.**
  [docs.aws.amazon.com/AmazonS3/latest/userguide/object-lock-overview.html](https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lock-overview.html)
  Retention periods, legal holds, and interaction with
  versioning.

- **S3 Replication (CRR / SRR) and Object Lock.**
  [docs.aws.amazon.com/AmazonS3/latest/userguide/replication.html](https://docs.aws.amazon.com/AmazonS3/latest/userguide/replication.html)
  Cross-region and cross-account replication mechanics, including
  the `DeleteMarkerReplication` guardrail chapter 06 relies on.

- **AWS CloudTrail.**
  [docs.aws.amazon.com/awscloudtrail/latest/userguide](https://docs.aws.amazon.com/awscloudtrail/latest/userguide/)
  The AWS control-plane audit log — a *consumer* of the audit
  design in this module, not the ML-platform audit stream itself.
  Chapters 01 and 06 explicitly distinguish the two.

### GCP

- **Cloud Storage — Bucket Lock (retention policies).**
  [cloud.google.com/storage/docs/bucket-lock](https://cloud.google.com/storage/docs/bucket-lock)
  Retention policy semantics; `--lock-retention-policy` makes
  the policy permanent (analogous to S3 COMPLIANCE mode).

- **Cloud Storage — Retention holds and event-based holds.**
  [cloud.google.com/storage/docs/holding-objects](https://cloud.google.com/storage/docs/holding-objects)
  The GCS analogue of AWS legal holds.

- **Cloud Storage — Object Versioning.**
  [cloud.google.com/storage/docs/object-versioning](https://cloud.google.com/storage/docs/object-versioning)
  Prerequisite for a defensible audit-sink configuration on GCP.

### Azure

- **Azure Blob Storage — immutability policies (time-based
  retention and legal holds).**
  [learn.microsoft.com/en-us/azure/storage/blobs/immutable-storage-overview](https://learn.microsoft.com/en-us/azure/storage/blobs/immutable-storage-overview)
  The Azure equivalent of Object Lock / Bucket Lock.

- **Azure Blob Storage — configure immutability policies.**
  [learn.microsoft.com/en-us/azure/storage/blobs/immutable-policy-configure-version-scope](https://learn.microsoft.com/en-us/azure/storage/blobs/immutable-policy-configure-version-scope)
  The API surface for locking a time-based retention policy;
  once locked, the policy cannot be shortened.

---

## Tamper-evident logs — Merkle-tree infrastructure

- **Trillian.**
  [github.com/google/trillian](https://github.com/google/trillian)
  Google's Merkle-tree log server; the substrate under Rekor
  and Certificate Transparency. Chapter 06 pattern B recommends
  a private Trillian instance for organisations wanting a
  self-contained audit trail.

- **Trillian — verifiable log design.**
  [github.com/google/trillian/blob/master/docs/papers/RFC6962BisWithLogsScalability.pdf](https://github.com/google/trillian/blob/master/docs/papers/RFC6962BisWithLogsScalability.pdf)
  <!-- needs-research: confirm the current canonical URL for
  the Trillian design paper — Google restructures GitHub docs
  periodically -->

- **RFC 6962 — Certificate Transparency.**
  [datatracker.ietf.org/doc/html/rfc6962](https://datatracker.ietf.org/doc/html/rfc6962)
  The original transparency-log protocol chapter 06's Merkle-tree
  primitive descends from. RFC 9162 is the v2 successor.

- **RFC 9162 — Certificate Transparency Version 2.0.**
  [datatracker.ietf.org/doc/html/rfc9162](https://datatracker.ietf.org/doc/html/rfc9162)
  Updated protocol; useful reading if you are designing a
  private log meant to interoperate with CT-style verifiers.

- **Sigstore Rekor as a Trillian instance.**
  [docs.sigstore.dev/logging/overview](https://docs.sigstore.dev/logging/overview/)
  Rekor is a Trillian-backed log tailored to signature bundles.
  Chapter 06 pattern A reuses public Rekor for hash-only audit
  entries.

- **Transparency Dev / Trillian community.**
  [transparency.dev](https://transparency.dev/)
  Community hub for transparency-log implementations and
  monitor design.

---

## Retention, governance, and regulatory anchors

> Every regulatory citation must be verified against the primary
> source at time of use. Verify article numbers, clause numbers,
> and retention durations against the current consolidated text
> before quoting externally.

- **Regulation (EU) 2024/1689 — the EU AI Act.**
  Consolidated text at
  [eur-lex.europa.eu/eli/reg/2024/1689/oj](https://eur-lex.europa.eu/eli/reg/2024/1689/oj).
  Article 11 and Annex IV specify technical documentation for
  high-risk AI systems. Article 12 covers automatic recording of
  events / logging. Article 13 covers transparency to users.
  Chapters 01, 05, and 06 lean on these articles.
  <!-- needs-research: verify article numbering and annex
  references against the current consolidated text before
  external publication; the Act was published in the OJEU in
  July 2024 and article references have drifted from earlier
  drafts -->

- **NIST AI Risk Management Framework (AI RMF 1.0)** (January
  2023).
  [nist.gov/itl/ai-risk-management-framework](https://www.nist.gov/itl/ai-risk-management-framework)
  MAP, MEASURE, MANAGE, GOVERN functions. Chapters 01 and 05
  align model-card evidence with MEASURE and MANAGE outputs.

- **NIST AI 100-1 (AI RMF 1.0 PDF).**
  [nvlpubs.nist.gov/nistpubs/ai/NIST.AI.100-1.pdf](https://nvlpubs.nist.gov/nistpubs/ai/NIST.AI.100-1.pdf)

- **NIST AI 600-1 — Generative AI Profile of the AI RMF** (July
  2024).
  [nvlpubs.nist.gov/nistpubs/ai/NIST.AI.600-1.pdf](https://nvlpubs.nist.gov/nistpubs/ai/NIST.AI.600-1.pdf)
  Adds GenAI-specific risks and evidence obligations that
  chapter 05's system-card guidance mirrors.

- **NIST SP 800-53 rev 5 — *Security and Privacy Controls for
  Information Systems and Organizations*.**
  [csrc.nist.gov/pubs/sp/800/53/r5/upd1/final](https://csrc.nist.gov/pubs/sp/800/53/r5/upd1/final)
  The AU (audit) control family that chapter 06's retention and
  monitoring design implements; the CM (configuration
  management) family that chapter 03 provenance answers to.

- **ISO/IEC 42001:2023 — AI management systems.**
  [iso.org/standard/81230.html](https://www.iso.org/standard/81230.html)
  Chapters 01, 04, and 05 map evidence outputs to specific
  ISO/IEC 42001 clauses.
  <!-- needs-research: pin specific clause numbers (documented
  information, operational planning, monitoring) before
  external citation; ISO clauses are paywalled and clause
  numbers should be verified against a current copy of the
  standard -->

- **ISO/IEC 23894:2023 — AI risk management guidance.**
  [iso.org/standard/77304.html](https://www.iso.org/standard/77304.html)
  Companion to 42001, complementary to NIST AI RMF.

- **ISO/IEC 5259 series — Data quality for analytics and
  machine learning.**
  [iso.org/standard/81088.html](https://www.iso.org/standard/81088.html)
  Data-quality standards chapter 01's dataset-snapshot evidence
  supports.

- **FRB SR 11-7 — *Guidance on Model Risk Management*** (April
  2011; still current for banks).
  [federalreserve.gov/supervisionreg/srletters/sr1107.htm](https://www.federalreserve.gov/supervisionreg/srletters/sr1107.htm)
  US bank model-risk expectations; chapter 01 cites its
  documentation and effective-challenge requirements for the
  retention-driver discussion.

- **OCC 2011-12 (interagency) — Supervisory Guidance on Model
  Risk Management.**
  [occ.gov/news-issuances/bulletins/2011/bulletin-2011-12.html](https://www.occ.gov/news-issuances/bulletins/2011/bulletin-2011-12.html)
  Companion issuance for OCC-supervised institutions.

- **HIPAA — 45 CFR § 164.316(b)(2)(i).**
  [ecfr.gov/current/title-45/subtitle-A/subchapter-C/part-164](https://www.ecfr.gov/current/title-45/subtitle-A/subchapter-C/part-164)
  Six-year retention for HIPAA Security Rule documentation, one
  of the retention floors chapter 01 references for
  healthcare-adjacent ML systems.
  <!-- needs-research: confirm current section citation for the
  six-year retention floor before external publication -->

- **GDPR (Regulation (EU) 2016/679).**
  [eur-lex.europa.eu/eli/reg/2016/679/oj](https://eur-lex.europa.eu/eli/reg/2016/679/oj)
  Data-minimisation and retention obligations that constrain
  training-data retention decisions in chapter 01.

---

## MLOps lineage / metadata systems (context, not primary evidence)

> These systems record lineage but are *not* signed provenance.
> Chapters 01 and 03 make the distinction explicit — MLflow /
> W&B / Vertex Lineage answer "what came from what" but not
> "who signed this and can you prove it".

- **MLflow.**
  [mlflow.org/docs/latest](https://mlflow.org/docs/latest/)
  Tracking, model registry, model versions. Chapter 01 treats
  MLflow tracking as lineage metadata, not audit evidence.

- **Weights & Biases.**
  [docs.wandb.ai](https://docs.wandb.ai/)
  Experiment tracking; artifact versioning.

- **Vertex AI ML Metadata / Vertex ML Lineage.**
  [cloud.google.com/vertex-ai/docs/ml-metadata](https://cloud.google.com/vertex-ai/docs/ml-metadata)
  and
  [cloud.google.com/vertex-ai/docs/lineage](https://cloud.google.com/vertex-ai/docs/lineage).
  GCP's lineage store.

- **SageMaker ML Lineage Tracking.**
  [docs.aws.amazon.com/sagemaker/latest/dg/lineage-tracking.html](https://docs.aws.amazon.com/sagemaker/latest/dg/lineage-tracking.html)
  AWS equivalent.

- **Kubeflow Pipelines — metadata.**
  [www.kubeflow.org/docs/components/pipelines/](https://www.kubeflow.org/docs/components/pipelines/)
  Pipeline metadata used as the lineage substrate chapters 01
  and 03 sign *on top of*.

- **ML Metadata (MLMD) library.**
  [github.com/google/ml-metadata](https://github.com/google/ml-metadata)
  Upstream library the TFX and Kubeflow lineage stores build
  on.

- **MLCroissant — dataset metadata format.**
  [github.com/mlcommons/croissant](https://github.com/mlcommons/croissant)
  Emerging dataset-metadata standard useful as the source-of-
  truth format for the dataset section of an ML-BOM.

---

## OCI registry, ORAS, and artifact-transport primitives

- **OCI Distribution Specification.**
  [github.com/opencontainers/distribution-spec](https://github.com/opencontainers/distribution-spec)
  Registry API surface; chapter 02 pushes signatures via cosign
  into an OCI-conformant registry.

- **OCI Image Specification.**
  [github.com/opencontainers/image-spec](https://github.com/opencontainers/image-spec)

- **ORAS — OCI Registry As Storage.**
  [oras.land](https://oras.land/)
  The pattern chapter 02 uses to push model artifacts and ML-BOM
  attestations as OCI artifacts to any OCI-compliant registry.

- **Referrers API (OCI 1.1).**
  [github.com/opencontainers/distribution-spec/blob/main/spec.md#listing-referrers](https://github.com/opencontainers/distribution-spec/blob/main/spec.md#listing-referrers)
  The mechanism by which signatures, attestations, and ML-BOM
  documents attach to a subject artifact without requiring a
  separate tag.

---

## Threat and adversary references

- **MITRE ATLAS — Adversarial Threat Landscape for Artificial
  Intelligence Systems.**
  [atlas.mitre.org](https://atlas.mitre.org/)
  Adversary techniques against ML systems; chapters 01 and 06
  reference the model-supply-chain and model-tampering
  categories as the adversary this module's provenance and
  audit-log controls are written to survive.

- **NIST AI 100-2 (2E 2025) — *Adversarial Machine Learning: A
  Taxonomy and Terminology of Attacks and Mitigations*.**
  [nvlpubs.nist.gov/nistpubs/ai/NIST.AI.100-2e2025.pdf](https://nvlpubs.nist.gov/nistpubs/ai/NIST.AI.100-2e2025.pdf)
  <!-- needs-research: confirm the current publication filename
  and edition; NIST re-publishes this taxonomy periodically -->
  Companion taxonomy — the shared vocabulary chapter 01's
  threat framing uses.

- **OWASP Top 10 for LLM Applications.**
  [owasp.org/www-project-top-10-for-large-language-model-applications](https://owasp.org/www-project-top-10-for-large-language-model-applications/)
  Referenced for chapter 05's system-card residual-risk
  section.

---

## Cross-references within this curriculum

- The [module plan](../../CURRICULUM.md) and the [job-
  requirements packet](../../JOB_REQUIREMENTS.md) at the
  repository root.
- Sibling modules:
  - [mod-102](../mod-102-threat-modelling-for-ai-ml-systems/) —
    the STRIDE + attack-tree scorecard names the adversaries
    this module's controls counter.
  - [mod-103](../mod-103-secure-ml-platform-architecture/) —
    installs the SPIFFE identity, admission gate, and mesh authz
    that consume this module's signatures and ML-BOM.
  - [mod-105](../mod-105-secrets-and-key-management/) — owns the
    KMS holding cosign signing keys and the Rekor / Trillian log
    signing keys.
  - [mod-109](../mod-109-ai-governance-and-compliance-engineering/) —
    consumes the model cards, system cards, and audit exports
    authored here as evidence at governance audits.
  - [mod-110](../mod-110-supply-chain-security-for-ai/) — the
    upstream-model-and-dataset scanning and third-party-artifact
    provenance verification chapters that hand the components to
    this module's ML-BOM.
  - [mod-111](../mod-111-security-operations-and-incident-response-for-ml/) —
    consumes the event bus authored in chapter 06 as the primary
    detection surface for ML-platform anomalies.
- The paired solutions repo (linked from the top-level README).

---

## Things deliberately not on this list

- Vendor whitepapers positioned as primary sources for
  provenance or ML-BOM authoring. Cite the standards (SLSA,
  in-toto, CycloneDX ML-BOM, ISO/IEC 42001) — vendor documents
  describe implementations.
- "AI-BOM in a box" marketing pages. The CycloneDX ML-BOM
  specification and the Authoritative Guide contain everything
  needed.
- Blog posts as the sole source for a control claim. If a
  control is real, it exists in the standard, the tool's
  documentation, or a NIST / ISO publication; those are the
  citations to use.
- SIEM product documentation as an authority on audit-log
  integrity. Splunk / Datadog / Elastic docs describe *consumer*
  behaviour; the integrity guarantees are set by the WORM store
  and the tamper-evident log, not by the SIEM.
