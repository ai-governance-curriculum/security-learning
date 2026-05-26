# Exercise 02 — Workload Identity Design

**Estimated time**: 2 hours
**Deliverable**: 2-page Markdown design document + a workload-identity table

---

## The assignment

Produce a workload-identity design for SmartRecs using SPIFFE-style
identities. The design specifies, for every workload class in the
system:

1. **The SPIFFE ID** (its full path).
2. **What attestation selectors** issue it (node selector, pod
   selector, image digest, etc.).
3. **What it is authorized to do**:
   - **Read access**: which resources, on which identities, at which
     paths.
   - **Write access**: same.
   - **Network egress**: which destinations.
4. **TTL** for the SVID.
5. **What it is explicitly *not* authorized to do** — at least two
   items per workload, to demonstrate the least-privilege principle.

## Workload classes for SmartRecs

You need to design identities for at least these workloads:

- **Training job**: runs nightly, reads training-data warehouse,
  writes model artifact.
- **Serving pod**: serves predictions, reads model artifact and
  feature store.
- **Gateway pod**: terminates customer API requests.
- **Governance pod**: reads model registry, writes audit log.
- **Notebook / experimentation pod**: data-scientist interactive
  environment.

You may add others if your Module 01 model identified them.

## Format

Use a table for the per-workload identities, plus prose for the
overall design.

```
# SmartRecs Workload Identity Design

## Trust domain
spiffe://smartrecs.internal

## Workload identity table

| Workload | SPIFFE ID | Attestation selectors | Read access | Write access | Network egress | SVID TTL | Explicitly NOT |
|---|---|---|---|---|---|---|---|
| Training | spiffe://...sa/training/v1 | k8s:pod:label app=trainer + image digest pinned + node label workload=batch | s3://training-data/<own-slice>/, internal warehouse via JDBC | s3://models/<run-id>/ | warehouse, S3 | 1h | model registry, other tenants' data |
| Serving | ... | ... | ... | ... | ... | ... | ... |
| ... | ... | ... | ... | ... | ... | ... | ... |

## Design rationale

### Why these attestation selectors
### Why these TTLs
### Why these least-privilege boundaries
### What changes if SmartRecs adds a second team

## Cross-workload identity flows

(Describe how the gateway's identity propagates to serving, and how
serving's identity propagates to the feature store. Address the
"on-behalf-of" question for the customer's identity.)

## Trade-offs accepted

(What's deliberately compromised in this design, e.g., notebook
environments where strict least-privilege isn't operationally
feasible.)
```

## Quality criteria

A passing design:

- Specifies **at least 5** distinct workload classes.
- Each identity has **at least one** explicit "not authorized to"
  entry that catches a realistic mistake.
- SVID TTLs are credible (1–12 hours typically; not 1 minute, not
  30 days).
- Attestation selectors are **enforceable** — they bind identity to
  concrete artifacts (image digest, namespace, service account)
  rather than to opt-in labels alone.
- Addresses **on-behalf-of** (how does the customer's identity
  travel with the request?).

A failing design:

- Gives every workload the same identity ("we'll figure out the
  details later").
- Uses long-lived TTLs (>24h) — that's not workload identity, that's
  a static credential.
- Attestation by namespace alone — easy to spoof if anyone can
  create a pod in that namespace.

## Reflection questions

1. What changes in the design if SmartRecs hires a second ML team
   that shares the same Kubernetes cluster but should not see
   tenant data from the first team?
2. What is the *first* identity in this design that a new platform
   engineer should look at to understand the access pattern? Why?
3. Which workload's identity is hardest to scope tightly? Why?

## Save your artifact

Used in Exercise 3 (microsegmentation), Exercise 4 (mesh authz),
and Module 05 (secrets management).
