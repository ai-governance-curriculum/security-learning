# mod-107-llm-agent-security: LLM and Agent Security Engineering — OWASP LLM Top 10, Prompt Injection, Tool ACLs, Agent Red-Teaming

> Scaffolded by `aicg org execute-plan`. Lecture chapters and exercise content are authored on subsequent autonomous cycles.

**Estimated effort:** 16 hours

## Learning objectives

- Working command of the OWASP LLM Top 10 v2025 categories, with a concrete production-scale mitigation for each
- Recognise and mitigate indirect prompt injection via retrieved content and tool responses (RAG, browser tool, email tool)
- Design agent-tool ACLs and human-in-the-loop enforcement patterns that bound Excessive Agency (LLM06) without gutting usability
- Author a red-team engagement plan against a production agent, using UK AISI Inspect or an equivalent harness for reproducible runs
- Design an incident-severity ladder specific to LLM/agent misuse events (data exfil via tool call, prompt injection exploitation, jailbreak in a customer-facing app)
- Cover requirement theme req-07

## Structure

- `01-…md` … `0N-…md`: lecture chapters.
- `exercises/`: per-exercise prompts.
- `labs/`: long-form hands-on labs.
- `quizzes/`: knowledge checks.
- `resources.md`: external references.
