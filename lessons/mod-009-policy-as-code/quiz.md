# Module 09 Quiz — Policy as Code

> Closed-book first.

---

## Conceptual (10 questions)

### Q1
The lecture argues that policies should live across three
control planes (§1.1): CI, admission, runtime. For each, give
one example of a policy violation it catches that the others
cannot.

### Q2
Explain in 3-4 sentences what makes Rego different from a
general-purpose language like Python. What does that
constraint buy you, and what does it cost?

### Q3
A new SmartRecs admission webhook is being deployed. The
implementer asks: "Should I set `failurePolicy: Fail` or
`Ignore`?" Defend each choice; recommend one.

### Q4
Compare Gatekeeper and Kyverno along five dimensions
(language, mutation, generation, image verification, learning
curve). For SmartRecs (small team, Kubernetes-native, OpenAI
integration with Cosign), which would you choose?

### Q5
Conftest runs Rego policies in CI. Name three classes of
violation that should be caught by Conftest before they reach
admission, and one class that admission still needs to catch
even if Conftest passed.

### Q6
The lecture states that the same policy should run in both
CI and admission (§6.3). Defend this principle. What goes
wrong if CI and admission have *different* policies for the
same control?

### Q7
For each ML-specific policy pattern (§9), name the **enforcement
point** (where the policy runs):
- Model promotion gate.
- Training-data governance.
- Prompt routing.
- Tenant isolation.

### Q8
A buggy ConstraintTemplate has been deployed to Gatekeeper and
is rejecting all `Deployment` admissions cluster-wide. Walk
through the recovery in order.

### Q9
The phased migration plan (§10) goes through 5 phases. For each,
name the **one signal** that tells you it's time to advance to
the next phase.

### Q10
"Untested policies fail in production" (§7). Give three
patterns of policy bug that **only show up under specific input
shapes** that an obvious test wouldn't cover.

---

## Applied (5 questions)

### Q11
Author a Rego policy that enforces:
- Every Pod has a `team` label (allowed values: `recs`,
  `fraud`, `gov`, `platform`).
- Pods in `prod-*` namespaces use images tagged with `@sha256:...`
  (digest references, not tag references).
- Pods don't use `imagePullPolicy: Always`.

Include `test_*` rules covering the happy path and at least
three failure paths.

### Q12
Convert the policy from Q11 to **Kyverno YAML**. Note any
constraints from Q11 that Kyverno doesn't naturally express,
and explain how you'd handle them (custom verb, separate
policy, etc.).

### Q13
Design the **model promotion gate** for SmartRecs as a Rego
policy. The policy must check:
- Cosign signature is valid.
- The signing identity matches the expected CI workflow.
- The model card includes accuracy + fairness metrics.
- Accuracy on the validation set is ≥ baseline - 0.5%.
- No protected-class accuracy drop > 1pp.
- A human approval exists in the registry.

Provide the full Rego (with helpers). Include at least 4
`test_*` rules.

### Q14
Audit the following Rego policy and produce a list of issues
(bugs, anti-patterns, gaps):

```rego
package admission

deny {
    input.kind == "Pod"
    container := input.spec.containers[_]
    contains(container.image, "latest")
}

allow {
    input.user.role == "admin"
}

deny[msg] {
    input.spec.privileged == true
    msg := "no privileged"
}
```

(There are at least 5 issues. Find them.)

### Q15
Plan the **migration to policy as code** for SmartRecs:
- Current state: admission policies exist as one-off webhooks
  written by various engineers; some PSS labels are set
  inconsistently; no CI policy gates; policies are
  un-versioned.
- Target state: codified policies in Git, CI + admission
  enforcement, audit-chain integration, automated testing.

Produce a phased plan (4-6 phases) with deliverables,
success criteria, duration per phase, and rollback.

---

## Self-assessment rubric

Same as previous modules. Passing: average ≥ 2.0, no question
scored 0.
