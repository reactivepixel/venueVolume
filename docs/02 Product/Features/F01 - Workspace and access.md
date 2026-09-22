---
type: feature
id: F01
status: specified
owner: product-and-engineering
updated: 2026-09-19
---

# F01 — Workspace and access

## Intent and basis

Proposed SaaS support. Sign in, create a workspace, invite people, assign scoped roles, inspect plan and billing.

The domain requested by the founder is authoritative. Detailed policies below are proposed requirements pending R&D validation, not evidence of implemented production behavior.

## Data and rules

Entities: Workspace, Membership, Invitation, RoleGrant, Subscription.

Workspace isolation is enforced on every request and asset read. Owner, editor, operator, and viewer grants are explicit; operating a show is a separate capability. Invites expire and are single-use. Pricing and quota values remain undecided.

## Interface responsibilities

Show invitation status, expired links, access denial, and session expiry. Never treat hidden buttons as authorization.

Wireframe and high-fidelity screens are mapped in [[../Design/Screen Inventory|Screen Inventory]]. See [[../Design/Interaction Coverage|Interaction Coverage]] for what the prototype actually implements.

## API, storage, and service responsibilities

Authenticate requests; scope all entity queries to workspace and show; audit grants, revocations, and sensitive actions. Billing webhooks must be signed, idempotent, and retryable.

## Runtime and operational responsibilities

A published active run must not stop merely because an editing session or subscription expires; offline authorization policy requires validation. New run admission and editing entitlements can be evaluated independently.

## Acceptance scenarios

A user in workspace A cannot read or mutate workspace B by substituting an ID; an operator cannot edit profiles without a separate grant; expired invites cannot be reused.

Apply tenant isolation, revision conflicts, invalid input, empty/loading/error, and permission checks where relevant. Test against resolved data rather than only the presentation.

## Relationships

- [[Feature Catalog]]
- [[../../03 Engineering/Domain Model|Domain Model]]
- [[../../03 Engineering/Service and Runtime Boundaries|Service and Runtime Boundaries]]
- [[../Design/Screen Inventory|Screen Inventory]]

