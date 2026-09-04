# mod-107-llm-agent-security: LLM and Agent Security Engineering — OWASP LLM Top 10, Prompt Injection, Tool ACLs, Agent Red-Teaming

**Estimated effort:** 16 hours

LLM-integrated applications inherit every classical adversarial-
ML risk from mod-106 and add a new attack surface on top of it:
the prompt is now the interface, tools are the model's hands,
and the outputs of one call flow into the inputs of the next. A
single "adversarial input" row on a threat model cannot express
that. LLM applications need their own vocabulary, their own
mitigations, and their own incident-response ladder.

This module installs those. It is written against the **OWASP
Top 10 for LLM Applications v2025**, cross-referenced to **NIST
AI 100-2** (generative-AI section) and **MITRE ATLAS**. It carries
a running requirement to make every control a *platform*
primitive — a runtime enforcement, a tool-registry entry, a
detector wired into an evaluation harness — so the defence
survives real production workload volume, real user pressure,
and a real on-call rota.

Covers requirement theme **req-07**.

---

## Learning objectives

- Working command of the OWASP LLM Top 10 v2025 categories,
  with a concrete production-scale mitigation for each.
- Recognise and mitigate indirect prompt injection via
  retrieved content and tool responses (RAG, browser tool,
  email tool).
- Design agent-tool ACLs and human-in-the-loop enforcement
  patterns that bound Excessive Agency (LLM06) without
  gutting usability.
- Author a red-team engagement plan against a production
  agent, using UK AISI Inspect or an equivalent harness for
  reproducible runs.
- Design an incident-severity ladder specific to LLM/agent
  misuse events — data exfil via tool call, prompt-injection
  exploitation, jailbreak in a customer-facing app, runaway-
  consumption cost incidents.

---

## Lecture chapters

1. [Chapter 01 — The OWASP LLM Top 10 v2025 Landscape](./01-owasp-llm-top-10-landscape.md).
   Installs the working vocabulary: ten categories, each with
   attacker goal, canonical example, NIST/ATLAS cross-map, and
   one production-scale mitigation. Names which categories
   this module owns and which belong to sibling modules.
2. [Chapter 02 — Indirect Prompt Injection](./02-indirect-prompt-injection.md).
   Why the model cannot separate instructions from data at
   the token level; the RAG / browser / mail surfaces;
   trust-boundary separation with content provenance labels;
   input- and output-side detectors; corpus-based evaluation.
3. [Chapter 03 — Agent Tool ACLs and Human-in-the-Loop](./03-agent-tool-acls-and-hitl.md).
   Blast-radius tiering (T0–T3); the tool-registry data
   structure; identity scope (`caller_only`, `workload`,
   `delegated`); HITL patterns that avoid rubber-stamping;
   composition with chapter 02's provenance labels.
4. [Chapter 04 — Agent Red-Teaming with UK AISI Inspect](./04-red-teaming-with-inspect.md).
   The engagement plan (scope, threat model, rules of
   engagement, corpus, metrics, reporting, regression gate);
   agent-level scorers beyond "did the model say something
   bad"; simulated HITL under conservative and permissive
   approvers; wiring the harness into CI.
5. [Chapter 05 — LLM/Agent Incident Severity Ladder](./05-llm-incident-severity-ladder.md).
   Five tiers with objective triggers, routing, and disclosure
   surfaces; trajectory-preservation as the evidence artefact;
   reach counters; disclosure clocks (GDPR, HIPAA, PCI DSS,
   EU AI Act); cost (LLM10) as its own severity axis.

---

## Exercises

Every exercise anchors on a specific chapter. Complete them in
order; each depends on the artefacts of the previous.

1. [Exercise 01 — OWASP LLM Top 10 to production mitigation map](./exercises/exercise-01-owasp-llm-top-10-to-production-mitigation-map.md).
   Fill in chapter 01's mitigation map for one production
   LLM/agent product: category, in-scope decision, attack
   scenario, primary control, owner, evidence artefact.
2. [Exercise 02 — Indirect prompt injection for one RAG app](./exercises/exercise-02-indirect-prompt-injection-for-one-rag-app.md).
   Ship a starter injection corpus and a runnable harness for
   one RAG application; measure `execution_rate` before and
   after enabling chapter-02 defences.
3. [Exercise 03 — Agent tool ACL and HITL design](./exercises/exercise-03-agent-tool-acl-and-hitl-design.md).
   Tier every tool in the product's agent, design ACLs and
   HITL policies per tier, wire chapter-02 provenance into
   the tool gate, and produce the tool-registry artefact.
4. [Exercise 04 — Agent red-team plan with Inspect](./exercises/exercise-04-agent-red-team-plan-with-inspect.md).
   Author a full engagement plan and a runnable Inspect (or
   equivalent) harness against the product's agent; produce
   the scorecard and wire a regression gate into CI.
5. [Exercise 05 — LLM incident severity ladder](./exercises/exercise-05-llm-incident-severity-ladder.md).
   Adapt this chapter's five-tier ladder to the org's
   existing incident-management surface: triggers, routing,
   evidence, disclosure clocks; produce the on-call runbook
   fragment for two seeded scenarios.

---

## Directory layout

- `01-…md` … `05-…md` — lecture chapters (this module).
- `exercises/` — per-exercise prompts. Solutions live in the
  paired solutions repo.
- `labs/` — long-form hands-on labs (scaffolded).
- `quizzes/` — knowledge checks (scaffolded).
- `resources.md` — curated primary-source reading list;
  standards, papers, tools, and cross-references.

---

## Cross-references within this curriculum

- [mod-102](../mod-102-threat-modelling-for-ai-ml-systems/) —
  the threat-model scaffolding chapter 01's mitigation map
  plugs into.
- [mod-103](../mod-103-secure-ml-platform-architecture/) —
  workload identity (SPIFFE/OIDC), tenancy, and the admission-
  gate primitives chapters 03 and 05 depend on.
- [mod-104](../mod-104-data-and-model-lineage-security/) —
  signed lineage for retrieval-store content (chapter 02),
  fine-tuning data (chapter 01 LLM04), and evidence surface
  for incidents (chapter 05).
- [mod-105](../mod-105-secrets-and-key-management/) —
  per-caller dynamic credentials for the tool layer
  (chapter 03) and the identity-revocation primitive used
  in the SEV-1/2 runbook (chapter 05).
- [mod-106](../mod-106-adversarial-ml-defense/) — the
  classical adversarial-ML taxonomy (evasion, poisoning,
  extraction, inference, backdoor) this module inherits;
  chapter 01 LLM04 defers to mod-106 chapter 04 for the
  detection pipeline.
- [mod-108](../mod-108-privacy-engineering-for-ml/) — the
  data-minimisation pipeline chapter 01 LLM02 references;
  the DSAR/erasure surface a SEV-1 privacy incident
  activates.
- [mod-109](../mod-109-ai-governance-and-compliance-engineering/) —
  the governance-evidence surface every chapter's artefacts
  land in; incident records from chapter 05 feed the
  regulator-reporting story.
- [mod-110](../mod-110-supply-chain-security-for-ai/) —
  signed base models, adapters, embedding models, and
  tokenizers; chapter 01 LLM03 defers here for the
  admission gate.
- [mod-111](../mod-111-security-operations-and-incident-response-for-ml/) —
  the incident-management platform this module's SEV
  ladder (chapter 05) is the LLM-specific content for.
