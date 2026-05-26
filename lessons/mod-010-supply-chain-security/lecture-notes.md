# Module 10 — Supply Chain Security for ML Systems

> **Note on AI-assisted content.** Drafted with AI assistance and
> under human review. SLSA, Sigstore, and supply-chain tooling
> evolve rapidly; verify with upstream docs. See
> [`resources.md`](./resources.md).

---

## 1. The supply chain you actually have

Most engineers underestimate their supply chain. A typical ML
production system depends on:

- **Base images** — `python:3.11-slim`, `pytorch/pytorch:...`,
  `nvidia/cuda:...` (some from official sources, some from
  community).
- **OS packages** — apt / yum dependencies in the base image and
  whatever you add.
- **Python packages** — your `requirements.txt` + everything
  those depend on (often 50-200 transitive dependencies).
- **System libraries** — CUDA, NCCL, MKL, OpenBLAS.
- **Pretrained models** — from Hugging Face, internal registry,
  or vendor APIs.
- **Datasets** — sometimes public benchmarks, often internal
  data, occasionally vendor-provided.
- **IaC modules** — Terraform modules, Helm charts.
- **CI tooling** — GitHub Actions used in workflows
  (third-party actions).
- **Build tools** — Docker BuildKit, ko, Bazel.

Each is a control point. An attacker who compromises *any*
gains code execution somewhere in your platform.

The ML-specific surface is the bottom three — pretrained models,
datasets, fine-tuning checkpoints. Conventional supply-chain
tools were built for code; ML artifacts need additional treatment.

### 1.1 The threat actors

- **Direct attacker**: targets your specific organization;
  compromises a dependency they know you use.
- **Opportunistic attacker**: publishes a malicious package and
  hopes someone installs it.
- **Nation-state**: long-running access to widely-used
  upstream projects.
- **Insider at upstream**: a maintainer of a dependency makes a
  malicious change.

The **opportunistic** case (typo-squatting, dependency
confusion) is the most common in practice and the easiest to
defend against. The **upstream insider** case (e.g., the
`xz-utils` 2024 incident) is the hardest.

### 1.2 The recurring patterns

A handful of supply-chain attack patterns recur:

1. **Typo-squatting**: publish a package with a name close to a
   popular one (`torcheval` vs. `torch-eval`).
2. **Dependency confusion**: take advantage of build systems
   that prefer public registries over private ones, and publish
   a public package with the same name as a private internal
   package.
3. **Lockfile injection**: PR that adds a malicious package via
   an updated lockfile.
4. **Malicious maintainer takeover**: legitimate package's
   maintainer account is compromised; malicious version
   published.
5. **Build-system compromise**: attacker gets code execution in
   CI; modifies built artifacts.
6. **Backdoored pretrained model**: a public model on Hugging
   Face contains a backdoor (ML07 transfer-learning attack).

Each requires different controls. This module covers them.

---

## 2. SLSA — Supply-chain Levels for Software Artifacts

SLSA is the de facto standard for supply-chain integrity
levels. Maintained by the Open Source Security Foundation
(OpenSSF). Version 1.0 ratified in 2023.

### 2.1 The framework structure

SLSA defines tracks, with each track having levels:

- **Build track** (the original SLSA) — levels Build-L1 to
  Build-L3+.
- (Future) Source track, Dependencies track.

For now, when people say "SLSA Level 3," they almost always
mean the build track.

### 2.2 The build levels

| Level | Property | Typical evidence |
|---|---|---|
| **Build-L1** | The build is automated and produces provenance | A CI run produces a build artifact + provenance file |
| **Build-L2** | The build runs on a hosted build platform that signs the provenance | The provenance signature is verifiable |
| **Build-L3** | Build is hardened against tampering, runs on a non-falsifiable build platform | Provenance is signed by a non-user identity; build env can't be tampered with by the developer |

Higher levels mean: an attacker has fewer paths to compromise
the artifact. Build-L3 forces an attacker to compromise the
build platform itself (e.g., GitHub Actions infrastructure)
rather than a developer's machine or a single workflow.

