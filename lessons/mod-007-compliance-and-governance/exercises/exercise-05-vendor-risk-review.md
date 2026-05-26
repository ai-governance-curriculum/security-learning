# Exercise 05 — Vendor Risk Review

**Estimated time**: 2 hours
**Deliverable**: A vendor risk review process + a worked example
(the OpenAI integration)

---

## Part 1 — The process

Design SmartRecs' **vendor risk review process**. It should:

1. **Trigger** when:
   - A new vendor is proposed.
   - An existing vendor changes their sub-processors.
   - An existing vendor has a security incident.
   - An annual review comes due.

2. **Inputs** required:
   - Vendor's most recent SOC 2 (Type 2 preferred) / ISO 27001
     certificate.
   - Vendor's DPA / BAA if regulated data flows.
   - Vendor's sub-processor list.
   - Description of data flow to the vendor.
   - Description of how the vendor's failure affects SmartRecs.

3. **Decision authority**:
   - Tier 1 (no regulated data): security engineer approval.
   - Tier 2 (some PII, but not PHI / EU-regulated): security
     engineer + legal approval.
   - Tier 3 (PHI / EU-regulated personal data): CISO + legal +
     compliance officer approval.

4. **Documentation produced**:
   - Risk assessment record.
   - Decision record.
   - Sub-processor list update (if applicable).
   - Customer notification (if your contracts require).

## Part 2 — The worked example

Apply the process to the **OpenAI integration** scenario from
Module 06: customer prompts containing PII may be sent to
GPT-4 for the customer-support LLM.

Produce:

1. **The risk assessment** — data flow, regulatory triggers,
   blast radius if vendor compromised.
2. **The decision** — approve, modify, or reject. Defend.
3. **Required contract terms** — DPA (for EU customers), BAA
   (for the healthcare customer's data, if applicable), SCCs
   (for transfer), specific data-use restrictions.
4. **Technical controls** to deploy alongside the vendor
   relationship — PII redaction before send, audit logging,
   per-tenant opt-out.
5. **Sub-processor handling** — OpenAI has its own
   sub-processors (Azure, others). How do you handle that?
6. **Ongoing monitoring** — what triggers re-review?
7. **Customer-notification plan** — how customers learn the
   data flow exists; opt-out mechanism if any.

## Format

```
# Vendor Risk Review

## Part 1: Process

### Trigger conditions

### Input requirements

### Decision authority matrix
| Tier | Data flowing | Approvers | SLA |
|---|---|---|---|

### Documentation produced

### Process diagram (RACI or flowchart)

### Annual cadence

---

## Part 2: Worked example — OpenAI

### Risk assessment

#### Data flow description
#### Regulations triggered (GDPR, HIPAA, sector-specific)
#### Blast radius if OpenAI is compromised

### Decision (approve / modify / reject)

### Required contract terms

| Document | Required | Status | Notes |
|---|---|---|---|

### Technical controls deployed alongside

| Control | Implementation | Owner |
|---|---|---|

### Sub-processor handling

### Ongoing monitoring

### Customer-notification plan
```

## Quality criteria

A passing review:

- The decision authority is **proportional to risk** — not the
  same approver for everything.
- The OpenAI risk assessment names specific risks (data
  retention by OpenAI, training-on-customer-data unless opted
  out, sub-processors, geographic data location).
- The decision is **defended**, with named conditions if it's
  "modify."
- Technical controls (PII redaction, audit) are real and
  reference earlier modules.

A failing review:

- "Approve" for everything because OpenAI has SOC 2.
- No PII redaction control.
- No sub-processor handling.
- Treats the decision as binary without naming conditions.

## Reflection questions

1. The product team wants OpenAI live in 2 weeks. What's the
   conversation about the BAA / DPA timeline?
2. OpenAI updates their sub-processor list. How does SmartRecs
   know, and what happens?
3. The healthcare customer asks: "Are you sending our PHI to
   OpenAI?" How do you answer honestly?

## Save your artifact

The process you design here is what SmartRecs will use for every
future vendor (Datadog, Snowflake, Auth0, etc.). The OpenAI
worked example is the template the team will reference.
