# Exercise 02 — STRIDE for ML: The Worked Example

**Estimated effort:** ~2 hours
**Deliverable:** One STRIDE-per-element table (Markdown or CSV) for
the target system from exercise 01.
**Prerequisites:** Exercise 01 complete (asset inventory + DFD +
dependency graph in hand). Chapter 03 read end-to-end.

---

## Objective

For the target system, apply **STRIDE-per-element** to every asset
in the exercise-01 inventory. Produce one row per (asset, STRIDE
letter) intersection that yields a real threat, with the ML-native
attack named. Add an **A (abuse)** column for the LLM assets where
STRIDE letters undercount NIST AI 100-2 abuse-violation threats.

By the end of the exercise, you have the STRIDE-per-element table
that chapter 04 will tag with ATLAS + NIST metadata.

## Problem statement

Same target system as exercise 01 (the fintech LLM assistant plus
the classical fraud model, or your substituted real system). You
already have the asset inventory and the DFD.

Now walk STRIDE — Spoofing, Tampering, Repudiation, Information
disclosure, Denial of service, Elevation of privilege — plus an
Abuse column for the LLM assets, against every asset.

## Requirements

Produce a single Markdown or CSV file with a STRIDE table. The
table has one row per identified threat and the following columns:

| Threat ID | Asset ID | Asset class | STRIDE letter | Attack (concise) | NIST AI 100-2 sketch | Preventive sketch | Detective sketch | Evidence sketch | Owner | Not-applicable defence (if letter has no threat) |

Rules of engagement:

- **No blank cells.** Every (asset, letter) pair either produces a
  populated threat row or an explicit "not applicable" row that
  defends the negation against the asset's admissible-operations
  envelope from exercise 01.
- **Add the A column for LLM assets** (prompt/tool graph, embedding
  index; and for the LLM decision surface where the fintech uses
  one). Rows in the A column are abuse-violation rows in NIST AI
  100-2 vocabulary.
- **Threat IDs must be stable and traceable** — the shape
  `THREAT-<CLASS>-<LETTER>-<N>` recommended in chapter 03 is a good
  starting point.
- **NIST AI 100-2 sketch column** — one line per row, in the form
  "family / capability / knowledge / lifecycle". Not the full
  chapter-04 tag; that is exercise 03.
- **Preventive / Detective / Evidence sketches** — one phrase each,
  cross-referenced by name to mod-101 chapter 01 controls where
  possible (do not re-teach the controls — cite them).
- **Owner column** — who owns the mitigation, not who owns the
  security review. If the answer is "unclear", say so and route it
  as an open question in the summary.

Include a section at the top that lists:

- The DFD version referenced (from exercise 01).
- The asset inventory version referenced.
- The STRIDE variant used (per-element primary, per-interaction
  supplement where noted).
- The abuse column: applicable to which assets?

Include a section at the bottom that lists:

- Assets with **the most threat rows** — usually the LLM prompt/tool
  graph and the decision surface.
- Assets with **the most gap-status preventive sketches** — used in
  exercise 03 to prioritise ATLAS tagging.
- **Cross-references** — where a threat row applies to multiple
  assets (inversion applies to training-data AND decision-surface),
  cross-reference the paired row explicitly.

## Starter guidance

- Do the classical fraud model first. Its threats are more familiar
  and the walk warms you up for the harder LLM columns.
- Walk STRIDE one asset at a time, one letter at a time. Do not
  skip letters — the discipline is the point.
- The abuse column for the LLM assets is where the module's
  distinctive value shows. Do not smuggle abuse into E; give it
  its own column.
- When two assets carry the same threat (inversion on training-data
  AND on the decision-surface), write both rows. Mitigation lives
  on both.
- Where a threat requires an attacker-in-the-training-pipeline
  capability that the target system's architecture rules out
  (e.g., the CI/CD signing key is HSM-held), note the row as
  applicable but low-likelihood — do not skip. Likelihood ranking
  is chapter 05's job; catch the row first.

## Acceptance criteria

A passing table:

- Covers every asset from exercise 01, every STRIDE letter, and the
  abuse column for LLM assets.
- Contains no blank cells — every (asset, letter) pair is either a
  threat row or a defended not-applicable.
- Contains at least the following ML-native threats, appropriately
  distributed across assets:
  - Evasion (against decision surfaces).
  - Poisoning (against training data).
  - Backdoor (against training data or transferred pretrained
    models).
  - Extraction (against decision surfaces).
  - Inversion (against training data and decision surfaces).
  - Membership inference (against training data and decision
    surfaces).
  - Model-artifact tampering (against model-artifact assets).
  - Direct prompt injection (against prompt/tool graphs).
  - Indirect prompt injection (against prompt/tool graphs via
    embedding indexes).
  - Sensitive-information disclosure (against prompt/tool graphs).
  - System-prompt leakage (against prompt/tool graphs).
  - Excessive agency (against prompt/tool graphs with tools).
  - Vector-store poisoning (against embedding indexes).
  - Cross-tenant retrieval (against embedding indexes with
    multi-tenant namespaces).
  - Unbounded consumption (against decision surfaces / prompt-tool
    graphs).
- Every preventive and detective sketch is a specific artifact,
  not a wish.
- Every not-applicable defence names the specific
  admissible-operations line that rules out the threat.

A failing table:

- Uses "STRIDE-per-interaction only" and misses assets-in-place
  threats.
- Omits the A column and hides abuse violations under E.
- Contains "TLS" as the preventive sketch for anything other than
  the ML09 output-integrity row.
- Uses "future work" or "TBD" anywhere.

## Stretch goals

- Overlay each row with its **OWASP ML / LLM v2025 identifier** and
  the **coverage-matrix status** from mod-101 exercise 01 if you
  completed it. This closes the loop between the two artifacts.
- For three rows of your choice, sketch the STRIDE-per-interaction
  view (the same threat viewed as an interaction between two DFD
  elements). Confirm the per-element walk did not miss anything the
  per-interaction walk catches; note any additions.
- Author a short paragraph naming the **structural blind spots** in
  the STRIDE table for the target system — threats that fit
  awkwardly into any letter, and how you tagged them.

## Do not

- Do not pre-map to ATLAS or NIST vocabulary here. That is
  exercise 03. Keep this exercise focused on the STRIDE walk.
- Do not prune "duplicate" rows across assets. Inversion appears on
  both training-data and decision-surface — that is the point.
- Do not commit a solution to any repository — solutions live in
  the paired solutions repo.
