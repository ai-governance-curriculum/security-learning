# Chapter 06 — Positioning Against NIST SP 800-61 and SANS Incident Response

> **Note on AI-assisted content.** NIST SP 800-61 is on
> revision 3 (2024/2025); SANS incident-handling guidance
> and FIRST community references evolve. Treat the numbers
> and section pointers below as orientation; verify against
> the current published documents in
> [`resources.md`](./resources.md) before quoting operationally.

---

## Why this chapter exists

An AI/ML security programme that reinvents incident
response is a programme that will not survive its first
audit. Enterprises run on a small number of widely-adopted
IR frameworks:

- **NIST SP 800-61** (Computer Security Incident
  Handling Guide — now at revision 3) — the US public-
  sector reference and, de facto, the vocabulary most
  mature private-sector programmes use.
- **SANS PICERL** (Preparation, Identification,
  Containment, Eradication, Recovery, Lessons Learned)
  — the training-industry formulation; essentially the
  same loop as SP 800-61 with slightly different
  labels.
- **ISO/IEC 27035** (Information security incident
  management) — the international-standards version;
  common in European and Asia-Pacific programmes.
- **FIRST CSIRT services framework** — a role / service
  taxonomy for CSIRTs that programmes borrow from
  liberally.

Each of these predates the AI/ML surface. None of them
tells you to preserve a trajectory bundle, to count the
reach of a poisoned retrieval chunk, or to pin a model
digest in the evidence record. But they *all* share a
scaffold the AI programme can slot into: a lifecycle,
roles, a classification scheme, a notification protocol,
and a post-incident learning loop.

This chapter positions the AI-specific work from the
preceding chapters against the SP 800-61 and SANS
scaffolds, so that:

- The AI playbooks (chapter 03) are recognisable to
  anyone trained on classical IR.
- The AI severity ladder (chapter 04) extends, not
  replaces, the SP 800-61 impact taxonomy.
- The AI role interface (chapter 05) is expressed in
  the vocabulary auditors already know.
- The programme's claims against ISO 27035 or the FIRST
  framework are *defensible* — the AI programme is in
  scope, in the right phase, and documented against
  the same shape as the rest of the IR capability.

You leave this chapter able to:

- Map the AI-specific additions in this module onto
  NIST SP 800-61r3's lifecycle phases.
- Translate chapter 03's playbooks into the SANS
  PICERL vocabulary for mixed audiences.
- Position the role's deliverables against ISO 27035
  controls and the FIRST CSIRT services framework.
- Explain where the AI programme *does* innovate on
  classical IR (trajectory as evidence, reach as a
  disclosure input, model-version pinning as scope-
  of-containment) and where it must *not* innovate
  (notification obligations, chain of custody).

---

## NIST SP 800-61 in one page

**SP 800-61** is the US National Institute of Standards
and Technology's incident-handling guide. Revision 3
(released 2024/2025) replaces the long-lived revision 2
and realigns the guidance with the NIST Cybersecurity
Framework 2.0 and current ransomware / supply-chain
realities.

The core SP 800-61 model has four phases:

1. **Preparation.** The capability itself — staffed
   team, tooling, playbooks, communication plans,
   training, exercises.
2. **Detection and Analysis.** The alert arrives, is
   triaged, is characterised. Precursors (early-
   warning signals) and indicators (confirmed signals
   of an incident) are distinguished. Impact is
   categorised.
3. **Containment, Eradication, and Recovery.** The
   bleeding is stopped, the attacker's foothold or the
   bad artefact is removed, operations return to a
   known-good state.
4. **Post-Incident Activity.** Learn, document,
   update, share.

Phases overlap and iterate in practice; the diagram is
a loop, not a line.

The guide also discusses:

- **Impact categorisation.** SP 800-61 lists impact
  dimensions (functional, information, recoverability)
  and recommends organisations build a categorisation
  consistent with their own risk tolerance. The AI
  severity ladder (chapter 04) is one such
  categorisation, extended for AI-specific impacts.
