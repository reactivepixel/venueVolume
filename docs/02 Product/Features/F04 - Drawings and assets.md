---
type: feature
id: F04
status: specified
owner: product-and-engineering
updated: 2026-09-19
---

# F04 — Drawings and assets

## Intent and basis

Confirmed need; format scope open. Save CAD drawings with templates, adapt drawings per venue, and retain supporting production files.

The domain requested by the founder is authoritative. Detailed policies below are proposed requirements pending R&D validation, not evidence of implemented production behavior.

## Data and rules

Entities: Asset, AssetRevision, ConversionJob, DrawingDocument, Layer, Placement.

Preserve original uploads and versioned derived previews. Store units, scale, coordinate system, layers, and stable references from placements to equipment. A venue drawing override is distinct from its template original. Native CAD editing is not yet a commitment.

## Interface responsibilities

Provide file library, upload progress/failure, template and venue drawing canvases, layer controls, equipment selection, scale/position inspection, and unsupported-format states.

Wireframe and high-fidelity screens are mapped in [[../Design/Screen Inventory|Screen Inventory]]. See [[../Design/Interaction Coverage|Interaction Coverage]] for what the prototype actually implements.

## API, storage, and service responsibilities

Object storage plus metadata records; authorized upload/download, checksums, format validation, quota checks, isolated conversion jobs, and retries. Supported DXF/DWG/PDF/SVG formats and licensing require an R&D decision.

## Runtime and operational responsibilities

Bundle the required validated drawing preview for offline use; runtime uses compiled fixture mapping, not geometry as an implicit DMX command.

## Acceptance scenarios

Uploading a new revision retains the previous original; a failed converter does not mark an asset ready; venue placement edits leave the template unchanged; unit conversions preserve known dimensions.

Apply tenant isolation, revision conflicts, invalid input, empty/loading/error, and permission checks where relevant. Test against resolved data rather than only the presentation.

## Relationships

- [[Feature Catalog]]
- [[../../03 Engineering/Domain Model|Domain Model]]
- [[../../03 Engineering/Service and Runtime Boundaries|Service and Runtime Boundaries]]
- [[../Design/Screen Inventory|Screen Inventory]]

