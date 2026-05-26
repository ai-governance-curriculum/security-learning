# Exercise 04 — Rate-Limit and DDoS Design

**Estimated time**: 2 hours
**Deliverable**: A 2-page design document

---

## The scenario

SmartRecs is launching an **LLM API**. It accepts text prompts up
to 32k tokens and streams back responses up to 8k tokens. Backend
is vLLM on H100s. Per-token GPU cost is meaningful — the cheapest
prompt costs <$0.001; the most expensive prompt costs ~$0.50 of
GPU time.

Customer tiers:
- **Free**: 60 requests / hour, 4k token max prompt + response
  combined.
- **Pro**: 1k requests / hour, 16k token max combined.
- **Enterprise**: negotiated; some customers send 100k req / hour
  bursts.

The product manager wants the API live in 3 weeks. The CTO wants
a defensible protection strategy.

## The assignment

Design a multi-layer rate-limit and DDoS protection plan that
prevents:

1. **Traditional DDoS** (volumetric flood from one or many IPs).
2. **Inference-cost amplification** (a single customer sending
   maximum-token requests).
3. **Concurrent-request flooding** (a customer who's "within
   the RPS limit" but holds 100 in-flight 30-second requests).
4. **Cross-tenant impact** (one customer's traffic degrading
   another's latency).

For each layer (lecture notes §7.3), name:
- The mechanism.
- What it catches.
- What it doesn't catch.
- The fallback when this layer is bypassed.

## Required deliverables

1. **A layered diagram** — what protection sits where, in what
   order.
2. **Per-tier policies** — specific numbers (RPS, concurrency,
   token-budget per hour) per tier.
3. **A cost-budget enforcement design** — how do you cap a
   tenant's spend per hour, not just their request count?
4. **An emergency-control plan** — if a customer goes runaway
   in production at 3 AM, what's the on-call's playbook?
5. **A trust-boundary review** — at which layer is a tenant's
   identity established? At which layers is it consumed?

## Format

```
# LLM API Rate-Limit and DDoS Design: SmartRecs

## Diagram
(ASCII art or Mermaid showing layered protection.)

## Per-tier policies

| Tier | RPS | Concurrency | Tokens/hour | Cost ceiling |
|---|---|---|---|---|

## Layer 1: Cloud LB
- Mechanism
- What it catches
- What it doesn't catch
- Fallback

## Layer 2: Edge gateway
...

## Layer 3: Service mesh / app
...

## Layer 4: Background cost enforcement
...

## Cost-budget enforcement design

## Emergency-control playbook
(For 3 AM on-call: a single customer is consuming all GPU.)

## Trust-boundary review

## Open questions for product / finance
(E.g., what is the cost-per-hour cap that, if exceeded, we
shut down a free-tier tenant? Product decision, not security.)
```

## Quality criteria

A passing design:

- **Four distinct layers**, each with a specific role.
- **Cost-budget enforcement** is named and architected, not
  hand-waved.
- **Concurrency limits** are present in addition to RPS.
- **Emergency playbook** has concrete commands, not "page the
  CTO."
- **Trust-boundary review** shows where the tenant identity
  becomes trusted and what the boundary is signed by.

A failing design:

- Single layer (LB rate limits only).
- No concurrency limit.
- "Just charge them more if they go over." (Not a protection;
  finance recovery doesn't prevent the GPU exhaustion.)
- No emergency playbook.

## Reflection questions

1. Which layer fails most often in real deployments? Why?
2. The CTO asks: "Can we just cap input length at 4k tokens for
   everyone?" Argue against. What's the business cost of that
   simple solution?
3. The Enterprise customer is paying $200k/month. They demand
   no rate limits. What's the response?

## Save your artifact

Reusable in Module 09 (Policy as Code) and Module 11 (Security
Operations).