### 2.3 What you do to reach each level

**Build-L1**: Build runs in CI; produces a provenance JSON file.

**Build-L2**: Use a hosted CI (GitHub Actions, GitLab CI,
Buildkite); the provenance is signed by the CI platform's
identity.

**Build-L3**: Hardened build:
- Reproducible / isolated build environments.
- Two-party review of build-config changes.
- Provenance signed by a workflow-bound identity (not a
  user-accessible key).
- Build can't be modified mid-flight (no SSH access to running
  builds, etc.).

GitHub Actions with its reusable workflow + OIDC-based signing
gets you most of L3 if configured carefully.

### 2.4 In practice

A SmartRecs-scale team:

- **L1 is the floor.** Every artifact has provenance.
- **L2 is achievable** with stock GitHub Actions + Cosign
  keyless.
- **L3 is achievable** with effort, primarily by hardening
  workflow patterns and using SLSA's reusable workflows.

Above L3 is for projects whose threat model includes "the
build platform vendor is adversarial" — rare.

---

## 3. SBOM — Software Bill of Materials

An SBOM is a list of what's *in* your software. The two main
formats:

- **CycloneDX** (OWASP) — JSON / XML; richer dependency
  metadata.
- **SPDX** (Linux Foundation) — JSON / XML / YAML; older,
  broader ecosystem.

Either works. Most tooling produces both.

### 3.1 What goes in an SBOM

For a container image:

- Every OS package with version + license.
- Every language-level dependency (Python `pip`, Node `npm`,
  Go modules) with versions.
- Every binary blob baked in.
- Source location for each component when known.

For a model artifact:

- The training framework version.
- The base model (if fine-tuned).
- The training dataset(s) referenced.
- The training-job ID and timestamp.

Model SBOMs are an emerging concept. CycloneDX has draft
"ML-BOM" extensions; SPDX is adding similar.

### 3.2 Generating SBOMs

Tools:

- **Trivy** — generates CycloneDX + SPDX for container images.
- **Syft** (Anchore) — focuses specifically on SBOM generation.
- **CycloneDX CLI** — official CycloneDX tooling.
- **`spdx-sbom-generator`** — official SPDX generator.

Typical CI flow:

```bash
trivy image --format cyclonedx --output sbom.cdx.json myimage:latest
trivy image --format spdx-json --output sbom.spdx.json myimage:latest
cosign attest --predicate sbom.cdx.json --type cyclonedx myimage:digest
```

The SBOM travels with the artifact as a signed attestation.

### 3.3 Using SBOMs in production

SBOM generation is the easy part. The harder part is *using*
them:

- **Vulnerability matching**: SBOM + a vulnerability database
  → "which deployed artifacts are affected by CVE-X?"
- **License compliance**: "Which deployed artifacts contain
  GPL code?"
- **Incident response**: "When CVE-Y was disclosed, which of
  our running services had it?"

For ML platforms specifically:
- **Model lineage**: "Which production models were trained on
  dataset Y?" (Used for retraining-after-incident.)
- **Framework version tracking**: "Which models were trained
  with the vulnerable PyTorch version?"

### 3.4 The reality

Most SBOMs sit in S3 unconsumed. The value is in **operational
queries** — wiring SBOMs into a queryable database (Grype DB,
OSV-Scanner, custom) so incident response can answer "what's
affected?" in minutes, not days.

---

## 4. Cosign + Sigstore at depth

Module 03 introduced Cosign. This section goes deeper into the
production patterns.

### 4.1 The three components

1. **Cosign** (the CLI / library) — signs and verifies.
2. **Fulcio** (the CA) — issues short-lived signing
   certificates bound to OIDC identities.
3. **Rekor** (the transparency log) — records every signature.
   Append-only, cryptographically verifiable.

The trust model: **the OIDC identity** is the root of trust.
The signature is signed by a Fulcio cert; the Fulcio cert is
bound to the OIDC subject; the binding is recorded in Rekor.

### 4.2 Keyless vs. key-based signing

Cosign supports both:

