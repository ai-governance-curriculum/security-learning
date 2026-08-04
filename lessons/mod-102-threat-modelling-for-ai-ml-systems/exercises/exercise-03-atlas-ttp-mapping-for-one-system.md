# Exercise 03 — ATLAS TTP Mapping for One System

**Estimated effort:** ~2 hours
**Deliverable:** The IR-consumable threat inventory in a
source-controllable machine-parseable format (YAML or JSON), plus a
one-page coverage-vs-gap report.
**Prerequisites:** Exercises 01 and 02 complete. Chapter 04 read
end-to-end. Access to the current [atlas.mitre.org](https://atlas.mitre.org/)
matrix and to NIST AI 100-2 e2023.

---

## Objective

Take the STRIDE table from exercise 02 and translate every row into
the **IR-consumable threat inventory** described in chapter 04.
Every row acquires ATLAS tactic + technique IDs, NIST AI 100-2
family + capability/knowledge/lifecycle metadata, a reference
attack citation, an IR runbook ID (stub is fine), and a data-source
requirement.

By the end of the exercise, the inventory is in a shape mod-111
(SecOps and IR) can consume as its detection-content backlog, and
the coverage-vs-gap report is in a shape mod-112 can quote in the
program-leadership metrics package.

## Problem statement

Same target system as exercises 01 and 02. You have the STRIDE
table from exercise 02; you now walk each row through the tagging
step and land the result in a machine-parseable file.

## Requirements

Produce two artifacts in a single PR-shaped commit.

### Artifact 1 — `threat-inventory.yaml` (or `.json`)

One entry per STRIDE row from exercise 02. Every entry contains
every field from the chapter-04 row template:

```yaml
- stride_id: THREAT-<CLASS>-<LETTER>-<N>
  asset_id: asset.<...>
  asset_class: training-data | model-artifact | decision-surface | prompt-tool-graph | embedding-index
  stride_letter: S | T | R | I | D | E
  abuse_col: true | false
  owasp: [ML0N, LLM0N:2025, ...]
  atlas:
    tactics: [TA####, ...]        # verify at atlas.mitre.org
    techniques: [AML.T####, ...]  # verify at atlas.mitre.org
    primary_technique_for_detection: AML.T####  # the one detection lands on
  nist_ai_100_2:
    family: <evasion | data_poisoning | backdoor_trojan | model_extraction |
             membership_inference | model_inversion | attribute_inference |
             reprogramming | prompt_injection_direct | prompt_injection_indirect |
             data_extraction_memorisation | abuse_violation | ...>
    attacker_goal: <availability | integrity_targeted | integrity_untargeted | privacy | abuse>
    attacker_capability: <training_time | inference_time_query | inference_time_score |
                          inference_time_gradient | ingest_influence | ...>
    attacker_knowledge: <white_box | grey_box | black_box_score | black_box_decision>
    lifecycle_stage: <training | inference | post_deployment>
  reference_attack:
    - "<citation to canonical academic paper>"
  ir_runbook_id: IR-<...>-01
  data_source_requirement:
    - <specific telemetry stream required for detection>
  status:
    preventive_mitigation: gap | partial | live
    detection_content: gap | partial | live
    evidence_artifact: gap | partial | live
  notes: <one-sentence context if useful>
```

Rules:

- **Verify every ATLAS ID at [atlas.mitre.org](https://atlas.mitre.org/) at time
  of authoring.** ATLAS moves; the module chapters flag this
  discipline for a reason. Add a `matrix_version` field at the top
  of the file naming the ATLAS matrix version you tagged against.
- **Verify NIST AI 100-2 family names against the current e2023
  edition** (or later). Do not invent family names.
- **Cite the canonical reference attack** for every family — the
  reference list at the bottom of mod-101 chapter 03 §"attack
  families" is the starting bibliography; resources.md is the
  extended list.
- **IR runbook IDs may be stubs**, but they must be stable strings
  the mod-111 backlog can consume. Do not use "TBD".
- **Data-source-requirement fields are the mod-112 investment
  argument.** Be specific — "per-tenant query stream with input
  embedding features" is a good field; "logs" is not.
- **Status block is honest.** Gap means no mitigation exists; partial
  means some coverage but not enough; live means the mitigation is
  in production with evidence.

### Artifact 2 — `coverage-vs-gap.md`

A one-page report with the following sections:

**Header** — one paragraph, date, threat-inventory file reference,
ATLAS matrix version.

**Coverage summary** — total row count; count of live / partial /
gap per (preventive / detection / evidence) axis.

**Coverage by ATLAS tactic** — count of covered vs gap-status rows
per tactic. Use the tactic names + IDs from the current matrix.

**Coverage by NIST AI 100-2 family** — same shape, per family.

**Top data-source gaps** — the three telemetry streams whose
absence blocks the most detection rows. Each with an eng-week
estimate for what it would take to emit them (feeds mod-112).

**Recommended next investment** — three bullet points naming the
top three gaps to close and what closes them. Not implementation
depth — the ranking is chapter 06's job. Just the shape.

## Starter guidance

- Do the mapping row-by-row, not framework-by-framework. Pick a
  STRIDE row, look up the ATLAS technique, look up the NIST family,
  fill in the fields.
- For each STRIDE row, ask *both* directions:
  - "*What is the attacker doing on the wire?*" → picks the ATLAS
    technique.
  - "*What family, capability, and knowledge?*" → picks the NIST
    fields.
- If a STRIDE row does not map cleanly to any ATLAS technique, the
  row is either a data-source gap (no telemetry for it exists in
  the matrix yet) or a novel-attack row your inventory contributes
  to the community catalogue. Note it either way; do not force a
  wrong tag.
- The reference-attack citation is not optional. If you cannot find
  a paper, either the attack has a different name in the
  literature (search harder) or your row is under-specified (fix
  it).
- Keep the status block honest. A row you desperately want to be
  "live" that is actually "partial" hurts the roadmap sequencing
  in chapter 06.

## Acceptance criteria

A passing inventory + report:

- Every STRIDE row from exercise 02 appears as an entry in the YAML
  / JSON file.
- Every entry has every field populated — no TBDs.
- Every ATLAS ID has been verified against atlas.mitre.org and
  the file names the matrix version.
- Every NIST AI 100-2 family name is a valid family name from the
  e2023 edition or later.
- Every entry cites at least one reference attack.
- The coverage-vs-gap report has all sections populated, with
  numbers, not adjectives.
- The top-data-source-gap list is ordered by how many detection
  rows the absence blocks.

A failing inventory + report:

- Uses invented ATLAS IDs or invented NIST family names.
- Skips the `matrix_version` field.
- Marks rows "live" without evidence.
- Contains "future work" or "TBD" anywhere.
- Uses PDF for the inventory (the consumers are pipelines).

## Stretch goals

- Publish the inventory as a schema-validated artifact — a JSON
  Schema for the entry shape checked in alongside the file.
- Add a **decay column** — for each ATLAS / NIST identifier used,
  record the source version and the recheck cadence (quarterly
  recommended). This is the version-pinning discipline from
  mod-101 chapter 02 §"Living-framework hygiene".
- Add a **cross-reference block** at the bottom of each entry
  listing other entries whose mitigations, if built, would also
  cover this entry (substitution relationships — chapter 06 input).

## Do not

- Do not skip verifying ATLAS IDs against the live matrix "because
  they don't change often". They change more than you think.
- Do not stall on missing IR runbook IDs — stubs are acceptable.
- Do not commit a solution to any repository — solutions live in
  the paired solutions repo.
