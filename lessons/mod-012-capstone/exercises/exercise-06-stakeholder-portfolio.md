# Capstone Exercise 06 — Stakeholder Communication Portfolio

**Estimated time**: 4 hours
**Deliverable**: Four distinct audience-targeted artifacts

---

## The assignment

The security program from Exercises 01-05 exists. Now you
must **communicate** it to four different audiences. Each
artifact reframes the same content for the audience that will
read it.

This exercise tests the underrated skill that distinguishes
"security engineer" from "security engineer who can land
work in an organization."

## The four artifacts

### Artifact 1: Board + CFO brief (1-page max)

**Audience**: NorthBridge's board of directors + CFO. They have
60-90 seconds to read it.

**Goal**: get sign-off on the security investment.

**Required content**:

- The TL;DR: the security posture in 3-4 sentences.
- The investment ask: dollars + timeline + headcount.
- The business value: customer-renewal protection, regulatory-
  fine avoidance, EU AI Act enabling new EU revenue.
- The risk if you don't invest: customer churn, regulatory
  exposure, brand harm from a public incident.
- The asks decision: approve / approve with conditions / defer.

**Constraints**:

- One page. Hard limit.
- Finance language, not engineering jargon.
- Specific numbers (real or defensible ranges).

### Artifact 2: Engineer-facing architecture README (5-8 pages)

**Audience**: NorthBridge's engineering team (8 today, growing
to 25).

**Goal**: bring them up the curve on the security program;
make the design implementable.

**Required content**:

- The architecture (zero-trust, network, crypto, secrets) at a
  level the team can build.
- Sequencing of work (which quarter, which team owns what).
- Key decisions and the rationale.
- Open questions (what's still TBD).
- "How to contribute" — how engineers add policies, write
  detection rules, etc.

**Constraints**:

- Engineering audience.
- Diagrams welcome.
- Doesn't need to repeat the threat model; references it.

### Artifact 3: Customer CISO response (3-5 pages)

**Audience**: a hospital customer's CISO conducting a
vendor-security review.

**Goal**: pass the review; renew the contract.

**Required content**:

- NorthBridge's security posture across HIPAA's safeguards.
- Encryption, access controls, audit, IR.
- Compliance certifications (current state + roadmap).
- Sub-processors with PHI access.
- Breach notification commitments.
- Honest statement of maturity gaps + roadmap to close them.
- A direct response to common security-review questions.

**Constraints**:

- Customer-facing tone (professional, reassuring but honest).
- Specific controls, not marketing.
- Includes a "what we're still maturing" section — customers
  appreciate candor.

### Artifact 4: EU AI Act technical documentation outline (3-5 pages)

**Audience**: an EU regulator or notified body reviewing
NorthBridge's high-risk AI compliance.

**Goal**: demonstrate readiness; satisfy Annex IV's technical
documentation requirements.

**Required content**:

For each high-risk system (Triage-Risk, HAI-Predict, Med-
Verify, Ambient-Doc):

- General description (intended purpose, deployer, classification
  rationale).
- Detailed description of elements (architecture, data
  governance, training process).
- Risk management measures (Article 9).
- Accuracy, robustness, cybersecurity measures (Article 15).
- Human oversight measures (Article 14).
- Quality management system pointer (Article 17).
- The notified-body engagement plan (if applicable).

**Constraints**:

- Formal tone.
- Article-by-article structure.
- Specific to NorthBridge's clinical context.
- Acknowledge unresolved questions (will be addressed in the
  full technical file, which this is the outline for).

## Quality criteria

For all four artifacts:

- **Different framing** — same content, audience-specific
  framing.
- **Honesty** — gaps acknowledged.
- **Actionability** — could drive decisions / next steps.

Specific to each:

- **Board brief**: under 1 page; finance-grade.
- **Engineer README**: implementable.
- **Customer CISO**: passes a security review.
- **EU AI Act doc**: filable.

A failing portfolio:

- One artifact rewritten four times.
- Marketing language replacing substance.
- All four read by the engineer; none for the actual audience.
- "We are fully compliant" claims.

## Reflection questions

1. Which artifact was hardest to write? Why?
2. Which artifact would you actually send tomorrow?
3. Which audience's response would teach you the most?
4. The same content, four framings. What's invariant across
   them?

## How this completes the capstone

You now have:

- A threat model (Exercise 01).
- An architecture (Exercise 02).
- ML-specific controls (Exercise 03).
- A compliance + policy program (Exercise 04).
- A SecOps program (Exercise 05).
- Four audience-targeted communications (Exercise 06).

That's a portfolio. Bind them together (a top-level README in
your capstone directory linking to each). It's the artifact you
take to interviews, performance reviews, internal advancement
conversations, or use as the starting point for the real
security program you eventually build.

## Time budget

- Board brief: 75 min (deceptively hard — short writing is
  longer to produce).
- Engineer README: 90 min.
- Customer CISO response: 60 min.
- EU AI Act outline: 75 min.
