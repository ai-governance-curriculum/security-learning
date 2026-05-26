# Module 12 — Capstone: Synthesis Guidance

> This is **not** a teaching module — it's guidance on how to
> approach synthesis work. The actual content is in the 11
> prior modules.

---

## 1. What "synthesis" actually means

The 11 modules taught skills in isolation. The capstone tests
whether you can integrate them. Integration is harder than it
sounds, for three reasons:

1. **Decisions in one area constrain decisions in another.**
   The threat model influences architecture; architecture
   influences controls; controls influence detection; detection
   influences IR. Mistakes in early decisions compound.

2. **Trade-offs become real.** In a module exercise, you pick
   "the right" defense. In synthesis, you pick *one* defense
   from many, and defend that against the alternatives.

3. **Audiences differ.** The same security program is described
   four ways depending on who's reading. The engineer wants
   architecture diagrams; the CFO wants spend; the auditor
   wants control narratives; the customer's CISO wants
   reassurance.

This module is about producing artifacts that survive contact
with all four audiences.

---

## 2. The synthesis workflow

A recommended order (you can deviate, but justify):

### Step 1 — Internalize the scenario

Read [`scenario-brief.md`](./scenario-brief.md) twice. Note:

- The **highest-leverage threats** for this specific scenario
  (clinical safety + PHI exposure + EU AI Act compliance).
- The **constraints** (small team, growth trajectory, 9-month
  SOC 2, 12-month multi-cloud).
