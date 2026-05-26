# Exercise 02 — Rego Policy Library

**Estimated time**: 2–3 hours
**Deliverable**: 5+ Rego policies with tests

---

## The assignment

Build a small policy library for SmartRecs. Each policy:

- Is a single Rego file.
- Has a clear `package`.
- Includes at least 3 `test_*` rules.
- Documents what it enforces and why.

## Required policies (minimum 5)

1. **`security.images.signed`** — every Pod's containers must
   have images signed by the SmartRecs CI's OIDC identity (the
   Cosign integration). Reject if not.

2. **`security.images.no_latest`** — images must not use
   `:latest` or be tag-less. Require digest references in
   `prod-*` namespaces.

3. **`security.pods.required_labels`** — every Pod must have
   `team`, `owner`, `cost-center` labels. Labels must match a
   set of allowed values.

4. **`security.pods.no_root`** — Pods must run as a non-root
   user. Reject `runAsUser: 0` or unset in `prod-*` namespaces.

5. **`security.network.no_metadata_egress`** — Pod's
   NetworkPolicy must not allow egress to the cloud metadata
   endpoint.

Optional further policies:

6. **`mlops.models.signed`** — model artifact references in
   ModelDeployment CRs must have valid signatures.

7. **`platform.namespaces.required_labels`** — every Namespace
   must have `pod-security.kubernetes.io/enforce` label set to
   a recognized profile.

## Each file's structure

```rego
# policies/security/images/signed.rego
package security.images.signed

# Documentation:
# Enforces that all container images are signed by the
# SmartRecs CI identity via Cosign. Rejects pods whose
# images cannot be verified.

import future.keywords.in

# Allowed signing identities
allowed_signers := [
    "https://github.com/smartrecs-org/recs/.github/workflows/build.yml@refs/heads/main",
    "https://github.com/smartrecs-org/fraud/.github/workflows/build.yml@refs/heads/main",
]

deny[msg] {
    container := input.review.object.spec.containers[_]
    not is_signed(container.image)
    msg := sprintf("Container image %s is not signed", [container.image])
}

is_signed(image) {
    # This is where you'd query Cosign verifying data — for the
    # exercise, you can stub it via input.data.signed_images:
    image in input.data.signed_images
}

# Tests
test_deny_unsigned {
    deny["Container image untrusted:v1 is not signed"] with input as {
        "review": {"object": {"spec": {"containers": [{"image": "untrusted:v1"}]}}},
        "data": {"signed_images": ["recs:v1"]}
    }
}

test_allow_signed {
    count(deny) == 0 with input as {
        "review": {"object": {"spec": {"containers": [{"image": "recs:v1"}]}}},
        "data": {"signed_images": ["recs:v1"]}
    }
}

test_deny_mixed {
    count(deny) == 1 with input as {
        "review": {"object": {"spec": {"containers": [
            {"image": "recs:v1"},
            {"image": "untrusted:v1"}
        ]}}},
        "data": {"signed_images": ["recs:v1"]}
    }
}
```

## Format

Produce one Rego file per policy with the structure above.
Include a top-level `README.md` listing the policies:

```
# SmartRecs Policy Library

## Policies

| Package | Purpose | Enforcement |
|---|---|---|
| security.images.signed | Cosign signature required | Gatekeeper admission |
| security.images.no_latest | No :latest tags | Gatekeeper admission + Conftest |
| ...

## How to test
opa test policies/

## How to deploy
(Reference Exercise 5 for bundle distribution.)
```

## Quality criteria

A passing library:

- 5+ policies with **real Rego syntax** (not pseudo).
- Each has 3+ tests covering at least one happy path and two
  failure modes.
- Tests pass under `opa test`.
- Documentation per policy explaining what and why.

A failing library:

- Pseudo-Rego that wouldn't parse.
- Tests cover only happy path.
- No documentation.
- Policies that don't address SmartRecs threats.

## Reflection questions

1. Which policy was hardest to write correctly?
2. Which test caught a bug in your initial implementation?
3. The team wants to add a 6th policy: "every Pod must have a
   `cost-budget` annotation in the format `$N.NN`". Write the
   skeleton, identify where Rego is awkward.
