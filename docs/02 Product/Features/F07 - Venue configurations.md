---
type: feature
id: F07
status: revised
updated: 2026-10-04
---

# F07 — Scanned venues

A venue is a captured physical room in the shared workspace library. It is not a show-owned copy of a rig template. No blank areas or CAD-created rooms are supported. The historical filename is retained for existing links.

The workspace and standalone `/upload` page accept a movie, preserve its UUID/source/checksum, submit it to Movie2Splat and show progress, failure and retry. Processing leaves the record in the inbox marked **Needs setup**. Import names the ready scan and adds it to the shared library without requiring a show, Tour or configuration. Each imported venue can then have multiple Load Outs, each with separate selected inventory, placement and patch.

A Tour can visit the venue more than once; each stop needs a dedicated Load Out. Renaming a scan must not change IDs or orphan plans. Future scan replacement must use explicit revisions and coordinate review.

The local intake service persists movies and splats; preparation records remain browser-local. See [service guide](../../../services/venue-ingest/README.md), [[../Design/SaaS UX Review - Scanned Venues and Load Outs]] and [[../../03 Engineering/Domain Model]].
