# mod-111-security-operations-and-incident-response-for-ml: Security Operations and Incident Response for ML — Detection Engineering, IR Playbooks, SOC Interface

> Scaffolded by `aicg org execute-plan`. Lecture chapters and exercise content are authored on subsequent autonomous cycles.

**Estimated effort:** 16 hours

## Learning objectives

- Author ATLAS-mapped detection content for a SIEM (ELK / Splunk / Sentinel) — coverage for model-download anomalies, out-of-band agent tool calls, unusual training-data access, membership-inference attack patterns
- Author Falco / eBPF runtime detection rules for ML-workload-specific behaviours
- Author AI-specific incident-response playbooks with concrete step-by-step actions — data-poisoning discovery, prompt-injection exploitation in production, model theft indicators, agent misuse
- Design an AI-incident severity ladder that maps into the enterprise SOC's existing severity model
- Define the interface between this role and the enterprise SOC / DFIR / Legal — who owns the alert, who owns the response, who owns the notification
- Cover requirement themes req-10 and req-11

## Structure

- `01-…md` … `0N-…md`: lecture chapters.
- `exercises/`: per-exercise prompts.
- `labs/`: long-form hands-on labs.
- `quizzes/`: knowledge checks.
- `resources.md`: external references.
