# Exercise 04 — Tabletop Scenario Library

**Estimated time**: 2 hours
**Deliverable**: 3+ tabletop scenarios + a facilitator guide

---

## The assignment

Build SmartRecs' tabletop scenario library — runnable exercises
that test the IR procedure.

## Required scenarios (minimum 3)

Each scenario covers a different incident class:

### Scenario A: Suspected model extraction over 2 weeks

A customer's query patterns have been gradually intensifying.
The team noticed in the weekly review. The customer is on the
Pro tier; their queries are technically within rate limits.
Their account was created 18 days ago.

### Scenario B: Compromised CI signing identity

A GitHub Security Advisory shows that the OIDC trust binding
configured by SmartRecs allows fork-PRs to assume the build
role. A researcher found this and reports it to security@
inbox. There's no evidence of exploitation, but the window of
exposure was 6 weeks.

### Scenario C: Customer-impacting LLM prompt-injection harm

A customer reports that the customer-support LLM ran
`cancel_subscription` on their account when they asked it to
"summarize this email"—the email contained injected
instructions. Their subscription is now cancelled.

(Pick or write 1-2 more if you want a fuller library.)

## For each scenario

Provide:

1. **Setup** — what alert fires (or doesn't), what evidence
   is on the table at T=0.
2. **Inject events** — additional evidence appearing at +10,
   +30, +60 minutes (and beyond if needed).
3. **Decision points** — choices the team faces, with
   alternatives.
4. **Expected outcomes** — what a correctly-run exercise
   accomplishes.
5. **Common mistakes** — failure patterns to watch for.
6. **Grading rubric** — how to evaluate the team's response.

### Facilitator guide

Cover:

- **Pre-exercise prep**: read the IR procedure, identify
  scenario, prepare inject events, gather participants.
- **During exercise**: pace the injects, take notes on
  decisions, watch for common mistakes, time-bound to 60-90
  min.
- **Post-exercise debrief**: 30 minutes of structured feedback,
  document gaps in the IR procedure, assign follow-up actions.

## Format

```
# SmartRecs Tabletop Scenario Library

## Library index

| ID | Scenario | Tactic class | Duration |
|---|---|---|---|

## Facilitator guide

### Pre-exercise prep
### During exercise
### Post-exercise debrief
### Documentation of gaps and follow-ups

---

## Scenario A: Suspected model extraction over 2 weeks

### Setup (T=0)
### Inject events
- T+10: ...
- T+30: ...
- T+60: ...

### Decision points
1. Decision: how confident is the signal? Acceptable
   responses: ...
2. Decision: containment timing (tighten rate limits now or
   investigate first?). Acceptable: ...
3. ...

### Expected outcomes
- Team identifies this could be extraction.
- Team contacts the customer's account contact.
- ...

### Common mistakes
- Immediate ban → customer relationship damage on a false
  alarm.
- Delayed action → letting the attack progress.
- Skipping audit-chain preservation.

### Grading rubric
| Aspect | Strong | Adequate | Weak |
|---|---|---|---|

## Scenario B: Compromised CI signing identity
...

## Scenario C: Customer-impacting LLM prompt-injection harm
...

## Quarterly rotation plan

(Which scenario you run when. New scenarios you'll need to
develop.)
```

## Quality criteria

A passing library:

- 3+ scenarios covering different incident classes.
- Each scenario has **specific evidence and time-bounded
  injects**.
- Each scenario lists **realistic common mistakes**.
- The facilitator guide is usable by someone who hasn't run
  one before.

A failing library:

- 1 scenario or generic exercises.
- No injects — just an initial briefing.
- "Discuss what you'd do" without decision points.
- No grading rubric.

## Reflection questions

1. Which scenario will reveal the **biggest gap** in
   SmartRecs' current readiness?
2. Which decision point is most likely to produce the wrong
   call under pressure?
3. The team has run a tabletop. What's the most important
   follow-up artifact? When does it become outdated?
