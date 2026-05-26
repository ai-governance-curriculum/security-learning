# Module 02 Quiz — Zero-Trust Architecture

> Take this quiz **after** working through the lecture notes and
> exercises. Closed-book first.

---

## Conceptual (10 questions)

### Q1
State the five tenets of zero-trust from NIST SP 800-207
(lecture-notes §1.1) in your own words. For each, give one
violation you have seen — or could plausibly see — in a real ML
system.

### Q2
A peer asks "isn't zero-trust just having mTLS everywhere?"
Respond with a clear, 4–6 sentence answer that gives them a
correct mental model without over-correcting.

### Q3
For each of these failures of the perimeter model in ML systems
(lecture-notes §2), name **one concrete attack scenario** the
failure enables:
- Trusted internal network.
- Authenticate-at-perimeter.
- Workloads trust each other.

### Q4
Compare a SPIFFE SVID, an AWS IAM Role for Service Accounts
(IRSA), and a long-lived Kubernetes Secret containing static
credentials. Which is most appropriate for the following
workloads? Explain.
- (a) A serving pod calling an internal feature store.
- (b) A serving pod calling an external SaaS API that only
      accepts API keys.
- (c) A training job that needs to read from S3 and write to a
      different S3 bucket.

### Q5
A network policy in namespace `recs` has a default-deny
NetworkPolicy *and* a specific allow that says "traffic from
namespace `recs` to namespace `feature-store` is allowed."
Identify two distinct ways this policy is *less restrictive*
than it appears.

### Q6
The lecture notes argue that mesh-layer authorization is
insufficient for multi-tenant feature access (§4.4). Explain why
in 3–4 sentences. What is the minimum additional layer required
to fix this?

### Q7
Workload identity attestation depends on node integrity (lecture
notes §5.7). Explain what this means concretely. Give one realistic
attack scenario where a compromised node defeats workload-identity
controls, and name one mitigation.

### Q8
For each ML-specific control below, name the threat it primarily
mitigates and the lifecycle stage where it applies.
- (a) Per-tenant feature authorization in the feature store API.
- (b) Per-version model artifact access scoping.
- (c) Time-bounded notebook identities.
- (d) Training-job identity scoped to that specific job.

### Q9
A vendor pitches you a product that "makes you zero-trust in a
single deployment." Describe three questions you would ask the
vendor to evaluate the pitch honestly.

### Q10
Name three threats zero-trust deliberately doesn't solve
(lecture notes §9). For each, which later module of this track
addresses it, and what control class does that module add?

---

## Applied (5 questions)

### Q11
Take your Exercise 01 SmartRecs threat model (from Module 01)
and identify the three threats whose mitigation is **most
materially improved** by adopting the architectural changes in
this module. Defend each pick. For each, name the specific
control(s) from this module that mitigates it.

### Q12
Draft an `AuthorizationPolicy` (Istio-flavored, YAML) that
allows only the `model-serving` workload in namespace `recs` to
call `POST /v1/predict` on the gateway. The policy should
explicitly *deny* all other callers. Note: you don't need to
look up exact field syntax; pseudo-YAML that gets the structure
right is fine.

### Q13
A teammate insists that "we have IAM, so we don't need workload
identity." They want to use a single IAM role for all pods on a
training node. Argue against this in concrete terms — what threat
is unmitigated, what incident would result. Aim for a 6–10
sentence response that's persuasive to a senior engineer, not
just correct.

### Q14
Walk through a request from "external customer with valid API
key" to "serving pod returning fraud prediction" using lecture
notes §5 as a template. At each hop, name (a) who's authenticating
to whom, (b) what authorization decision is being made, (c) what
identity is being verified.

### Q15
Suppose your platform has 50 ML services in 12 namespaces. Six
teams own them. You're asked to design a phased zero-trust
adoption plan, sequenced by reversibility (lecture notes §5 of
Module 01 mentions sequencing by reversibility; apply the same
principle here). Outline the phases — at least 3, at most 6 —
with what's in each phase and the success criterion to advance.

---

## Self-assessment rubric

Same scale as Module 01:

| Score | Meaning |
|---|---|
| **3** | Correct and defensible under questioning. |
| **2** | Correct but needed thinking — re-read relevant section. |
| **1** | Partial — re-read the section, try again. |
| **0** | Don't know — re-read the lecture notes. |

Passing: average ≥ 2.0, no question scored 0.
