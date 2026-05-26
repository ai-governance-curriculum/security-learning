# Module 10 Quiz — Supply Chain Security

> Closed-book first.

---

## Conceptual (10 questions)

### Q1
Name the four threat-actor categories from §1.1. For each, give
one concrete attack pattern they would prefer.

### Q2
Distinguish SLSA Build-L1, L2, and L3 in your own words. For
SmartRecs (small team, GitHub Actions, no special build
hardening), which level are you at today, and which is the next
realistic step?

### Q3
For each of the following SBOM use cases, name which format is
typically used and what query the SBOM enables:
- (a) Vulnerability tracking.
- (b) License compliance.
- (c) Incident response after a CVE disclosure.

### Q4
Cosign supports both keyless and key-based signing. Compare
them along three dimensions: operational cost, threat-model
applicability, recovery from compromise.

### Q5
An in-toto attestation has three parts (§5.1). Name them and
give one example each for an ML model artifact.

### Q6
For each ML artifact, name the **most useful** attestation
predicate type:
- (a) A container image of a serving pod.
- (b) A trained model file.
- (c) A training dataset.
- (d) A vulnerability scan result.

### Q7
The lecture argues that "most SBOMs sit in S3 unconsumed"
(§3.4). What turns an SBOM from a compliance artifact into an
operational one? Give one concrete example.

### Q8
For each common ML supply-chain attack (§10), name the **single
best mitigation**:
- (a) Typo-squatting.
- (b) Dependency confusion.
- (c) Compromised Hugging Face model with unsafe deserialization.
- (d) Compromised CI.
- (e) Backdoored pretrained model.

### Q9
The Rekor transparency log has three security properties (§4.5).
Name them. What attack does each prevent?

### Q10
The lecture argues that SmartRecs-scale teams don't need an
internal package mirror Day 1 (§12.4). When *does* the team
need one? What's the triggering condition?

---

## Applied (5 questions)

### Q11
Design the **signed-pipeline** for SmartRecs' model-serving
container image:
- (a) Where signing happens in the CI.
- (b) What gets signed (image, attestations, SBOM, etc.).
- (c) What identity signs.
- (d) What attestations are attached.
- (e) The admission verification logic at deploy time.

### Q12
Design the **model-artifact provenance flow**:
- (a) The training job produces what artifacts + attestations?
- (b) The validation job produces what?
- (c) The human approval produces what?
- (d) The serving cluster verifies what?
- (e) Lineage tracking — what's recorded where?

### Q13
A new SmartRecs use case wants to use a Hugging Face model.
The model is from a community account (not an org), has 500
downloads, and uses the older (unsafe) checkpoint format.
Walk through the vetting:
- (a) The questions you ask.
- (b) The tests you run.
- (c) The decision: approve, modify, or reject.
- (d) If approved with modifications, what controls do you add.

### Q14
A confirmed CI compromise — an attacker has been signing
artifacts as your CI identity for the past 48 hours. Walk
through the incident response:
- (a) Immediate containment (within 1 hour).
- (b) Blast-radius audit (within 24 hours) — query Rekor for
  unexpected signatures.
- (c) Eradication (rotating identities, etc.).
- (d) Recovery (re-establishing trust).
- (e) Customer communication.

### Q15
Author admission policy logic (Rego or Kyverno YAML, your
choice) that:
- Allows images only with a valid Cosign signature.
- Requires the OIDC subject matches `https://github.com/smartrecs-org/*/.github/workflows/build.yml@refs/heads/main`.
- Requires a SLSA Provenance attestation.
- Requires a CycloneDX SBOM attestation.
- Requires the vulnerability scan attestation reports zero
  Critical CVEs.

Include realistic syntax (pseudo is OK).

---

## Self-assessment rubric

Same as previous modules. Passing: average ≥ 2.0, no question
scored 0.
