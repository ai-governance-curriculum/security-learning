# Exercise 01 — ML Secrets Inventory

**Estimated effort:** ~2 hours
**Deliverable:** One Markdown document containing (a) an
enumeration of the target ML platform's secrets across the
eleven classes from chapter 01, (b) a per-secret inventory
table with classification (sensitivity / environment / tenant)
and blast-radius on leak, and (c) a prioritised gap list
naming every long-lived credential and every
missing-inventory-row surprise.
**Prerequisites:** Chapter 01 read end-to-end. Mod-102 asset
inventory for the target platform. Read access to the target
platform's git repositories, CI configuration, and cloud
account.

---

## Objective

Produce the **authoritative inventory** of secrets an ML
platform actually holds. The inventory is the input to
chapters 02–05 — every long-lived credential becomes a
chapter-02 or chapter-04 work item; every un-classified
secret becomes a chapter-03 blocker; every ownerless secret
becomes a chapter-05 gap.

By the end you should be able to point at any secret in the
target platform and answer, from the inventory: what class is
it, who owns it, where does it live today, where should it
live, what happens if it leaks, and who runs the runbook when
it does.

---

## Problem statement

You are the AI/ML Security & Governance Engineer for the
fintech carried through mod-101 → mod-104. The `fraud` model
platform in question:

- **Data plane.** Snowflake warehouse for the training corpus;
  a Feast feature store backed by Redis (online) and Parquet
  in S3 (offline); an MLflow model registry; an OCI registry
  for signed model images.
- **Compute plane.** Kubeflow on GKE; a mix of scheduled
  training jobs and interactive Jupyter notebooks; GitHub
  Actions for CI.
- **External integrations.** OpenAI API (used by an eval
  harness as a judge); Anthropic API (used by a red-team
  harness); PagerDuty and Slack for alerting; Datadog for
  observability.
- **Data sensitivity.** The training corpus includes
  transactional data derived from customer records —
  restricted, some PII columns; PHI in an evaluation subset
  from a healthcare-partner integration.
- **Current-state secret handling.** Kubernetes `Secret`
  objects for most credentials; a handful of `.env` files in
  the notebooks repo; GitHub Actions Secrets for CI cloud
  credentials; a single AWS KMS CMK used for SSE-KMS on the
  `s3://acme-data-lake/` bucket.

If you have a real ML platform in front of you, substitute
it — the exercise structure is identical.

---

## Requirements

Produce a single Markdown document with the following
sections.

### Section 1 — Enumeration across the eleven classes

For each of the eleven classes from chapter 01, list every
instance in the target platform. If a class has no instance
(e.g. no judge-model credentials because there is no LLM
eval harness), state that explicitly — an empty class row is
a finding one way or the other (either genuinely absent or
present-but-unnoticed).

Format:

```
## Class 1 — Training-data-store credentials

- Snowflake `SNOWFLAKE_ML_ROLE` password, currently in
  Kubernetes `Secret` `snowflake-creds` in namespace
  `ml-training`.
- Redshift `REPORT_READ` password (used by an offline eval
  path), currently in Vault KV at `kv/data/ml-eval/redshift`.
- …
```

### Section 2 — Inventory table

The table from chapter 01, one row per secret from section 1.
Every column required. Do not leave blanks.

| Secret ID | Class (1–11) | Description | Primary owner | Current store | Ideal store (per chapters 02/03/04) | Long-lived? | Rotation cadence (actual / stated) | Sensitivity tier | Environment scope | Tenant scope | Blast radius on leak (one sentence) | Leak-response owner |

Rules:

- **Every row has a `Primary owner` and `Leak-response
  owner`.** If either column reads "unknown", that is the
  most-urgent chapter-05 gap — surface it in section 3.
- **`Long-lived?` is `YES`** for any credential that lasts
  longer than 1 hour without automatic re-issuance.
- **`Rotation cadence`** has two values: what the policy says
  (`stated`) and what the git history / provider audit log
  says actually happens (`actual`). Disparities are a
  finding.
- **`Sensitivity tier`** matches your org's data-
  classification scheme (from mod-108). If none exists, use
  the three-tier `public` / `restricted` / `confidential`
  scheme from chapter 01 and note the absence of an
  organisational scheme as a finding.
- **`Environment scope`** is `prod-only` / `staging-only` /
  `dev-only` / `shared`. A `shared` value is almost always a
  gap.
- **`Tenant scope`** is `single-tenant` / `per-tenant` /
  `shared`. Only relevant for multi-tenant platforms; on
  single-tenant platforms every row is `single-tenant`.
- **`Blast radius`** is one sentence, concrete, e.g. "read
  of the entire Snowflake training warehouse for the
  compromise window" — not "would be bad".

### Section 3 — Prioritised gap list

Turn the table into a work-item list ordered by risk. Format:

| Gap ID | Secret ID | Gap type | Chapter that closes it | Effort | Priority |

Gap types include (non-exhaustive):

- `long-lived-credential` → chapter 02 or 04.
- `no-owner` → immediate assignment; chapter 05 dependency.
- `wrong-store` (e.g. Kubernetes `Secret` in place of Vault
  KV) → chapter 02.
