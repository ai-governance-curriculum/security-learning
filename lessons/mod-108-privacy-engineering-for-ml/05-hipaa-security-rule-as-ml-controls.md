# Chapter 05 — HIPAA Security Rule as ML Platform Controls

> **Note on AI-assisted content.** This chapter is not legal
> advice. HIPAA regulatory text and OCR (HHS Office for Civil
> Rights) guidance evolve; verify every citation against the
> primary source (45 CFR Part 164 Subpart C on
> [eCFR](https://www.ecfr.gov/current/title-45/subtitle-A/subchapter-C/part-164))
> and the org's Security Officer / counsel before publishing
> externally. The mapping below is the engineering translation
> intended for the platform team; the Security Officer owns the
> formal control determination. See [`resources.md`](./resources.md).

---

## Why this chapter exists

If the ML platform touches Protected Health Information (PHI)
under HIPAA, the org is either a **covered entity** (health
plan, health-care clearinghouse, or a healthcare provider
transmitting electronic transactions) or a **business associate**
(a vendor performing a function or service on behalf of a
covered entity involving PHI). Either way, the HIPAA **Security
Rule** (45 CFR §§ 164.302–318) applies to electronic PHI
(ePHI), and there is no ML-specific version of the rule — the
rule is written for information systems generally, and the
platform team must translate.

The specific failure mode this chapter is written to prevent:

> A healthcare vendor builds an ML feature that ingests
> patient notes, embeds them for retrieval, and answers
> clinician questions from the embeddings. A Business
> Associate Agreement (BAA) is in place with the covered
> entity. The engineering team ships storage encryption,
> mTLS, and access controls — all reasonable IT-security
> practices. Twelve months later, an incident: prompt logs
> retained in a shared S3 bucket without ePHI-appropriate
> access controls; no risk analysis document per
> §164.308(a)(1)(ii)(A) exists; no Security Officer per
> §164.308(a)(2) is named; the six-year documentation
> retention under §164.316(b)(2) is missing three of the
> twelve months. The technical controls looked fine; the
> **required standards** the Security Rule enumerates were
> half-shipped.

The Security Rule is not a technology stack. It is a
programme with **standards** and **implementation
specifications** — some *required*, some *addressable* — that
the covered entity or business associate must have. This
chapter walks the standards and names the ML-platform-specific
control that satisfies each.

You leave this chapter able to:

- Read the Security Rule at the level of standards and
  implementation specifications; identify which apply to ML
  systems.
- Produce a **HIPAA control-mapping matrix** for one ML
  system that names, per standard, the concrete platform
  control, the owner, and the evidence artefact.
- Distinguish "PHI in training data" from "PHI at inference"
  from "PHI in trajectory / prompt logs" from "PHI in
  supporting artefacts (backups, snapshots, canary sets)"
  and apply the right controls to each.
- Understand the Breach Notification Rule enough to know
  when a Security Rule failure has escalated into a reportable
  event.
- Own the **Business Associate Agreement (BAA) implications**
  for ML platform decisions — what a BAA obliges the
  business associate to, and what a subcontractor / model-
  provider BAA needs.

Chapter 04 covered GDPR; this chapter covers HIPAA. For a
system touching both (a US healthcare provider serving EEA
residents; a US-based business associate operating on EU
patient data), the two frameworks compose — most controls are
compatible; specific tensions (data-subject rights vs.
minimum-necessary access, cross-border transfer vs. HIPAA
disclosure) resolve at the DPO / Security Officer level.

---

## Where the Security Rule lives and how to read it

Structure of 45 CFR Part 164 Subpart C:

- **§164.302** — Applicability. The Security Rule applies to
  covered entities and, per HITECH / Omnibus Rule, directly to
  business associates.
- **§164.304** — Definitions.
- **§164.306** — General rules. The four security-programme
  requirements (ensure confidentiality, integrity, and
  availability of ePHI; protect against reasonably-anticipated
  threats; protect against reasonably-anticipated impermissible
  uses/disclosures; ensure workforce compliance) and the
  flexibility-of-approach principle (§164.306(b) — the entity
  may use any measures reasonable and appropriate given its
  size, complexity, cost, and threat environment).
- **§164.308** — **Administrative safeguards.** Nine
  standards.
- **§164.310** — **Physical safeguards.** Four standards.
- **§164.312** — **Technical safeguards.** Five standards.
- **§164.314** — Organizational requirements (BAA content).
- **§164.316** — Policies, procedures, and documentation.
- **§164.318** — Compliance dates.

Each **standard** may have one or more **implementation
specifications**. Each specification is either **required** (R)
or **addressable** (A). "Addressable" is a common source of
confusion:

- Addressable does **not** mean optional. It means: the entity
  must assess whether the specification is reasonable and
  appropriate given its environment; if yes, implement; if
  no, document why not and implement an equivalent alternative.
- "We decided not to bother" is not a documented rationale.
- The addressable determination is a written artefact retained
  under §164.316.

Also relevant, though outside Subpart C:

- **Privacy Rule** (Subpart E, §§ 164.500–534) — the
  substantive rules on PHI use and disclosure, including the
  **minimum-necessary** standard (§164.502(b)), the
  designated-record-set concept (§164.501), and individual
  rights.
- **Breach Notification Rule** (Subpart D, §§ 164.400–414) —
  what constitutes a breach and the notification obligations.
- **HITECH Act / Omnibus Rule** — the 2013 amendments that
  extended direct Security Rule applicability to business
  associates and tightened breach notification.

The ML platform team needs enough of the Privacy Rule and the
Breach Rule to know when a design decision is a compliance
issue; the Security Rule is where the engineering controls
map.

---

## The PHI surfaces on an ML platform

Before mapping controls, name where PHI lives on an ML
platform. Every surface gets its own control set:

1. **PHI in the training data.** Patient records, clinical
   notes, imaging, lab results — the corpus the model is
   trained or fine-tuned on. The most obviously-regulated
   surface; often the one platforms think about first.
2. **PHI at inference.** The prompt / feature vector sent to
   the model at serving time may contain PHI (a clinician
   pasting a note; an underwriter querying with patient
   details). This surface is separate from training.
3. **PHI in trajectory / prompt logs.** For LLM and agent
   systems, the retained log of prompts, tool calls, and
   completions. Frequently missed; frequently ends up as an
   unclassified ePHI store.
4. **PHI in the retrieval / RAG store.** Documents indexed
   for retrieval; every retrieval hit contains PHI. Separate
   access control model from the underlying database.
5. **PHI in model artefacts.** Model weights that memorised
   training data; embeddings that leak content
   (embedding-inversion attacks). Chapters 01 (DP-SGD) and
   02 (inference controls) address; the storage of the model
   itself is here.
6. **PHI in supporting artefacts.** Canary sets (chapter 02)
   with members' PHI; snapshots of feature stores; backups;
   log-analysis pipelines; monitoring dashboards that render
   PHI. Frequently missed.
7. **PHI in downstream integrations.** Third-party APIs the
   agent calls (a lab-results API, an insurance-eligibility
   API); each is a disclosure surface that requires a BAA if
   the third party is a business associate.

The HIPAA control-mapping matrix in this chapter has a row per
standard **and** a column per PHI surface — the same standard
often applies with different implementation details across
surfaces.

---

## Administrative safeguards (§164.308) — the programme

Nine standards. Every ML platform on PHI has to answer each.

### §164.308(a)(1) — Security Management Process

- **Risk analysis (R).** A thorough analysis of the potential
  risks and vulnerabilities to ePHI. For an ML platform, the
  risk analysis explicitly covers each PHI surface above;
  attacks from mod-102 (threat modelling), mod-106
  (adversarial ML), and mod-107 (LLM); the DP posture from
  chapter 01; the inference-attack risks from chapter 02.
- **Risk management (R).** Implement security measures
  sufficient to reduce risks to a reasonable and appropriate
  level. The mitigations from this module, mod-103, and
  mod-105.
- **Sanction policy (R).** Apply sanctions to workforce
  members who violate policies. Not an engineering control;
  HR + Security Officer own.
- **Information system activity review (R).** Regular review
  of records of information system activity (audit logs,
  access reports, security incident tracking). The mod-104
  audit log and the mod-106 chapter 05 serving-side
  telemetry feed this; someone has to actually review.

**ML platform artefact.** A **Security Rule risk analysis
document** referencing:

- Per PHI surface: assets, threats, vulnerabilities,
  likelihood, impact, existing controls, residual risk.
- The chapter-01 tier-map placement.
- The chapter-02 inference-attack threat model.
- Cross-references to mod-102 threat models.
- Sign-off by the Security Officer.
- Review cadence (annually and on material change).

### §164.308(a)(2) — Assigned Security Responsibility

- **Security Official (R).** Identify the individual
  responsible for the development and implementation of the
  policies and procedures required by the subpart.

**ML platform artefact.** A named Security Officer with the
authority and remit to enforce the HIPAA programme on the
platform. Not a title on a policy document — a real person
with real authority. If the org has a Security Officer at
the enterprise level and a platform-level delegate, both are
named.

### §164.308(a)(3) — Workforce Security

- **Authorisation and/or supervision (A).**
- **Workforce clearance procedure (A).**
- **Termination procedures (A).**

**ML platform artefact.** Access provisioning workflows for
ML platform workforce (data scientists, ML engineers,
platform SREs, on-call responders) covering onboarding,
periodic re-attestation, and off-boarding. Access to PHI
surfaces (training data, prompt logs, canary sets) is gated
per role; the deprovisioning path is automated and audited.

### §164.308(a)(4) — Information Access Management

- **Isolating healthcare clearinghouse functions (R)** — only
  applicable to healthcare-clearinghouse covered entities.
- **Access authorisation (A).**
- **Access establishment and modification (A).**

**ML platform artefact.** For every PHI surface, a written
access policy: who may access, under which role, with which
approval workflow. **Minimum-necessary** (from the Privacy
Rule §164.502(b)) applies here — access is scoped to the
minimum PHI needed for the workforce member's function.
mod-103 chapter 03's workload identity and mod-105's
per-caller credentials support the enforcement.

### §164.308(a)(5) — Security Awareness and Training

- **Security reminders (A).**
- **Protection from malicious software (A).**
- **Log-in monitoring (A).**
- **Password management (A).**

**ML platform artefact.** ML-team-specific training modules:
what PHI is, what the platform's PHI surfaces are, how DLP
(chapter 03) works, what the incident-reporting path is,
what actions require a formal risk-analysis update. Not
"annual click-through training" — role-appropriate content.

### §164.308(a)(6) — Security Incident Procedures

- **Response and reporting (R).** Identify and respond to
  suspected or known security incidents; mitigate; document
  incidents and their outcomes.

**ML platform artefact.** An ML-platform incident runbook
referencing mod-111 (incident response) and mod-107 chapter 05
(LLM-specific severity ladder). PHI-relevant incident
triggers named — DLP failure, prompt-log exposure, model-
extraction attempt with PHI inputs, MI-AUC regression on a
PHI-trained model. Documentation retained per §164.316.

### §164.308(a)(7) — Contingency Plan

- **Data backup plan (R).**
- **Disaster recovery plan (R).**
- **Emergency mode operation plan (R).**
- **Testing and revision procedures (A).**
- **Applications and data criticality analysis (A).**

**ML platform artefact.** Backup, DR, and business-continuity
plans that cover ePHI in **every surface**, not just the
primary database. Prompt logs, training snapshots, and
retrieval indices are all ePHI stores if they contain PHI —
back them up per policy or purge them per policy. Test the
recovery periodically.

### §164.308(a)(8) — Evaluation

- **Periodic technical and non-technical evaluation (R).**

**ML platform artefact.** A named cadence for platform-wide
Security Rule evaluation. Feeds the risk-analysis update and
the mod-109 governance evidence.

### §164.308(b) — Business Associate Contracts and Other
Arrangements

- **Written contract or other arrangement (R).** A BAA with
  every business associate.

**ML platform artefact.** A **BAA register** listing every
third-party service that touches PHI on behalf of the
platform. For ML systems, this frequently includes:

- Model providers (hosted LLM APIs, hosted embedding APIs)
  when PHI is included in requests. A BAA with the model
  provider is required; not every provider offers one.
- Managed vector databases holding embeddings of PHI.
- Observability providers ingesting logs that contain PHI
  (this is where the surprise usually lands).
- Cloud providers hosting the compute (typically covered by
  a platform-wide BAA, but verify it covers the ML services
  used).
- Any subcontractor of a business associate under §164.502(e)
  and §164.308(b)(2) — a chain of BAAs may be required.

**No BAA → no PHI to the third party.** This is the platform's
enforcement point. Chapter 03's DLP redacts PHI before it
would cross to a non-BAA-covered service; the tool ACLs from
mod-107 chapter 03 block calls that would send PHI to
non-BAA-covered tools.

---

## Physical safeguards (§164.310)

Four standards. For cloud-hosted platforms, most of these are
inherited from the cloud provider's controls (SOC 2, ISO
27001, HITRUST attestations) and evidenced by the provider's
BAA + attestation reports. Named for completeness:

### §164.310(a)(1) — Facility Access Controls

- **Contingency operations (A).**
- **Facility security plan (A).**
- **Access control and validation procedures (A).**
- **Maintenance records (A).**

**ML platform artefact.** For cloud-hosted training clusters
and serving infra: inherit from the cloud provider's
facility controls; attach the provider's BAA + attestation
report to the risk analysis. For any on-premises GPU
cluster: physical access controls apply — locked cage,
badge access, visitor logs, camera coverage.

### §164.310(a)(2) — Workstation Use / §164.310(b) — Workstation Security

**ML platform artefact.** Endpoint policy for workforce
machines that handle PHI. Full-disk encryption; MDM;
prohibited-software policy. Data scientists who pull PHI
subsets to laptops must do so under a specific approval and
short retention policy; often the better path is a remote
workstation (VDI) that keeps PHI off endpoints entirely.

### §164.310(d)(1) — Device and Media Controls

- **Disposal (R).**
- **Media reuse (R).**
- **Accountability (A).**
- **Data backup and storage (A).**

**ML platform artefact.** Media-disposal procedures for
disks / SSDs holding training data or model artefacts.
Provider-managed storage is usually crypto-erased on
disposal per provider policy; verify with the provider.
On-prem GPU cluster disk disposal is a controlled process
with retention of disposal records.

---

## Technical safeguards (§164.312) — the code-level controls

Five standards. This is where the ML platform's controls map
most directly.

### §164.312(a)(1) — Access Control

- **Unique user identification (R).** Assign a unique name
  and/or number for identifying and tracking user identity.
- **Emergency access procedure (R).** Procedures for
  obtaining necessary ePHI during an emergency.
- **Automatic logoff (A).** Terminate an electronic session
  after a predetermined time of inactivity.
- **Encryption and decryption (A).** Mechanism to encrypt
  and decrypt ePHI.

**ML platform artefact.** Per-user identity (mod-103) for
every ePHI-touching workflow — every training-data query,
every model-serving call, every prompt-log read. No shared
accounts; no service-to-service calls without identity.
Emergency access — the break-glass path — is a named,
audited procedure with post-incident review. Automatic
logoff on interactive access. **Encryption at rest and in
transit is addressable, not required — but it is the
easy addressable specification; if you do not encrypt PHI at
rest and in transit, the addressable-determination
documentation had better be very good.** In practice, the
right answer is always to encrypt.

### §164.312(a)(2) — (implementation specs listed above under §164.312(a)(1))

### §164.312(b) — Audit Controls

- **Audit controls (R).** Implement hardware, software, and
  procedural mechanisms that record and examine activity in
  information systems that contain or use ePHI.

**ML platform artefact.** Comprehensive audit logging (mod-104
chapter 06) covering every PHI surface: training-data
access, model-inference calls with PHI, prompt-log access,
retrieval-store access, canary-set access. Log records
include actor identity, timestamp, action, and object
identifier. Log integrity per mod-104 (immutable / tamper-
evident); retention per §164.316 (six years from creation or
last-in-effect date).

Specific ML-relevant items to audit:

- Every training-run kickoff, with a hash of the training-
  data snapshot and the DP-configured `(ε, δ)`.
- Every model download / export.
- Every DP-model retraining (the composition ledger).
- Every DSAR / erasure request and the systems it touched.
- Every DLP failure (chapter 03 fail-closed events).
- Every MI-AUC threshold breach (chapter 02).

The audit surface feeds §164.308(a)(1)(ii)(D) information
system activity review; the surface must be reviewed, not
just retained.

### §164.312(c)(1) — Integrity

- **Mechanism to authenticate ePHI (A).** Corroborate that
  ePHI has not been altered or destroyed in an unauthorised
  manner.

**ML platform artefact.** For every ePHI-containing artefact:
integrity check. mod-104's signed provenance (SLSA + Sigstore)
covers training-data snapshots and model artefacts;
storage-level integrity (S3 checksum, GCS MD5, Azure MD5)
covers stored PHI files; database transactions cover
row-level records.

For the training-run's DP guarantee itself: an integrity
mechanism is the mod-104 signed lineage record that names
the training-data hash and the `(ε, δ)` — a tampered
lineage would be detected.

### §164.312(d) — Person or Entity Authentication

- **Person or entity authentication (R).** Verify that a
  person or entity seeking access is the one claimed.

**ML platform artefact.** Multi-factor authentication for
interactive access to PHI-touching systems. Workload identity
(mod-103 chapter 03) — SPIFFE / X.509 / OIDC-federated —
for service-to-service. No long-lived shared credentials.

### §164.312(e)(1) — Transmission Security

- **Integrity controls (A).**
- **Encryption (A).**

**ML platform artefact.** mTLS or equivalent for every
ePHI-carrying transport (mod-103). Integrity checks (either
via TLS or via app-layer signatures) on every artefact
transferred. Same addressable-determination note as at rest:
in practice, always encrypt.

---

## Organizational requirements (§164.314) — the BAA

§164.314(a) sets the required content of the BAA between the
covered entity and the business associate. For ML platforms
that are business associates, the BAA obligates you to (among
other things):

- Not use or further disclose PHI except as permitted or
  required by the contract or by law.
- Use appropriate safeguards to prevent impermissible use or
  disclosure (i.e., the Security Rule applies to you
  directly).
- Report to the covered entity any use or disclosure not
  provided for by the contract, including breaches per the
  Breach Notification Rule.
- Ensure that any subcontractors that create, receive,
  maintain, or transmit ePHI on behalf of the business
  associate agree to the same restrictions and conditions.
- Make available PHI in accordance with individual rights.
- Make available its practices, books, and records to HHS
  for compliance review.
- Return or destroy PHI at contract termination when feasible.

**ML platform artefact.** A **BAA obligation matrix** that
maps each BAA obligation to the platform mechanism that
delivers it — e.g. "make available PHI per individual rights"
→ the DSAR / access workflow; "return or destroy PHI at
contract termination" → the tenant-purge workflow (which
must reach training data, model artefacts, retrieval
indices, prompt logs, canary sets).

