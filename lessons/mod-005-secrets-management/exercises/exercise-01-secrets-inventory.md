# Exercise 01 — Secrets Inventory

**Estimated time**: 2 hours
**Deliverable**: A spreadsheet-style inventory (Markdown table) + a 1-page analysis

---

## The assignment

Produce a comprehensive secrets inventory for SmartRecs. The
inventory is the foundation for everything else in this module —
you cannot manage what you cannot enumerate.

## What counts as a secret

Use the lecture-notes §1 definition: any value whose disclosure
to an unintended party is a security event.

Include at minimum:
- Internal service-to-service auth (any API keys, JWTs).
- Database credentials (training warehouse, feature store
  metadata DB, audit DB).
- Object-store credentials (model artifact bucket).
- External vendor API keys (OpenAI, Anthropic, monitoring
  vendors, alerting vendors).
- TLS private keys.
- Customer-facing API keys (validation side, not the customer's
  copy).
- Signing keys (artifact, audit, JWT).
- Customer-managed encryption keys.
- CI/CD tokens.
- Webhook secrets.

## Per-secret fields

For each secret, capture:

| Field | What goes here |
|---|---|
| **Name** | Human-readable name |
| **Class** | Static long-lived / Dynamic short-lived / Identity-derived |
| **Where stored today** | Specific (e.g., "K8s Secret `ml-creds`", "Vault `secret/openai-key`") |
| **Who reads it** | Which workloads (by identity, ideally) |
| **Rotation cadence today** | Days / Quarterly / Never |
| **Compromise blast radius** | What an attacker can do with it |
| **Detection of compromise** | How would we know? |
| **Target state** | What the post-Module-05 state should be |
| **Owner** | A team (not a person) |

## Format

Use a table. After the table:

1. **Analysis section** — patterns you see across the inventory.
   - How many secrets are static / dynamic / identity-derived?
   - Which secrets have *the largest* blast radius if leaked?
   - Which secrets have *no* compromise detection today?
   - Which secrets have unclear ownership?
2. **Top 5 priorities** — five secrets to address first, with
   justification.

## Quality criteria

A passing inventory:

- **At least 15 distinct secrets** identified (most ML systems
  have more).
- Each has all fields filled.
- "Where stored today" is specific — not "Kubernetes."
- Identifies at least three secrets with unclear ownership.
- Calls out at least two secrets that *should* be dynamic but
  are currently static.

A failing inventory:

- < 10 secrets (you missed half the system).
- "Owner: TBD" everywhere.
- "Detection: monitoring" without specifying which monitor.

## Reflection questions

1. Which secret was easiest to forget? Why?
2. Which secret has the *largest* blast radius? Defend the
   ranking against a likely alternative.
3. Which secret should be retired entirely (replaced with
   identity, not stored)?

## Save your artifact

Foundation for Exercises 02-05.
