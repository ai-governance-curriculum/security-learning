# Exercise 05 — Encryption-in-Use Decision Document

**Estimated time**: 2 hours
**Deliverable**: A 2–3 page decision document

---

## The scenario

A new SmartRecs customer is a **healthcare network**. They want
to onboard with a tightened threat model: the cloud provider's
privileged operators (AWS support, system engineers) must **not**
be able to access patient-derived features at rest *or in
process memory* during inference.

The customer expects an answer in 2 weeks: "yes we can do this,
here's how, here's what it costs, here's the timeline" — or "no
we cannot do this; here's why; here are alternatives."

## The assignment

Write the decision document that goes to your CTO, the customer's
CISO, and the project sponsor. It must:

1. **State the customer's requirement** in your own words.
2. **Identify the threats** the requirement is addressing.
3. **Evaluate three options**:
   - (a) **Application-layer encryption with customer-managed keys**,
     decrypted only inside the model service.
   - (b) **Confidential VMs** (AMD SEV-SNP or AWS Nitro Enclaves).
   - (c) **Homomorphic encryption** for inference.
4. **For each option**, address:
   - What the option actually defends against.
   - What it leaves undefended.
   - Latency and cost impact (be quantitative when possible).
   - Engineering effort to deploy.
   - Operational complexity.
   - Whether it meets the customer's stated requirement.
5. **Recommend** an option — or recommend rejecting all three with
   a documented alternative.
6. **List the open questions** for the customer (what do you
   *not* know that would change the recommendation).

## Constraints to honor

- SmartRecs' current architecture uses standard EKS (non-
  confidential). Migrating to confidential infrastructure has
  blast radius beyond this one customer.
- The healthcare customer is paying a price premium; expensive
  options aren't automatically off the table.
- The latency budget for inference is **150ms p95** for the
  recommender; the customer accepts up to **500ms p95** for
  their use case.

## Format

```
# Decision: Healthcare customer encryption-in-use requirement

## Audience
(CTO, customer CISO, project sponsor)

## Date / Author

## TL;DR (3-4 sentences)

## The customer's requirement (your interpretation)

## Threat model behind the requirement

## Options evaluated

### Option A: Application-layer encryption + customer-managed keys
- What it defends against
- What it leaves undefended
- Latency / cost
- Engineering effort
- Operational complexity
- Meets requirement?

### Option B: Confidential VMs (AMD SEV-SNP / Nitro Enclaves)
...

### Option C: Homomorphic encryption
...

## Recommendation

(Which option, and why. If "none", justify and propose an
alternative.)

## Open questions for the customer

## Risks of the recommendation

## Sequencing if the recommendation is approved

## Sequencing if the customer rejects the recommendation
```

## Quality criteria

A passing document:

- Threats are named **specifically**, not "privileged operator
  threats" hand-waved.
- Each option is evaluated against **the same criteria** (apples
  to apples).
- Latency / cost numbers are **defensible**, even if rough. "10×
  latency" is OK; "an unspecified amount slower" is not.
- The recommendation is *defensible under questioning*. The
  document anticipates the obvious follow-up.
- Names **what you don't know**. A decision document that claims
  certainty everywhere is overclaiming.

A failing document:

- Treats all three options as equally serious without
  quantifying.
- Recommends HE because it sounds the most sophisticated.
- Hides operational complexity ("we'll figure it out").
- Doesn't address "what if the customer rejects the
  recommendation" — that's a real outcome.

## Reflection questions

1. What is the customer's *real* concern behind the stated
   requirement? (Sometimes "encrypted in use" is a proxy for
   "we don't trust your cloud provider" — and the right answer
   is to address that trust gap, not the literal requirement.)
2. Which option, if you got it wrong, would be hardest to
   reverse?
3. What signal in the customer's procurement process would tell
   you they would accept Option A even though it doesn't
   literally satisfy "no plaintext in memory"?

## Save your artifact

A decision document like this is the highest-leverage artifact a
security engineer produces in any given quarter. The exercise of
*writing it* is the point.

## Solution comparison

After writing your own, compare against the reference document
in [`ai-infra-security-solutions/modules/mod-003-cryptography-for-ml/exercise-05/`](https://github.com/ai-infra-curriculum/ai-infra-security-solutions/tree/main/modules/mod-003-cryptography-for-ml) (when published).
