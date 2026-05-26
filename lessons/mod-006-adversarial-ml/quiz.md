# Module 06 Quiz — Adversarial ML

> Closed-book first.

---

## Conceptual (10 questions)

### Q1
Fill in the 2×3 attack-class matrix from §1.1. For each cell,
name the OWASP ML Top-10 item that primarily addresses it.

### Q2
Explain the difference between **white-box** and **black-box**
attackers. Give one example of a defense that is meaningful
against black-box but ineffective against white-box.

### Q3
Why does the **norm budget** (L∞ / L2 / L0) matter when stating
an adversarial-robustness claim? Give one example where
robustness in L∞ does not imply robustness in L2.

### Q4
Walk through the PGD attack mathematically — what the inner
loop does at each step, and why projection back into the ε-ball
is necessary. In 4–6 sentences.

### Q5
Adversarial training trades clean accuracy for robust accuracy.
Describe the trade-off in 3 sentences. Then state a scenario in
which the trade-off is **worth it**, and one in which it isn't.

### Q6
Compare adversarial training and randomized smoothing. For each:
- (a) What does the defense prove (if anything)?
- (b) What is the inference cost?
- (c) When is it the right choice?

### Q7
BadNets-style backdoors are invisible to standard validation.
Explain why in 3-4 sentences. What's the operational implication
for a team that's evaluating a model's quality?

### Q8
Differential privacy bounds the influence of any single record.
Explain in your own words what the parameters **ε** and **δ**
mean. Give a defensible range for each in a production ML
setting.

### Q9
Why is **indirect prompt injection** considered more dangerous
than direct prompt injection? Give an example scenario where
indirect injection causes harm and the LLM's API hasn't been
called by the attacker.

### Q10
Rank the following defenses by **leverage in a typical
production system** (highest to lowest), and justify the ranking
in 1-2 sentences each:
- Input validation and rate limiting.
- Adversarial training.
- Differential privacy in training.
- Randomized smoothing.
- Watermarking.

---

## Applied (5 questions)

### Q11
You inherit a fraud-detection model deployed via API. The model
is exposed to authenticated customers. The customer mix
includes some adversarial users (fraudsters). Walk through an
adversarial-robustness assessment:
- What attacks are realistic?
- What do you measure?
- What's a reasonable robustness target?
- What's the operational cost of getting there?

### Q12
A team proposes RLHF as the LLM's safety control: "We
fine-tuned for safety." Argue the position in 6-10 sentences
that this is insufficient as the sole safety mechanism. Name
at least three additional controls and what each catches.

### Q13
Design a poisoning-detection plan for a retraining pipeline
that:
- Ingests user feedback from the production API.
- Aggregates feedback weekly.
- Retrains the model on aggregated feedback.
- Promotes the retrained model to production.

Identify at least 4 controls to detect or limit poisoning, with
specific places in the pipeline.

### Q14
Configure a DP-SGD training run for a small image classifier on
the MNIST-equivalent of "facial-feature dataset" (sensitive).
Specify:
- Target privacy budget (ε, δ).
- Clipping bound C (heuristic).
- Noise multiplier σ (qualitatively — how does it relate to ε?).
- Training duration / epochs (and how this consumes privacy
  budget).
- Expected utility cost vs. non-private training.

### Q15
Audit the following LLM-system architecture and produce a list
of prompt-injection / jailbreak findings:

> A customer-support LLM is given a system prompt: "You are a
> helpful assistant for SmartRecs customers. Only answer
> questions about SmartRecs products. Refuse to answer questions
> about competitors or non-SmartRecs topics."
>
> The LLM has tool access to: a `lookup_customer_account(email)`
> function (returns the customer's account details), and a
> `cancel_subscription(account_id)` function.
>
> Customer messages are concatenated with the system prompt
> directly: `<system_prompt>\n\nUser: <user_message>`.
>
> There is no output filtering. The LLM's response is returned
> directly to the customer.
>
> Authentication: the user's email comes from the authenticated
> session and is automatically passed to
> `lookup_customer_account()` if the LLM decides to call it.

At least 5 findings, with severity + specific exploitation
scenarios.

---

## Self-assessment rubric

Same scale as previous modules. Passing: average ≥ 2.0, no
question scored 0.
