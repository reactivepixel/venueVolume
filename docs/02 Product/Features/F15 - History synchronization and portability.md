---
type: feature
id: F15
status: specified
owner: product-and-engineering
updated: 2026-09-19
---

# F15 — History synchronization and portability

## Intent and basis

Supporting requirement. Track changes, recover revisions, preserve offline work, and export a complete show.

The domain requested by the founder is authoritative. Detailed policies below are proposed requirements pending R&D validation, not evidence of implemented production behavior.

## Data and rules

Entities: ChangeEvent, Revision, SyncCheckpoint, ConflictRecord, ExportManifest.

Differentiate draft, published, downloaded, and active revisions. Audit who changed what and at which scope. Restore creates a new revision. Concurrent edits use explicit conflict handling. Portable bundles include schema versions and referenced profiles/assets.

## Interface responsibilities

Provide history, revision review, restore confirmation, sync badges, conflicts, export progress, corrupted-import errors, and unsaved-navigation handling.

Wireframe and high-fidelity screens are mapped in [[../Design/Screen Inventory|Screen Inventory]]. See [[../Design/Interaction Coverage|Interaction Coverage]] for what the prototype actually implements.

## API, storage, and service responsibilities

Use optimistic concurrency, durable revisions, atomic publication, backup/restore, tenant-scoped asset manifests, and schema migrations. Large assets use checksummed references and availability tracking.

## Runtime and operational responsibilities

Local runtime verifies bundle integrity and compatibility before arming. A cloud sync must not replace the active run. Logs distinguish desired, sent, acknowledged, and observed state.

## Acceptance scenarios

Two editors cannot silently overwrite the same revision; a missing bundle asset prevents a false ready state; interrupted writes are recoverable; export/import preserves script references, overrides, and fixture profiles.

Apply tenant isolation, revision conflicts, invalid input, empty/loading/error, and permission checks where relevant. Test against resolved data rather than only the presentation.

## Relationships

- [[Feature Catalog]]
- [[../../03 Engineering/Domain Model|Domain Model]]
- [[../../03 Engineering/Service and Runtime Boundaries|Service and Runtime Boundaries]]
- [[../Design/Screen Inventory|Screen Inventory]]

