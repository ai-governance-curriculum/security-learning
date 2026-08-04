# Exercise 01 — OWASP ML Top 10 and LLM Top 10 v2025 to Control Map

**Estimated effort:** ~2 hours
**Deliverable:** One coverage matrix document (~3–4 pages Markdown)
**Prerequisite:** Chapter 01 read end-to-end

---

## Objective

Take a real (or realistic-composite) ML/LLM system and produce the
**working coverage matrix** described in chapter 01 — one row per
OWASP ML Top 10 item that applies, and one row per OWASP LLM Top 10
v2025 item that applies. Every row must name a preventive control, a
detective control, an evidence artifact, and an owner.

By the end of the exercise you should be able to walk this matrix
into a design review, a release gate, or an audit interview and
defend every cell.

## Problem statement

You are the AI/ML Security & Governance Engineer for a mid-sized
consumer fintech. The product team is preparing to ship an
LLM-powered financial-planning assistant to external customers. The
system has two ML surfaces:

1. **A classical fraud-detection model** — an XGBoost classifier that
   scores every user's transaction stream in near real-time. Trained
   monthly on internal transaction data, deployed on the ML
   platform. Serves an internal decisioning service.
2. **An LLM-powered agent** — a chat surface that answers customer
   questions about their spending, calls two tools ("get transactions
   for period X" and "categorise this transaction"), and — pending
   release-gate approval — will soon be permitted to "propose a
   savings-transfer" tool that moves money between the user's linked
   accounts, subject to human confirmation.

A public research white paper on similar assistants has recently
demonstrated indirect prompt injection via customer-support emails
ingested into the retrieval corpus. Your peer
`ai-evaluation-engineer` cannot open the release-gate review until
this matrix is on the table.

## Requirements

Produce a Markdown document with the following structure:

### Section 1 — System description (1 page maximum)

- Data flows: from data ingest through training / retrieval / serving
  / consumption.
- Trust boundaries: where does an untrusted token become trusted.
- Assets: the models, the vector store, the tool endpoints, the
  training data, the customer data.
- External surface: which endpoints and inputs a non-authenticated
  attacker can reach.

### Section 2 — Coverage matrix

Two tables. Table A is the OWASP ML Top 10 walk-through against the
fraud-detection model. Table B is the OWASP LLM Top 10 v2025
walk-through against the LLM agent.

Every row must have:

| Column | Requirement |
| --- | --- |
| Risk ID | OWASP ML ID or OWASP LLM v2025 ID. |
| Applies? | YES / NO, one-sentence justification. "NO" answers must defend the negation with the system's actual architecture. |
| Preventive control | Specific artifact (config file, policy, service, library). "Follow best practice" is not a preventive control. |
| Detective control | Specific alert with a query and a threshold, plus the runbook ID (may be a stub — see Section 3). |
| Evidence artifact | Specific file / signature / log line / SBOM entry an admission gate can inspect. |
| Owner | The team the control routes to when it fails. |
| Coverage | Adequate / Partial / Inadequate. |
| Remediation ticket | Fake ticket ID acceptable; must describe what closes the gap in a sentence. |

### Section 3 — Detection stubs (optional but strongly recommended)

For any three rows where you named a detective control, produce a
short stub for the alert query using pseudo-Sigma or a
platform-appropriate query language. Include the false-positive
shape.

### Section 4 — Executive summary (0.5–1 page)

Top three coverage gaps by impact × likelihood. Defend the ranking.
Propose a sequencing of the remediation work in eng-weeks.

## Starter guidance

- Reread chapter 01 §Part A and §Part B before you start. The table
  in the "Reading the list as an engineer" section is the shape of
  every row.
- Prompt injection (LLM01:2025) is item one. Do the LLM table first
  and start from LLM01 — most other v2025 rows depend on that row's
  controls.
- Do not paper over the seam where the fraud model consumes an
  embedding produced by (or referenced from) the LLM system. Note the
  cross-system dependency explicitly.
- If a Top-10 item does not apply, defend the "does not apply" in
  writing with the architecture that removes the surface. A blanket
  "NO" without defence is a failing row.
- Do not use "we have TLS" as a mitigation for anything in the
  ML column. TLS does not affect ML01–ML10 except ML09 (channel
  integrity).

## Acceptance criteria

A passing matrix:

- Every applicable Top-10 item across both lists has a row.
- Every row has all seven / eight columns filled in — no TBDs.
- Every preventive and detective control is a concrete artifact,
  not a wish.
- Every evidence artifact is inspectable at admission time by an
  automated policy.
- Every "NO" answer defends the negation against the actual system
  description in Section 1.
- The executive summary's top-three ranking is defended (not just
  asserted) against the alternatives.

A failing matrix:

- Treats "we have an audit log" as sufficient for ML05 or LLM02.
- Uses "follow best practice" as any cell contents.
- Marks four or more items NO with no defence.
- Skips LLM01:2025 or claims it does not apply.

## Stretch goals

- Extend the matrix with a NIST AI 100-2 vocabulary column (chapter
  03) — attacker goal / capability / knowledge / lifecycle stage per
  row.
- Extend the matrix with an ATLAS tactic + technique ID column
  (chapter 02) for the detective controls.
- Trace one row (recommendation: LLM06:2025 Excessive Agency) all
  the way to an OPA/Rego policy pseudo-code that would enforce the
  admission gate. You are not implementing the policy, you are
  showing what the policy would inspect.
- Write a paragraph explaining what changes in the matrix if the
  "propose a savings-transfer" tool is enabled without
  human-in-the-loop confirmation. Which rows worsen?

## Do not

- Do not solve the exercise by writing a taxonomy of controls. The
  deliverable is a coverage matrix for **this** system, not a
  library.
- Do not paper over gaps with "future work"; declare the gap and
  its remediation ticket.
- Do not commit a solution to any repository — solutions live in the
  paired solutions repo.