- **Communication and co-ordination.** External
  co-ordination with sector ISACs, law enforcement,
  CERTs, regulators, legal counsel, and the public.
- **Information sharing.** Threat intelligence
  exchange; evidence sharing to the extent allowed.
- **Service relationships.** Interfaces with the
  SOC, with managed security services, with the
  broader enterprise (legal, HR, PR).

NIST SP 800-61r3 explicitly realigns on the CSF 2.0
functions (Govern, Identify, Protect, Detect, Respond,
Recover). An AI programme claiming SP 800-61 alignment
in 2026 should express itself against these functions,
not against SP 800-61r2's older phrasing.

### Mapping this module onto SP 800-61r3

| SP 800-61r3 phase / activity | This module |
| --- | --- |
| Preparation — detection content | Chapter 01 (ATLAS SIEM content) |
| Preparation — runtime policy | Chapter 02 (Falco / eBPF) |
| Preparation — playbooks | Chapter 03 |
| Preparation — classification scheme | Chapter 04 |
| Preparation — roles, interfaces, SLAs | Chapter 05 |
| Preparation — training and rehearsal | Chapters 03 § Rehearsal, 05 § Rehearsing the interface |
| Detection and Analysis — identification | Chapter 03 (I-phase of each playbook) + chapter 04 (severity assignment) |
| Containment, Eradication, Recovery | Chapter 03 (CER phases per playbook) |
| Post-Incident Activity | Chapter 03 § L-phase + chapter 04's metrics + mod-109 governance evidence |

The AI programme is *not* a new box next to the SP
800-61 lifecycle. It is content that lives inside each
of its phases.

---

## SANS PICERL — the training-industry labelling

SANS teaches **Preparation, Identification, Containment,
Eradication, Recovery, Lessons Learned (PICERL)**. The
mapping to SP 800-61:

| SP 800-61r3 | SANS PICERL |
| --- | --- |
| Preparation | Preparation |
| Detection and Analysis | Identification |
| Containment, Eradication, Recovery | Containment / Eradication / Recovery |
| Post-Incident Activity | Lessons Learned |

Chapter 03 of this module uses PICERL headings because
they are compact and because the SANS vocabulary is
widely used by SOC teams. The content is identical to
what SP 800-61r3 would describe; the choice of labels
is stylistic.

The practical implication: a playbook written in
PICERL vocabulary meets an SP 800-61r3-aligned audit
with a one-paragraph crosswalk. Pick one vocabulary
consistently through the programme; publish the
mapping to the other once.

---

## ISO/IEC 27035 and the FIRST CSIRT services framework

**ISO/IEC 27035** (Information security incident
management) is the international-standards version of
the same scaffold. The current parts (27035-1 and
27035-2 publicly available; 27035-3 and 27035-4 in
development/newer revisions) emphasise:

- A documented incident-management process with
  defined roles.
- Classification and prioritisation per the
  organisation's risk appetite.
- Communication plans — internal, external,
  regulatory.
- Lessons-learned feedback into the ISMS (ISO/IEC
  27001 management system).

For a programme formally pursuing ISO/IEC 27001
certification with an AI/ML scope, ISO/IEC 42001 (AI
management system — mod-109 chapter 02) is the
companion standard; the two share management-system
grammar.

**FIRST (Forum of Incident Response and Security
Teams)** publishes the **CSIRT Services Framework**, a
taxonomy of services a CSIRT can offer. The service
areas most relevant to an AI/ML programme:

- Information Security Event Management.
- Information Security Incident Management.
- Vulnerability Management (closest to the mod-110
  supply-chain overlap).
- Situational Awareness.
- Knowledge Transfer (closest to this module's
  rehearsal cadence).

The CSIRT services framework is a *descriptive* tool;
teams use it to communicate their scope. An AI/ML
programme that says "we offer AI-specific detection
engineering, incident response for AI-specific
threats, and AI-threat situational awareness" is using
the framework's vocabulary — which auditors and peer
CSIRTs will recognise.