- **Keyless** — short-lived cert, OIDC-bound, recorded in
  Rekor. No private key to manage.
- **Key-based** — a long-lived signing key. You manage the
  key.

Keyless is the modern default for CI signing. Key-based is
appropriate for release signing where the threat model
includes "the CI platform is adversarial" (rare).

### 4.3 Signature targets

Cosign can sign:

- **Container images** — the most common case. Signature is
  stored as an OCI artifact alongside the image.
- **Arbitrary blobs** (`cosign sign-blob`) — for files that
  aren't OCI artifacts.
- **Model files** — same as blobs.
- **Attestations** — signed in-toto statements.

For ML platforms, all four matter.

### 4.4 Verification at admission

Module 09's admission policies enforce signature verification.
Kyverno has a built-in `verifyImages` verb. Gatekeeper
verifies via Rego policies that query Cosign data.

Verification logic:

1. Pull the image (or get its digest).
2. Query Cosign for signatures.
3. For each signature:
   - Verify the Fulcio cert chains to Sigstore's root.
   - Verify the cert's subject matches expected OIDC subject.
   - Verify the Rekor entry exists and matches.
4. If at least one signature satisfies the policy, allow.

The expected OIDC subject is the production-grade constraint:
`https://github.com/smartrecs-org/<repo>/.github/workflows/<wf>@refs/heads/main`.
This says: the image was signed by the production CI workflow
on the main branch. A signature from a feature branch wouldn't
satisfy this.

### 4.5 The Rekor transparency log

Rekor's value: a permanent, append-only record of every
signature. Three properties:

- **Auditable**: anyone can query Rekor for a hash.
- **Tamper-evident**: Rekor's Merkle-tree structure is
  cryptographically verifiable; an entry can't be modified
  without detection.
- **Public**: the open Sigstore Rekor instance is public; an
  attacker who signs malicious artifacts can't hide it.

For sensitive deployments, you can run a private Rekor
instance. The trade-off: you lose the auditability of the
public log.

---

## 5. in-toto attestations

Cosign signs artifacts. **in-toto attestations** sign
*statements about* artifacts.

### 5.1 The structure

An in-toto attestation is JSON with:

- **subject**: the artifact(s) the attestation is about
  (named by name + digest).
- **predicateType**: what kind of statement this is
  (provenance, SBOM, vulnerability scan, test results, ...).
- **predicate**: the actual statement.

A SLSA provenance attestation:

```json
{
  "_type": "https://in-toto.io/Statement/v1",
  "subject": [
    {"name": "myimage:v1", "digest": {"sha256": "..."}}
  ],
  "predicateType": "https://slsa.dev/provenance/v1",
  "predicate": {
    "buildDefinition": {
      "buildType": "https://github.com/actions/workflow@v1",
      "externalParameters": {
        "repo": "smartrecs/recs",
        "branch": "main",
        "workflow": ".github/workflows/build.yml"
      }
    },
    "runDetails": {
      "builder": {"id": "https://github.com/actions/runner"},
      "metadata": {
        "invocationId": "...",
        "startedOn": "2026-01-15T10:00:00Z"
      }
    }
  }
}
```

This attestation says: "image `myimage:v1` was built by
GitHub Actions, in the `smartrecs/recs` repo, from the main
branch, by `.github/workflows/build.yml`."

The attestation is then signed by the CI's identity via
Cosign.

### 5.2 Common predicate types

- **SLSA Provenance** (`https://slsa.dev/provenance/v1`) — how
  the artifact was built.
- **SPDX SBOM** (`https://spdx.dev/Document`) — software bill
  of materials.
- **CycloneDX SBOM** — alternate SBOM format.
- **Vulnerability scan results** — what scanning found at
  build time.
- **Test results** — what tests passed.
- **Quality attestation** (ML-specific) — model accuracy /
  fairness metrics.

### 5.3 ML-specific attestations

For an ML model artifact, useful attestations:

- **Training provenance** — what code, what data, what
  hyperparameters produced this model.
- **Validation evidence** — accuracy on hold-out, fairness
  metrics, adversarial robustness measurements.
