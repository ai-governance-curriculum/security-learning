# Module 09 — Policy as Code

> **Note on AI-assisted content.** Drafted with AI assistance and
> under human review. OPA, Gatekeeper, Kyverno, and Rego specifics
> evolve; verify with current upstream docs before relying on
> exact syntax. See [`resources.md`](./resources.md).

---

## 1. Why policy as code

The pattern problem: policies are normally written in three
different forms — Kubernetes YAML for admission, application
code for authorization, English-language docs for everything
else. Each diverges. The single source of truth becomes "ask
the person who wrote it."

Policy as code consolidates:

- One **declarative language** for policy.
- Policies **versioned in Git** alongside other code.
- **CI tests** prove policies do what they claim.
- **Distribution** is a build-and-deploy step.
- **Audit** is queryable: every decision produces an evidence
  trail.

The benefits compound: when a policy is "the Rego file at
`policies/security/network/no-public-egress.rego`," everyone
knows where it is, how it's tested, and how to change it.

### 1.1 Three control planes for policy

In an ML platform, policy applies at three points:

| Control plane | What it gates | When |
|---|---|---|
| **CI** | Image builds, deployment manifests, IaC | Pre-merge / pre-deploy |
| **Admission** | What enters the cluster | At `kubectl apply` time |
| **Runtime** | What happens after admission | Continuously |

A defensible posture uses **all three**. Each catches different
classes of issues. CI catches "the YAML you wrote is wrong";
admission catches "what's being applied violates a policy";
runtime catches "what the workload actually does violates a
policy."