---

## Where AI incident response **does** innovate

The classical frameworks were written against:

- Network and host compromise.
- Malware infection.
- Credential theft and account takeover.
- Data exfiltration via known channels.
- Denial of service.

AI incidents share surface area with every one of these,
but add surface area the classical frameworks never
contemplated. The genuine innovations:

### Trajectory as the primary evidence artefact

Classical IR preserves disk images, memory dumps, network
captures. AI IR preserves **trajectories** — the full
sequence of prompt fragments (with provenance labels),
model responses, tool calls (with arguments and results),
and runtime decisions. The trajectory is to an AI incident
what the pcap is to a network incident. SP 800-61 does
not list it; the chapter 03 evidence manifest and the
chapter 04 metadata contract do.

### Reach as a disclosure input

Classical breach-notification obligations fire on
confirmed-impact-and-count. AI incidents often involve
a shared resource (retrieval index, system-prompt cache,
model version) whose contamination affects every user
who hit it. The **reach counter** (chapter 04) is the
AI-specific scope-of-impact measurement. Legal consumes
it alongside the classical "number of records exposed".

### Model and resource pinning as scope-of-containment

A classical "scope of containment" lists hosts and
accounts. An AI containment lists: the model digest,
the runtime version, the tool-registry version, the
retrieval-index version, the system-prompt version.
Without these, "we rolled back" is ambiguous; with
them, the rollback is auditable.

### Behavioural compromise, not just code compromise

A classical compromise usually involves code execution,
privilege escalation, or data access via an exploited
vulnerability. An AI compromise is often a **behavioural**
compromise — the model did something it was not supposed
to do, in response to inputs that an attacker shaped.
No CVE was exploited; no process was spawned (necessarily);
no privilege was escalated. The AI playbooks (chapter 03)
accommodate this; the classical SP 800-61 flow has to be
told that "the model refused the guardrail" is itself an
incident shape.

### Continuous learning as containment

For many AI systems, a continuously-updated behaviour
(retrieval index, feedback-learned policy, periodically
re-trained model) is the thing that was compromised. The
AI eradication path often includes **re-training against
clean inputs** and the regression test for the specific
behaviour — a step that has no analogue in a classical
"re-install the OS" eradication.

---

## Where AI incident response **must not** innovate

The classical frameworks exist because they encode
hard-won knowledge about:

- **Chain of custody.** Evidence must be preserved
  with cryptographic hashes, immutable storage, and
  access logs. An AI trajectory bundle is subject to
  the same chain-of-custody discipline as a disk
  image. The hash function, the immutable storage,
  and the access-log review are not places to be
  creative.
- **Attorney-client privilege.** Communications about
  an incident are privileged when conducted under
  counsel's direction. AI-specific technical memos
  are not an exception; they belong under the same
  privilege framework.
- **Regulatory notification determinations.** Legal
  decides whether GDPR, HIPAA, PCI DSS, EU AI Act, SEC
  Form 8-K, state law, or sector rules apply. The AI
  programme supplies facts; it does not opine on
  obligations. (Chapter 05.)
- **Communications discipline.** Comms owns external
  messaging; the AI/ML Security role does not talk to
  the press. The programme's technical SMEs do not
  tweet about the incident.
- **The lifecycle.** Preparation → Detection /
  Identification → Containment / Eradication /
  Recovery → Lessons Learned is not negotiable. An AI
  programme that invents "we skip Lessons Learned
  because we move fast" is a programme that will fail
  its next audit and its next retrospective.
- **Shared accountability.** The RACI (chapter 05)
  reflects decades of practice. The AI role is one
  participant; it does not become the whole
  response.

---

## Positioning the programme in the enterprise

Three audiences, three framings:

### For the SOC and DFIR teams

"This is SP 800-61 / PICERL. We author detection content
and playbooks for ATLAS-mapped AI threats; we provide
SME-on-call for AI-specific incidents; we hand off
containment to the ML platform team and incident
command to the SOC. The AI content lives inside your
existing processes."