- **Approval attestation** — a human approval recorded as a
  signed statement.

The pattern: every claim about a model is a signed
attestation. The admission policy verifies all of them.

### 5.4 Verification chains

A defensible admission policy verifies:

1. The image has a SLSA provenance attestation.
2. The provenance was built by the expected workflow.
3. The image has an SBOM attestation.
4. The SBOM has no critical vulnerabilities (per a
   vulnerability scan attestation).
5. (For ML deployments) the model has a validation
   attestation.
6. (For ML deployments) the model has an approval attestation.

This is the production-grade pattern. It's expensive to set
up; once set up, it's largely automatic.

---

## 6. Image scanning

Different from signing. Signing answers "who built this?";
scanning answers "what vulnerabilities are in this?"

### 6.1 Tools

- **Trivy** — CNCF; comprehensive; produces SBOM + vuln scan.
- **Grype** (Anchore) — focused on scanning; uses Syft for SBOM
  generation.
- **Snyk Container** — commercial.
- **Aqua Security** — commercial.
- **Trivy / Grype databases** — both pull from OSV, NVD, GitHub
  Security Advisories, and language-specific advisory sources.

### 6.2 When to scan

Three points:

1. **At build time** — in CI, before the image is pushed.
2. **At admission time** — verifying the scan result is
   acceptable.
3. **Continuously** — re-scanning deployed images as new
   vulnerabilities are disclosed.

The third is the part most teams miss. A scan at build time is
fine until the CVE is disclosed three weeks later — the image
is still vulnerable.

### 6.3 The triage problem

A typical scan of a Python ML image: dozens to hundreds of
CVEs. Most are:

- In packages your code doesn't use.
- In libraries called only in restricted code paths.
- Already mitigated by other controls (network policy, etc.).
- Disputed (no working exploit).

Triage is the work. Tools that help:

- **Reachability analysis** — does your code path actually
  reach the vulnerable function?
- **VEX (Vulnerability Exploitability eXchange)** — a format
  for documenting "this CVE doesn't apply to us because of X."
- **Severity-based triage** — Critical / High = act; Medium =
  schedule; Low = accept.

For SmartRecs-scale teams, the realistic approach:

- Block deploy on Critical CVEs with patches available.
- Schedule remediation for High CVEs.
- Accept Medium / Low CVEs unless escalated.

### 6.4 ML images specifically

ML images are large (often 5-15GB). Common findings:

- **PyTorch / TensorFlow CVEs** — usually low severity in
  practice but show up frequently.
- **CUDA library CVEs** — patched in newer driver versions.
- **OS package CVEs** — apt-get / yum packages in the base.

A multi-stage Dockerfile that strips out the build chain in the
final image reduces the scanned surface significantly.

---

## 7. Dependency scanning

Image scanning covers what's *in* the image. Dependency
scanning covers what's *in your code* — declared
dependencies, lockfiles, manifests.

### 7.1 Tools

- **Dependabot** (GitHub) — automated dependency-update PRs.
- **Snyk** — comprehensive dependency scanning.
- **OSV-Scanner** (Google) — uses the OSV vulnerability
  database.
- **GitHub Security Advisories** — surfaces advisories on PRs.
- **`pip-audit`** — Python-specific.
- **`npm audit` / `yarn audit`** — Node-specific.

### 7.2 The renovate pattern

Dependabot / Renovate automate dependency updates. For
ML platforms:

- **Auto-merge low-risk updates** (patch versions of stable
  dependencies).
- **Manual review** for minor / major version updates.
- **Always test** before merging (CI runs the test suite).

The trade-off: auto-merging is convenient but trusts the
upstream. A compromised upstream that pushes a malicious patch
release could land via auto-merge.

Mitigation: pin to specific versions in requirements; use a
lockfile; consume from an internal mirror (next section).

### 7.3 Internal mirrors

For regulated or sensitive deployments, run an internal
package mirror:

- **Python**: `devpi`, `bandersnatch`, or commercial (Artifactory,
  Nexus).
