# Module 08 Quiz — Runtime Security

> Closed-book first.

---

## Conceptual (10 questions)

### Q1
Runtime security has two jobs (§1). Name them and explain how
they differ.

### Q2
Compare Pod Security Standards' three profiles
(Privileged / Baseline / Restricted). For each, name one
workload class that's appropriate for that profile.

### Q3
The lecture argues that **RuntimeDefault seccomp** is "one of
the highest-leverage configurations" (§3.1). Explain why in 3-4
sentences. What attack surface does it remove?

### Q4
For each of the following, identify whether **seccomp**,
**AppArmor**, or **PSS** is the right enforcement layer:
- (a) Block a syscall the application doesn't need.
- (b) Block a pod from running with hostNetwork.
- (c) Restrict a process's filesystem access to a specific path.
- (d) Enforce non-root user.

### Q5
Compare Falco and Tetragon (§6.3). For a greenfield SmartRecs-
scale deployment in 2026, which would you pick? Defend the
choice in 4-6 sentences.

### Q6
Container sandboxing (gVisor, Kata Containers) is operationally
expensive. Name **three scenarios** where the cost is justified
and **two scenarios** where it isn't.

### Q7
Behavioral analytics complements rule-based detection (§8).
Explain in 3-4 sentences what each catches that the other
doesn't. Give one example of each.

### Q8
The "alert pyramid" (§10.1) is the principle behind operating
runtime security at scale. Why does failing to layer alert
priorities lead to "few alerts treated seriously"?

### Q9
For each ML-specific runtime threat (§9), name the most likely
detection source:
- (a) Model file tampering.
- (b) Training-job egress to unknown destination.
- (c) Cryptomining via compromised container.
- (d) Reverse shell from production serving.

### Q10
The lecture argues that for a SmartRecs-scale team (§11), some
sophisticated tools (Tetragon, gVisor, custom seccomp profiles)
aren't needed Day 1. Defend this calibration. When *do* these
tools become worth deploying?

---

## Applied (5 questions)

### Q11
Roll out **Pod Security Standards: Restricted** to the SmartRecs
production namespace `recs`. Specify:
- (a) The namespace labels for `warn → audit → enforce`
  transition.
- (b) The timeline (in weeks).
- (c) The expected failures during the rollout (which workloads
  will fail, why).
- (d) The remediation for each expected failure.
- (e) The rollback plan if the enforce step breaks production.

### Q12
Write a Falco rule (or set of rules) that detect:
- (a) A `kubectl exec` into a production serving pod.
- (b) A write to `/models/<anything>` from a process other than
  `model-loader`.
- (c) An outbound connection from a notebook pod to a domain
  not in `internal-pypi-mirror.smartrecs.com` or
  `data-samples.smartrecs.internal`.

Use realistic Falco syntax (or pseudo-syntax if you don't
remember exactly). For each rule, note the expected
false-positive rate.

### Q13
Design a **behavioral baseline** for the SmartRecs `model-
serving` workload:
- (a) The dimensions to baseline.
- (b) The baseline window (learning period).
- (c) The alert thresholds.
- (d) The mechanism for re-learning when the workload changes.
- (e) The acceptance test ("how do you know the baseline is
  working?").

### Q14
A Critical Falco alert fires at 3 AM:
> Rule: "Container escape attempt detected"
> Container: `serving-recs-7f8d9c-xq2`
> Namespace: `recs`
> Output: A process inside the container called `setns(2,
> CLONE_NEWNS)` and successfully entered the host mount
> namespace.

Walk through the **on-call response**:
- (a) Immediate steps (within 5 minutes).
- (b) Containment (within 30 minutes).
- (c) Investigation (within 24 hours).
- (d) Communication.
- (e) Post-incident actions.

### Q15
The team proposes adopting Tetragon **alongside** Falco — they
want both. Argue for or against:
- (a) When is dual-stack justified?
- (b) What's the cost?
- (c) Recommend: keep both, replace Falco with Tetragon, keep
  only Falco. Defend.

---

## Self-assessment rubric

Same as previous modules. Passing: average ≥ 2.0, no question
scored 0.
