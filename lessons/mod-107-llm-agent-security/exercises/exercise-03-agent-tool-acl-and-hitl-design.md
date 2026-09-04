# Exercise 03 — Agent Tool ACL and HITL Design

**Estimated effort:** ~4 hours
**Deliverable:** A committed tool-registry design bundle for
one tool-using agent product, consisting of (a) a **tool
inventory** naming every tool the agent can call today, with
blast-radius tier (T0–T3), identity scope, and current ACL
status; (b) a **target tool-registry artefact** (YAML or
structured config) specifying, per tool, tier, ACL,
provenance policy, HITL policy, rate limits, and audit
level; (c) a **HITL UX sketch** — the display template a
human sees for each Tier-2 and Tier-3 tool, with the
argument fields the user has to inspect; (d) a **usability-
tax analysis** naming the top three interruption paths in a
representative user flow and how the design keeps them from
collapsing into rubber-stamping; and (e) a **written design
memo** aimed at the engineering lead who will implement the
registry.
**Prerequisites:** Chapter 03 read end-to-end; chapter 02
skimmed for the provenance-labelling primitive. Access to
one tool-using agent product (the same product used in
exercise 01, ideally — the mitigation map's LLM06 row
becomes the input to this exercise). Sufficient product
context to name every tool the agent can call, the identity
each currently runs as, and the user's typical workflow.

---

## Objective

