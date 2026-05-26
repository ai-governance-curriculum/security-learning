# Exercise 04 — ML-Specific Policy Catalog

**Estimated time**: 2–3 hours
**Deliverable**: At least 3 ML-specific policies + tests

---

## The assignment

Author the ML-specific policy catalog for SmartRecs. These
are policies that exist *because* the platform runs ML — they
don't apply to generic infrastructure.

## Required policies (minimum 3)

### 1. Model promotion gate

Enforces that a model artifact can be promoted to production
only if:

- The model artifact has a valid Cosign signature.
- The signing identity is the expected CI workflow.
- The model card includes (in structured fields):
  - `accuracy` ≥ baseline - 0.5%.
  - `fairness.disparate_impact` ≤ 1.25 (no protected-class
    accuracy drop > 1pp).
  - `adversarial_robustness.robust_accuracy_eps_8_255`
    ≥ baseline - 5pp.
- A human approval is recorded in the audit chain.

The policy runs as a Conftest gate in the promotion pipeline
and as an admission policy on the `ModelDeployment` CRD.

### 2. Training-data governance

Enforces that a training job's spec includes:

- Provenance attestation for every dataset (signed).
- Retention policy for any regulated-classified dataset.
- Privacy budget configuration if the dataset is
  privacy-classified.

The policy runs as an admission policy on the `TrainingJob`
CRD.

### 3. Tenant isolation (feature store)

Enforces, at the feature-store request level, that a caller
can only read features for tenants they're authorized for.
This is the application-layer authorization gap from Module
02.

The policy runs as an external authorization (ext-authz) call
from the feature-store service to an OPA sidecar.

Optional further policies:

### 4. Prompt-routing policy (LLM)

Decides which LLM endpoint handles a given prompt based on
tenant tier, prompt characteristics, and compliance class.

### 5. Notebook policy

Enforces that notebook pods cannot access regulated training
data (only anonymized samples).

## Per-policy deliverable

For each:

- The Rego file(s).
- At least 5 `test_*` rules.
- A short note on **where the policy runs** (Gatekeeper /
  Kyverno / sidecar / Conftest).
- A short note on **what evidence the policy produces** for
  the audit chain.
- A short note on **the failure mode** if the policy engine is
  unavailable.

## Format

```
# ML-Specific Policy Catalog: SmartRecs

## Policy 1: Model Promotion Gate

### Purpose
### Where it runs (admission, CI, or both)
### Inputs
### Outputs
### Audit-chain evidence

### Rego
```rego
package mlops.model_promotion

# ... policy logic ...
```

### Tests
```rego
test_deny_unsigned_model { ... }
test_deny_low_accuracy { ... }
test_deny_fairness_regression { ... }
test_deny_no_approval { ... }
test_allow_full_compliance { ... }
```

### Failure mode
(What happens if OPA is unavailable when promotion is attempted?)

## Policy 2: Training-Data Governance
...

## Policy 3: Tenant Isolation
...

## Cross-references
- Module 03 Cosign signatures
- Module 07 audit chain
- Module 06 adversarial robustness measurements
```

## Quality criteria

A passing catalog:

- Policies use **real Rego** with structure that would actually
  run.
- Tests cover the full decision space (happy path + each
  failure mode).
- Each policy names where it runs and what evidence it produces.
- Failure modes are explicit (fail-open vs. fail-closed
  decision documented).

A failing catalog:

- Pseudo-Rego.
- Tests only cover happy path.
- No evidence integration.
- Treats every policy as "block on failure" without
  considering fail-open scenarios.

## Reflection questions

1. The model promotion gate has many inputs. Where do they all
   come from in your system? Which are easy to provide,
   which require new instrumentation?
2. The tenant-isolation policy is the application-layer
   authorization fix from Module 02. Why is it cleaner as a
   policy than as application code?
3. The prompt-routing policy (if you wrote it) makes routing
   decisions. How do you A/B test policy changes safely?
