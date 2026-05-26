# Exercise 05 — Network Observability Plan

**Estimated time**: 2 hours
**Deliverable**: A telemetry plan + a small detection-rule set

---

## The assignment

Produce a network observability plan for SmartRecs that:

1. Catalogs the **sources of network telemetry** available
   (lecture notes §8).
2. Maps each source to the **threats from your Module 01
   threat model** that it can detect.
3. Identifies the **gaps** — threats with no observability
   coverage.
4. Specifies **at least three detection rules** (in Sigma
   pseudo-syntax or as plain-English logic) that would fire
   on realistic attack patterns.
5. Names the **storage / retention / cost** model: where do
   the logs go, how long are they kept, what does it cost.

## Sources you have or could have

Pick which of these to use. Justify each yes / no:

- **Cilium Hubble** (you'd have it if you picked Cilium in
  Exercise 01).
- **VPC flow logs** (cloud-native, separate billing).
- **Istio mesh access logs** (Envoy structured logs).
- **DNS query logs** (CoreDNS, Cilium DNS proxy).
- **API gateway access logs** (Loki today, see Exercise 03).
- **Audit chain** (the Module 03 / Module 07 system).

## Required deliverables

1. **A telemetry inventory** — sources, what each captures,
   retention.
2. **A threat-to-source mapping table** — for each of the top 5
   threats from your Module 01 model, which sources catch it.
3. **At least 3 detection rules** for realistic patterns.
   Examples to consider:
   - **Lateral-movement detection**: workload X starts talking
     to workload Y for the first time.
   - **Exfiltration detection**: egress bytes from pod X exceed
     historical baseline by >5×.
   - **DNS-based exfiltration**: pod X queries domains with
     unusually long subdomains (encoded data).
   - **Cloud-metadata access**: any pod queries
     `169.254.169.254`.
   - **Cross-namespace anomaly**: workload X in namespace A
     calls workload Y in namespace B and that call has not been
     seen in 7 days of baseline.
4. **Cost model** — rough monthly cost in storage + ingest.
5. **Open questions** — what would you need from a vendor or
   from internal data to refine this plan.

## Format

```
# Network Observability Plan: SmartRecs

## Source inventory

| Source | Captures | Retention | Approx monthly cost |
|---|---|---|---|

## Threat-to-source mapping

| Module 01 threat | Sources | Confidence |
|---|---|---|

## Coverage gaps

(Threats with no realistic source coverage today.)

## Detection rules (3+ rules)

### Rule 1: <name>
- Source: <log source>
- Logic (Sigma pseudo-syntax or English):
- What it catches:
- Expected false-positive rate:
- Triage steps (what to do when it fires):

### Rule 2: ...
### Rule 3: ...

## Storage / cost model
(Rough numbers — Hubble adds ~X GB/day, VPC flow logs ~Y,
audit chain ~Z. Total monthly cost: ~$N.)

## Open questions
```

## Quality criteria

A passing plan:

- Maps **specific Module 01 threats** to specific sources, not
  generic "lateral movement → flow logs."
- Acknowledges that **some threats have no good observability**
  — there are honest gaps.
- Detection rules have **specific logic** and a triage step.
- Cost model is real — at scale, observability is expensive.

A failing plan:

- "Turn on all the logs and look for anomalies." Not a plan.
- Detection rules with no triage step. (A firing rule that
  produces no action is alert fatigue, not security.)
- No cost model.

## Reflection questions

1. Which threat from Module 01 has the **worst** coverage?
   What's the realistic mitigation if observability won't
   catch it?
2. Which detection rule will have the highest false-positive
   rate? How do you tune it?
3. If forced to cut the observability budget by 50%, which
   sources would you drop, and why?

## Save your artifact

The detection-rule set is the input to Module 11 (Security
Operations).
