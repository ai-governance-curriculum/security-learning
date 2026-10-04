# Exercise 01 — SLSA-for-Models Level-Up Plan

**Estimated effort:** ~3 hours
**Deliverable:** A committed SLSA-level-up bundle for one
real (or realistic) training pipeline consisting of
(a) a **current-state assessment** against SLSA v1.0 Build-
track requirements, with each L1 / L2 / L3 row marked
*met / partial / not-met* and justified from observable
evidence, (b) a **target state** (claimed level and the
specific producer / platform / provenance rows that
support it), (c) a **gap plan** of concrete engineering
tasks sized to close the delta, with owners, dependencies,
and sequencing, (d) a **sample SLSA Provenance v1 predicate
document** representing what the pipeline would emit at
target state, (e) an **admission-side verification sketch**
showing how the model registry and deployment admission
controller would consume the provenance, and (f) a one-
page **risk-and-non-goal statement** stating what the plan
does and does not buy.
**Prerequisites:** Chapter 01 read end-to-end; chapter 02
read for the signing / admission context. Access to one
training pipeline (your own; or a realistic reference
pipeline you can model from — Kubeflow Pipelines, Argo
Workflows, SageMaker Training Jobs, Vertex AI custom
training). Familiarity with the in-toto Attestation
specification and the SLSA Provenance v1 predicate shape.

---

## Objective

Chapter 01's claim is that a model training pipeline is a
*build system* in SLSA's sense, and that L1 / L2 / L3 are
answered by walking a short checklist against observable
properties of the pipeline. This exercise is the exercise
that runs that walk honestly, produces a defensible claimed
level, and plans the work to raise it.

By the end of this exercise you have:

- A **current-state checklist** against every SLSA v1.0
  Build-track requirement, grounded in a specific pipeline.
- A **claimed-level** statement (`L1` / `L2` / `L3`) that
  is the *minimum* row met across producer, build platform,
  and provenance — not aspiration.
- A **target-level** statement with per-row engineering
  tasks sized at the 1–4 week level.
- A **sample provenance document** your target pipeline
  would emit (populated with placeholder but
  *schema-compliant* fields).
- An **admission-side sketch** that names the registry
  and deployment-controller policies the provenance will
  be verified against.
- A **risk-and-non-goal statement** disclaiming what SLSA
  does not address (weight-space backdoors, dataset
  content poisoning, model behavioural safety) so the
  reader of the plan does not mistake it for a complete
  model-security answer.

You are **not** implementing the plan end-to-end in this
exercise. You are producing the assessment, the plan, and
the artefacts the plan will produce when run.

---

## Problem statement

Pick one training pipeline. If you work on an ML platform,
pick a real pipeline you can observe. If you do not, pick
one of the common reference shapes and state the shape:

- **Kubeflow Pipelines or Argo Workflows on a shared GKE /
  EKS / AKS cluster** — a `PipelineRun` CRD; steps as
  containers; artefacts in object storage.
- **SageMaker Training Jobs** — one `TrainingJob` per run;
  managed; attestable via CloudTrail + S3.
- **Vertex AI custom training** — `CustomJob` resource;
  managed; Google-service-account identity; artefacts in
  GCS.
- **Ray Train / Determined / Kubeflow Training Operator**
  — distributed training on a managed cluster.

State before you start:

- Pipeline name and shape (one of the above or a specific
  variant).
- What the pipeline produces: a single OCI image, a
  directory of weight files, a safetensors artefact, a
  Keras model, etc.
- Where it writes outputs: an OCI registry, GCS / S3, a
  Hugging Face internal mirror.
- Who the *producer* is (the ML team / owner).
- Who the *build platform* is in SLSA terms (the managed
  service; the self-hosted controller; the shared
  Kubernetes namespace).
- The identity model: workload identity on the training
  compute; the OIDC issuer for that identity.

If the pipeline is hypothetical, say so and model it
explicitly — the goal is a defensible plan, not a fictional
success story.

---

## Requirements

### Deliverable A — current-state assessment

Walk the Build-track levels. For each requirement, mark
*met / partial / not-met* and justify.

Suggested layout — a Markdown table or YAML document:

