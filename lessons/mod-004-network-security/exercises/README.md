# Module 04 Exercises

Five exercises. Reuses SmartRecs from earlier modules.

| # | Exercise | Output | Time |
|---|---|---|---|
| 1 | [CNI evaluation](./exercise-01-cni-evaluation.md) | Decision document choosing a CNI for SmartRecs | 2 h |
| 2 | [Complete NetworkPolicy set](./exercise-02-complete-networkpolicy-set.md) | YAML manifests covering ingress + egress + default-deny | 2–3 h |
| 3 | [Edge gateway hardening](./exercise-03-edge-gateway-hardening.md) | Hardening plan + checklist for the customer-facing API | 2 h |
| 4 | [Rate-limit and DDoS design](./exercise-04-rate-limit-ddos-design.md) | Multi-layer rate-limit design for LLM API | 2 h |
| 5 | [Network observability plan](./exercise-05-network-observability-plan.md) | Telemetry plan keyed to Module 01 threats | 2 h |

## Working notes

- Exercises 1, 2, 5 reuse the SmartRecs scenario and your Module 02
  workload-identity artifact.
- Exercise 3 is independent (the GlobalRecs gateway from Module 01
  Exercise 04 can be reused if helpful).
- Exercise 4 introduces an LLM-API scenario — a new asset class
  with new failure modes.

## Mistake patterns to watch for

- **NetworkPolicy without verifying CNI enforcement.** First step
  is always: confirm enforcement.
- **Treating egress as an afterthought.** Most exfiltration goes
  through egress; design it first.
- **Cloud metadata endpoint left unblocked.** Easy to miss.
- **Rate limits only at the LB layer.** Insufficient for ML APIs.
