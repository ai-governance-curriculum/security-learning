# Capstone Scenario — NorthBridge Health

> Read this **before** any exercise. The exercises build on this
> scenario; without internalizing it, the work won't be coherent.

---

## The company

**NorthBridge Health** is a 3-year-old digital-health company
based in Boston. They provide:

- A **clinical decision support** platform used by hospitals
  and large clinics.
- ML models for: triage scoring, hospital-acquired-infection
  risk prediction, medication-error detection, and (newly)
  ambient documentation assistance via a custom LLM.
- A small **patient-facing wellness app** that uses simpler
  consumer-grade ML (the wellness app is consumer; everything
  else is clinical).

Revenue: ~$25M ARR. ~85 employees, of which **8 are engineers
today** and growing to **25 engineers over the next 12 months**.

## The customers

| Tier | Description | Count | Compliance trigger |
|---|---|---|---|
| Enterprise hospital systems (US) | 200-500 bed hospitals; integrated EHR | 12 contracts | HIPAA |
| Mid-market clinics (US) | 20-150 bed; faster sales cycle | 38 contracts | HIPAA |
| EU healthcare (Ireland, Netherlands, Germany) | Recent expansion | 4 contracts | GDPR, EU AI Act high-risk |
| Consumer wellness app users | Direct-to-consumer | ~15k users | CCPA (CA), GDPR (EU) |

The clinical platform processes:

- Patient demographics, diagnoses, lab results, medications,
  vital signs.
- Clinician notes (free text, sometimes structured).
- Imaging metadata (not images directly; image-derived
  features).

The wellness app processes:

- User-reported symptoms.
- Wearable-derived metrics (heart rate, sleep, activity).
- User-uploaded notes.

## The ML system today

### Models in production

1. **Triage-Risk** — classification model; predicts adverse-
   event risk in ED triage. Trained on aggregated multi-
   hospital data with appropriate BAAs.
2. **HAI-Predict** — early-warning model for hospital-acquired
   infections; runs every 4 hours on inpatient EHR data.
3. **Med-Verify** — medication-error detection; runs at order
   entry.
4. **Ambient-Doc** (newly launched) — LLM-based documentation
   assistant that summarizes clinician-patient encounters.
   Uses a fine-tuned open-weight LLM (Llama 3 70B) plus a RAG
   layer over the patient's chart.
5. **Wellness-Coach** — consumer-side conversational LLM
   (uses OpenAI's API for the underlying generation).

### Architecture (current)

- AWS only (us-east-1, us-west-2 for HA).
- EKS clusters per environment (dev / staging / prod).
- MLflow for experiment + model registry.
- Feature store (Feast).
- Training data lives in a federated lake (Delta Lake on S3).
- Serving via FastAPI + Helm + KEDA.
- Ambient-Doc serving via vLLM.
- Wellness-Coach calls OpenAI API; PII is redacted by a
  pre-processor before send.
- General observability via Datadog.
- Some security tooling: AWS GuardDuty, basic CloudTrail
  alerting, Falco running in audit-only mode.
- Authentication: enterprise customers use SAML SSO; mid-market
  uses API keys.
- Authorization: per-tenant ACLs in the gateway service. (The
  ML-platform team admits this is "fragile.")

### Known gaps

- No formal SOC 2 today.
- HIPAA technical safeguards "mostly" in place; no recent
  external audit.
- No EU AI Act readiness for the clinical models (clearly
  high-risk).
- Adversarial robustness measured only informally; no
  systematic evaluation.
- No DP-SGD applied to any training run.
- No model promotion gate (deploys are done by a platform
  engineer with `kubectl`).
- Falco is audit-only; many noisy rules.
- No internal SIEM. CloudTrail + GuardDuty go to a Slack
  channel that is read inconsistently.
- No formal IR procedure.
- Cosign signing is not deployed.

## The threat landscape

NorthBridge's threats span four classes:

### 1. Regulated-data exposure
- PHI / PII leakage via model inversion or membership
  inference (especially for Triage-Risk and HAI-Predict,
  which are trained on patient records).
- PHI exposure via prompt injection in Ambient-Doc.
- Cross-tenant feature-store leakage (multi-tenant
  authorization fragility).
- Subject-rights compliance failures (GDPR Art 22 — automated
  decision making).

### 2. Clinical safety
- A poisoned model could harm patients (Med-Verify failing
  to catch dangerous medication orders).
- Skewing of Triage-Risk (e.g., systematically under-scoring
  certain patient populations) — fairness AND safety issue.
- Adversarial-input attacks on clinician workflows.

### 3. Supply-chain risk
- Llama 3 fine-tune base — vetted, but the fine-tuning data is
  proprietary.
- Python ML stack with hundreds of transitive deps.
- OpenAI as a sub-processor (Wellness-Coach) — already a
  vendor risk concern.
- Hugging Face dependencies for some embedding models.

### 4. Operational maturity
- No SOC 2 means several Enterprise customers are dissatisfied;
  their security reviews are blocking renewals.
- EU AI Act timelines mean the clinical models need
  documentation, risk management, accuracy bounds, etc.
- Incident response is ad-hoc; the team has been lucky to date.

## The people

- **CTO Sarah Chen** — engineering leader. Pragmatic. Owns
  decisions on platform direction. Knows compliance is a
  blocker; wants pragmatic plans.
- **Director of Product (clinical) Marcus Reyes** — owns the
  clinical product. Hospital-customer-facing. Less technical;
  needs translation.
- **ML Platform Lead Priya Patel** — owns the ML systems day-
  to-day. Strong technically; weak on security.
- **You** — newly hired as the first **AI infrastructure
  security engineer** at NorthBridge. Reporting to Sarah.
- **Outside Counsel firm** — handles privacy and compliance
  matters. You'll work with them on regulatory questions.
- **Board** — wants to see the company past SOC 2 + EU AI
  Act compliance + improved security posture within 18 months.

## The 12-month context

In 12 months, NorthBridge expects to:

- Have 25 engineers (3× the current team).
- Be SOC 2 Type 2 attested.
- Have an EU-resident multi-cloud setup (likely Azure for
  EU sovereignty); some customers want their data not on AWS.
- Have onboarded 2-3 large hospital systems with strict
  security requirements.
- Have launched a fine-tuned variant of Ambient-Doc for
  specialty practices (cardiology, oncology).

## Your charter (from Sarah, week 1)

> "I need you to figure out what kind of security program we
> need, how we get from where we are today to a defensible
> posture, and what it costs. I want artifacts I can share with
> the board, with our auditor, with our hospital customers'
> CISOs, and with my engineering team. Be honest about gaps.
> The audit clock is 9 months out, but the EU AI Act deadline
> is more complicated and I want your read on it."

That charter is the assignment. The six exercises produce the
artifacts you'd deliver against it.

## Out of scope for the capstone

To keep the deliverable manageable:

- You don't write deployment code.
- You don't run real adversarial-robustness benchmarks.
- You don't deploy real SIEM detections.
- You don't engage with Outside Counsel for legal questions
  (you note where engagement is needed).

What you produce: the **design + plan + documentation**.
Implementation is the engineering team's follow-up.

## Note on realism

NorthBridge Health is fictional. The scenario is calibrated to
be **realistic** — a real Series A / B digital-health company
on this growth trajectory has roughly this shape. The threats,
gaps, and timelines are commonplace.

You can substitute your own company / a real-world analog if
preferred. The exercises produce defensible artifacts either
way.