```yaml
pipeline:
  id: fraud-classifier-training
  shape: argo-workflows-on-shared-gke
  identity: ksa://training/training-runner (OIDC: Vertex / GitHub Actions / internal)
  outputs: safetensors in OCI registry

producer:
  build_definition_in_vcs:
    status: met
    evidence: "github.com/company/ml-pipelines/pipelines/fraud/*.yaml, PR history, protected branch."
  artifact_identifier:
    status: met
    evidence: "OCI image digest sha256:... emitted by step 'promote'."

build_platform_l1:
  provenance_emitted:
    status: partial
    evidence: "Argo WorkflowStatus records parameters and container images. No in-toto document is produced today."
    notes: "A separate controller writes JSON to s3://..., but it is not SLSA v1 predicate shape."

build_platform_l2:
  hosted_platform:
    status: met
    evidence: "Shared cluster; not self-hosted by scientist."
  provenance_signed:
    status: not-met
    evidence: "Current JSON output is unsigned."

build_platform_l3:
  build_isolation:
    status: not-met
    evidence: "Pipelines share the 'training' namespace. ServiceAccount is shared across runs."
  provenance_not_user_writeable:
    status: not-met
    evidence: "The 'promote' step itself writes the JSON output and signs with the KSA. User-authored code paths can therefore control the fields."
  ephemeral_builder:
    status: partial
    evidence: "Pods are ephemeral but node filesystem is shared across pod lifecycle on each node."
  non_falsifiable_provenance:
    status: not-met
    evidence: "No platform-observed input-fetch metadata is emitted today."

provenance_contents_l1:
  slsa_v1_schema:
    status: not-met
    evidence: "Current output is custom shape; not SLSA Provenance v1 predicate."

provenance_contents_l2:
  signed:
    status: not-met
    evidence: "Not signed."

provenance_contents_l3:
  resolved_dependencies_source:
    status: not-met
    evidence: "Dataset ref is passed as a parameter by the user; recorded as self-reported."

claimed_level: L0 (operational); L1-pending on the attestation-controller rollout.
```

Rules:

- **Evidence is observable.** "The pipeline is secure" is
  not evidence; "the Argo WorkflowStatus does not emit an
  in-toto document today" is.
- **"Partial" is a signal, not a verdict.** Partial rows
  get a task in the gap plan.
- **No overclaiming.** The claimed level is the *minimum*
  level fully met across producer, platform, and
  provenance.

### Deliverable B — target-state statement

A short statement:

- **Target level** (`L1` / `L2` / `L3`).
- **Why this level, not higher.** L3 is expensive; a
  programme that currently produces no provenance moving
  to L2 in one plan cycle is realistic; L3 in one cycle
  usually is not. Name the realistic ceiling for the plan
  horizon (90 days? one quarter? one year?).
- **What the target level does *not* buy.** L2 defeats
  registry-write attackers; it does not defeat a
  compromise of the training identity. Say so.

### Deliverable C — the gap plan

A numbered list of engineering tasks that together close
the gap. Shape per task:

```yaml
- id: gap-01
  title: "Deploy an attestation controller as a sibling to the Argo workflow"
  rationale: "Decouple provenance generation from the training step; move signing identity out of reach of user-authored code."
  acceptance:
    - "A new controller watches WorkflowStatus completion."
    - "On completion, controller reads container digests, parameter values, resolved dataset manifest hash, and output digest from the status object."
    - "Controller emits a SLSA Provenance v1 in-toto Statement; signs via a dedicated OIDC identity (not the training KSA)."
    - "Attestation lands in the OCI registry as a companion tag to the artefact digest."
  owner: "ML Platform team"
  effort: "~2 weeks"
  dependencies:
    - "Fulcio / internal OIDC trust bundle rolled out (chapter 02)."

- id: gap-02
  title: "Move dataset resolution out of the training step"
  rationale: "L3 wants resolvedDependencies to be platform-observed, not script-self-reported."
  acceptance:
    - "A new 'resolve-inputs' step runs with its own identity (no training identity)."
    - "This step pulls datasets by snapshot ID and emits a resolved-inputs manifest."
    - "The training step mounts the resolved manifest read-only; it cannot change the recorded hashes."
  owner: "Data Platform team"
  effort: "~3 weeks"
  dependencies: []

# ...and so on
```

Rules:

- **Tasks are specific and sized.** "Improve the pipeline"
  is not a task; "deploy an attestation controller" is.
- **Owner names a team, not a person.** Reality: people
  change teams; the plan is read six months later.
- **Dependencies are named.** A task that depends on
  Fulcio / internal OIDC should say so; otherwise the plan
  looks sequenceable when it isn't.
- **Tasks that cannot be done in the plan horizon are
  listed as "post-plan".** Honest.

