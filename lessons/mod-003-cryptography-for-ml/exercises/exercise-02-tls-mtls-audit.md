# Exercise 02 — TLS / mTLS Configuration Audit

**Estimated time**: 2 hours
**Deliverable**: A 2-page audit report

---

## The setup

You inherit a serving deployment with the following TLS posture:

- **External API**: TLS 1.2 enabled, TLS 1.0 enabled, TLS 1.3 not
  enabled. Cipher suites include `TLS_RSA_WITH_AES_128_CBC_SHA`.
  Cert from Let's Encrypt, auto-renewed via cert-manager.
- **Service-to-service mTLS**: Istio mesh, `PeerAuthentication`
  set to `PERMISSIVE` (mTLS preferred, plaintext allowed).
  AuthorizationPolicy not set anywhere — default-allow.
- **Internal service-to-service (non-mesh)**: gRPC services
  using `grpc.WithInsecure()` in code. No TLS at all. Reasoning
  documented: "they're inside the cluster, the network is secure."
- **Client-to-KMS**: AWS SDK default config. The SDK uses TLS
  with cert verification on by default; no override seen.
- **Model-artifact download**: serving pulls model from S3 over
  HTTPS. Bucket is public-read.
- **Internal CA**: there isn't one. Internal TLS where it exists
  uses certs minted by cert-manager pointing at Let's Encrypt
  HTTP-01 (which doesn't work for internal services, so most
  services skip TLS).
- **Cert validation in Python clients**: a couple of services
  use `requests.get(..., verify=False)` to talk to internal
  services. Comment: "fixes weird cert issue."

## The assignment

Produce an audit report that:

1. Identifies every finding. For each:
   - **Title**.
   - **Severity** (Critical / High / Medium / Low).
   - **The standard / control violated** — cite §-numbers from
     the lecture notes or NIST docs.
   - **The threat** the misconfiguration enables.
   - **The fix** — be specific.
   - **Effort** to fix.
2. Orders findings by severity, then by effort within severity.
3. Names a **sequencing recommendation** — the order to apply
   fixes that minimizes risk and avoids outages.
4. Identifies the **one** finding that, if not fixed, makes
   most of the others irrelevant.
5. **What's right** — calibrated reviews say what was done
   correctly.

## Format

```
# TLS / mTLS Audit: <deployment name>

## Reviewer + date
## Scope (what was reviewed, what wasn't)

## Summary recommendation
(Block production traffic / Fix on next sprint / Accept risk with
documentation — which, and why)

## What's right

## Findings
### Critical (must fix before continuing prod traffic)
- Finding 1
- Finding 2
- ...

### High (fix within current sprint)
- ...

### Medium
### Low

## Sequencing recommendation
(In what order should these fixes be applied? Why?)

## The single most consequential finding
(One paragraph: why this one matters more than the others.)

## Open questions
```

## Quality criteria

A passing audit:

- Identifies **at least 8 distinct findings**.
- Severities are calibrated — not everything Critical.
- Cites specific configurations (`PERMISSIVE` mode, TLS 1.0
  enabled, public-read S3 bucket, `verify=False`).
- The sequencing recommendation reflects operational reality —
  don't fix `PERMISSIVE` → `STRICT` before there are working
  AuthorizationPolicies in place, or you'll outage everything.

A failing audit:

- Every finding is "Critical" with no calibration.
- "Implement TLS best practices" with no specifics.
- Misses the "verify=False" bombs.
- Misses the public-read S3 bucket.
- Recommends flipping `PERMISSIVE` to `STRICT` immediately
  without sequencing.

## Reflection questions

1. Which finding will the team **most strongly resist** fixing?
   How do you defend the priority?
2. The reasoning given for unencrypted internal gRPC ("the
   network is secure") is a perimeter-model assumption. What's
   the right response to the team that wrote it?
3. Which finding is most likely to be discovered first in an
   external pen test or compliance audit?

## Save your artifact

This is the input to Module 04 (Network Security) and Module 07
(Compliance).
