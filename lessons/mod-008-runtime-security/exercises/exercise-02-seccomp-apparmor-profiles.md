# Exercise 02 — Seccomp + AppArmor Profiles

**Estimated time**: 2 hours
**Deliverable**: Concrete profiles + a deployment plan

---

## The assignment

Harden the SmartRecs **model-serving** workload with custom
seccomp and AppArmor profiles.

### Part 1 — Seccomp

1. **Apply RuntimeDefault** to every pod in `recs` and `fraud`
   namespaces.
2. **Author a custom profile** for `model-serving` that's
   tighter than RuntimeDefault — denies syscalls the Python +
   PyTorch + Uvicorn stack doesn't need.
3. **Document the profile-generation process**:
   - Tools used (`syscall2seccomp`, Inspektor Gadget, etc.).
   - Test methodology.
   - Acceptance criteria.

### Part 2 — AppArmor

1. **Author an AppArmor profile** that restricts model-serving
   to:
   - Read-only access to `/models`.
   - Read/write to `/tmp` and the pod's writable layer.
   - Network: bind to one port; outbound to specific
     destinations.
   - No `mount`, no `ptrace`, no `setns`.
2. **Apply the profile** via the appropriate Kubernetes
   annotation.
3. **Document the rollout** — `complain` mode first, then
   `enforce`.

## Format

```
# Hardened Profiles: model-serving

## Part 1 — Seccomp

### RuntimeDefault rollout
- Pods affected
- Pod-spec snippet
- Acceptance test

### Custom profile
- Profile generation: how
- Profile YAML / JSON
- Test scenarios
- Acceptance criteria
- Rollback plan

### Risk acknowledged: profile drift on dependency upgrade
- Detection
- Mitigation

## Part 2 — AppArmor

### Profile design
- Rationale per restriction
- Profile text (or pseudo-syntax)

### Deployment
- Profile location on nodes
- Pod annotation
- complain → enforce transition

### Operational concerns
- How violations are surfaced
- Triage path

## Comparison: when seccomp alone is enough; when AppArmor is
worth adding
```

## Quality criteria

A passing exercise:

- RuntimeDefault is applied namespace-wide via pod template /
  policy.
- The custom seccomp profile is concrete (even if pseudo).
- The AppArmor profile restricts at least filesystem, network,
  and dangerous capabilities.
- The profile-generation methodology is documented (not just
  "we tuned it").

A failing exercise:

- Skips RuntimeDefault, jumps to custom.
- Custom profile is a placeholder.
- No profile-generation methodology.
- AppArmor profile that blocks legitimate operations.

## Reflection questions

1. Which is harder to maintain — seccomp or AppArmor? Why?
2. The team objects: "We don't need AppArmor; RuntimeDefault is
   fine." When is that the right call, and when isn't it?
3. A dependency upgrade introduces a new syscall the profile
   blocks. What's the engineering process to catch this before
   production?
