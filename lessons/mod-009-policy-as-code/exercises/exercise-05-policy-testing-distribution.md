# Exercise 05 — Policy Testing + Distribution Plan

**Estimated time**: 2 hours
**Deliverable**: A plan document covering test, sign, distribute, audit

---

## The assignment

Build the **operational backbone** for SmartRecs' policy as
code:

1. **Testing pipeline** — how policies get validated before
   reaching production engines.
2. **Signing + bundling** — how policies are packaged so the
   engines can trust them.
3. **Distribution** — how engines pick up policy updates.
4. **Audit-chain integration** — how policy decisions become
   compliance evidence.
5. **Rollback** — how to revert a bad policy.

## Required elements

### Testing pipeline

- **Unit tests** (`opa test`) on every PR.
- **Integration tests** (apply policy in a test cluster, send
  test resources, verify decisions).
- **Conformance tests** (run candidate policy against a
  representative sample of production resources; report
  rejections; iterate before enforcement).
- **Performance tests** (admission latency under load).

### Signing + bundling

- Bundles are built per-environment (dev / staging / prod).
- Bundles are Cosign-signed by the CI workflow (Module 03,
  Module 10 connection).
- Bundle metadata includes Git SHA + policy version.

### Distribution

- Decide between **bundle server** (OPA pulls) and **GitOps**
  (ArgoCD pushes).
- Define refresh interval.
- Define what happens if the bundle server is down.

### Audit-chain integration

- Every policy decision produces an audit-chain entry:
  - Workload identity making the request.
  - Resource being acted on.
  - Policy + version.
  - Decision (allow / deny + violations).
  - Timestamp.

- The audit-chain entry is queryable for compliance reviews.

### Rollback

- Bundle versioning lets you roll back a specific policy
  version.
- The rollback procedure is rehearsed.
- The rollback decision authority is documented.

## Format

```
# Policy Testing + Distribution Plan: SmartRecs

## Testing pipeline

### Unit tests
- Tool, location, when run

### Integration tests
- Test cluster (kind, k3d, or shared dev)
- Test resources catalog
- Expected results
- Pass criteria

### Conformance tests
- Production-resource sample source
- Cadence
- Tuning loop

### Performance tests
- Tool (k6, custom)
- Acceptable latency bounds

## Signing + bundling

### Bundle structure
(policies/, data/, manifest)

### Per-environment configuration
| Env | Source branch | Signing identity | Refresh interval |
|---|---|---|---|

### Bundle CI workflow
(YAML or pseudo)

## Distribution

### Decision: bundle server vs. GitOps

### If bundle server:
- Server choice (S3 + signed URLs, custom registry)
- OPA pull configuration

### If GitOps:
- ArgoCD / Flux configuration
- Sync interval

### Failure modes
- Bundle server down: behavior
- Stale bundle: behavior
- Signature verification fail: behavior

## Audit-chain integration

### Entry schema
- Fields
- Signing identity
- Storage

### Query patterns
- "Show me all deny decisions in the last 7 days for namespace X."
- "Show me all policy changes deployed in the last 30 days."
- "Show me the policy version that decided this rejection."

## Rollback

### Procedure
- Steps
- Authority
- Communication

### Rehearsal
- Cadence
- Acceptance criteria

## Risks and mitigations
- Stale policy enforcement (e.g., policy says "v1.2.3 OK"
  but v1.2.3 has a known CVE now)
- Performance regression from policy complexity
- Operator error in policy authoring
```

## Quality criteria

A passing plan:

- Each section is **concrete** — names tools, configs,
  cadences.
- The signing + distribution flow connects to Module 03's
  Cosign work.
- Audit-chain integration produces queryable evidence
  suitable for SOC 2 / GDPR audits.
- Rollback is rehearsable.

A failing plan:

- "Test the policies somehow."
- No signing.
- Audit-chain entries are vague ("log the decision").
- No rollback procedure.

## Reflection questions

1. Which test layer (unit / integration / conformance /
   performance) has the highest ROI? Which has the lowest?
2. The team objects: "Conformance tests will block every
   policy update for weeks while we tune." How do you
   balance speed and safety?
3. A bug in a new policy causes a 30-minute admission outage.
   What's the post-mortem outline, and what's the structural
   fix to prevent recurrence?

## Save your artifact

This plan is the **operational backbone** for the policy-as-code
program. It's a high-leverage artifact.
