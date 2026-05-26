# Exercise 05 — Postmortem Template + Worked Example

**Estimated time**: 2 hours
**Deliverable**: A reusable postmortem template + a fully filled-in example

---

## Part 1 — The template

Produce SmartRecs' standard postmortem template. It must:

- Follow the structure from §10.2.
- Be **blameless** by design (no fields invite blame).
- Encode the regulatory clocks (GDPR, HIPAA) so they're
  tracked.
- Include sections for action-item ownership and follow-up.

### Required sections

1. **Header**: Title, severity, dates (start/contain/resolve),
   author, IC.
2. **Summary**: 3-5 sentences readable in 30 seconds.
3. **Impact**: customer impact (count, type), data impact,
   business impact.
4. **Timeline**: chronological events with timestamps and
   attribution to systems or roles (not to individuals).
5. **Root cause analysis**: 5-Whys or equivalent.
6. **What went well**: at least 3 items.
7. **What went poorly**: at least 3 items.
8. **Action items**: at minimum 5, each with owner (team, not
   person), due date, success criterion.
9. **Lessons learned**: generalize beyond this incident.
10. **Regulatory tracking**: which clocks started, when, who
    owns the notification, due dates.
11. **References**: links to evidence (Slack threads, audit
    chain entries, runbooks consulted).

## Part 2 — The worked example

Fill in the template for the following incident:

> **Incident**: Customer-data exfiltration via ML pipeline.
> A serving pod exfiltrated customer feature data over the
> course of 36 hours.
>
> **Detection**: Hubble flow log anomaly detector caught
> sustained outbound to an unrecognized destination starting at
> 14:00 UTC. On-call investigated, confirmed exfiltration, and
> contained at 18:30 UTC.
>
> **Root cause**: A vulnerability in a Python dependency
> allowed RCE in the serving pod. The vulnerability had been
> disclosed 11 days earlier but the team's vulnerability-scan
> workflow had a misconfiguration that prevented the dependency
> from being flagged.
>
> **Affected customers**: 3 customers' feature data exposed.
>
> **Detection time**: 36 hours after compromise (initial
> detection point at the 36-hour mark; full investigation
> completed 6 hours after that).
>
> **Contained**: 38.5 hours after compromise (5.5 hours after
> first detection signal).

Fill in:

- Summary.
- Impact.
- Timeline (fabricate plausible details consistent with the
  above).
- Root cause (5-Whys leading to the deeper "why").
- What went well + what went poorly.
- At least 5 action items with owners and due dates.
- Lessons learned.
- Regulatory tracking (GDPR 72h clock — when does it start?
  Who notifies?).
- References (link placeholders).

## Format

```
# Postmortem Template

(Template that other teams will use. Empty / placeholder
sections.)

---

# Postmortem: Customer-Data Exfiltration via Serving Pod (2026-XX-XX)

(Filled-in worked example using the template.)
```

## Quality criteria

A passing template + example:

- The template is **reusable** — other engineers can fill it
  in.
- The template is **blameless** — no field that invites
  individual blame.
- The example is **realistic** — details are consistent and
  plausible.
- Action items are **systemic**, **owned**, and **time-bounded**.
- Regulatory clocks are tracked with start conditions named.

A failing template:

- Loose, generic fields.
- Action items like "be more careful."
- No regulatory tracking.
- Example that reads as fiction (inconsistent timeline,
  unrealistic detail).

## Reflection questions

1. Which action item from the example would have the **highest
   leverage** in preventing recurrence?
2. Which one is most likely to be **closed superficially** to
   tick a box?
3. The example identifies a root cause (vuln-scan workflow
   misconfiguration). The deeper "why" might be: "no one
   reviews vuln-scan workflow changes." How does this affect
   the action items?

## Save your artifact

The template becomes part of the IR procedure (Exercise 03).
The worked example serves as training material for future
on-calls.