This module focuses on CI + admission. Runtime is Module 08's
territory (with overlap via Tetragon's enforcement features).

---

## 2. Open Policy Agent (OPA)

OPA is the general-purpose policy engine. CNCF graduated. The
core architecture:

- **OPA evaluates policies** written in Rego.
- **Inputs** are JSON-serializable data (an admission review,
  a Terraform plan, an HTTP request).
- **Outputs** are JSON-serializable decisions (allow / deny,
  plus rationale).
- **OPA can be deployed** as a library (in-process), as a
  sidecar, as a service, or via specific integrations
  (Gatekeeper, Conftest).

### 2.1 The OPA mental model

A Rego policy is a set of **rules** evaluated against an
**input** + **data** context. Rules either produce values or
fail to match. The set of values produced is the decision.

```rego
package admission

deny[msg] {
    input.kind == "Pod"
    input.spec.containers[_].image == "nginx:latest"
    msg := "Containers must not use 'latest' tag"
}
```

This rule says: if the input is a Pod and any container image
is `nginx:latest`, add the message to the `deny` set. The
caller then checks: if `deny` is non-empty, the admission is
rejected.

### 2.2 Where OPA lives

| Deployment shape | When it fits |
|---|---|
| **Library** (embedded in your service) | Authorization decisions in your application code |
| **Sidecar** (each pod has an OPA) | Per-request authorization with low latency |
| **Service** (OPA as a deployment) | Shared policy evaluation across many services |
| **Gatekeeper** (Kubernetes admission) | Cluster admission control |
| **Conftest** (CLI) | CI policy gates |

The same Rego rules can drive multiple deployment shapes.
That's the strategic advantage: policy is portable across
where it's enforced.

---

## 3. Rego: the policy language

Rego is a declarative logic language designed for policy. It's
not Python, not JSON, not HCL. The learning curve is real but
moderate.

### 3.1 Core syntax

A Rego file:

```rego
package security.admission

import future.keywords.in

# Default decision
default allow := false

# Rule: allow if all conditions match
allow {
    input.user.role == "admin"
}

# Rule: deny with message
deny[msg] {
    not has_required_label
    msg := "Pod must have 'owner' label"
}

# Helper rule
has_required_label {
    input.metadata.labels.owner != ""
}
```

Key concepts:

- **`package`** declares the namespace.
- **`default`** sets a value when no rule produces one.
- **Rules** are sets of conditions that must all hold for the
  rule to "match."
- **The `[msg]` syntax** indicates the rule produces a set; if
  the conditions match, `msg` is added to the set.
- **Variables** with names starting with uppercase are scope-
  local; lowercase are package-level.

### 3.2 The trickiest concepts

#### Iteration over collections

```rego
# Check all containers, deny if any has issue
deny[msg] {
    container := input.spec.containers[_]
    container.image == "untrusted/badimage"
    msg := sprintf("Container %s uses untrusted image", [container.name])
}
```

The `[_]` indexes iterate over collections. Rego's "for any
matching element" pattern.

#### Negation

```rego
# Allow if the pod has a "scanned: true" annotation
allow {
    input.metadata.annotations["security/scanned"] == "true"
}

# Deny if the annotation is missing
deny[msg] {
    not input.metadata.annotations["security/scanned"]
    msg := "Image must be scanned before deployment"
}
```

`not` works on rule bodies, not on values directly. This trips
up beginners.

#### Sets vs. lists

A rule defined with `[msg]` produces a *set*. Order doesn't
matter. Useful for collecting denial reasons.

#### `with` statements (for testing)

```rego
# Test: deny rule fires when annotation is missing
test_deny_missing_annotation {
    deny["Image must be scanned before deployment"] with input as {
        "kind": "Pod",
        "metadata": {"annotations": {}}
    }
}
```

Tests in Rego use the same language as policies. Run with
`opa test`.

### 3.3 What Rego does well

- **Declarative** — you describe what's allowed, not how to
  check.
- **Portable** — same rules across all OPA deployment shapes.
- **Testable** — `opa test` runs `test_*` rules.
- **Performant** — partial evaluation, indexing optimizations.

### 3.4 What Rego is bad at

- **Stateful computation** — Rego is pure-functional;
  multi-step processes are awkward.
- **Loops with side effects** — there aren't any.
- **External data fetching** — possible via "external data"
  features but adds complexity.
- **String manipulation** beyond basics.

When the policy logic gets imperative, consider whether OPA is
the right tool.

---

## 4. Gatekeeper

Gatekeeper is OPA packaged for Kubernetes admission. The
canonical Kubernetes admission controller for OPA.

### 4.1 How it works

- Gatekeeper installs as a Kubernetes admission webhook.
- **ConstraintTemplates** define reusable policy logic in Rego.
- **Constraints** instantiate templates with parameters.
- When a resource is created/modified, Gatekeeper evaluates
  constraints and either allows or denies.

### 4.2 Constraint authoring

ConstraintTemplate:

```yaml
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: k8srequiredlabels
spec:
  crd:
    spec:
      names:
        kind: K8sRequiredLabels
      validation:
        openAPIV3Schema:
          type: object
          properties:
            labels:
              type: array
              items:
                type: string
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package k8srequiredlabels

        violation[{"msg": msg, "details": {"missing_labels": missing}}] {
          provided := {label | input.review.object.metadata.labels[label]}
          required := {label | label := input.parameters.labels[_]}
          missing := required - provided
          count(missing) > 0
          msg := sprintf("missing required labels: %v", [missing])
        }
```

Constraint:

```yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequiredLabels
metadata:
  name: ns-must-have-owner-and-team
spec:
  match:
    kinds:
      - apiGroups: [""]
        kinds: ["Namespace"]
  parameters:
    labels:
      - "owner"
      - "team"
```

### 4.3 Operating Gatekeeper

- **Audit mode** vs. **enforce mode** — constraints can audit
  existing resources for violations without enforcing.
- **`enforcementAction: dryrun`** — log violations; admit
  anyway.
- **Library** of pre-built ConstraintTemplates: the [Gatekeeper
  Library](https://open-policy-agent.github.io/gatekeeper-library/).

### 4.4 Gatekeeper gotchas

- **`namespaceSelector` / `match.namespaceSelector`** —
  excluding system namespaces is critical; otherwise you can
  brick your cluster.
- **Mutation features** require a separate Gatekeeper Mutation
  component.
- **Per-policy Rego is in YAML strings** — formatting and
  debugging is awkward.

---

## 5. Kyverno

Kyverno is the alternative Kubernetes admission controller.
Its key differentiator: **policies are written in YAML, not in
a separate language**.

### 5.1 The policy shape

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-labels
spec:
  validationFailureAction: Enforce
  rules:
    - name: check-required-labels
      match:
        resources:
          kinds:
            - Namespace
      validate:
        message: "Namespaces must have 'owner' and 'team' labels"
        pattern:
          metadata:
            labels:
              owner: "?*"
              team: "?*"
```

The same constraint as the Gatekeeper example, in YAML.

### 5.2 Kyverno's capabilities

- **Validation** — accept / reject.
- **Mutation** — modify resources at admission (inject
  defaults, labels, annotations).
- **Generation** — automatically create related resources
  (e.g., create a default NetworkPolicy when a namespace is
  created).
- **Image verification** — built-in Cosign integration for
  signature verification.

### 5.3 Gatekeeper vs. Kyverno

| Factor | Gatekeeper | Kyverno |
|---|---|---|
| **Policy language** | Rego (powerful, learning curve) | YAML patterns + custom verbs |
| **Mutation** | Separate component | Built-in |
| **Generation** | No | Yes |
| **Image verification** | Via custom Rego | Built-in Cosign verb |
| **Performance** | Generally good | Generally good |
| **OPA portability** | Yes (Rego works elsewhere) | No (Kyverno-specific) |
| **Library** | Curated library exists | Curated library exists |
| **Learning curve** | Steeper (Rego) | Shallower (YAML) |

The honest defaults:

- **Pick Kyverno** if your team is Kubernetes-native, doesn't
  need Rego elsewhere, and wants the lower learning curve.
- **Pick Gatekeeper** (and Rego) if you also need policy
  outside Kubernetes (CI gates, terraform validation,
  application authorization), since Rego works there too.

For SmartRecs-scale teams: Kyverno is usually the right pick.
For larger orgs running OPA in many places: Gatekeeper provides
language consistency.

---

## 6. Conftest: policies in CI

Conftest evaluates configuration files against Rego policies.
The CI-friendly OPA tool.

### 6.1 The flow

```bash
# Check Kubernetes manifests
conftest test deploy/*.yaml --policy policies/

# Check Terraform plan
terraform plan -out=plan.binary
terraform show -json plan.binary | conftest test --policy policies/

# Check Dockerfile
conftest test Dockerfile --parser dockerfile --policy policies/
```

The exit code is non-zero on policy violation; the CI fails the
build.

### 6.2 What goes in CI policy

Pre-merge checks that catch issues before they hit admission:

- **No `:latest` image tags.**
- **No `imagePullPolicy: Always` for production deployments**
  (use a digest reference).
- **No `hostPath` mounts.**
- **All resources have required labels.**
- **Terraform changes don't open security groups to 0.0.0.0/0.**
- **Dockerfile doesn't run as root.**

A CI policy that catches an issue is cheaper than a runtime
policy that catches it after deploy.

### 6.3 Layering with admission

If both CI and admission enforce the same policy, the CI step
is the **fast feedback loop**; the admission step is the
**hard gate**. CI fails: fix and re-push. Admission fails:
some bypass path got through; investigate.

The policies should be **the same** in both places, defined
once. Diverging policies between CI and admission is a
maintenance nightmare.

---

## 7. Policy testing

Untested policies fail in production. Three layers of testing:

### 7.1 Unit tests in Rego

`opa test` runs `test_*` rules:

```rego
test_deny_latest_tag {
    deny[_] with input as {
        "kind": "Pod",
        "spec": {"containers": [{"image": "nginx:latest"}]}
    }
}

test_allow_pinned_tag {
    count(deny) == 0 with input as {
        "kind": "Pod",
        "spec": {"containers": [{"image": "nginx:1.25.3"}]}
    }
}
```

Each `test_*` rule should test one behavior. Cover happy paths,
violation paths, edge cases.

### 7.2 Integration tests

Deploy the policy to a test cluster; apply known-bad and
known-good resources; verify the policy decisions.

Tools: `kube-test`, custom scripts, the Gatekeeper / Kyverno
test frameworks.

### 7.3 Conformance tests

Before a major policy change goes to production:

- Run against a known corpus of production resources.
- Identify resources that would have been rejected.
- Decide: tolerate (warn-mode period), exempt explicitly, or
  reject (and fix the resources).

---

## 8. Policy distribution

Where do the policies live, and how do they get to the engines?

### 8.1 Bundles

OPA can consume **bundles** — signed `.tar.gz` packages of
Rego files + data. Bundles are pulled from an HTTP server (S3,
a custom registry, etc.).

The pattern:

1. Policies live in Git.
2. CI builds bundles on merge to main.
3. CI signs bundles (Cosign — Module 03).
4. CI pushes bundles to a bundle server.
5. OPA / Gatekeeper / Kyverno deployments pull bundles
   periodically.

This is the **policy supply chain**. It needs the same controls
as your code supply chain (Module 10): signatures, provenance,
audit.

### 8.2 GitOps for policies

Alternative: policies live in Git, ArgoCD / FluxCD syncs them
to clusters. Same supply-chain considerations apply.

### 8.3 Centralization vs. federation

Two patterns:

- **Centralized**: one Git repo holds all policies; one bundle
  per cluster; tight platform-team control.
- **Federated**: per-team policies layered on platform-team
  baselines.

Most production deployments use **federated**: the platform
team's baseline policies are mandatory; team-specific policies
add tighter restrictions.

---

## 9. ML-specific policy patterns

Where policy as code adds concrete value in an ML platform.

### 9.1 Model promotion gate

```rego
package mlops.promotion

import future.keywords.in

# Allow promotion only if:
# - Model is signed (Cosign)
# - Validation evidence shows accuracy meets threshold
# - Fairness metrics show no protected-class regression > 1pp
# - Promotion is approved by a human in the registry

allow {
    has_valid_signature
    accuracy_meets_threshold
    no_fairness_regression
    has_human_approval
}

deny[msg] {
    not has_valid_signature
    msg := "Model artifact must have a valid Cosign signature"
}

deny[msg] {
    not accuracy_meets_threshold
    msg := sprintf(
        "Accuracy %.2f below threshold %.2f",
        [input.model.validation.accuracy, input.policy.accuracy_threshold]
    )
}

# etc.
```

The policy lives in Git, runs in the promotion pipeline (CI) or
in an admission webhook, and produces audit evidence.

### 9.2 Training-data governance

Constraints on training data:

- All datasets used in training must have provenance
  attestation.
- Datasets containing PII must have a documented retention
  policy.
- Datasets must be classified before being used for training.

A policy gate at training-job submission:

```rego
package mlops.training

deny[msg] {
    dataset := input.spec.datasets[_]
    not dataset.provenance
    msg := sprintf("Dataset %s missing provenance", [dataset.name])
}

deny[msg] {
    dataset := input.spec.datasets[_]
    dataset.classification == "regulated"
    not dataset.retention_policy
    msg := sprintf("Regulated dataset %s missing retention policy", [dataset.name])
}
```

### 9.3 Prompt routing (LLM platforms)

For LLM platforms, policy decides which model handles which
request:

```rego
package llm.routing

# Free-tier customers get llama-3-8b
choose_model = "llama-3-8b" {
    input.customer.tier == "free"
}

# Pro-tier with PII in prompt gets the PII-redacted path + GPT-4
choose_model = "gpt-4-with-redaction" {
    input.customer.tier == "pro"
    input.prompt_analysis.contains_pii
}

# Enterprise customers with healthcare data routed to a
# regional model under BAA
choose_model = "claude-3-on-aws-baa" {
    input.customer.tier == "enterprise"
    input.customer.compliance_class == "healthcare"
}
```

The routing logic is auditable, testable, and changeable
without code deploys.

### 9.4 Tenant isolation policy

The application-layer authorization gap from Modules 02 and 04
gets solved here:

```rego
package multitenant.feature_store

allow {
    input.caller.tenant == input.request.tenant_id
}

deny[msg] {
    input.caller.tenant != input.request.tenant_id
    msg := sprintf(
        "Caller tenant %s cannot access tenant %s features",
        [input.caller.tenant, input.request.tenant_id]
    )
}
```

The feature store calls OPA (sidecar) per request; OPA evaluates
the tenant-isolation policy; allows or denies.

---

## 10. Migrating from ad-hoc to policy as code

You start with policies in:

- Confluence pages.
- Hand-written Kubernetes YAML.
- Code reviewer's heads.
- Slack threads.

You want to end with policies in:

- Git, version-controlled.
- Rego (or Kyverno YAML).
- CI-tested.
- Distributed via bundles.

The migration is multi-quarter. The phases:

### 10.1 Phase 1 — Codify what exists

Pick the policies that are most often violated. Codify them in
Rego or Kyverno. Run in `warn` mode (no enforcement yet).
Observe violations. Tune.

### 10.2 Phase 2 — CI gates

For new code, add policy gates in CI. New violations are
caught pre-merge. Old violations remain.

### 10.3 Phase 3 — Admission warn → enforce

Move codified policies from `warn` to `enforce`. Catch
violations at deploy time. Existing violations get fixed as
they're re-deployed.

### 10.4 Phase 4 — Coverage expansion

Add policies for things that weren't enforced before. The
infrastructure is in place; new policies are now cheap.

### 10.5 Phase 5 — Steady state

Policies are part of the development workflow. Adding a new
policy is a PR. Removing one is a PR. Auditors can read the
Git history and see the policy posture over time.

---

## 11. Operational concerns

### 11.1 Policy failures must not break clusters

A buggy policy can reject all admissions. Mitigations:

- **`enforcementAction: dryrun`** in production initially.
- **`failurePolicy: Ignore`** on the admission webhook
  configuration (lets pods admit if the webhook is down).
- **Health checks** on the policy engine.
- **Tested rollback**.

### 11.2 Policy evaluation latency

Admission webhooks are in the path of every `kubectl apply`. A
slow policy slows your deploys. Profile and tune.

OPA's partial evaluation is the main optimization tool — for
common decisions, pre-compute as much as possible.

### 11.3 Auditing policy decisions

Every decision should be auditable. The hash-chain audit log
(Module 03) is the substrate. Per-decision entry: who tried to
do what, what was decided, by which policy.

### 11.4 Policy ownership

Different policies have different owners:

- **Platform team**: cluster-wide baseline (no privileged
  containers, all images signed).
- **Security team**: security-specific constraints (no
  cloud-metadata egress, no `latest` tags).
- **Application team**: app-specific business rules.

A federated model gives each owner their own policy files;
RBAC controls who can modify what.

---

## 12. What you should be able to do after this module

- [ ] Choose between Gatekeeper and Kyverno for a given context
      and defend the choice.
- [ ] Author a Rego policy with conditions, helpers, and
      tests.
- [ ] Write a Kyverno ClusterPolicy that validates and mutates.
- [ ] Set up Conftest in a CI pipeline.
- [ ] Author at least 3 ML-specific policies (promotion gate,
      training-data governance, tenant isolation).
- [ ] Plan the migration from ad-hoc policies to policy as
      code.
- [ ] Operate a policy engine with proper failure modes and
      audit integration.

---

## 13. What this module deliberately doesn't cover

- **Generic OPA application authorization patterns** — covered
  in OPA's documentation; same principles apply.
- **Specific Terraform policy modules** (Sentinel, CloudGuard,
  etc.) — out of scope; same Rego works via Conftest on
  `terraform show -json`.
- **Detection rules** — Module 11.
- **Specific commercial platforms** — Styra DAS, Snyk Policies
  for OPA are products that build on the principles here.

---

## 14. Suggested reading order

After this:

1. Read the [OPA documentation](https://www.openpolicyagent.org/docs/latest/).
2. Read the [Gatekeeper library](https://open-policy-agent.github.io/gatekeeper-library/).
3. Read the [Kyverno policy library](https://kyverno.io/policies/).
4. Try `opa test` on a policy you authored.
5. Move to **Module 10: Supply Chain Security**.

---

## Appendix A — Glossary

- **Conftest**: CLI tool for evaluating configuration files
  against Rego policies in CI.
- **Constraint** (Gatekeeper): an instantiation of a
  ConstraintTemplate with specific parameters.
- **ConstraintTemplate** (Gatekeeper): a reusable policy
  defined in Rego.
- **Gatekeeper**: Kubernetes admission controller built on OPA.
- **Kyverno**: Kubernetes admission controller with YAML-based
  policies.
- **OPA**: Open Policy Agent. CNCF general-purpose policy engine.
- **Policy bundle**: signed package of Rego policies + data.
- **Rego**: OPA's policy language.

---

## Appendix B — Common misconceptions

| Misconception | Reality |
|---|---|
| "We have admission policies, so we have policy as code." | Policy as code means *versioned, tested, distributed*. Random admission webhooks in a cluster don't count. |
| "Rego is too hard; let's just use YAML." | Kyverno YAML is fine for simple validation. Beyond simple, you need Rego (or something equivalent). |
| "Policies should be enforced everywhere immediately." | Phased rollout (warn → audit → enforce) is the only safe path. |
| "Policy decisions are obvious; we don't need tests." | Untested policies fail in unexpected ways. Test like any other code. |
| "Policy engines are reliable; they won't fail." | They can and do. `failurePolicy: Ignore` + health checks are essential. |
| "Centralized policy is better." | Federated policy (platform baseline + team additions) is what scales. |

---

*Continue to the [exercises](./exercises/) when you're ready.*
