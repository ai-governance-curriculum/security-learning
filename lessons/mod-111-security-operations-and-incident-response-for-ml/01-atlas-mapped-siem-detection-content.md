# Chapter 01 — ATLAS-Mapped SIEM Detection Content

> **Note on AI-assisted content.** MITRE ATLAS tactic
> and technique IDs, SIEM vendor product features (Elastic
> Security, Splunk ES, Microsoft Sentinel), and model-registry
> telemetry schemas all change frequently. The IDs and query
> fragments in this chapter are shaped against the versions
> cited in [`resources.md`](./resources.md); verify every ID
> and every schema field against the primary source before
> deploying a rule.

---

## Why this chapter exists

Every mature security-operations programme answers one
question for each threat it cares about: *if this happens,
what fires?* The question has three parts — the signal
source (the log stream), the detection logic (the rule),
and the response (what the SIEM does with the alert). A
threat without an answer for all three is uncovered,
regardless of how prominently it appears on the risk
register.

For classical infrastructure the question has an entire
industry of answers: MITRE ATT&CK supplies the technique
vocabulary, Sigma gives a portable rule format, and most
vendors ship curated detection packs that cover the common
TTPs. For ML systems that answer did not exist for a long
time; the ML team logged training metrics to Weights &
Biases while the SOC watched the Kubernetes audit log for
`kubectl exec`, and the two never joined up.

MITRE ATLAS (Adversarial Threat Landscape for AI Systems)
is the ATT&CK equivalent for ML. It defines tactics,
techniques, and case studies specifically for AI/ML
attacks — reconnaissance against a public model, access
to a training dataset, model-evasion attacks against a
deployed classifier, membership inference against a
privacy-sensitive endpoint. The role of a security-
operations engineer for ML is to make the ATLAS matrix
*detectable* in the enterprise SIEM: Elastic Security,
Splunk Enterprise Security, Microsoft Sentinel, Chronicle,
or whatever platform the SOC already runs.

The failure mode this chapter is written against:

> An org adopts a managed LLM service, deploys a
> fine-tuned classifier to production, and stands up a
> model registry. The SOC's SIEM continues to ingest only
> Kubernetes audit, VPC flow logs, and WAF events. Six
> months in, an engineer at a competitor publishes a paper
> describing how they recovered training examples from a
> model served by the vendor the org uses. The exec asks
> "would we have seen this?" and the honest answer is "no
> rule exists for this; the telemetry does not reach the
> SIEM; the SOC has nothing to say". The ATLAS matrix had
> `AML.T0024.001` (Infer Training Data Membership) listed
> under *ML Attack Staging*; nobody mapped it to a signal.

You leave this chapter able to:

- Explain the ATLAS tactic/technique vocabulary and how
  it mirrors but is not identical to ATT&CK.
- Pick signal sources for each ATLAS technique you care
  about and ingest them into the SIEM in a parseable
  shape.
- Author detection rules in a portable form (Sigma) and
  translate them into Elastic / Splunk / Sentinel.
- Attach the ATLAS technique ID to every rule so
  coverage is reportable.
- Avoid the common failure modes — rules without
  response, rules without baselines, rules written
  against synthetic data only.

---

## ATLAS in one page

MITRE ATLAS reuses ATT&CK's structural grammar — tactics
across the top, techniques down each column — with a
vocabulary adapted to AI/ML attacks. The current
(2024/2025-era) tactic set covers roughly:

- **Reconnaissance** against a target ML system — probing
  a model's decision boundary, enumerating a public model
  card, scraping a public dataset.
- **Resource Development** — standing up adversarial
  tooling, generating adversarial examples, developing
  capability for proxy models.
- **Initial Access** — getting *into* the ML system
  (physical, API, supply-chain-via-base-model,
  compromise of a user with model access).
- **ML Model Access** — reaching the model's inference
  surface (public API, SaaS LLM, physical device, a web
  app that proxies to the model).
- **Execution / ML Attack Staging** — running adversarial
  procedures against the model (crafting evasion inputs,
  staging membership-inference queries, poisoning
  training inputs).
- **Collection** — pulling training data, pulling model
  weights, pulling the system prompt.
- **Exfiltration / Impact** — the terminal step: data
  taken out, decisions caused, cost run up, reputation
  harmed.

Each tactic contains techniques (`AML.T####`) and some
have sub-techniques (`AML.T####.###`). Each technique has
a description, suggested mitigations, and references to
real-world incidents. The matrix is a living document;
your SIEM content needs to be *re-walked* on an interval
(a quarter is a reasonable cadence).