- **npm**: `verdaccio`, Artifactory.
- **Container images**: Artifactory, Harbor, ECR with caching
  from upstream.

The mirror provides:
- **Caching** — independence from upstream availability.
- **Scanning at ingress** — packages are scanned before
  becoming available.
- **Allowlists** — only approved packages are available.
- **Tamper-proof** — once accepted, the package version is
  pinned.

For SmartRecs-scale: an internal mirror is overkill. For
enterprise or regulated: it's foundational.

---

## 8. ML model artifact provenance

The ML-specific supply chain. The patterns above (Cosign,
in-toto, scanning) apply to models with adaptations.

### 8.1 What "provenance" means for a model

A model artifact's provenance answers:

- **Code**: what version of the training code produced this?
- **Data**: what datasets were used? at what versions /
  snapshots?
- **Hyperparameters**: what configuration?
- **Environment**: what framework version, what hardware?
- **Validation**: what evaluations passed before this was
  considered for promotion?
- **Approval**: who signed off?

Each is recorded as in-toto attestations bound to the model
artifact.

### 8.2 The signing flow

1. **Training job runs**. Produces a model file and a training-
   provenance attestation.
2. **Validation runs**. Produces a validation attestation
   (accuracy, fairness, robustness).
3. **Human review** (if required). Produces an approval
   attestation, signed by the reviewer's identity.
4. **Cosign sign-blob** signs the model file.
5. **All attestations** are signed and attached to the same
   subject (model digest).
6. **Admission policy** at the serving cluster verifies the
   chain.

### 8.3 Lineage tracking

Beyond signing: the model registry should record lineage:

- Which dataset version trained which model version.
- Which model version is deployed to which serving cluster.
- Which production prediction was made by which model version.

This is the **forensic backbone**. When an incident happens
("model X is making bad predictions"), lineage answers
"which dataset did model X learn from, and is that dataset
itself compromised?"

### 8.4 Cross-references with Module 03

Module 03 covered the cryptographic primitives. Module 10
applies them to the model lifecycle. The hash chain (Module 03
§8) is where provenance entries are recorded for tamper-
evidence.

---

## 9. ML dataset provenance

Datasets are the most-overlooked part of the ML supply chain.
A model trained on a compromised dataset is itself compromised.

### 9.1 The dataset supply chain

Where datasets come from:

- **Public benchmarks** (MNIST, CIFAR, ImageNet, GLUE,
  RedPajama).
- **Vendor data** (third-party labeled data).
- **Internal customer data** (the most common case in
  production).
- **Crawled data** (web crawls, with appropriate licenses).
- **Generated data** (synthetic, from another model).

Each has its own risk profile. Public benchmarks are
relatively low-risk (widely scrutinized). Vendor data depends
on the vendor. Crawled data is the highest-risk for unintended
content (poisoning, copyrighted material, illegal content).

### 9.2 Dataset signing

Sign datasets with Cosign sign-blob. The signature is bound to
the producer's identity:

- For public benchmarks: a signature from the publisher (if
  available).
- For internal data: a signature from the data-engineering
  workload that prepared it.
- For vendor data: a signature from the vendor (if available);
  if not, your data-ingest pipeline's signature on the version
  you received.

The signature plus an in-toto attestation about the dataset
(source, version, classification, retention policy) gives you a
verifiable record.

### 9.3 Detecting dataset tampering

If a dataset is signed, tampering is detected at verification
time. Without signing, you have to scan:

- **Hash comparison** against a known-good baseline.
- **Statistical comparison** — feature distributions, label
  distributions.
- **Spot-check sampling** — manually review random samples for
  anomalies.

The hash comparison is the strongest detection if a baseline
exists. Signing makes the baseline canonical.

### 9.4 Dataset attestations

Useful attestations for a dataset:

- **Source attestation** — where the data came from.
- **Classification attestation** — public / internal /
  confidential / restricted.
- **Privacy attestation** — what's in here (PII / PHI / none).
- **Quality attestation** — what data-quality checks passed
  (duplication, outliers, schema).