If the platform uses subcontractors (hosted LLMs, managed
vector DBs, observability providers), the "same restrictions
and conditions" clause requires a chain of BAAs. The BAA
register (§164.308(b) artefact above) is where this is
tracked.

---

## Policies, procedures, and documentation (§164.316)

Two standards, both closely watched by OCR:

### §164.316(a) — Policies and Procedures

- Written policies and procedures to comply with the
  standards, implementation specifications, or other
  requirements of the Security Rule.

**ML platform artefact.** Every control named above has a
written policy — not "we do this" in a wiki, but a
version-controlled, dated, signed policy document. The
ML-security team owns the drafting; the Security Officer
approves.

### §164.316(b)(1)–(3) — Documentation

- (b)(1): Maintain policies and procedures in written form,
  and any actions, activities, or assessments required by
  the subpart.
- (b)(2)(i): **Time limit (R).** Retain the documentation for
  6 years from the date of its creation or the date when
  it last was in effect, whichever is later.
- (b)(2)(ii): **Availability (R).** Make documentation
  available to those responsible for implementing the
  procedures.
- (b)(2)(iii): **Updates (R).** Review documentation
  periodically and update as needed.

**ML platform artefact.** A retention policy on the
compliance-documentation store enforcing the six-year floor.
This applies to the risk analysis, the addressable-
determination documents, the audit logs (per HIPAA and per
mod-104 chapter 06), incident-response documentation, and
the BAA register. mod-104's immutable audit-log architecture
supports the retention; the retention policy names the six-
year floor explicitly.