Where ATLAS and ATT&CK overlap — a classical software
compromise that lands in the ML system — you should keep
the ATT&CK ID too. Many ML incidents start with an
`T1078` (Valid Accounts) finding before they graduate
into an ATLAS technique.

### How ATLAS differs from ATT&CK, operationally

- **The target is often the model's behaviour, not the
  host.** Signals live in model-serving telemetry, not
  the kernel audit log.
- **Many techniques do not touch the host at all.** A
  membership-inference attack is 100 % API traffic; no
  process is spawned, no file is written.
- **"Compromise" is sometimes legal use of a public
  endpoint.** The attacker is a paying customer. You
  cannot block them without blocking a customer; your
  detections must distinguish *patterns of abuse* from
  normal use.

These three differences drive the signal choices below.

---

## Picking the signal sources

A SIEM rule is only as good as the log stream it reads.
Four classes of signal matter for ATLAS coverage, and
each needs its own ingest pipeline before any rule is
written.

### Model-serving telemetry

The inference API itself. For each request:

- Identity of the caller (API-key hash, OIDC subject,
  tenant ID, workload identity if the caller is a
  service).
- Prompt / request content with a *provenance label* —
  which parts came from the user, which from retrieval,
  which from a system-prompt template (mod-107
  chapter 02 covers the labelling).
- Response content, length, token count, latency.
- Model version served (digest), serving replica
  identity, routing key if the request was A/B-split.
- Guardrail / content-filter decisions (allow, redact,
  block) with the specific rule that fired.
- Tool calls emitted by the model (the function name,
  the arguments, the tool-registry tier from mod-107
  chapter 03), their results, and the time taken.
- Cost signals: tokens in, tokens out, retrieval
  calls, external API calls.

This stream is the richest source for ATLAS detections
and is usually the one the SOC does *not* yet have. The
first wire-up task is often "ship the LLM gateway's
access log into the SIEM at parity with how the ingress
proxy's access log already is".

### Model-registry and training-pipeline telemetry

- Model-registry events: pushes, pulls, deletes,
  signature attachments, approval transitions. Each
  event names the artefact digest and the acting
  identity.
- Training-pipeline events: pipeline runs, dataset
  checkouts, container-image pulls, intermediate-artefact
  writes. Each event names the pipeline-run ID, the
  dataset version it pinned, and the identities involved.
- Dataset-store access events: who read which bucket at
  what time with what credential.

These streams light up the "Collection" and "Resource
Development" tactics — someone pulling model weights or
reading the training corpus at an odd time of day.

### Runtime / infrastructure telemetry

The classical streams, filtered to the ML workloads:

- Kubernetes audit log for the training and serving
  namespaces (`kube-system` is noise; `ml-training` and
  `ml-serving` are signal).
- VPC flow / cloud-network telemetry for egress from
  training and serving node pools.
- Cloud control-plane audit (CloudTrail, Cloud Audit
  Logs, Azure Monitor Activity Log) scoped to the
  ML-platform project / subscription / account.
- Container-image registry pulls, SBOM-scan results.

Falco / eBPF runtime signals come from the host and belong
in the same stream; chapter 02 covers rule authoring, but
the pipeline is the SIEM pipeline.

### Governance / platform signals

- Approvals-and-exceptions tickets (mod-109) — who
  approved a model promotion, when a policy exception
  was granted and expired.
- SBOM / ML-BOM feeds (mod-110) — the dependency list
  for a currently-deployed model.
- Lineage events (mod-104) — a model's data-provenance
  record and its integrity verification results.