### Deliverable D — sample SLSA Provenance v1 predicate

A JSON document, schema-compliant with
`https://slsa.dev/provenance/v1`, that represents what
the pipeline *will emit* at target state. Populate every
required field; mark placeholder values clearly:

```json
{
  "_type": "https://in-toto.io/Statement/v1",
  "predicateType": "https://slsa.dev/provenance/v1",
  "subject": [
    { "name": "registry.company.com/models/fraud-classifier", "digest": { "sha256": "abcd..." } }
  ],
  "predicate": {
    "buildDefinition": {
      "buildType": "https://company.com/build-types/argo-training/v1",
      "externalParameters": {
        "pipeline_ref": "git+https://github.com/company/ml-pipelines@v42",
        "dataset_ref": "data:ticket-corpus@v3",
        "base_model_ref": "model:distilbert-base@6cdc0aad3",
        "seed": 42
      },
      "internalParameters": {
        "argo_workflow_uid": "ABCD-EFGH-1234-5678",
        "runner_pool": "training-us-east-01"
      },
      "resolvedDependencies": [
        { "name": "data:ticket-corpus@v3", "digest": { "sha256": "ef12..." }, "mediaType": "application/vnd.ticket-corpus+manifest" },
        { "name": "model:distilbert-base@6cdc0aad3", "digest": { "sha256": "..." }, "mediaType": "application/vnd.oci.image.manifest.v1+json" },
        { "name": "container:pytorch@2.4-cuda12.1", "digest": { "sha256": "..." }, "mediaType": "application/vnd.oci.image.manifest.v1+json" }
      ]
    },
    "runDetails": {
      "builder": {
        "id": "https://argo.company.com/controllers/attestation/v1",
        "version": { "attestation-controller": "1.4.2" }
      },
      "metadata": {
        "invocationId": "run-20261004-abcde",
        "startedOn": "2026-10-04T15:02:00Z",
        "finishedOn": "2026-10-04T22:14:33Z"
      },
      "byproducts": [
        { "name": "training-log", "uri": "s3://logs/run-20261004-abcde/stdout.log.gz", "digest": { "sha256": "..." } }
      ]
    }
  }
}
```

Rules:

- **Schema compliance.** Validate the JSON against the
  SLSA Provenance v1 schema (project publishes a JSON
  Schema). State the validator used.
- **No PII.** Dataset references by hash; parameters are
  identifiers, not data.
- **`builder.id` is distinct from the training-step
  identity.** The controller is the builder; the training
  pod is a build-step input.
- **Placeholders marked.** Use `"abcd..."`-style placeholders
  only; mark the sample as `example — not from a real run`.

### Deliverable E — admission-side verification sketch

A one-to-two-page sketch:

- **Where verification runs.** The model registry's admission
  webhook; the deployment admission controller (sigstore
  policy-controller on the serving cluster); any
  intermediate promotion gates.