Six years is a **floor**, not a ceiling — state, sector, or
contractual retentions may be longer. The retention policy
carries the highest applicable retention per artefact type.

---

## The HIPAA control-mapping matrix — the artefact this chapter produces

The mapping matrix is the ML platform's discharge of the
Security Rule. Every standard has a row; every applicable
implementation specification has a sub-row. Every row names
the concrete platform control, the owner, and the evidence
artefact.

Template (populate per system):

| §-ref | Standard / spec | R/A | ML platform control | PHI surface(s) | Owner | Evidence |
| --- | --- | --- | --- | --- | --- | --- |
| §164.308(a)(1)(ii)(A) | Risk analysis | R | Risk-analysis document referencing chapter 01 tier map + chapter 02 threat model + mod-102 STRIDE for the platform | All | Security Officer | `docs/security/hipaa/risk-analysis-<system>-<version>.md` |
| §164.308(a)(1)(ii)(B) | Risk management | R | Mitigations per this module + mod-103 + mod-105 | All | Security Officer + eng lead | Same doc §5 |
| §164.308(a)(2) | Security Official | R | Named Security Officer with platform-level authority | All | HR + exec | `docs/security/roles/security-officer.md` |
| §164.308(a)(3) | Workforce security | A | Access-provisioning + termination workflow via mod-103 identity | All | Platform IAM | `docs/security/iam/workforce-lifecycle.md` |
| §164.308(a)(4) | Info access management (minimum necessary) | A | Per-surface access policy; mod-103 identities; mod-105 dynamic creds; DLP per chapter 03 | Training, inference, logs, retrieval, canary | Platform IAM + ML security | Per-surface access-policy docs |
| §164.308(a)(5) | Security awareness / training | A | ML-team-specific training modules; onboarding checklist | All | Security + ML team leads | `training/hipaa-ml.md`; training completion records |
| §164.308(a)(6) | Incident procedures | R | ML incident runbook referencing mod-111 + mod-107 chapter 05 ladder | All | Security on-call | `runbooks/incident-response-ml.md` |
| §164.308(a)(7)(i)–(v) | Contingency plan (backup / DR / emergency) | R (i–iii), A (iv–v) | Backup + DR plan covering every PHI surface; tested annually | All | Platform SRE | `docs/dr/ml-platform-dr.md`; test reports |
| §164.308(a)(8) | Evaluation | R | Annual + on-material-change platform-wide Security Rule evaluation | All | Security Officer | `docs/security/hipaa/annual-evaluation-<year>.md` |
| §164.308(b) | BAA / subcontractor agreements | R | BAA register; DLP + tool-ACL enforcement of "no PHI to non-BAA services" | All (esp. downstream integrations) | Legal + Security Officer + eng lead | `registers/baa.yaml`; enforcement configs |
| §164.310(a)(1) | Facility access controls | A | Inherited from cloud provider (BAA + attestations) or on-prem physical-security controls | All (physical layer) | Cloud team / facility lead | Provider BAA + attestation reports |
| §164.310(b) / (c) | Workstation use / security | A | Endpoint MDM + full-disk encryption; PHI-off-endpoint policy; VDI where appropriate | Workforce endpoints | Endpoint team | `docs/security/endpoint/phi-workstation-policy.md` |
| §164.310(d)(1) | Device and media disposal / reuse | R | Provider-managed crypto-erase; on-prem disposal procedure with logs | Storage | Cloud team / facility lead | Provider attestations; disposal logs |
| §164.312(a)(1) | Access control — unique user id / emergency / auto logoff / encryption at rest | R (id, emergency); A (auto logoff, encryption) | mod-103 per-caller identity; break-glass procedure; session-idle logoff; encryption everywhere (KMS via mod-105) | All | Platform IAM + KMS team | `docs/security/iam/`; KMS key registry |
| §164.312(b) | Audit controls | R | mod-104 chapter 06 immutable audit log covering all PHI surfaces + ML-specific events (training, DP composition, DSAR, DLP failures, MI regressions) | All | Platform observability | mod-104 audit-log architecture; log-review cadence |
| §164.312(c)(1) | Integrity | A | mod-104 signed provenance on training data + models; storage-level checksums; app-level integrity on transferred artefacts | All | Platform SRE + ML security | mod-104 lineage records |
| §164.312(d) | Person / entity authentication | R | MFA for interactive access; SPIFFE / OIDC workload identity for services | All | Platform IAM | `docs/security/iam/authentication.md` |
| §164.312(e)(1) | Transmission security | A | mTLS everywhere (mod-103); app-layer integrity where required | All (in transit) | Platform mesh + IAM | mod-103 mesh policy |
| §164.314(a) | BAA content | R | Standard BAA template + subcontractor agreements per §164.308(b) | Third-party integrations | Legal | BAA template; register |
| §164.316(a) | Policies and procedures | R | Version-controlled policy repository | All | Security Officer | `docs/security/hipaa/policies/` |
| §164.316(b)(2)(i) | Documentation — 6-year retention | R | Retention policy on compliance-doc store; audit log retention per mod-104 | All (documentation) | Security Officer + platform SRE | `docs/security/hipaa/retention-policy.md` |
| §164.316(b)(2)(ii) | Documentation availability | R | Docs available to relevant workforce via internal portal | All | Security Officer | Portal ACLs |
| §164.316(b)(2)(iii) | Documentation updates | R | Annual review + on-material-change | All | Security Officer | Review-cadence record |

