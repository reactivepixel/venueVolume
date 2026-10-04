---
type: feature
id: F03
status: revised
updated: 2026-10-04
---

# F03 — Load Outs (replaces configuration templates)

A Load Out is the selected physical fixture inventory, placement and patch for one imported scanned venue. Multiple Load Outs can exist per venue. The historical filename is retained for existing links; the old template-to-venue creation workflow is superseded.

Create from an existing scan, select inventory, place fixtures, patch and review. Duplicating a Load Out creates an independent plan in the same room using the same unit IDs; it does not create hardware. A Tour stop owns a dedicated Load Out seeded with the Tour's base inventory selection. Venue additions remain local, and later base changes require review.

The SaaS prototype supports these preparation records locally, numeric coordinates and a schematic plan. Browser Gaussian rendering, cloud persistence, production program binding and native sync remain open. See [[../Design/SaaS UX Review - Scanned Venues and Load Outs]] and [[../../03 Engineering/Domain Model]].
