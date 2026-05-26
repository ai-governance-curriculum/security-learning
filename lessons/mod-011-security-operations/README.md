# Module 11 — Security Operations for ML Systems

**Duration**: ~35 hours (~1.5 weeks full-time, ~3 weeks part-time)
**Prerequisites**:
- Modules 01–10 completed.
- Module 01's MITRE ATLAS material is the foundation.
- Detection signals from Modules 04, 06, 08, 10 are the inputs
  this module turns into operational detections.
- Comfort with log queries (some SIEM exposure — SPL, KQL,
  Elasticsearch DSL, or any query language).

## What this module is for

Security operations (SecOps) is what makes the rest of the
track operational. The other 10 modules produce controls and
signals; this module is how those signals become **detections**,
**alerts**, **incidents**, **investigations**, and **lessons
learned**.

You will learn:

1. **SIEM fundamentals** — what a SIEM is, what it's for, how
   to choose one.
2. **Detection-rule authoring** — Sigma rules, KQL / SPL /
   ESQL / similar.
3. **MITRE ATLAS / ATT&CK mapping** — how detections map to
   adversary tactics; how to find gaps.
4. **Triage and alert tuning** — making alerts actionable.
5. **Incident response (IR) procedures** — the lifecycle and
   the playbook structure.
6. **On-call patterns** — making 24/7 coverage sustainable.
7. **Forensics** — preserving evidence, investigating, drawing
   conclusions.
8. **Threat intelligence** — operationalizing IOCs and TTPs.
9. **Tabletops and game days** — practicing what you've never
   needed yet.
10. **Postmortems** — turning incidents into systemic
    improvements.
11. **Metrics** — MTTD, MTTR, dwell time; what they tell you
    and how they lie.
12. **ML-specific detections** — model-extraction patterns,
    prompt-injection signals, poisoning indicators.

## How to work through this module

1. Read [`lecture-notes.md`](./lecture-notes.md).
2. Complete the five exercises in [`exercises/`](./exercises/).
3. Take the [quiz](./quiz.md).
4. Use [`resources.md`](./resources.md) for primary sources.

## Module deliverables

- A **SIEM evaluation** for SmartRecs (Exercise 01).
- An **ML-specific detection ruleset** (10+ Sigma rules)
  (Exercise 02).
- An **IR procedure** keyed to ML threats (Exercise 03).
- A **tabletop scenario library** with at least 3 scenarios
  (Exercise 04).
- A **postmortem template + worked example** (Exercise 05).

## How this module connects to the rest of the track

| Where module 11 shows up later | What it provides |
|---|---|
| Module 12 Capstone | The detection + IR layer in the full security program |

## Quick reference

- **Lecture notes**: [`lecture-notes.md`](./lecture-notes.md)
- **Exercises**: [`exercises/`](./exercises/)
- **Quiz**: [`quiz.md`](./quiz.md)
- **Resources**: [`resources.md`](./resources.md)
- **Paired project**: [`projects/project-5-security-operations/`](../../projects/project-5-security-operations/)
- **Paired solution**: [`ai-infra-security-solutions/projects/project-5-security-operations/SOLUTION.md`](https://github.com/ai-infra-curriculum/ai-infra-security-solutions/blob/main/projects/project-5-security-operations/SOLUTION.md)