For every **addressable** row, the mapping matrix carries a
separate **addressable-determination document** stating why
the specific implementation is reasonable and appropriate,
or — if not implemented — the equivalent alternative and the
rationale. "Not applicable" as a rationale is not accepted.

The matrix is a living artefact — additions to the platform
(a new PHI surface, a new third-party service, a new decision
class) trigger a matrix update; the update is dated, signed,
and retained per §164.316.

---

## The Breach Notification Rule — when a control failure becomes a reportable event

The Security Rule protects ePHI; the **Breach Notification
Rule** (Subpart D, §§ 164.400–414) governs what happens when
protection fails.

Definition of a breach (§164.402): the acquisition, access, use,
or disclosure of PHI in a manner not permitted under the Privacy
Rule which compromises the security or privacy of the PHI —
unless the covered entity or business associate demonstrates
that there is a low probability that the PHI has been
compromised based on a risk assessment.

Exceptions to "breach" (§164.402):

- Unintentional acquisition, access, or use by a workforce
  member acting in good faith within scope.
- Inadvertent disclosure by a person authorised to access PHI
  to another authorised person at the same covered entity or
  business associate.
- A disclosure where the covered entity has a good-faith
  belief that the unauthorised person would not reasonably
  have been able to retain the PHI.

Notification obligations (broadly):

