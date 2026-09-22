---
type: reference
status: active
updated: 2026-09-19
---

# Glossary

**Art-Net** — An Ethernet protocol for transporting DMX-style lighting data over IP networks.

**Channel** — One 8-bit control value in a DMX universe, conventionally numbered 1–512.

**Cue** — A stored lighting state or transition that can be recalled during a show.

**DMX512** — A unidirectional digital control standard widely used for entertainment lighting and effects.

**Fixture** — A controllable lighting or effects device. A fixture may consume one or many DMX channels.

**Fixture definition/profile** — Structured metadata describing a fixture's modes, channels, capabilities, defaults, and control semantics.

**Look** — The visual result produced by a set of fixture parameters.

**Patch** — The mapping between logical fixtures and physical output addresses/universes.

**RDM** — A bidirectional extension to DMX512 used for discovery, configuration, and status where supported.

**sACN / E1.31** — A standard for transporting lighting-control data over IP networks.

**Scene** — A saved static lighting state. Some systems use “scene” and “cue” differently.

**Universe** — A logical group of up to 512 DMX slots transmitted as a unit.

**Show** — The production project that owns configuration templates, venues, presets, cues, scripts, and assets.

**Configuration template** — A reusable show configuration containing a saved drawing and production inventory. Venues start from a selected revision and adapt it locally.

**Venue configuration** — One show's venue-specific layout, equipment, patch, role mapping, and programming adaptations.

**Override** — An explicit venue-level change to an inherited value. Removing an override restores inheritance; zero remains a valid explicit value.

**Preset** — A reusable set of DMX parameter intents applied to compatible fixture roles, groups, or instances.

**Script** — The expected sequence of cue references and operator instructions. The same cue may appear in multiple distinct script entries.

**Local bridge** — The proposed venue-local component responsible for authenticated control, validated run snapshots, and physical output transport.

**Run snapshot** — An immutable, fully resolved combination of show, venue, script, patch, asset, and profile revisions used for a particular run.
