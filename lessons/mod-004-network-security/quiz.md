# Module 04 Quiz — Network Security

> Closed-book first.

---

## Conceptual (10 questions)

### Q1
NetworkPolicy is **additive**. Explain in 3 sentences what this
means and give one example of how additivity could produce an
unintended allow.

### Q2
You inherit a Kubernetes cluster. How do you verify (with
concrete commands or test approach) that NetworkPolicy is
actually being **enforced**, not just accepted by the API
server?

### Q3
Name three things that **standard** Kubernetes NetworkPolicy
cannot do that **Cilium L7** can do. For each, explain why this
matters in an ML context.

### Q4
The cloud metadata endpoint (`169.254.169.254`) is a security
concern. Explain in 4 sentences:
- (a) What it provides.
- (b) Why it's dangerous.
- (c) What the network-layer mitigation is.
- (d) What the IAM-layer mitigation is.

### Q5
An Istio AuthorizationPolicy has both `ALLOW` and `DENY` rules.
Walk through the evaluation order. Then describe a use case
where a DENY rule is the cleanest way to express the desired
policy.

### Q6
Compare classic Istio (sidecar) and Istio Ambient for two
scenarios:
- (a) An ML platform with 200 lightweight serving pods, mostly
  needing L4 policy.
- (b) A platform with 30 services, all needing per-request L7
  authorization.

### Q7
The lecture notes argue that "service meshes don't replace
NetworkPolicy" (§4.5). Give two concrete examples of attacks or
failure modes where NetworkPolicy is the layer that catches the
issue and the mesh is not.

### Q8
For an LLM serving API, list **four layers** of rate limiting
and what each layer protects against.

### Q9
Name four sources of network telemetry from §8 and what each is
best at detecting. Which is most likely to be the first to fire
on a real lateral-movement scenario?

### Q10
A team proposes putting all egress through a single Squid proxy
pod for "centralized control." Argue for or against. Be
specific about what this configuration helps and what it breaks.

---

## Applied (5 questions)

### Q11
Write a NetworkPolicy YAML (or pseudo-YAML) for a notebook pod
that:
- Allows DNS to cluster DNS only.
- Allows access to an internal pypi mirror at
  `mirror.smartrecs.internal`.
- Allows access to an anonymized-data S3 bucket (via VPC
  endpoint at `10.50.0.0/16`).
- Blocks the cloud metadata endpoint.
- Blocks everything else.

### Q12
Audit the following egress configuration for a training job:

```yaml
egress:
  - {} # allow all
```

Identify at least four threats this enables. For each, propose
the specific change to the policy that would catch it.

### Q13
The ML team wants to call the OpenAI API (`api.openai.com`)
from their serving pod for an LLM fallback. The current
NetworkPolicy denies all egress. Walk through the three
realistic options for enabling this, including their trade-offs:
- (a) Pure NetworkPolicy with IP allowlist.
- (b) Cilium FQDN egress policy.
- (c) Egress gateway pod with hostname filtering.

Recommend one. Defend the choice.

### Q14
Design a phased rollout for changing the SmartRecs production
mesh from `PeerAuthentication: PERMISSIVE` to `STRICT` across
12 namespaces. The constraint: no production outage. Outline 3-5
phases.

### Q15
Your CTO asks: "We're getting hammered by what looks like
abusive traffic on the LLM API — a single customer is sending
huge prompts and consuming most of our GPU capacity." Propose
the immediate mitigations (in priority order) and the
medium-term controls. Identify which controls are
application-layer, which are network-layer, and which need
identity / observability work.

---

## Self-assessment rubric

Same scale as previous modules. Passing: average ≥ 2.0, no
question scored 0.