Turn "the agent has tools" into a defensible design: each
tool tiered, each tier's ACL and HITL policy explicit, and
the resulting UX sanity-checked against rubber-stamping.
This is the artefact chapter 04's red-team plan asks about
("what is the tool registry version?") and chapter 05's
severity ladder consults ("what tier was the tool the
attacker reached?").

By the end of this exercise you have:

- Every tool tiered with an argument.
- A machine-readable tool registry, reviewable like code.
- HITL policies chosen per tool that concentrate friction
  where it earns its cost.
- A usability-tax analysis that names the interruption
  budget for the target user flow.
- A memo the engineering lead can read and implement
  from — with named test criteria for the ACL and HITL
  behaviour.

You are **not** implementing the runtime enforcement — that
is a code deliverable, not an exercise. You are producing
the *design* the runtime implements, and the test criteria
the implementation is judged against.

---

## Problem statement

Pick one tool-using agent product. If you completed
exercise 01, use the same product — the mitigation-map's
LLM06 owner becomes the reader for this design.

Whatever you pick, name up front:

- **Users.** External customers? Employees? A specific
  team's power users? Anonymous callers?
- **Tools.** Every tool the agent can call. If the agent
  is built on MCP / LangGraph / OpenAI Assistants /
  Anthropic tool use, list them by tool name.
- **Actions.** The concrete side effects — what changes
  in the outside world when a tool call succeeds. "The
  CRM record is updated with the assistant's summary."
  "An email is sent to the customer." "A refund is
  issued to the customer's card."
- **Existing identity model.** How the tool call
  currently authenticates — as the caller (via OAuth
  on-behalf-of, SPIFFE, delegated credential), as a
  service account, or as a shared token.
- **Existing HITL surface.** Any approval or confirmation
  step already in place, and where in the user flow it
  fires.

If the agent is small — three tools or fewer — the exercise
is easy but still requires the argument for each choice.
If the agent is large — a dozen or more — cover every tool;
the artefact scales with the product.

---

## Requirements

### Deliverable A — the tool inventory

A table with one row per tool:

| Tool name | Description (one line) | Blast-radius tier | Current identity scope | Current ACL / HITL (if any) | Where it lives (code / config) |
| --- | --- | --- | --- | --- | --- |

- **Blast-radius tier** uses the chapter-03 taxonomy: T0
  (read, non-sensitive, idempotent), T1 (read-sensitive
  or scoped-write), T2 (cross-boundary write), T3
  (irreversible / high-financial / safety-critical).
- **Current identity scope** is one of: `caller_only`,
  `workload`, `delegated`, `shared_service_account`,
  `shared_api_key`. The last two are red flags — name
  them if they exist today.
- **Current ACL / HITL** describes what is in place
  *today*. "None" is a valid answer for today; the
  target-registry deliverable is where the design
  changes.
- **Where it lives** points at concrete code or config.

The inventory is a facts-of-today document; the tiering
argument goes in the memo (Deliverable E).

### Deliverable B — the target tool registry

A machine-readable registry (YAML or structured JSON)
specifying every tool. Suggested schema:

```yaml
tools:
  - name: crm.get_customer
    version: v3
    tier: 1
    description: "Fetches a customer record by ID; scoped
                  to the caller's tenant."
    parameters_schema: { ... }         # JSON Schema, strict
    identity_scope: caller_only
    provenance_policy:
      max_source_trust: tenant
      reset_on: [session_end]
    hitl_policy:
      mode: audit_only
      approver_selector: self
      approval_channel: chat
      display_template: |
        The assistant read customer <name> (<id>).
      cool_off_seconds: 0
      max_batch: 100
      policy_name: null
    rate_limit:
      per_caller_per_minute: 60
      per_caller_per_day: 5000
    audit: standard

  - name: mail.send
    version: v2
    tier: 2
    description: "Sends an email on behalf of the caller."
    parameters_schema: { ... }
    identity_scope: caller_only
    provenance_policy:
      max_source_trust: tenant
      reset_on: [human_ack]
    hitl_policy:
      mode: in_band
      approver_selector: self
      approval_channel: chat
      display_template: |
        Send email:
          To: {{recipients}}
          Subject: {{subject}}
          Body preview: {{body_preview}}
      cool_off_seconds: 30
      max_batch: 5
    rate_limit:
      per_caller_per_hour: 20
      per_recipient_per_day: 3
    audit: high

  - name: payments.transfer
    version: v1
    tier: 3
    description: "Moves funds between accounts the caller controls."
    parameters_schema: { ... }
    identity_scope: caller_only
    provenance_policy:
      max_source_trust: system
      reset_on: [human_ack]
    hitl_policy:
      mode: out_of_band
      approver_selector: manager
      approval_channel: sso_mfa
      display_template: |
        Approve transfer:
          From: {{from_account}}
          To: {{to_account}}
          Amount: {{amount}}
          Policy: {{policy_name}}
      cool_off_seconds: 300
      max_batch: 1
      policy_name: "financial-transfer-policy-v3"
    rate_limit:
      per_caller_per_day: 5
    audit: high
```

Rules the registry must obey:

- Every tool has a `tier`, `identity_scope`, and both
  `provenance_policy` and `hitl_policy` set explicitly —
  no defaults, no missing fields.
- `identity_scope: workload` requires a written
  justification in the memo. `shared_service_account`
  and `shared_api_key` are prohibited outputs — if the
  current inventory has them, the target registry lifts
  them to `caller_only` or `delegated`.
- `provenance_policy.max_source_trust` for T2 is at
  least `tenant`; for T3 is `system`.
- `hitl_policy.display_template` is a rendered summary
  the human reads, not a raw JSON dump. Argument
  interpolation names the fields the user must inspect.
- Every T3 tool has a named `policy_name`.

### Deliverable C — HITL UX sketch

For every Tier-2 and Tier-3 tool, a rendered example of
the HITL surface the human sees. This can be:

- A screenshot / mockup of the chat card ("Approve /
  Cancel").
- A Markdown mockup of the out-of-band approval
  message.
- A screenshot / mockup of the SSO step-up prompt.

Each mockup must **explicitly show** the resolved
arguments the user is approving — for `mail.send`, the
full list of recipients (not just "the customer");
for `payments.transfer`, the destination account and
amount side-by-side with the named policy.

Bonus: for one Tier-2 tool, show the **batch-approval**
UX — five drafts as a single card with a summary and
individual "review each" links.

### Deliverable D — usability-tax analysis

Pick one representative user flow — 30–60 seconds of
typical usage, described as a step-by-step user script.
Then walk the runtime through the flow and count:

- How many tool calls fire.
- How many are T0 (silent), T1 (audit-only), T2 (in-
  band interrupt), T3 (out-of-band).
- How many *interrupts* the user sees.

For each interrupt, argue whether it earns its cost.
Rules:

- **A user who sees the same in-band interrupt more
  than 3 times in a flow will start rubber-stamping.**
  If your design produces that, redesign the tier or
  add batching.
- **Cool-off must be tuned.** For a tool used often
  (e.g. drafting a series of similar emails), a 30-
  second cool-off is a permission-cache; the fourth
  send in a row does not re-interrupt.
- **A T3 tool that fires 5+ times per user per day
  suggests the tool should be split.** T3 is for the
  irreversible; if it fires that often, the *action*
  is not actually irreversible, or the tool's scope is
  too broad. Note it and propose a split.

The output is a table:

| Step | Tool called | Tier | Interrupt? | Justification |
| --- | --- | --- | --- | --- |

Followed by a paragraph naming any interrupt that is a
usability risk and how the design addresses it.

### Deliverable E — design memo

~2 pages. Written for the engineering lead who will
implement the registry. Answer in order:

1. **What the agent is and what its tool surface looks
   like.** One paragraph.
2. **Tiering argument.** For every tool that is not
   T0, one line justifying the tier. Especially for
   T2 vs T3: name the reversibility argument.
3. **Identity choices.** Any tool that is not
   `caller_only` — the reason, the compensating
   control, and the review cadence.
4. **HITL choices.** For each Tier-2 and Tier-3 tool,
   the reason for the specific `mode`, `approver_
   selector`, and `approval_channel`. Especially for
   Tier-3: why the approval channel is out-of-band
   and what named policy backs the decision.
5. **Provenance composition.** How chapter-02's
   provenance labels enter the tool gate. State the
   `max_source_trust` band per tier and any tools
   that require `human_ack` to clear contamination.
6. **Test criteria.** Three or more concrete tests
   the implementation must pass:
   - A T3 call attempted after an untrusted fragment
     entered context is blocked without a human ack.
   - A batch-of-5 send with an out-of-list recipient
     triggers a new interrupt even inside the batch
     cool-off.
   - A workload-scope tool call by a caller with no
     paired delegation is refused.

Cite:

- The framework the registry integrates with (MCP /
  LangGraph / Assistants / custom).
- The identity primitive the registry consumes
  (mod-103 workload identity / mod-105 dynamic
  credentials).

---

## Starter guidance

- **Do the inventory first.** Trying to design tiers
  before you have a clean list of tools produces a
  half-inventory. Get the facts down before assigning
  values.
- **Ask "what does one call, with attacker arguments,
  actually do?"** for every tool. That is the tier.
  A tool's *typical* effect is not its blast radius;
  its *worst-case single-call* effect is.
- **Split power tools.** A `db.query_raw` tool is
  almost never the right shape; you can propose a
  split (`db.get_customer_orders(customer_id)`,
  `db.list_active_shipments(warehouse_id)`) even if
  today's product ships the raw one. The proposal is a
  legitimate design output.
- **Do the display template early.** Trying to write
  the ACL without knowing what the human sees leads
  to unreadable approval prompts. The template
  clarifies which arguments matter.
- **Cool-off is not "throttle".** It is a permission
  cache: after one approval, related calls proceed
  silently until a change signal fires. Design the
  change signal (new recipient, new amount, tool
  switch).
- **Out-of-band is a channel change.** SSO step-up
  MFA, a Slack DM from a separate bot, a signed
  email. In-band-in-a-different-widget is still
  in-band.

---

## Acceptance criteria

A passing bundle:

- Inventory names every tool with tier, identity
  scope, and current ACL/HITL status.
- Target registry is complete and valid — every tool
  has all required fields; no `shared_*` identity
  scopes in the target; no missing `policy_name` on
  Tier-3 tools.
- HITL UX sketches show resolved arguments for every
  T2 and T3 tool.
- Usability-tax analysis walks a representative flow
  with tool-by-tool tiers and identifies any
  rubber-stamp risk.
- Memo argues the tiering, identity, HITL, and
  provenance choices, and names three or more
  concrete test criteria the implementation must
  meet.
- Cross-references to chapter 02 (provenance) and
  chapter 05 (severity) are present where relevant.

A failing bundle:

- Every tool tiered T0 or T1 (a suspicious tiering —
  ask what an attacker can do).
- Every tool tiered T3 (a suspicious tiering — the
  ACL will produce a rubber-stamp UX).
- HITL display templates that are raw JSON dumps.
- No provenance rule for T2 / T3 tools.
- `workload` identity scope without written
  justification.
- Missing test criteria — the design cannot be
  verified.

## Stretch goals

- **Simulated-approver spec.** Write the two
  simulated-approver personas (conservative,
  permissive) chapter 04's harness will use to
  measure the HITL bypass rate. Name what each
  approver looks at and what heuristics they use to
  decide.
- **Cross-tool dependency graph.** Some tool calls
  presuppose others (e.g. `mail.send` after
  `contacts.lookup`). Sketch a graph and note where
  a cross-tool provenance contamination path exists.
- **Registry versioning and rollout plan.** How the
  registry migrates from today's inventory to the
  target — a phased plan with named milestones,
  including a "grace period" configuration.
- **CI gate.** Any change to the registry runs a
  policy-lint that enforces the rules above; PRs
  that add a `workload` scope require security
  review.
- **Framework-specific export.** Emit the registry
  in the format your framework expects (MCP tool
  descriptors, LangGraph tool definitions, OpenAI
  Assistants config).

## Do not

- Do not ship a target registry that keeps
  `shared_*` identity scopes; if today's product
  has them, the target lifts them.
- Do not design HITL to fire on every T1 call —
  audit is the pattern; interrupt is not.
- Do not put credentials, tenant IDs, or model-
  visible secrets in the registry.
- Do not treat MCP / a framework as "the ACL" — the
  framework is the substrate; the ACL is your
  design on top of it.
- Do not commit a solution here — solutions live in
  the paired solutions repo.
