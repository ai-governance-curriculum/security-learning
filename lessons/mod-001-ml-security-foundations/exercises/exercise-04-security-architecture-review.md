# Exercise 04 — Security Architecture Review

**Estimated time**: 2 hours
**Deliverable**: A 2–3 page review document
**Prerequisite**: None (independent of Exercises 01–03)

---

## The setup

A peer on a sibling team — **GlobalRecs**, a separate product —
sends you the following architecture proposal for review. They are
about to start building it.

> **GlobalRecs proposal:**
>
> We are building a recommendation service for our retail clients.
>
> - **Model**: We will start from a pretrained `bert-large-uncased`
>   from Hugging Face and fine-tune on our customer's product
>   catalog.
> - **Training**: Nightly retraining job that downloads the latest
>   public version of the base model, fine-tunes for 3 epochs on
>   the previous day's events, and pushes the resulting artifact
>   to our internal S3.
> - **Serving**: 4 model-server pods load the latest artifact from
>   S3 on pod startup. No registry; the pods point at a path
>   `s3://globalrecs/models/latest/`.
> - **API**: HTTPS gateway with per-customer API keys. We chose
>   API keys over OIDC because OIDC was "more complex." Customers
>   share keys with their data team and their analytics team.
> - **Feedback**: Click events are streamed back to a shared
>   warehouse and used in tomorrow's retraining.
> - **Network**: Default-allow Kubernetes network policy. We'll
>   add restrictions "after launch."
> - **Secrets**: AWS access keys for the training job are stored
>   in a Kubernetes `Secret` resource. The pod that runs training
>   has its own ServiceAccount, but the secret is mounted as
>   environment variables.
> - **Observability**: Per-pod CPU and memory in Prometheus. No
>   per-request logging because it would be "too much volume."
> - **Compliance**: We have SOC 2.

## Your assignment

Produce a written security review of this proposal. The peer is
about to start building it, so your review needs to be **useful**
(actionable) and **calibrated** (not every finding is critical).

The review should:

1. **Identify the findings.** Each finding includes:
   - **Title** (one line).
   - **Severity**: Critical / High / Medium / Low.
   - **The threat it represents** — what could go wrong.
   - **Reference** — OWASP ML Top-10 item, MITRE ATLAS tactic, or
     a lecture-notes section.
   - **Recommended fix** — concrete, not "improve security
     posture."
   - **Effort** — small / medium / large.
2. **Order findings by severity**, then by effort within severity.
3. **Include a "what's right" section.** Calibrated reviews call
   out what was done correctly. If everything is criticism, the
   review reads as adversarial and gets dismissed.
4. **End with a recommendation.** Approve as-is? Approve with
   conditions? Block until fixes? Whichever you choose, defend it.

## Format

Suggested structure:

```
# Security Review: GlobalRecs Architecture Proposal

## Reviewer
## Scope (what was reviewed, what wasn't)

## Summary recommendation
(Approve / Approve with conditions / Block until fixes)

## What's right

## Findings

### Critical (must fix before launch)
  - Finding 1
  - Finding 2

### High (fix in first sprint after launch)
  - ...

### Medium (planned next quarter)
  - ...

### Low (note for the backlog)
  - ...

## Open questions

## Next steps
```

## Quality criteria

A passing review:

- Identifies **at least 6 distinct findings** across multiple
  severities.
- Names a concrete fix for every finding.
- Calibrates severity. Not everything is Critical; not everything
  is Low.
- Acknowledges what's right (there's usually something).
- Has a clear recommendation that a manager can act on.

A failing review:

- Marks everything Critical.
- Recommends "implement security best practices" with no
  specifics.
- Misses the SOC 2-as-shield comment (lecture notes §5.6 covers
  this directly).
- Misses the LLM-specific risks the OWASP ML Top 10 misses
  (lecture notes §2.3).

## Reflection questions

1. Which finding will the GlobalRecs team push back on hardest?
   Why? How will you respond?
2. Which finding is *least* serious despite looking serious on
   first read?
3. If you had to drop one finding to keep the review actionable,
   which would you drop, and why?

## Solution comparison

After writing your own, compare against the reference review in
[`ai-infra-security-solutions/modules/mod-001-ml-security-foundations/exercise-04/`](https://github.com/ai-infra-curriculum/ai-infra-security-solutions/tree/main/modules/mod-001-ml-security-foundations) (when published).