- **§164.404** — Notification to individuals: without
  unreasonable delay and in no case later than **60 calendar
  days** after discovery.
- **§164.406** — Notification to media: for breaches
  affecting **more than 500 residents** of a state or
  jurisdiction, notify prominent media outlets within the
  same 60-day window.
- **§164.408** — Notification to the Secretary (HHS): for
  breaches affecting 500 or more individuals, notify HHS
  concurrently with individuals; for smaller breaches,
  annually.
- **§164.410** — Business associate to covered entity:
  notify the covered entity without unreasonable delay and
  in no case later than **60 days** after discovery. In
  practice, the BAA typically shortens this materially (often
  to a few business days).

**ML-platform triggers likely to be breach events:**

- Prompt-log data (with PHI) accidentally exposed via a
  misconfigured access control or an unintended service
  integration.
- Model output that returned PHI belonging to a different
  patient than the caller was authorised to view (chapter 02
  attribute inference in the wild; membership inference
  confirming a specific patient's presence in the training
  set).
- Retrieval store hit returned to the wrong tenant / caller.
- Training data uploaded to a non-BAA-covered service.
- Model weights containing memorised PHI shared with a
  third party without BAA.
- Extraction of training-data PHI from the deployed model.

The ML platform's incident runbook (§164.308(a)(6) artefact)
names these triggers. When one fires, the runbook's first step
is to notify the Security Officer and start the discovery
clock (breach notification runs from discovery, not from
containment). Chapter 04 covers the parallel GDPR clock; the
two often start together.