- **What is verified.** The cosign-verifiable signature on
  the attestation + the content policy against the
  predicate (chapter 02's "verify + policy" pattern).
- **The policy content.** For example, a Rego or CUE
  policy stating:
  - `predicate.buildDefinition.buildType` must equal the
    expected buildType for the model's class.
  - `predicate.runDetails.builder.id` must be on the
    org's approved-builder list.
  - `predicate.buildDefinition.resolvedDependencies` must
    reference dataset hashes present in the approved-
    dataset register.
  - `predicate.buildDefinition.externalParameters.
    base_model_ref` must have its own signed intake
    attestation (chapter 05).
- **Failure behaviour.** How a failed verification is
  surfaced (registry rejects the push; serving admission
  denies the Pod; a human-readable reason is logged).
- **Exception path.** Who can sign a time-boxed exception,
  how it is audited (mod-109 chapter 04 pattern).

### Deliverable F — risk-and-non-goal statement

A one-page statement:

- **What SLSA L2/L3 defeats.** Registry-write attackers;
  build-definition-tampering attackers (L3 only); some
  classes of insider attacks on the build pipeline.
- **What SLSA does not defeat.** Weight-space backdoors;
  training-data poisoning; model behavioural failures;
  licence violations in training data; compromise of the
  signing identity itself.
- **What SLSA shares with the rest of the stack.** Points
  to the signing stack (chapter 02), the ML-BOM
  (chapter 03), the scanning stack (chapter 04), the
  intake runbook (chapter 05), the policy pack (mod-109
  chapter 04), the eval system (mod-106), and the
  behavioural evaluations (mod-104 chapter 06).

The non-goal statement exists because readers of the plan
will otherwise mistake "we got to L3" for "the model is
safe". The plan is a *build-integrity* plan, not a model-
safety plan.

---

## Starter guidance

- **Walk the current pipeline before writing anything.**
  The temptation is to produce the plan from the chapter;
  the plan is only useful if the current-state assessment
  is honest.
- **Prefer the attestation-controller pattern** (gap-01 in
  the sample) early in the plan. It is the single step
  that unblocks L2 and starts L3; downstream rows depend
  on it.
- **Pin container images by digest in every row.** The
  current state often has `tags`; the plan says `digests`;
  the attestation references the digest. All three say
  the same thing or the attestation lies.
- **Record every input the training step reads.** A step
  that lists parameters is halfway to recording them;
  attestations need observed, resolved inputs.
- **Separate signing identities early.** The training
  identity cannot sign the attestation. If today it does,
  the top of the gap plan is the KSA split.
- **Use the sigstore trust root the organisation uses.**
  Chapter 02 covered public vs private; the plan's
  verifier reference is whichever your org pins.
- **Schedule the non-goals section as its own section.**
  If the plan is read by a stakeholder who thinks SLSA ==
  "model is safe", the non-goals section is the correction.

---

## Acceptance criteria

A passing bundle:

- Current-state assessment walks each SLSA v1 Build-track
  requirement, with evidence per row (not just a status
  flag).
- Target-state statement names a defensible level and the
  rationale for not aiming higher within the plan horizon.
- Gap plan has sized, owned, dependency-aware tasks that
  together close the delta.
- Sample provenance JSON validates against the SLSA v1
  schema; `builder.id` is distinct from the training-step
  identity; no PII in parameters.
- Admission-side verification sketch names the specific
  policy content and failure behaviour.
- Risk-and-non-goal statement names what SLSA does and
  does not address.

A failing bundle:

- Current state is "we are at L1 because we have a CI
  pipeline" without evidence.
- Target state is "L3" without a plan for isolation or
  provenance-not-user-writeable.
- Gap plan is a list of principles ("improve
  reproducibility") rather than engineering tasks.
- Provenance JSON omits `resolvedDependencies` or carries
  `latest` tags.
- Admission sketch is "we verify the signature" without
  content policy.
- Non-goals section asserts SLSA is sufficient model
  security.

---

## Stretch goals

- **Policy-pack extension.** Convert the admission sketch
  into a Rego or CUE policy under mod-109 chapter 04's
  pack. Test with positive and negative inputs.
- **Hermeticity hardening.** Add tasks that pin the Python
  lockfile with hashes, run the training step with network
  egress disabled, and populate a local wheelhouse at
  build time.
- **Behavioural-reproducibility floor.** Define a
  behavioural-reproducibility SLO (same inputs → metrics
  within tolerance on held-out set) and wire a CI
  reproducibility test that enforces it.
- **Transparency-log choice.** For organisations running
  a private Rekor, document the trust-bundle rollout and
  the key-rotation plan.
- **SLSA L3 Isolation sprint.** Separate deliverable
  scoping the per-run isolation work (Firecracker,
  per-run VMs, dedicated node pools with taints) with its
  own cost and risk discussion.
- **Multi-pipeline portfolio.** Repeat the assessment for
  a second pipeline (recommender; LLM fine-tune;
  computer-vision model) and compare the gap plans;
  identify shared controller / policy work.
- **Vendor assessment.** If the training is on a managed
  service (SageMaker, Vertex), produce a one-page
  assessment of what SLSA level the service itself claims
  and what the gap is between the service's floor and the
  organisation's target.

---

## Do not

- Do not claim a level the current state does not support.
  Honest L0 is better than mis-claimed L2.
- Do not treat SLSA as the model-safety story. It is one
  of several stories; the risk-and-non-goal statement is
  the correction.
- Do not conflate container-image signing with model-
  artefact signing. The container is one input; the model
  artefact is the output; both need signatures and
  attestations.
- Do not store the attestation beside the artefact in a
  bucket a build-step identity can write to. Attestations
  go through the signing identity and are stored
  content-addressed; chapter 02 is the mechanism.
- Do not treat `main` or `latest` as a pin anywhere in
  the plan.
- Do not commit the solution plan to this repo. Solutions
  live in the paired `-solutions` repo.