Each is signed and attached to the dataset's digest.

---

## 10. Common ML supply-chain attacks

### 10.1 Typo-squatting

Examples in the wild:

- `tensorflow-cpu` is real; a typo-squatter publishes
  `tensorflow_cpu` or `tensorflowcpu`.
- `langchain` is real; squatters have published similar names.

Mitigations:

- Pin specific versions in requirements.txt.
- Use a lockfile.
- Use an internal mirror with an allowlist.

### 10.2 Dependency confusion

The 2021 Birsan attack:

- Many companies use private internal packages with names like
  `internal-prod-lib`.
- Some build systems prefer public registries over private ones
  when both have the same package.
- An attacker publishes `internal-prod-lib` on PyPI with a
  higher version.
- Your build system pulls the public (malicious) version.

Mitigations:

- Configure your build system to prefer private registries.
- Reserve your private package names on public registries.
- Use scoped names (`@your-org/...` on npm).

### 10.3 Compromised Hugging Face models

Hugging Face hosts hundreds of thousands of community-uploaded
models. Some have been found to:

- Execute arbitrary code at load time via unsafe deserialization
  formats (the default Python serialization for model
  checkpoints is not safe against malicious files).
- Contain backdoors (BadNets-style triggers).
- Steal API keys or environment variables at load time.

Mitigations:

- **Don't use unvetted Hugging Face models in production.**
- Prefer the `safetensors` format when downloading checkpoints;
  it does not execute code on load.
- Pin to specific model revisions (with commit hashes).
- Scan downloaded models before deploying.
- Vet the publisher (official org accounts, established
  maintainers).

### 10.4 Compromised CI

An attacker who gets credentials for your CI can:

- Sign malicious artifacts with your CI identity.
- Modify build outputs.
- Exfiltrate secrets from CI runner state.

Mitigations:

- **Keyless CI** (Module 05 §8) — no long-lived credentials to
  steal.
- **Branch protection** — require approvals on workflow changes.
- **Pinned action versions** — don't use `@main`; pin to a
  specific commit SHA.
- **Audit-chain logging** of every CI run.

### 10.5 Backdoored pretrained model

A more sophisticated attack: an attacker contributes a
pretrained model to a public hub with a subtle backdoor (ML07
in OWASP ML Top 10). Fine-tuning the model preserves the
backdoor.

Mitigations:

- Use models from trusted, audited sources.
- Run behavioral tests against suspicious-input corpora
  (Module 06 §5.4).
- Differential testing across multiple base models.

---

## 11. Compromised CI patterns: what to defend against

CI compromise is the most consequential supply-chain attack.
An attacker with CI access can sign anything as you.

### 11.1 What an attacker tries

- **Modify a workflow** to add malicious steps.
- **Add a new workflow** that signs a malicious artifact.
- **Steal CI secrets** to use elsewhere.
- **Modify a release process** to publish a malicious version.

### 11.2 Defense patterns

- **Workflow review**: every change to `.github/workflows/`
  requires review.
- **Permissions scoping**: workflows declare minimal
  `permissions:`.
- **Pin actions to commit SHAs**: not version tags (which can
  be re-tagged).
- **Limit secret scope**: CI secrets are scoped to specific
  environments; not all workflows can use all secrets.
- **OIDC trust scoping**: AWS IAM trust policies should limit
  trust to specific workflows + branches, not the whole org.
- **Audit logging**: every CI run produces an audit-chain
  entry.

### 11.3 Detection

- **Anomaly detection** on workflow patterns — new workflows
  that hit production immediately, or workflows that run at
  unusual times.
- **Signature monitoring** — alerts on signatures from
  unexpected workflows.
- **Rekor monitoring** — alerts on entries from your identities
  that don't correspond to known builds.

---

## 12. Operating supply-chain security at SmartRecs scale

A defensible baseline:

### 12.1 Day 1 (low effort)

- Cosign keyless signing in every CI workflow.
- SBOMs generated and attached as attestations.
- Image scanning (Trivy) in CI; block on Critical CVEs.
- Pinned action versions.
- Pinned dependency versions.
- Branch protection on `.github/workflows/`.

