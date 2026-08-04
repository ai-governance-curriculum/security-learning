# Chapter 02 — MITRE ATLAS as the Living TTP Catalogue

> **Note on AI-assisted content.** Verify tactic and technique
> identifiers against [atlas.mitre.org](https://atlas.mitre.org/) at
> the time this content is consulted. ATLAS is a living framework;
> IDs, titles, and mappings change.

---

## Why this chapter exists

OWASP ML Top 10 and OWASP LLM Top 10 (chapter 01) tell you *what
categories of risk exist*. NIST AI 100-2 (chapter 03) gives you the
*academic vocabulary* for those risks. Neither of them is the shape
your SIEM detection engineers and your incident-response playbooks
consume.

MITRE ATLAS is. ATLAS is the ML-specific analogue of MITRE ATT&CK,
and — like ATT&CK for enterprise IT — it is the *scaffold your
detection content and your IR playbooks map to*. If your Splunk /
Sentinel / ELK content is not tagged with ATLAS tactic and technique
IDs, an incoming analyst cannot walk from a firing alert to a
runbook, and your `mod-111` deliverables will fall over on the first
real incident.

This chapter installs how to read ATLAS as an engineer authoring
detection and response content, not as a reader of another framework
document.

The primary source: [atlas.mitre.org](https://atlas.mitre.org/).
Everything below refers to the current live catalogue; refresh it
before authoring content.

---

## The shape of ATLAS

ATLAS mirrors ATT&CK's structure:

- **Tactics** are the *why* — the phases of an ML-focused attack chain.
- **Techniques** are the *how* — the concrete actions under each
  tactic.
- **Sub-techniques** refine techniques with variants.
- **Case studies** are the *evidence* — real-world incidents mapped
  onto the tactic/technique grid.
- **Mitigations** are the recommended defensive posture, tagged back
  to the techniques.

At the time of writing, the ATLAS tactic chain covers, in order:

<!-- needs-research: refresh the tactic list, IDs, and ordering against atlas.mitre.org before citing. The list below reflects the tactic chain in the current public matrix; ATLAS revises periodically. -->

1. **Reconnaissance** — the attacker learns about the target ML system
   (architecture, training data sources, tooling, deployment).
2. **Resource Development** — the attacker builds the capabilities
   they will use (proxy models, attack datasets, infra).
3. **Initial Access** — the attacker gains access to the ML system or
   its supporting infrastructure (supply chain, valid credentials,
   web-app exploits, phishing).
4. **ML Model Access** — the attacker obtains access to query,
   inspect, or copy the model.
5. **Execution** — attacker-controlled code runs in the ML environment
   (notebook execution, user-supplied training config, plugin
   execution in an LLM tool call).
6. **Persistence** — the attacker maintains a foothold across restarts
   and retraining.
7. **Privilege Escalation** — the attacker elevates from an ML-user
   role to an ML-admin role, or from a workload to a node.
8. **Defense Evasion** — the attacker avoids detection (rate-limit
   evasion, prompt-injection obfuscation, low-signal query streams).
9. **Credential Access** — the attacker obtains credentials that enable
   further stages.
10. **Discovery** — the attacker maps the system's defenses (rate
    limits, retrieval sources, downstream tools).
11. **Collection** — the attacker gathers data of interest (model
    artifacts, training data, embeddings, prompts).
12. **ML Attack Staging** — the attacker prepares the actual ML attack
    (crafts adversarial examples, plants a backdoor, drafts an
    injection payload).
13. **Exfiltration** — the attacker moves data or capability out.
14. **Impact** — the attacker realises the goal (integrity loss, data
    theft, cost impact, harm to users).

The naming is deliberate: ATLAS reuses ATT&CK's tactic names where the
underlying phase is the same, adds `ML Model Access` and `ML Attack
Staging` as ML-specific tactics, and specialises the technique
inventory under every tactic.

### How to read a technique page

Every ATLAS technique page includes:

- The technique **ID** (e.g. `AML.T0018` — verify current IDs at the
  source before quoting).
- The technique **title**, a **description**, and a **procedure
  examples** section.
- The **tactic(s)** the technique falls under (some techniques bridge
  tactics).
- The **mitigations** ATLAS suggests, tagged by their `AML.M####` ID.
- The **case studies** that demonstrate the technique in the wild.

Your job as an engineer authoring detection content is to walk each
technique page and answer:

- **Data source**: what signal must be present in my SIEM for this
  technique to be detectable at all? (Training-job logs, retrieval
  audit, tool-call log, per-tenant query counters, egress DNS logs.)
- **Detection**: what specific query, threshold, or ML-based
  anomaly detection would fire on this technique?
- **Response**: what step-by-step actions belong in the IR playbook
  when the detection fires?
- **Coverage gap**: which techniques are in the catalogue but
  *undetectable* in my platform because the data source is missing?

That last row is the deliverable your program-leadership slice
(mod-112) uses to argue for logging investment.

---

## Case studies as the connective tissue

ATLAS case studies are the operative reason the catalogue exists.
Each case study — for example, PoisonGPT, Microsoft Tay, Bumblebee
model, evasion of malware classifiers, prompt-injection incidents —
walks a real incident through the tactic chain from Reconnaissance
to Impact and highlights the techniques used at each step.

Two ways to use case studies:

1. **Coverage backfill.** For each case study, walk the tactic chain
   and mark whether your detection content or your platform controls
   would have interrupted the attack at *any* step. A case study for
   which your coverage is empty across the chain is a program-level
   gap you owe your CISO organisation.
2. **Tabletop drills.** Run a mod-111 IR tabletop against a case
   study — brief the responders, walk them through each ATLAS-tagged
   step, and grade the response against the tactic timeline.

The catalogue's value multiplies when you tie it to your own case
studies. Any AI-specific incident your organisation handles under
mod-111 should be written up with ATLAS tactic/technique tags before
it is filed. This is how your organisation contributes to and
consumes the community catalogue.

---

## The ATLAS ↔ ATT&CK bridge

Not every stage of an ML-focused attack is ML-specific. When the
attacker in ATLAS's Initial Access tactic is exploiting a vulnerable
web app to reach an ML system, they are using ATT&CK techniques from
the enterprise matrix. The same is true for Persistence, Credential
Access, and Defense Evasion at the infrastructure layer.

Practical rule for detection engineering:

- **Author or reuse ATT&CK detections** for the enterprise-generic
  tactics (Initial Access via web exploit, valid-account credential
  abuse, DNS exfiltration).
- **Author net-new ATLAS detections** for the ML-specific tactics —
  ML Model Access, ML Attack Staging, and any technique whose
  procedure is unique to the ML lifecycle.

The mapping avoids duplication and clarifies ownership: enterprise
detection engineers own the ATT&CK-side content; you own the
ATLAS-side content. See mod-111 for the full handshake.

---

## Detection content — the concrete authoring workflow

For every ATLAS technique you decide to cover, produce:

1. **Detection artifact** — a Sigma rule (the SIEM-agnostic format),
   or the SIEM-native equivalent (Splunk SPL, Sentinel KQL, Elastic
   EQL), plus:
   - The `atlas_technique_id` tag in the rule metadata.
   - The `atlas_tactic_id` tag.
   - A short description of the attacker behaviour the rule
     approximates.
   - The false-positive shape and the tuning guidance.
2. **Runbook** — the IR playbook stub the alert routes to, with:
   - Triage steps (verify the alert, gather adjacent telemetry).
   - Containment steps (revoke tenant, rotate credential, pull
     model version).
   - Root-cause steps (which tactic came before, which technique
     enabled this one).
   - Notification path (owner team, CISO, Legal for
     regulatory-relevant events).
3. **Coverage register** — one row per technique in a control-library
   sheet with the columns:
   - `atlas_id`
   - `data_source_required`
   - `data_source_available` (Y/N with source)
   - `detection_status` (implemented / drafted / gap)
   - `mitigation_status` (preventive controls that make the
     technique harder in the first place)

Example — one drafted Sigma rule stub for a model-extraction pattern:

```yaml
# Draft Sigma rule — verify field names, source, and threshold
# against your SIEM before enabling. Illustrative, not authoritative.
title: ML Model Access — Anomalous Query Coverage by Single Tenant
id: 00000000-0000-0000-0000-000000000000  # generate a real UUID
status: experimental
description: >
  Detects a single tenant whose query embeddings cover an unusually
  high fraction of the model's decision surface in a short window,
  consistent with model-extraction (ATLAS ML Attack Staging /
  Extraction).
author: ai-ml-security-team
date: 2026-08-04
tags:
  - attack.ml_model_access
  - atlas.T0044   # verify current ID at atlas.mitre.org
  - atlas.tactic.ml_attack_staging
logsource:
  product: model_serving
  service: inference_gateway
detection:
  selection:
    event_type: inference_response
  timeframe: 24h
  condition: >
    count(distinct decision_region_id) by tenant_id > 0.30 *
    total_decision_region_count
falsepositives:
  - Legitimate high-diversity workloads (batch offline scoring runs
    should be excluded by tenant_role).
level: high
```

This rule is illustrative — the field names, the `decision_region_id`
signal, and the exact threshold are stand-ins for whatever your
platform actually emits. The *point* is the metadata shape: an
ATLAS-tagged rule that a responder can trace to a runbook and that a
release-gate policy can require the presence of.

---

## Mitigations and the crosswalk to OWASP

ATLAS `AML.M####` mitigations are the recommended defensive posture
tagged back to each technique. They are the crosswalk that connects
ATLAS to the OWASP Top 10 controls from chapter 01:

- ATLAS mitigations for the Model Access tactic overlap heavily with
  OWASP ML05 (Model Theft) preventive controls: per-tenant rate
  limits, watermarking, output-confidence truncation, restricted
  read access to the model artifact.
- ATLAS mitigations for the ML Attack Staging tactic overlap with
  OWASP ML01 preventive controls: adversarial training, input
  validation, distribution monitoring.
- ATLAS mitigations for Persistence, Credential Access, and Defense
  Evasion are largely reused from ATT&CK — enterprise-generic.

The direction of the mapping matters:

- Start with the OWASP risk (which class of attack) → look up the
  ATLAS techniques that instantiate it (which specific behaviours) →
  design detection content per technique and preventive controls per
  the ATLAS mitigation set.

This is the workflow Exercise 02 walks you through end to end.

---

## Living-framework hygiene

ATLAS is a living framework. Three habits keep your content current:

1. **Version-pin every artifact.** Every Sigma rule, every runbook,
   every control-library row carries the ATLAS matrix version it was
   authored against. Version diffs are how you find retired,
   renamed, or split techniques.
2. **Re-review on a cadence.** Every quarter, diff the ATLAS matrix
   against your coverage register and open tickets for new
   techniques.
3. **Contribute case studies back.** AI-specific incidents your team
   handles under mod-111 belong in a public case study if the
   organisation permits publication. This is how the field's TTP
   catalogue stays current.

---

## The two artifacts this chapter is training you to produce

By the end of this chapter and Exercise 02:

- A **techniques tour** — for a chosen tactic (e.g., ML Model Access
  or ML Attack Staging), read every technique in the tactic and mark
  whether your target system has data-source coverage, detection
  content, and preventive mitigation.
- A **detection-content stub map** — for the top three techniques by
  impact/likelihood, a Sigma-shaped detection stub tagged with the
  ATLAS technique and tactic IDs, and a runbook stub for what the
  responder does when it fires.

These deliverables plug directly into mod-111 (Security Operations
and Incident Response), where the depth lives.

---

## Summary

- ATLAS is the *TTP scaffold* your detection engineering and IR
  playbooks map to; if your content is not ATLAS-tagged, an incoming
  analyst cannot navigate it.
- Read every technique page for its data-source requirement, its
  detection shape, and its recommended mitigation.
- Case studies are how ATLAS connects the abstract catalogue to real
  incidents; use them for coverage backfill and tabletop drills.
- Cross-reference ATLAS techniques to OWASP ML / LLM risk categories
  (chapter 01) and to NIST AI 100-2 vocabulary (chapter 03) so a
  single control artifact carries all three labels.