- The **politics** (board pressure, customer churn risk,
  Sarah's pragmatism).

### Step 2 — Threat-model and prioritize (Exercise 01)

Apply Modules 01, 06, 07. Produce:

- Threat model (STRIDE+ML).
- Regulatory applicability matrix.
- Prioritized risk register.

This is the **foundation**. Every later artifact references it.

### Step 3 — Architecture (Exercise 02)

Apply Modules 02, 03, 04, 05. Produce:

- Zero-trust workload-identity design.
- Cryptography + key management plan.
- Network microsegmentation.
- Secrets management.

Each must address the prioritized risks from Step 2.

### Step 4 — ML-specific controls (Exercise 03)

Apply Module 06 + Module 10's ML provenance + Module 09's
model promotion gate. Produce:

- Adversarial defense plan per model.
- Differential-privacy decisions per training run.
- LLM safety pipeline for Ambient-Doc and Wellness-Coach.
- Model + dataset provenance.

### Step 5 — Compliance + policy (Exercise 04)

Apply Modules 07, 09. Produce:

- SOC 2 readiness plan.
- HIPAA technical-safeguards mapping.
- EU AI Act high-risk article-by-article plan.
- Policy-as-code program.

### Step 6 — SecOps (Exercise 05)

Apply Modules 08, 11. Produce:

- Runtime security baseline.
- SIEM + detection ruleset.
- IR procedure + playbooks.
- Tabletop schedule.

### Step 7 — Stakeholder communication (Exercise 06)

Apply nothing new; reformat what you have for the four
audiences:

- Board / CFO brief (1-page summary + financials).
- Engineering README (architecture-focused).
- Customer CISO response (compliance-focused).
- Regulator-ready documentation (EU AI Act technical
  documentation).

---

## 3. Writing for different audiences

The same content reframed:

### For engineers

- Architecture diagrams (with named components).
- Concrete control names and tools.
- Sequencing (what depends on what).
- "Here's the design; here's the trade-off; here's the gap."

### For the CFO

- Cost in dollars; ROI in dollars or avoided fines.
- Headcount implied.
- Timeline — what's delivered when.
- Risk reduction expressed in business terms (not "MTTD
  improved" but "customers won't churn over security
  concerns").

### For the customer's CISO

- Reassurance with specifics. Not "we take security seriously"
  but "we have X, Y, Z controls; here's the evidence."
- Direct answers to common security-review questions
  (encryption, access, audit, IR).
- A short statement of where you're still maturing — honesty
  wins.

### For the regulator (EU AI Act audience)

- Article-by-article mapping.
- Technical documentation that satisfies Annex IV of the AI
  Act.
- Evidence pointers (where to find the proof).
- Acknowledgment of unresolved questions.

---

## 4. The recurring trade-offs

The capstone will surface trade-offs at every step. Common
ones:

### Speed vs. depth

You're under board pressure to ship SOC 2 in 9 months. You
also know the EU AI Act work is larger. How do you sequence?
- Compromise: minimal-viable SOC 2 (just Security criterion +
  Confidentiality), then expand. EU AI Act work can run in
  parallel since the operational deadlines are later.

### Operational cost vs. control strength

- Adversarial training is expensive (10× training time). Worth
  it for Triage-Risk (life-safety)? Probably yes. Worth it
  for HAI-Predict? Defendable either way.
- DP-SGD reduces utility. Worth it for Triage-Risk training?
  Depends — the customer / regulator may *require* it.

### Internal vs. vendor

- Run Sigstore privately, or use the public service?
- Build SIEM on Elastic, or buy Datadog Cloud SIEM?
- Self-host LLM (privacy-preserving) or use OpenAI (cheaper,
  faster)?

There are no universally correct answers. The capstone judges
your reasoning, not your choice.

### Pragmatism vs. principle

- HIPAA technically requires X. Industry practice is to do Y.
  Customer demands Z. You can defend any of the three, depending
  on context. Make the call and justify.

---

## 5. Common capstone failure modes

What separates a passing capstone from a failing one:

### Failure: copying module exercises wholesale

The module exercises were calibrated to SmartRecs scenarios.
NorthBridge is different. Lifting prior work without adapting
to the new scenario produces an incoherent capstone.

### Failure: glossing over the gaps

Honest gaps make a capstone stronger. "We can't yet do X; here's
the plan to get there" is more credible than claiming complete
coverage.

### Failure: writing only for one audience

The deliverables are read by engineers AND CFO AND auditors. A
capstone that only speaks to engineers fails the multi-audience
test.

### Failure: no sequencing

Listing 50 controls without sequencing them is unactionable.
Sequencing — what comes first, why, what depends on what — is
the high-value layer.

### Failure: ignoring the EU AI Act

The NorthBridge scenario explicitly flags the EU AI Act. A
capstone that only addresses HIPAA + SOC 2 misses the most
distinctive regulatory challenge of the scenario.

### Failure: ignoring the team-size growth

NorthBridge is going from 8 to 25 engineers in 12 months. The
security program has to scale. A capstone designed only for
today's team fails when the team triples.

### Failure: ignoring customer/board politics

NorthBridge has customers churning over SOC 2; the board has
opinions. A capstone that produces a technically-perfect plan
the company can't execute is a failed capstone.

---

## 6. The peer-review process

If you have access to a peer reviewer (instructor, study
partner, mentor), use the peer-review structure:

1. **Submit the portfolio** (all six exercises completed).
2. **Reviewer reads the scenario brief**, then reads each
   artifact in order.
3. **Reviewer scores against the grading rubric**
   ([`grading-rubric.md`](./grading-rubric.md)).
4. **Reviewer provides written feedback** with at least:
   - Three things the capstone does well.
   - Three substantive concerns.
   - One question the reviewer would ask in an interview.
5. **You revise** based on feedback.

If you're working solo, use the rubric for self-assessment.
Aim to score yourself honestly; the rubric is calibrated to
real reviewer standards.

---

## 7. What "ready to operate" looks like

At the end of the capstone, a candidate who's "ready to
operate" can:

- Read a real-shaped scenario brief and identify the threats,
  controls, compliance triggers in 30 minutes.
- Produce defensible architecture artifacts.
- Defend choices under questioning.
- Identify what they don't know and where to get help.
- Communicate with technical, executive, regulatory, and
  customer audiences.
- Sequence work realistically against constraints.

The capstone artifacts are the **evidence** of that
operability. They're what you'd show in a job interview, a
performance review, or a customer security review.

---

## 8. After the capstone

A finished capstone is a **portfolio**. Useful next steps:

- **Job applications**: link to the portfolio in your resume.
  Real artifacts beat self-descriptions.
- **Internal advancement**: bring a polished version to your
  manager. "Here's what an AI security program looks like;
  here's what we're missing."
- **Continued learning**: the field moves. Re-do the capstone
  in 2 years with current frameworks (NIST AI RMF v2, EU AI
  Act updates, new MITRE ATLAS tactics).
- **Teach**: explain the capstone to a less-experienced
  engineer. The teaching surfaces gaps in your understanding.

The 11-module track plus this capstone is the **on-paper
preparation** to operate as an AI infrastructure security
engineer. The next step is **doing it**.

---

## Cross-references

For each capstone exercise, the relevant prior modules:

| Capstone exercise | Relies on |
|---|---|
| 01: Threat model + risk register | 01, 06, 07 |
| 02: Architecture | 02, 03, 04, 05 |
| 03: ML-specific controls | 06, 09, 10 |
| 04: Compliance + policy | 07, 09 |
| 05: SecOps | 08, 11 |
| 06: Stakeholder communication | 07 (audience awareness) |

---

*Begin with [Exercise 01](./exercises/exercise-01-threat-model-and-risk-register.md)
when you've internalized the scenario brief.*