The vocabulary is the SOC's. The additions are the
AI-specific detection content, the AI-specific
playbooks, the AI-specific evidence contract.

### For the Legal and GRC teams

"This is ISO/IEC 27035 and 42001-compatible. We
produce the AI-risk governance evidence surface
(mod-109); every SEV-1 and SEV-2 incident lands in it;
the disclosure-clock service pages legal from the
first awareness event; AI incidents feed the risk
register and the policy pack."

The vocabulary is management-system standards. The
additions are AI-specific risk categories and
AI-specific evidence surfaces.

### For executives and the board

"When an AI system misbehaves badly enough to matter,
we detect it, we have a playbook, we page the right
people, we meet the regulatory clocks, and we have
evidence that is audit-worthy. The programme is
expressed in the same vocabulary as the rest of
security; the AI-specific knowledge is content inside
that vocabulary, not a separate programme in a
separate dashboard."

The vocabulary is the risk / audit framing. The
message is that the AI programme is *mature* and
*integrated*, not experimental and parallel.

---

## Standard failure modes

- **"We don't do SP 800-61; AI is different."** The
  AI programme becomes isolated from the enterprise
  IR capability; audit evidence is incompatible; the
  SOC does not know what to do with AI alerts.
- **PICERL / SP 800-61 vocabulary adopted in prose
  but not in process.** The playbook has the right
  headings; the paging rotations, the evidence
  preservation, and the lessons-learned loop are
  not actually wired up.
- **AI-specific innovation on things the law decides.**
  "We've determined this is not a reportable breach"
  from a technical SME is a programme-ending statement.
  Legal decides.
- **Classical vocabulary applied without AI content.**
  The playbook says "preserve forensic evidence"; the
  trajectory bundle is not preserved because
  "forensic evidence" to a classical responder means
  disk and memory. The AI-specific manifest has to be
  explicit.
- **ISO 27001 claims without ISO 42001 integration.**
  The IR capability is certified; the AI programme
  is a sidecar; the two never reconcile. Mod-109
  chapter 02 is where this gets fixed.
- **"CSIRT" services framework in a document nobody
  reads.** The framework is useful only when it is
  used to communicate scope — to the SOC manager, to
  the audit committee, to peer CSIRTs.
- **Lessons-Learned skipped because the incident was
  "small."** Every AI incident donates a regression
  test, a detection-content update, a governance
  evidence record. Scale of the incident is
  independent of the discipline of the learning
  loop.

---

## Summary

- **The AI programme is content inside classical IR
  frameworks, not a replacement.** NIST SP 800-61r3,
  SANS PICERL, ISO/IEC 27035, and the FIRST CSIRT
  services framework all provide the scaffold; this
  module provides the AI-specific content.
- **The lifecycle is the same.** Preparation /
  Detection / Containment / Eradication / Recovery /
  Lessons Learned. Chapter 03 playbooks fit; chapter
  04 severity ladder fits; chapter 05 RACI fits.
- **The AI innovations** are trajectory evidence,
  reach as a disclosure input, model-and-resource
  pinning as scope-of-containment, behavioural
  compromise as a first-class incident shape, and
  retraining-against-clean-inputs as an eradication
  step. These extend the classical framework; they
  do not replace it.
- **The AI programme does not innovate** on chain of
  custody, privilege, regulatory notification
  determinations, comms discipline, lifecycle
  discipline, or shared accountability.
- **Positioning is audience-specific.** For SOC /
  DFIR, use PICERL vocabulary. For Legal / GRC, use
  ISO 27035 / 42001 vocabulary. For executives, use
  risk / audit vocabulary. The underlying content is
  the same; the labels are not.
- **The programme's maturity** is measured by how
  seamlessly an AI incident runs through the
  enterprise's existing IR capability. The best
  outcome is that nothing about AI incident response
  requires a special case; the second-best outcome is
  that the special cases are explicit, documented,
  and rehearsed.
