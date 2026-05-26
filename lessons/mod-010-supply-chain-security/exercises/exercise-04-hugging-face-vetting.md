# Exercise 04 — Hugging Face Model Vetting

**Estimated time**: 2 hours
**Deliverable**: A vetting process + a worked example

---

## The assignment

Design SmartRecs' Hugging Face model vetting process. Then
apply it to a worked example.

## Part 1 — The process

A vetting process for any Hugging Face model proposed for
production use. The process must:

1. **Triage by tier**:
   - **Tier 0**: Official org accounts (Meta, Mistral, Google,
     Anthropic, etc.) — fast-track.
   - **Tier 1**: Well-known community maintainers — moderate
     vetting.
   - **Tier 2**: Unknown / individual accounts — heavy vetting
     or rejection.

2. **Per-tier checks**:
   - File-format verification (`safetensors` preferred; older
     formats require additional scrutiny).
   - Pinned revision (commit hash, not `main`).
   - License check.
   - Model card review (training data, intended use, known
     limitations).
   - Static / scanner pass (where applicable).
   - Behavioral testing (does the model produce expected
     outputs on a small evaluation set).

3. **Documentation produced**:
   - The vetting record (signed, in the audit chain).
   - The approved revision pinning.
   - The technical controls deployed alongside.

4. **Re-vetting**:
   - When a model's revision changes.
   - On a scheduled cadence (quarterly).
   - On a vendor security incident.

## Part 2 — Worked example

Apply the process to one of:

- A popular open-weight LLM from an official org account (e.g.,
  `mistralai/Mistral-7B-v0.1`).
- A community-fine-tuned embedding model.
- A model from an unknown account with intriguing benchmarks.

For each: walk through the tier classification, the per-tier
checks, the decision, and the technical controls.

## Format

```
# Hugging Face Model Vetting: SmartRecs

## Part 1: Process

### Tier classification

| Tier | Definition | Vetting depth | Approval authority |
|---|---|---|---|

### Per-tier checks

#### Tier 0 (Official orgs)
- Check 1
- Check 2
- ...

#### Tier 1 (Known community)
- ...

#### Tier 2 (Unknown)
- ...

### Documentation produced
- Vetting record schema
- Audit-chain entry
- Approved revision pinning location

### Re-vetting triggers + cadence

### Decision authority matrix

## Part 2: Worked examples

### Example 1: <model name + URL>
- Classification tier: ...
- Checks performed: ...
- Findings: ...
- Decision: ...
- Technical controls deployed: ...
- Re-vetting cadence: ...

### Example 2: <model name + URL>
...

## Common rejection reasons

## Common conditions for "approve with modifications"

## What this process does NOT cover
- Vendor risk for models *behind* an API (OpenAI / Anthropic
  — that's Module 07 vendor risk).
- Internal model promotion (Module 09's model promotion gate).
```

## Quality criteria

A passing process:

- **Tiers are realistic** and based on observable signals.
- **Per-tier checks** are specific (commands or steps).
- **Worked examples** show the process in action.
- **Technical controls** are named (sandboxing, network
  isolation, behavioral testing).

A failing process:

- "Review by hand" with no specifics.
- All tiers get the same checks.
- No worked examples.

## Reflection questions

1. A Tier-2 model has impressive benchmark numbers but no
   reputable account. What's the conversation with the team
   that wants to use it?
2. Hugging Face publishes a security advisory about a specific
   model your team is using. What's the response?
3. The team builds a fine-tuned model based on a Hugging Face
   base. How does the vetting process apply to the resulting
   fine-tune?