---

## Design-time decisions the Security Rule forces

Beyond the mapping matrix, several ML-platform design
decisions have a HIPAA-shaped answer:

- **Where does model inference run for PHI queries?** If
  inference is on a hosted third-party API, that provider is
  a business associate and needs a BAA. If no BAA is
  available, either the provider does not receive PHI (DLP
  scrub before send) or the inference runs on
  BAA-covered infra.
- **Does the training data need to include PHI?**
  Minimum-necessary (Privacy Rule) applies. If the model
  can be trained on de-identified data (per §164.514(a)
  Safe Harbor or Expert Determination), the Security Rule
  applies to a much smaller surface. If de-identification is
  infeasible, the tier map (chapter 01) puts PHI in the
  personal-sensitive band with `ε ≤ 1` targets.
- **Where do prompt logs and trajectory logs live?**
  Per-surface classification. If they contain PHI, they are
  ePHI stores and inherit the full Security Rule control set.
  Consider whether the logging can be scoped-down (redacted
  at ingest via chapter 03; retention limited; access
  controlled).
- **Who has emergency access?** The §164.312(a)(2)(ii)
  emergency-access procedure is a required implementation
  spec. In an ML context, this is the on-call responder's
  break-glass path for retrieving a specific patient's
  trajectory to investigate an incident. Design it; log it;
  review it.