### 12.2 Day 30 (modest investment)

- Admission policy verifies Cosign signatures.
- Vulnerability scan results as attestations.
- Continuous re-scanning of deployed images.
- Dependency scanning with auto-merge on patch versions.

### 12.3 Day 90 (steady state)

- Model artifact signing + admission verification.
- in-toto provenance attestations for builds.
- Dataset signing for internal datasets.
- Vendor / Hugging Face model vetting process.

### 12.4 What you don't need at SmartRecs scale

- Internal package mirror (overkill).
- Reproducible builds (significant engineering investment).
- Private Sigstore instance (public Sigstore is fine).
- Continuous attestation re-validation (beyond admission).

---

## 13. What you should be able to do after this module

- [ ] Generate and attach SBOMs to container images.
- [ ] Configure Cosign keyless signing in a CI workflow.
- [ ] Author admission policies that verify signatures +
      provenance + SBOM constraints.
- [ ] Distinguish SLSA Build-L1, L2, L3 and what's required for
      each.
- [ ] Identify the supply-chain risk of a given Hugging Face
      model and vet it.
- [ ] Design a model-artifact provenance flow with all relevant
      attestations.
- [ ] Detect a dependency-confusion or typo-squatting attempt.
- [ ] Plan the response to a confirmed CI compromise.

---

## 14. What this module deliberately doesn't cover

- **Specific commercial supply-chain products** (Snyk, Chainguard).
- **Cryptographic primitives** — Module 03.
- **Admission policy authoring** — Module 09.
- **Detection rules for supply-chain anomalies** — Module 11.

---

## 15. Suggested reading order

After this:

1. Read the [SLSA specification](https://slsa.dev/spec/v1.0/).
2. Read the [Sigstore documentation](https://docs.sigstore.dev/).
3. Skim the [in-toto specification](https://in-toto.io/specs/).
4. Read about [CycloneDX](https://cyclonedx.org/) and
   [SPDX](https://spdx.dev/).
5. Move to **Module 11: Security Operations**.

---

## Appendix A — Glossary

- **Attestation**: a signed statement about an artifact.
- **CycloneDX**: an SBOM format.
- **Fulcio**: Sigstore's CA, issues short-lived signing certs.
- **in-toto**: framework for software-supply-chain
  attestations.
- **Rekor**: Sigstore's transparency log.
- **SBOM**: Software Bill of Materials.
- **safetensors**: a checkpoint format that does not execute
  code on load (unlike older Python checkpoint formats).
- **Sigstore**: the umbrella project for keyless signing
  (Cosign + Fulcio + Rekor).
- **SLSA**: Supply-chain Levels for Software Artifacts.
- **SPDX**: an SBOM format.
- **VEX**: Vulnerability Exploitability eXchange.

---

## Appendix B — Common misconceptions

| Misconception | Reality |
|---|---|
| "We sign our images, so we have supply-chain security." | Signing is one layer. SBOMs, scans, attestations, admission verification, ongoing monitoring are all part of the program. |
| "SBOM is for compliance only." | SBOMs are the substrate for vulnerability tracking and incident response. Compliance is a side benefit. |
| "Hugging Face models are safe because they're popular." | Popularity doesn't equal safety. Some checkpoint formats execute arbitrary code at load. Vet before using; prefer `safetensors`. |
| "Keyless CI signing means we don't need branch protection." | Keyless means no long-lived secrets. Branch protection prevents malicious changes from getting into the signing workflow in the first place. |
| "SLSA L3 is for big tech only." | A 6-person team on GitHub Actions can get close to L3 with reusable workflows and proper configuration. |
| "Our internal models don't need signing." | Internal != trusted. A compromised internal CI signs internal models the same way. |
| "Dependency scanning catches all supply-chain attacks." | Scanning catches known CVEs. Novel attacks (typo-squatting, dependency confusion, compromised maintainers) often aren't in advisory databases. |

---

*Continue to the [exercises](./exercises/) when you're ready.*