- `no-classification` → chapter 01 / chapter 03 dependency.
- `shared-environment` → chapter 03.
- `no-rotation` → chapter 02 (dynamic) or chapter 05
  (rotation-schedule policy).
- `secret-in-code` → immediate remediation (chapter 05
  incident) plus chapter 04 (prevent recurrence).

Priority is `1` (production credential with immediate risk),
`2` (production credential with mitigated risk or non-
production credential with high blast radius), or `3`
(non-production, low blast radius).

### Section 4 — Discovery method log

Name every source you consulted to compile the inventory and
what you found:

- `git log -p --all -S 'AKIA'` on the mono-repo → 3 hits, 2
  in test fixtures (verified inert), 1 in a notebook (still
  live — treat as incident, file per chapter 05).
- `kubectl get secret --all-namespaces -o json` → N secrets
  enumerated.
- Vault `vault list kv/` in each namespace → M paths
  enumerated.
- GitHub Actions Secrets across the org's repos → …
- AWS KMS keys / SSM parameter store / Secrets Manager → …
- GCP Secret Manager / KMS → …
- OpenAI, Anthropic, Datadog, PagerDuty admin consoles →
  keys enumerated by ID (never the value).

The discovery log is what makes the inventory reproducible.
The next quarter's re-scan re-runs each source and diffs.

### Section 5 — Notebook check

Because Jupyter notebooks are the top source of ML secret
leaks, produce a **separate scan result** for the
`notebooks/` directory (and any equivalent research repo):
files containing anything that matches a secret-shaped
pattern. Even validated-inert findings go on this list, so
that the next scan has a baseline.

## Starter guidance

- Run **`gitleaks detect`** and **`trufflehog git`** with
  their default rulesets across the mono-repo and the
  notebooks repo. Combine the findings; the false-positive
  rate is high, and each finding still needs a human
  verdict.
- For the Kubernetes plane, `kubectl get secrets -A` gives
  the list; for each secret, `kubectl describe` gives the
  type; a shell one-liner reveals the keys but never look at
  the raw values in a place that gets logged.
- For AWS / GCP / Azure, use the vendor CLI to enumerate
  secrets stores + KMS keys; annotate each key with the
  applications that reference it (`aws kms list-grants
  --key-id …`).
- The inventory is a scan-and-classify exercise, not a
  design one. Don't design the fix (that's chapters 02–04);
  just find and classify.
- Every unknown owner is a chapter-05 pre-incident. Do not
  paper it over; file the finding and route it to the
  security-leadership on-call as chapter-05 phase 1
  (detect).

## Acceptance criteria

A passing document:

- Enumerates all eleven classes (with explicit "no instance"
  entries where genuine).
- Inventory table has no blank cells.
- Every long-lived credential row appears in the gap list
  with a chapter reference.
- Every `unknown` owner is called out as a P1 gap.
- Discovery log names every source consulted and the
  commands run; the inventory is reproducible.
- Notebook scan produces a separate list with per-file
  verdicts.
- Blast-radius sentences are concrete and specific to the
  target platform, not generic ("access to data").

A failing document:

- Enumerates fewer than eleven classes.
- Has any inventory row with no `Primary owner`,
  `Leak-response owner`, `Blast radius`, or `Rotation
  cadence`.
- Uses "medium" or similarly vague values in the sensitivity
  / priority columns.
- Skips the notebooks scan.
- Files "yes we have Vault" as evidence that any specific
  secret is well-managed without pointing at the actual
  Vault path.
- Cites secret values (even hashed) in the deliverable —
  the deliverable must be shareable with a broader audience
  than the raw values allow.

## Stretch goals

- **Cross-provider spot-check.** Pick three high-blast-
  radius secrets and independently verify the provider-side
  view (e.g. call the OpenAI API `usage` endpoint under the
  key to confirm the key is live; check the AWS access-key
  last-used timestamp; check the Vault lease age).
- **Third-party OIDC support matrix.** For every external-
  API secret (class 4 and 6), note whether the provider
  supports OIDC / workload-identity federation. Providers
  that do become chapter-04 candidates.
- **Historical leak analysis.** Run gitleaks with
  `--log-opts="--all"` against the entire repository history,
  not just the current tree. Any secret found in history —
  even if removed from HEAD — is potentially compromised; add
  those to the inventory with a "historically-leaked"
  annotation and a chapter-05 remediation entry.
- **Notebook policy proposal.** Draft the smallest policy
  change that would prevent the notebook-leak pattern going
  forward: pre-commit hook, notebook-clear-output requirement,
  Vault-backed kernel-secrets driver, or notebook-execution
  in a sandbox that mounts secrets from Vault at runtime.

## Do not

- Do not commit the actual secret values (or hashes of them)
  to the deliverable.
- Do not attempt remediation of live leaks as part of this
  exercise beyond routing them to the chapter-05 on-call —
  active remediation follows the runbook, not this doc.
- Do not build the Vault topology (that is exercise 02).
- Do not design the key hierarchy (that is exercise 03).
- Do not wire keyless CI (that is exercise 04).
- Do not commit a solution here — the paired solutions repo
  is where solutions live.
- Do not invent sensitivity tiers or regulatory citations —
  use the org's existing scheme where present; annotate with
  `<!-- needs-research: ... -->` where a claim cannot be
  verified in this session.
