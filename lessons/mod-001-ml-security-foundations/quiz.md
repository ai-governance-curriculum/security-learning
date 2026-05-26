# Module 01 Quiz — Foundations of ML Security

> Take this quiz **after** working through the lecture notes and the
> five exercises. Closed-book is harder than open-book — try
> closed-book first.
>
> An answer key lives in the paired solutions repo at
> [`ai-infra-security-solutions/modules/mod-001-ml-security-foundations/quiz-answers.md`](https://github.com/ai-infra-curriculum/ai-infra-security-solutions/tree/main/modules/mod-001-ml-security-foundations).
> (If the answer key isn't there yet, post the question you're
> stuck on in Discussions.)

---

## Conceptual (10 questions)

### Q1
Name the three structural classes of ML-specific threats described
in §1.1 of the lecture notes. For each, give one OWASP ML Top-10
item that exemplifies it.

### Q2
A team protects its ML serving API with strong IAM, mTLS, and rate
limits. Name three ML-specific threats this configuration does
**not** mitigate, and explain why each is still possible.

### Q3
A model's accuracy on a held-out test set is unchanged month over
month, but the team's model-monitoring dashboard shows a measurable
drop in real-world prediction quality. Is this a security event?
Justify in 3–4 sentences.

### Q4
You inherit an ML system whose production model is loaded from a
public Hugging Face checkpoint at startup, with no signature
verification. Map this configuration against the OWASP ML Top 10
and identify the **three** Top-10 items most directly applicable.

### Q5
For each OWASP ML Top-10 item below, name the lifecycle stage(s)
where the most effective preventive controls live:
- ML02 Data Poisoning
- ML03 Model Inversion
- ML05 Model Theft
- ML06 AI Supply Chain
- ML09 Output Integrity

### Q6
The lecture notes argue that "compliance is a consequence of
security, not a substitute for it." Restate this principle in your
own words and give one concrete example of a control that would
pass an audit but fail against a real ML threat.

### Q7
Walk a **model extraction** scenario through five MITRE ATLAS
tactics. For each, name the tactic and describe the adversary
action in one sentence.

### Q8
A new ML system stores its training-data lineage in a single
PostgreSQL table whose schema includes a `last_modified` timestamp.
A senior engineer proposes this is sufficient for audit purposes
because "we have full lineage in the database." Argue against this
on threat-model grounds. What is the insider-threat scenario this
design fails to handle, and what would fix it?

### Q9
Which of the six security architecture principles in §5 is most
directly violated by each of the following designs? (One principle
per design; some principles will not be the answer to any design.)

- **(a)** All training pods in the platform share a single AWS IAM
  role that has read access to the entire feature store.
- **(b)** A new "secure" deployment workflow requires engineers to
  open three separate Jira tickets and wait for two approvals
  before any change.
- **(c)** Model artifacts are signed at build time, but the
  serving cluster does not verify the signature at load.
- **(d)** A model that has been deprecated is removed from the
  registry UI, but its serving deployment continues to receive
  traffic.

### Q10
For an LLM-based assistant taking user input and returning text
responses, list **four** threats that the OWASP ML Security Top 10
covers, and **two** threats it does *not* cover that you would
still need to address.

---

## Applied (5 questions)

### Q11
You are threat-modeling a fraud-detection model that:

- Trains nightly on the past 90 days of transaction data, including
  PII fields (name, address, partial card number).
- Serves predictions via an internal gRPC API used by 12 downstream
  services.
- Has a feedback loop where flagged-but-overturned predictions are
  added to the next training run.

Produce a STRIDE+ML threat table with one threat per category, the
ML-specific extension applicable to this system, and one mitigation
each.

### Q12
The lecture notes claim "the model is the asset" represents a
mental shift from non-ML systems. For each of the three asset
classes (model, training data, decision surface), describe one
audit question you would ask a team that you would **not** ask of
a non-ML team protecting an analogous web application.

### Q13
You are reviewing a proposed architecture diagram in which all
inference traffic from external customers passes through a
gateway, then to the model service, then back. The gateway has
input validation and rate limits. Name three additional controls
the design needs to be defensible against ML01, ML04, and ML05
**simultaneously**, and explain why fewer controls than three
would leave at least one of these threats unmitigated.

### Q14
A production incident: a recommender model has started producing
outputs heavily biased toward a small set of items, harming the
business's diversity metrics. The change is real (not a
measurement error) but the team cannot identify a code change,
training-data change, or infrastructure change that explains it.
Walk through how you would investigate this as an ML security
event, including which OWASP ML items you would consider first
and which MITRE ATLAS tactics you would look for evidence of.

### Q15
Your CISO asks for a **one-page** brief justifying a new "AI
infrastructure security" hire to a finance review. Write the brief.
Constraints: the brief must (a) be readable in 90 seconds, (b)
make a defensible case in terms a CFO will accept, (c) avoid
hand-waving about "AI risk" without specifying what risk, (d)
identify at least two named threats and one realistic incident
scenario.

---

## Self-assessment rubric

For each question, score yourself as follows:

| Score | Meaning |
|---|---|
| **3** | You answered correctly, can explain your answer to a peer, and could defend it under questioning. |
| **2** | You answered correctly but had to think about it. You probably need to re-read the relevant section. |
| **1** | You answered partially or with material gaps. Re-read the relevant section and try again. |
| **0** | You don't know. Re-read the lecture notes. |

Module passing threshold: **average score ≥ 2.0 across all 15
questions**, with no question scored **0**. If you have any **0**
scores, identify which sections of the lecture notes apply and
re-read those before attempting the next module.