These are not the detection signals themselves; they are
the enrichment data that lets a SIEM rule attach context
("this model is cleared for PHI? which training-data
version is it on? who last approved its deployment?") to
an alert.

### Ingest shape

Across all four classes, two rules keep the content pack
sustainable:

- **Structured logging, every event.** Nested JSON with
  known field names; no "parse the free-text message".
  Define a schema per source and keep it versioned.
- **ECS-aligned where feasible.** Elastic Common Schema
  is widely supported across SIEMs (Elastic, OpenSearch,
  and various integrations); mapping to ECS up-front
  means a rule you write in Sigma translates with less
  loss.

---

## Four detection focus areas (the module objective)

The module objective calls out four coverage areas
specifically: model-download anomalies, out-of-band
agent tool calls, unusual training-data access, and
membership-inference patterns. Each is grounded in an
ATLAS tactic and worked below as a rule-authoring
exercise.

### Model-download anomalies — Collection / Exfiltration

ATLAS technique context: `AML.T0044` (Full ML Model
Access) and `AML.T0048.004` or related — the attacker
*obtains the weights*. The signal lives in the model
registry's access log.

**What distinguishes malicious from normal.**

- Volume: downloading an entire family of models in one
  hour versus pulling the one needed for a deployment.
- Identity: a developer workstation versus a serving
  deployer-controller service account.
- Time: an interactive pull at 03:00 local versus a CI
  pull during a deploy window.
- Source: an inbound-restricted KSA versus an unexpected
  IP range.
- Target class: weights versus eval reports versus
  metadata.

**Baselining.** Every model-download rule needs a
baseline. The baseline is per-identity (what does this
service account normally pull) and per-model (what
pattern of callers normally pulls this model). A rule
that fires on "unusual" without a baseline is a
false-positive machine.

**Sample Sigma rule.** This is deliberately conservative;
tune the thresholds against the org's traffic.

```yaml
title: Anomalous Model-Registry Full Weight Download
id: 7f3b2e7e-8b4c-4e3b-9e3b-ml-registry-dl-001
status: experimental
description: >
  Full download of model weights from the registry by an
  identity whose weekly profile shows no prior pulls of
  this artefact. Covers ATLAS AML.T0044.
author: mod-111 reference content
references:
  - https://atlas.mitre.org/techniques/AML.T0044
logsource:
  product: model_registry
  service: access_log
detection:
  pull_event:
    event.action: "artifact.pull"
    artifact.media_type|contains: "model/weights"
  excessive_bytes:
    bytes_out|gt: 500000000
  not_baseline:
    identity.weekly_pulls_of_this_artifact: 0
  condition: pull_event and (excessive_bytes or not_baseline)
fields:
  - identity.name
  - identity.type
  - artifact.name
  - artifact.digest
  - bytes_out
  - source.ip
level: medium
tags:
  - atlas.AML.T0044
  - atlas.tactic.collection
falsepositives:
  - First-time deployer of a new model into a new environment.
  - Backfill job explicitly scheduled for mirror population.
```

**Elastic / Splunk / Sentinel translations.** The Sigma
rule above compiles with `sigma-cli` or
`pySigma`-backed converters to:

- **Elastic (EQL / KQL / ES|QL)** against the model-
  registry data stream. Elastic's Detections engine
  accepts rules as JSON; the `atlas.AML.T0044` tag goes
  into the rule's `threat.framework` + `threat.
  technique.id` fields so the matrix visualisation shows
  coverage.
- **Splunk (SPL)** against an index-and-sourcetype you
  chose for registry events. The Enterprise Security
  framework will map the technique field to its
  Correlation Search metadata; add `annotations.mitre_
  attack` with the ATLAS ID even though the field was
  historically ATT&CK-only (Splunk ES tolerates
  additional annotation fields that the matrix
  dashboard surfaces).
- **Sentinel (KQL)** against a custom-table log stream
  (e.g. `ModelRegistryAccess_CL`). Analytics-rule YAML
  carries the ATLAS tactic/technique in the
  `tactics`/`techniques` fields; Sentinel's content hub
  increasingly accepts non-ATT&CK tags.

Vendor documentation drifts on how exactly ATLAS tags
render in each matrix dashboard. The important thing is
that the ID is stored on the rule, not whether the
dashboard icon looks pretty.

### Out-of-band agent tool calls — ML Attack Staging / Impact

ATLAS technique context: `AML.T0049` (Exfiltration via
ML Inference API) when the model issues a tool call that
exfiltrates data to an attacker-controlled destination,
or `AML.T0053` (LLM Prompt Injection) as the preceding
step. For agent systems these appear together: an
indirect-injection payload (mod-107 chapter 02) causes
the model to call a tool it was not supposed to.

**What distinguishes malicious from normal.**

- Tool tier (mod-107 chapter 03): a Tier-3 tool fired by
  an identity not usually authorised to call it.
- Arguments: destinations that are not on the agent's
  normal destination list (a `mail.send` whose `to:`
  field is a brand-new domain; a `webhook.post` to a
  freshly-registered URL).
- Sequence: the model issued the tool call *in the same
  turn* as it ingested retrieval content whose
  provenance label was `external_untrusted`.
- Volume: dozens of outbound tool calls in a session
  where sessions normally see one or two.

**Sample Sigma rule — tool call to an unknown destination
following external-untrusted retrieval.**

```yaml
title: Agent Tool Call to Unknown Destination After External Retrieval
id: 2a7c9f3b-7d4b-4e3b-9e3b-ml-agent-oob-001
status: experimental
description: >
  LLM agent invoked a Tier-2+ tool whose argument is an
  external destination not previously seen on this
  identity, within the same session as retrieval content
  labelled external_untrusted. Covers ATLAS AML.T0049
  with AML.T0053 as the entry vector.
author: mod-111 reference content
references:
  - https://atlas.mitre.org/techniques/AML.T0049
  - https://atlas.mitre.org/techniques/AML.T0053
logsource:
  product: llm_gateway
  service: trajectory_log
detection:
  risky_tool_call:
    event.action: "tool.invoke"
    tool.tier|gte: 2
    tool.destination.first_seen_hours|lte: 24
  recent_untrusted_retrieval:
    session.retrieval.provenance|contains: "external_untrusted"
  condition: risky_tool_call and recent_untrusted_retrieval
fields:
  - session.id
  - identity.name
  - tool.name
  - tool.destination
  - session.retrieval.sources
level: high
tags:
  - atlas.AML.T0049
  - atlas.AML.T0053
  - atlas.tactic.exfiltration
falsepositives:
  - Legitimate new-destination tool call authorised through HITL (mod-107 ch 03).
```

The rule relies on the trajectory log carrying the
provenance labels from mod-107. If the gateway does not
yet emit those, the rule is unenforceable; the first
engineering task is the enrichment, not the rule.

### Unusual training-data access — Resource Development / Collection

ATLAS context: `AML.T0024.*` (ML Attack Staging via
training-data probing), `AML.T0025` (Exfiltration via
Cyber Means) when the dataset itself is stolen, and the
upstream `AML.T0019` (Publish Poisoned Datasets) when
the goal is to influence a future training run.

**What distinguishes malicious from normal.**

- Access by an identity whose role profile does not
  include training-data read.
- Access patterns that look like enumeration: wide
  listings of the whole bucket, rather than targeted
  reads of specific partitions.
- Access that follows a known indicator (an identity
  that just received a privilege-escalation finding, a
  session that just failed a MFA step twice).
- Writes to the training-data store from identities that
  should only read. ATLAS poisoning techniques start
  here.

**Sample Sigma rule — training-data write from unexpected
identity.**

```yaml
title: Unexpected Write to Training-Data Store
id: 5d1b7c3e-9f4c-4e3b-9e3b-ml-trainset-write-001
status: experimental
description: >
  Object-store write into the training-data prefix by an
  identity not on the training-data writer allowlist.
  Covers ATLAS AML.T0019 as a dataset-poisoning precursor.
author: mod-111 reference content
references:
  - https://atlas.mitre.org/techniques/AML.T0019
logsource:
  product: cloud_storage
  service: access_log
detection:
  write_to_training:
    event.action: "object.write"
    resource.bucket|endswith: "-training"
  not_allowlisted:
    identity.name|not_in:
      - training-ingestor-sa
      - lineage-publisher-sa
  condition: write_to_training and not_allowlisted
fields:
  - identity.name
  - resource.bucket
  - resource.key
  - event.source.ip
level: high
tags:
  - atlas.AML.T0019
  - atlas.tactic.resource_development
falsepositives:
  - A new ingest pipeline that was not added to the allowlist (fix the allowlist, not the rule).
```

The rule depends on an allowlist that is maintained *as
code* — the detection content and the identity model
agree, or the alert is noise.

### Membership-inference patterns — Collection

ATLAS context: `AML.T0024.001` (Infer Training Data
Membership). Membership-inference attacks (mod-108
chapter 02) try to decide whether a specific record
was in the training set by probing a deployed model
with that record and comparing confidence against
known-non-member records.

**What distinguishes malicious from normal.**

- Many near-duplicate inferences from one identity.
  Normal users do not query the model with 10,000
  slightly-different versions of the same input.
- Repeated probes against *the same* record over time,
  possibly with slight perturbations.
- Confidence-score harvesting: callers who hit a
  model-explanation / return-probabilities endpoint
  volume well above the mean.
- Latency / timing-channel probing patterns.

**Sample Sigma rule — probe-shape pattern against the
inference endpoint.**

```yaml
title: Possible Membership-Inference Probe Pattern
id: 6e3b7c3e-ab4c-4e3b-9e3b-ml-mia-probe-001
status: experimental
description: >
  High count of near-duplicate inferences from a single
  identity against a model known to expose confidence
  scores, within a short window. Covers ATLAS
  AML.T0024.001.
author: mod-111 reference content
references:
  - https://atlas.mitre.org/techniques/AML.T0024.001
logsource:
  product: inference_gateway
  service: access_log
detection:
  high_near_duplicate_rate:
    inference.near_duplicate_count_15m|gt: 500
    model.exposes_confidence: true
  condition: high_near_duplicate_rate
fields:
  - identity.name
  - model.name
  - inference.near_duplicate_count_15m
  - inference.unique_hash_fingerprint
level: medium
tags:
  - atlas.AML.T0024.001
  - atlas.tactic.collection
falsepositives:
  - Scheduled model-evaluation harness (confirm with the eval team).
  - Backtest run against historical labelled data.
```

The *near-duplicate count* is itself an enrichment field
computed on ingest (locality-sensitive hashing or a
similar cheap approximation) — the SIEM does not compute
it in-line. See chapter 02 for the ingest-side
enrichment pattern.

---

## Making the coverage reportable

A detection pack with ATLAS IDs on every rule becomes a
*coverage map*: for each tactic and each technique in the
matrix, how many rules do we have, what severity, and
what the signal source is. This is the artefact the
governance programme (mod-109) consumes.

A simple shape:

```yaml
coverage:
  AML.T0019:                     # Publish Poisoned Datasets
    rules:
      - id: 5d1b7c3e-9f4c-4e3b-9e3b-ml-trainset-write-001
        severity: high
        source: cloud_storage.access_log
    status: covered
  AML.T0024.001:                 # Infer Training Data Membership
    rules:
      - id: 6e3b7c3e-ab4c-4e3b-9e3b-ml-mia-probe-001
        severity: medium
        source: inference_gateway.access_log
    status: covered
  AML.T0044:                     # Full ML Model Access
    rules:
      - id: 7f3b2e7e-8b4c-4e3b-9e3b-ml-registry-dl-001
        severity: medium
        source: model_registry.access_log
    status: covered
  AML.T0048.004:                 # ...
    rules: []
    status: uncovered
```

Rules without an ATLAS ID do not appear on the coverage
map; they are not forbidden, but they do not count toward
ATLAS coverage. Rule reviews should insist on the ID
before merge.

---

## Standard failure modes

- **Rules with no response.** The alert fires, nobody
  owns the triage queue; the detection is theatre.
  Chapter 05 (SOC interface) resolves ownership *per
  rule*; rules without an owner should not merge.
- **Rules without a baseline.** "Unusual" needs a
  definition; usually a per-identity histogram over the
  last N days. Without it the rule is a false-positive
  generator.
- **Rules trained against synthetic data only.** A rule
  tuned on hand-crafted red-team payloads often does not
  catch real traffic. Replay against sanitised
  production samples before promoting.
- **Rules that assume a signal the pipeline does not
  carry.** A membership-inference rule that reads
  `inference.near_duplicate_count_15m` is unenforceable
  unless the gateway emits that field. The rule and the
  ingest schema evolve together.
- **ATLAS IDs retrofitted after the fact.** Tagging a
  rule you already wrote with the first ATLAS ID that
  looks close is coverage theatre. The ID should drive
  the signal choice, not decorate the rule.
- **One-shot content pack.** The ATLAS matrix evolves;
  rules bitrot; log schemas drift. A content pack
  without a quarterly review becomes a liability.
- **ATT&CK and ATLAS confused.** `T1078` is ATT&CK;
  `AML.T0024.001` is ATLAS. Use both when both apply;
  do not pretend they are the same framework.
- **Rules written in a single vendor dialect.** The org
  changes SIEMs more often than it changes detection
  intent. Author in Sigma; convert to the current
  vendor's dialect in CI.

---

## Summary

- **ATLAS is the ATT&CK of ML.** Its tactic/technique
  vocabulary is what SIEM detection content for ML/AI
  maps against.
- **The signal sources are four classes:** model-
  serving telemetry, model-registry and training-
  pipeline telemetry, runtime/infra telemetry filtered
  to ML workloads, and governance/platform enrichment.
  Each needs its own ingest pipeline before any rule is
  written.
- **The module's four focus areas** — model-download
  anomalies, out-of-band agent tool calls, unusual
  training-data access, membership-inference patterns —
  each have an ATLAS technique mapping and a sample
  rule shape above.
- **Rules are authored in Sigma**, carry an ATLAS ID,
  depend on baselines not single-event thresholds, and
  translate into Elastic / Splunk / Sentinel from the
  portable form.
- **Coverage is reportable** as a tactic/technique map;
  the governance programme consumes it as evidence of
  detection posture.
- Standard failure modes are rules-without-response,
  rules-without-baseline, rules-against-synthetic-data,
  and rules whose required signal does not exist. The
  content pack and the ingest schema evolve together.
