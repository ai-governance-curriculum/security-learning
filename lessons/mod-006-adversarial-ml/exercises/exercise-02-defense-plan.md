# Exercise 02 — Defense Plan with Quantified Trade-offs

**Estimated time**: 2 hours
**Deliverable**: A 2–3 page decision document

---

## The assignment

Given the robustness numbers from Exercise 01, propose a
**defense plan** for the model. The plan must:

1. Identify the threat model the defense addresses.
2. Choose among the defense options.
3. Quantify the trade-offs.
4. Justify the choice.
5. Acknowledge what the defense doesn't solve.

## Defense options to evaluate

For each, evaluate whether it's appropriate:

- (a) **No defense beyond input validation + rate limiting.**
- (b) **Adversarial training (PGD-based).**
- (c) **TRADES** (tunable adversarial training).
- (d) **Randomized smoothing** (certified robustness).
- (e) **DP-SGD** (privacy + some adversarial robustness as
  side effect).
- (f) **Multi-defense ensemble.**

## Specific scenarios to evaluate

Don't just produce one plan. Produce **three plans** for three
different deployment scenarios:

### Scenario A: Consumer recommendation model

- 50M predictions / day.
- Authenticated users.
- Adversarial attackers are not in the primary threat model
  (consumer recs are not high-value to attack).
- Clean accuracy matters more than robustness; users notice 1%
  accuracy drops in product metrics.

### Scenario B: Medical-imaging classifier

- 10k predictions / day.
- Used by clinicians as decision support (not autonomous).
- A single wrong decision is high-stakes.
- Regulatory environment (FDA / EU AI Act).
- Some training data is from regulated sources.

### Scenario C: Public LLM API

- 100M tokens / hour.
- Authenticated paying customers.
- Adversarial attackers very much in the threat model
  (jailbreaks, extraction, prompt injection are realistic).
- The model is a competitive asset.

## For each scenario, the plan must include

1. **Threat model summary** (1-2 sentences).
2. **Defense choice** with justification.
3. **Quantified cost**:
   - Engineering time (eng-weeks).
   - Compute cost (relative to no defense).
   - Latency impact (if any).
   - Clean-accuracy impact (with numbers if available, ranges
     otherwise).
4. **Quantified benefit**:
   - Expected robust accuracy under realistic attacker.
   - Threats *not* mitigated.
5. **Sequencing** — if multiple defenses, in what order are they
   deployed?
6. **Measurement plan** — how do you know the defense is still
   working in production?

## Format

```
# Defense Plan: <model name>

## Scenario A: Consumer recommendation model

### Threat model
### Defense choice
### Trade-off analysis
| Defense | Eng-weeks | Latency | Compute | Clean accuracy | Robust accuracy |
| ... | ... | ... | ... | ... | ... |
### Recommendation
### What this doesn't solve
### Measurement plan

## Scenario B: Medical-imaging classifier
...

## Scenario C: Public LLM API
...

## Cross-scenario observations
(Patterns you noticed across the three.)
```

## Quality criteria

A passing plan:

- **Different defense choices** for the three scenarios (a
  one-size-fits-all answer means you didn't think about it).
- Quantified trade-offs, even if approximate.
- Acknowledges what the chosen defense doesn't solve.
- Measurement plan is real — production controls degrade
  silently without it.

A failing plan:

- Same defense for all three scenarios.
- Picks adversarial training reflexively without justifying the
  cost.
- No measurement plan.

## Reflection questions

1. Which scenario was hardest? Why?
2. In which scenario would you push back on the product team's
   requirements? What's the conversation?
3. What's the one defense you'd pick if forced to choose only
   one across all three scenarios? Defend.
