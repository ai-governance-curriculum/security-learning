# Exercise 01 — Threat-Model a Small ML System

**Estimated time**: 2–3 hours
**Deliverable**: A 3–5 page written threat model in Markdown
**Reusability**: This is the input to Exercises 02, 03, and 05

---

## The system

**SmartRecs**, a fictional company, runs a product-recommendation
service for mid-sized e-commerce stores. The architecture:

- **Training pipeline**: nightly, on the past 90 days of customer
  events. Reads from a shared analytics warehouse. Writes a new
  model artifact to an internal artifact store (S3-compatible)
  with version tag `recs-vN`.
- **Promotion**: a manual ticket-and-approval workflow promotes a
  `recs-vN` to a `recs-prod` alias.
- **Serving**: 6 model-server pods behind a gateway. Pulls the
  artifact pointed at by `recs-prod` at pod startup. Returns the
  top 10 recommendations per request.
- **API**: an HTTPS endpoint scoped per customer-store. Customers
  authenticate via an API key issued by SmartRecs. Free tier 1k
  RPM, paid tier 100k RPM.
- **Feedback loop**: clicks and purchases are logged to the
  analytics warehouse. The next training run uses them.
- **Observability**: per-pod Prometheus metrics; per-request audit
  log to S3 with 30-day retention.
- **Team**: 3 ML engineers, 1 backend engineer, 1 ops-on-call.
  No dedicated security engineer (that's why they're hiring you).

The platform team manages the Kubernetes cluster, IAM, and
secrets. The product team owns the ML pipelines and the API.

## Your assignment

Produce a written threat model that:

1. **Inventories the assets.** What protectable things does this
   system contain? Be specific — not "training data" but "60
   days of customer events including event type, item ID,
   anonymized customer ID, store ID, and timestamp."
2. **Identifies the trust boundaries.** Where does data cross from
   untrusted to trusted, or between trust zones? Who enforces the
   transition?
3. **Walks STRIDE+ML** (from lecture notes §4.1) against the
   system. Produce a table with rows for each STRIDE category and
   columns for the classical and ML-specific extensions. Each
   cell is a concrete threat in the form *"attacker A wants
   outcome B by doing C"* (or "N/A" with a one-line
   justification).
4. **Identifies the three ML-specific threats** from lecture notes
   §4.2 (model quality degradation, fairness regression, decision
   authority overreach) and assesses applicability.
5. **Names existing controls** at SmartRecs — be honest about what
   they have and don't have.
6. **Names the gaps.** What controls are missing? What controls are
   present but insufficient?
7. **Prioritizes** the gaps by likelihood × impact. Use a simple
   high / medium / low scale; defend each ranking in one
   sentence.

## Format

Markdown, 3–5 pages. Suggested structure:

```
# SmartRecs Threat Model

## 1. System summary
## 2. Assets
## 3. Trust boundaries
## 4. STRIDE+ML threats (table)
## 5. ML-specific threats not covered by STRIDE
## 6. Existing controls
## 7. Gaps and missing controls
## 8. Prioritized mitigation backlog
```

## Quality criteria

A passing threat model:

- Is **concrete**. Threats name a hypothetical actor, the asset
  they want, and the path they would use.
- Is **honest**. It names the gaps even if they make SmartRecs
  look bad.
- Is **defensible**. You can argue each ranking under questioning.
- Is **usable**. The next person reading it would know what to
  build.

A failing threat model:

- Lists Top-10 IDs without naming concrete threats.
- Treats compliance items ("we have SOC 2") as mitigations.
- Hedges every gap so nothing looks urgent.

## Reflection questions

After producing the artifact:

1. Which threat in your model surprised you most? Why didn't you
   spot it on the first read of the system description?
2. Which threat is most likely to be *under*-prioritized by a team
   like SmartRecs (whose first hire is a security engineer
   responding to incidents, not designing systems)? Why?
3. Which gap would you address *first*? Defend the choice
   against the obvious alternative (likely the most-famous threat).

## Save your artifact

Save the threat model to your own notes. You will reuse it in:

- **Exercise 02**: mapping it against the OWASP ML Top 10.
- **Exercise 03**: walking one of its threats through MITRE ATLAS.
- **Exercise 05**: producing a defense-in-depth design.

## Solution comparison

After writing your own, compare against the reference threat model
in [`ai-infra-security-solutions/modules/mod-001-ml-security-foundations/exercise-01/`](https://github.com/ai-infra-curriculum/ai-infra-security-solutions/tree/main/modules/mod-001-ml-security-foundations) (when published).

Don't read the reference first. The point is to discover what *you*
spot before being told what to spot.