- **De-identification (§164.514) as a design choice.** Two
  methods:
  - **Safe Harbor** — remove the 18 identifiers listed in
    §164.514(b)(2). Deterministic; explicit. May not always
    yield a usable dataset — clinical notes often carry
    identifier-like content in free text (chapter 03 DLP is
    where the free-text scrub lands).
  - **Expert determination** — a qualified statistician
    determines that the risk of re-identification is very
    small. Case-by-case; requires documentation.
  De-identified data (per either method) is not PHI and
  Security Rule obligations attach differently. Consider
  whether the training corpus can be reduced to
  de-identified form.

---

## Interaction with other regulatory regimes

HIPAA is US-federal-and-healthcare-specific. ML platforms
often live under multiple regimes concurrently:

- **HIPAA + GDPR** (US healthcare provider serving EEA
  residents, or US business associate operating on EU
  patient data). Chapter 04 + this chapter compose. Tensions:
  minimum-necessary (HIPAA) vs. data subject access rights
  (GDPR); breach clocks (60 days HIPAA to individuals vs.
  72 hours GDPR to supervisory authority). The DPO + Security
  Officer resolve; the incident runbook triggers both clocks.
- **HIPAA + state laws.** State privacy laws (CA CMIA, TX
  HB 300, WA My Health My Data Act, etc.) add obligations
  beyond HIPAA — cover here or in mod-109. Some state laws
  are stricter than HIPAA and pre-empt the "at least as
  stringent" threshold.
- **HIPAA + FDA (SaMD).** ML systems classified as software
  as a medical device inherit FDA obligations in addition to
  HIPAA. Out of scope for this chapter; cite mod-109.
- **HIPAA + 42 CFR Part 2** (federal substance-use disorder
  records). Stricter consent regime than HIPAA. Applies to
  a narrower dataset; when it applies, it dominates.

