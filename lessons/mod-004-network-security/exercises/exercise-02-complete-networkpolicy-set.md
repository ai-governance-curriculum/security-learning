# Exercise 02 — Complete NetworkPolicy Set

**Estimated time**: 2–3 hours
**Deliverable**: At least 8 NetworkPolicy YAML manifests + a
coverage table

---

## The assignment

Produce the **complete** NetworkPolicy set for the SmartRecs
production namespaces. The set must cover ingress *and* egress
for every workload class.

## Namespaces and workloads

- `edge` — `gateway` pods (3 replicas).
- `recs` — `model-serving` pods (6 replicas), `recs-trainer`
  cron job.
- `features` — `feature-api` pods (4 replicas).
- `gov` — `governance-api` pod (1 replica).
- `obs` — `prometheus` and `grafana`.
- `data` — internal warehouse proxy (`warehouse-proxy` pod).
- `notebooks` — JupyterHub for data scientists.

## Required policies (minimum)

1. **`default-deny-all`** in every namespace.
2. **Allow ingress** to `model-serving` from `gateway` only.
3. **Allow egress** from `model-serving` to:
   - DNS (cluster DNS).
   - `feature-api` in `features` namespace.
   - Model artifact store (via VPC endpoint CIDR; use
     `10.50.0.0/16` as a placeholder).
   - Prometheus in `obs`.
4. **Allow egress** from `recs-trainer` to:
   - DNS.
   - `warehouse-proxy` in `data` namespace.
   - Model artifact store (write).
   - Prometheus.
5. **Allow ingress** to `feature-api` from `model-serving` and
   `recs-trainer` only.
6. **Allow ingress** to `governance-api` from `gateway` and
   admin tooling (via a specific label).
7. **Egress from `notebooks`**: heavily restricted; only the
   internal PyPI mirror (`10.50.10.0/24`) and an anonymized
   sample-data S3 endpoint.
8. **Block cloud metadata** (`169.254.169.254/32`) from every
   workload that doesn't legitimately need it (which is
   everyone in SmartRecs).

## Format

Produce the YAML for each policy. After the YAML, write a
coverage table:

| Policy | What it allows | What it denies | Threat caught | Module 01 threat ref |
|---|---|---|---|---|

End with:

- **The single most consequential policy** (which one, if
  misconfigured, breaks isolation worst).
- **Testing strategy** — how would you verify these policies
  actually enforce what they claim?

## Quality criteria

A passing set:

- Has a `default-deny-all` per namespace.
- Every allow rule uses **pod selectors** + **namespace
  selectors**, not just namespace.
- DNS is allowed only to cluster DNS, never to arbitrary
  destinations.
- Cloud metadata endpoint is blocked.
- Egress is restricted to specific destinations, not "any
  external IP."
- The coverage table maps policies to specific Module 01
  threats.

A failing set:

- Only ingress; egress is `{}` (allow all).
- Allows entire namespaces.
- Forgets the metadata endpoint.
- Allows DNS to `0.0.0.0/0:53` (any DNS).

## Reflection questions

1. Which policy was the hardest to write correctly? Why?
2. What's the one wildcard or broad allow you accepted that
   you'd narrow further if you had more time?
3. How does this NetworkPolicy set relate to your Module 02
   Istio AuthorizationPolicy set? Where do they overlap, where
   does one catch what the other misses?
