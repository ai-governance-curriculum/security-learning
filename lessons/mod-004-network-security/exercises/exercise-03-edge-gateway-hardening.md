# Exercise 03 — Edge Gateway Hardening

**Estimated time**: 2 hours
**Deliverable**: A 2-page hardening plan with prioritized checklist

---

## The assignment

Produce a hardening plan for SmartRecs' customer-facing API
gateway. The gateway is the public face of the platform —
customers hit it with API keys to call the recommender, fraud,
and (soon) LLM APIs.

## Current state

- **Ingress controller**: nginx-ingress (legacy). No WAF.
- **TLS**: Let's Encrypt cert, TLS 1.2 and 1.3 enabled.
- **Auth**: API keys passed in `X-API-Key` header. The key is
  validated against a Redis-backed lookup; if it exists, the
  request proceeds with the key's tenant ID as a header
  attached to the request.
- **Rate limits**: 1k RPM per API key (free tier), 100k RPM (paid).
  Implemented in the gateway service itself with an in-memory
  counter per pod. (Issue: counters are not shared across the 3
  pods, so a tenant can get effectively 3× the documented rate.)
- **Logging**: gateway logs are sent to stdout; ingested into
  Loki. No audit chain integration.
- **Headers**: the gateway adds `X-Tenant-ID` based on the API
  key's lookup. Downstream services trust this header.

## Your assignment

Walk through the gateway's surface and produce:

1. **A list of findings.** Each with:
   - Title.
   - Severity (Critical / High / Medium / Low).
   - The threat.
   - Recommended fix.
   - Effort estimate.
2. A **prioritized action plan** (sequenced).
3. A **trust-boundary review** — the gateway sits between the
   internet and the cluster; what trust does it grant
   downstream, and is that trust appropriate?
4. A **checklist** that the team can audit themselves against
   next quarter.

## Specific topics to address

The lecture notes (§5) cover the gateway security checklist.
Apply it. In particular:

- The `X-Tenant-ID` header pattern is fragile. What's the
  problem, and what fixes it?
- Rate limits with in-memory counters are wrong at scale. How
  is this exploited and what's the fix?
- The gateway has no audit-chain integration. What audit events
  should it produce, and how should they be signed?
- TLS 1.2 is enabled. Should it be? Defend or refute.

## Format

```
# Gateway Hardening: SmartRecs

## Reviewer + date

## Trust-boundary review
(What the gateway is trusted for by downstream services.
What it should be trusted for, and any delta.)

## Findings

### Critical
- Finding 1
- Finding 2
- ...

### High
- ...

### Medium
- ...

## Prioritized action plan

| Order | Action | Effort | Risk if delayed |
|---|---|---|---|

## Self-audit checklist
(For the team to review themselves quarterly.)

## What this hardening plan does NOT cover
(WAF tuning specifics, customer-facing TLS cert UX, etc.)
```

## Quality criteria

A passing plan:

- Identifies at least **6 distinct findings** with calibrated
  severity.
- Addresses the `X-Tenant-ID` trust issue specifically.
- Addresses the in-memory rate-limit counter issue specifically.
- Names audit-chain integration as a gap.
- Has a self-audit checklist that's actually actionable.

A failing plan:

- Marks everything Critical.
- Recommends "implement security best practices" without
  specifics.
- Misses the multi-pod rate-limit bug.
- Misses the trust-the-header bug.

## Reflection questions

1. Which finding will the platform team push back on most? How
   do you respond?
2. The CTO asks: "Why do we need to fix the rate-limit
   counter? It's worked fine for two years." What's the
   business-language answer?
3. If you had to ship **one** of these findings this week and
   defer the rest, which one is it? Why?