The mapping matrix carries a column (or a note per row) for
non-HIPAA regimes that apply.

---

## Standard failure modes

- **Prompt log ends up as an unclassified ePHI store.** The
  most common ML-specific HIPAA failure. Fix: chapter 03
  DLP; access control; retention; explicit inclusion in the
  risk analysis.
- **Third-party model API without a BAA.** PHI in the prompts;
  no BAA in place. Fix: BAA register; DLP-before-send;
  tool-ACL block on non-BAA-covered destinations.
- **Six-year retention only on the primary log.** Audit-log
  retention set for six years on the mod-104 store; incident
  documentation stored elsewhere for two. Fix: retention
  policy covers *all* Security Rule documentation.
- **Addressable implementation specs treated as optional.**
  A team decides not to implement encryption at rest without
  a written determination. Fix: every addressable spec has
  either an implementation or a written addressable-
  determination document.
- **Security Officer named on paper but has no platform
  authority.** The role is titular; nobody can actually stop
  a bad deployment. Fix: Security Officer has release-gate
  authority; the role is real.
- **No mapping matrix.** The team believes controls are in
  place but cannot cite standard-to-control mapping. Fix:
  the matrix is a first-class artefact under
  `docs/security/hipaa/`.
- **Risk analysis skipped because "we're a business
  associate, the covered entity did theirs".** Business
  associates have their own risk-analysis obligation under
  §164.308(a)(1)(ii)(A). Fix: the business associate's own
  risk analysis exists.
- **Discovery clock (breach) not started at discovery.**
  Runbook step missed. Fix: incident runbook first step is
  Security Officer notification.
- **Emergency access unlogged / unreviewed.** The break-glass
  path exists but is not audited. Fix: every emergency-access
  invocation writes to the mod-104 audit log and is reviewed
  by the Security Officer per policy.
- **De-identification claimed but not per §164.514.**
  Ad-hoc redaction claimed as de-identification. Fix: only
  Safe Harbor (18 identifiers) or Expert Determination
  qualifies. Document the method.

---

## The mistakes this chapter is trying to prevent

- **Confusing "we have good security" with "we discharge the
  Security Rule".** The Rule is a programme with named
  standards and required documentation, not a technology
  bar.
- **PHI-in-logs by accident.** Prompt logs, trajectory logs,
  and debug logs are the most common surprise ePHI stores.
  Design their DLP and access controls before turning them
  on.
- **BAA blind spots.** Every third-party service that could
  receive PHI is either under a BAA or blocked. The
  platform enforces the block; the register lists the
  approvals.
- **Six-year retention as an afterthought.** Documentation
  retention is required, not aspirational. Set the retention
  when the surface is created, not after an audit finding.
- **Security Officer as a nameplate.** Real authority; real
  attention; real involvement in platform decisions.

---

## Summary

- The HIPAA Security Rule (45 CFR §§ 164.302–318) is a
  programme with **administrative**, **physical**, and
  **technical** safeguards. Each standard has required or
  addressable implementation specifications; addressable is
  not optional.
- ML platforms have **multiple PHI surfaces** — training
  data, inference inputs, prompt / trajectory logs,
  retrieval stores, model artefacts, supporting artefacts
  (canary sets, backups), downstream integrations. Every
  surface needs its own control set.
- The **HIPAA control-mapping matrix** is the platform's
  discharge of the Rule: standard → ML control → owner →
  evidence. Addressable specs get an addressable-
  determination document.
- **BAAs** are the platform's blast-radius control on
  third-party integrations. Every service that could receive
  PHI is either under a BAA or blocked by DLP / tool-ACL.
- The **Breach Notification Rule** (Subpart D) governs when
  a control failure becomes a reportable event. 60 days to
  individuals; 60 days to HHS for ≥500-person breaches;
  business associates report to covered entities without
  unreasonable delay (typically much shorter per BAA).
- **Six-year documentation retention** (§164.316(b)(2)(i)) is
  a floor, not a ceiling. The retention policy applies to
  every Security Rule artefact — risk analysis, audit logs,
  incident documentation, BAA register.
- **De-identification per §164.514** (Safe Harbor or Expert
  Determination) is a design lever to reduce the Security
  Rule's surface. Use it where the ML use case allows.
- **HIPAA composes with other regimes** — GDPR, state laws,
  FDA, 42 CFR Part 2. The DPO + Security Officer + counsel
  resolve tensions; the artefacts in this chapter and chapter
  04 are compatible where the underlying regimes are
  compatible.
- **The Security Officer is a real role with real platform
  authority.** Without that, the mapping matrix is paperwork.
