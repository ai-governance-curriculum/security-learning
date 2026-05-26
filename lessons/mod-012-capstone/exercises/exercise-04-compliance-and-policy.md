# Capstone Exercise 04 — Compliance and Policy Program

**Estimated time**: 5 hours
**Deliverable**: A 10-15 page program document

---

## The assignment

Produce NorthBridge's compliance + policy-as-code program.
This synthesizes Modules 07 and 09 against the specific
scenario.

## Required sections

### Section A: SOC 2 Type 2 readiness (9-month timeline)

Apply Module 07 Exercise 03's pattern at scale:

- **Audit scope**: Security + Confidentiality (recommended);
  defend if you'd add Privacy or Processing Integrity.
- **Trust Services Criteria gap analysis**: control-by-control
  state.
- **90-day, 180-day, 270-day plan**: deliverables per quarter.
- **Evidence streams**: per control, what evidence + where it's
  stored + retention.
- **Auditor-facing artifacts**: SoA, System Description, MA
  drafts.
- **Risks**: which controls might not be in place at audit
  time, and the mitigation.

### Section B: HIPAA technical safeguards

Map each Security Rule technical safeguard to a control at
NorthBridge:

| Safeguard | Implementation | Status | Gap |
|---|---|---|---|
| Access control | Workload identity + RBAC + MFA | ... | ... |
| Audit controls | Hash-chain audit log + Datadog | ... | ... |
| Integrity | Signing + integrity monitoring | ... | ... |
| Person / entity authentication | OIDC + MFA | ... | ... |
| Transmission security | mTLS + TLS 1.3 | ... | ... |

Address:

- BAA inventory (AWS, Datadog, OpenAI, Hugging Face, etc.).
- De-identification process for any data shared externally.
- Breach response timeline (60-day HHS notification).

### Section C: EU AI Act high-risk readiness

For Triage-Risk, HAI-Predict, Med-Verify, and Ambient-Doc:

**Classification analysis**: which Article 6 + Annex III tier
each falls under. (Hint: clinical decision support typically
falls under Annex III medical devices or critical infrastructure.)

For each high-risk model, address:

- **Article 9 — Risk management system**: how you implement.
- **Article 10 — Data governance**: training data quality,
  representativeness, bias mitigation. NorthBridge's federated
  lake should comply.
- **Article 13 — Transparency / information to deployers**:
  documentation for the hospital customers.
- **Article 14 — Human oversight**: clinician-in-the-loop
  design.
- **Article 15 — Accuracy, robustness, cybersecurity**: maps
  to the Module 06 work (adversarial robustness, DP-SGD).
- **Article 17 — Quality management system**: organizational.
- **Article 18 — Documentation retention**.
- **Annex IV — Technical documentation**: produce an outline.

Timeline: when each article's obligations kick in.

### Section D: Audit-chain integration

The hash-chain audit log is the substrate. For each compliance
need, what gets recorded:

- Subject requests (GDPR Art 15-22).
- Model promotions (SOC 2 change management).
- Vendor sub-processor additions (GDPR Art 28).
- Access reviews (SOC 2).
- Policy violations (SOC 2).
- Breach incidents (HIPAA / GDPR).
- Risk-assessment outcomes.

Each entry: signing identity, schema, retention.

### Section E: Policy-as-code program

Apply Module 09 to NorthBridge:

- **Engine choice**: Gatekeeper or Kyverno. Defend.
- **Policy library**: at least 10 policies tailored to
  NorthBridge:
  - Image signing.
  - No latest tags.
  - PHI-bearing pods isolation.
  - Tenant-aware feature access.
  - Model promotion gate (cross-ref Exercise 03).
  - Training-data classification check.
  - DP-SGD requirement for PHI training.
  - Vendor-allowlist enforcement.
  - Notebook-namespace restrictions.
  - Cosign signature verification at admission.

- **Distribution + signing**: how policies travel from Git to
  enforcement.
- **Testing pipeline**: how policies are validated.
- **Rollback**: how to revert a bad policy without an outage.

### Section F: Customer-facing compliance posture

A short "security at NorthBridge" overview that a hospital
customer's CISO would read. Honest about maturity; specific
about controls. (Stub of Exercise 06's customer-CISO doc — full
version is in Exercise 06.)

## Quality criteria

A passing exercise:

- SOC 2 plan is **sequenced realistically** for 9 months with
  an 8-engineer team.
- HIPAA mapping is **per-safeguard**, not generic.
- EU AI Act addresses **the specific articles**, not just
  "we'll comply."
- Policy library has **at least 10 real policies** (Rego or
  Kyverno).
- Audit-chain integration is **specific** about what gets
  recorded.

A failing exercise:

- Generic SOC 2 checklist.
- HIPAA "covered."
- EU AI Act handwaved.
- Policy library is 2-3 boilerplate examples.

## Reflection questions

1. The 9-month SOC 2 timeline is tight. What gets cut from
   scope?
2. The EU AI Act obligations are larger than SOC 2. How do
   you sequence them given the SOC 2 audit clock?
3. The hospital customer's CISO asks "are you compliant?" —
   what's the precise, honest answer for each regulation?

## Time budget

- SOC 2 readiness: 90 min.
- HIPAA: 60 min.
- EU AI Act: 90 min.
- Audit-chain integration: 30 min.
- Policy-as-code program: 60 min.
- Customer-facing posture: 30 min.
