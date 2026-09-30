# Fixture library record contract — version 1

Repository layout:

```text
assets/fixtures/catalog.json
assets/fixtures/<manufacturer>/<model-variant>/
  fixture.json
  sources/                 downloaded reference images, drawings, manuals, CAD/GDTF
  models/fixture.blend      editable source, one documented neutral pose
  models/fixture.usdz       complete portable runtime asset
  models/build_fixture.py  reproducible modeling/export or CAD-conversion script
  previews/                front, side, rear, three-quarter and dimensional review
  validation/usdz.json     measured exported geometry and checks
  validation/realitykit.md optional actual Mac/headset test record
  revisions/               previous manifests and changed local artifacts as needed
docs/08 Fixture Library/entries/<manufacturer>/<model-variant>.md
docs/08 Fixture Library/Catalog.md
```

Use lowercase ASCII slugs with hyphens. `id` is `<manufacturer>/<model-variant>`, matching
the record's directory exactly. Variant identity includes any body/lens/generation option
that changes geometry, optics or DMX. An alias is not a new fixture. Revisions are positive
integers; use ISO dates. `status` is `draft`, `researched`, or `ready_for_visualization`.
The last means packaged and dimension-checked, not hardware-verified or runtime-integrated.

## Evidence and facts

Every source has `id`, `url` (HTTPS when online, null for a user measurement), `title`,
`kind` (`manufacturer_product`, `manufacturer_manual`, `manufacturer_drawing`,
`manufacturer_asset`, `secondary`, `measurement`), `accessed_at`, `document_revision`,
`locator` (page, section, figure, or table), and `reuse_status`. Optional `file` is a path
relative to this fixture directory with `sha256`. Downloaded source copies are research
assets, distinct from distributable runtime assets. Reuse status may be `unknown`.

A fact is `{ "value": ..., "unit": ..., "status": ..., "source_ids": [...] }`.
Statuses: `documented`, `measured`, `estimated`, `unknown`. Unknown values are null.
Documented/measured facts require evidence. Estimated values need an explanatory `note`;
the associated sources explain the estimate, not manufacturer endorsement of it.
Keep original units/wording in optional `source_value`, `source_unit`, and `note`.
Normalize outer width/height/depth to meters and identify the source drawing's pose.
Don't include packaging dimensions, a shipping weight, or bracket-removed dimensions
as the normal assembled fixture's specification. Record those separately.

Use the four `features` groups for applicable facts. Examples: `optical.zoom_min` in deg,
`optical.luminous_flux` in lm with measurement conditions, `electrical.max_power` in W,
`mechanical.mass` in kg, `mechanical.pan_range` in deg, `control.protocols` as a list.
Keep beam angle distinct from field angle; luminous flux distinct from intensity/lux.
Specify zoom/lens/color conditions for manufacturer photometric claims. Do not derive
physical lux calibration from a marketing lumen number alone.

## DMX modes

Each mode: `name`, `footprint` (1–512), `firmware` (nullable), `source_ids`,
`mapping_status` (`not_transcribed`, `transcribed`, `bench_verified`), `channels`.
Offsets are one-based within a mode, not a venue's absolute start address. Each channel
has `offset`, `parameter`, `resolution_bits` (8 or 16), optional `fine_offset`, and `ranges`.
Each range specifies inclusive `min`, `max`, `meaning`, and any actual physical `unit` /
`physical_min` / `physical_max`. Retain reserved ranges, cross-channel dependencies,
reset/control timing, and coarse/fine ordering. Gaps in transcription remain explicit.
A transcribed mode includes all offsets; don't fill missing channels with invented data.
Bench verification needs a linked test record and hardware/firmware identification.
This schema stores research; no DMX output compiler or GDTF parser is supplied by the skill.

## Model metadata and artifacts

Model status: `not_built`, `unscaled_draft`, `scaled`, `validated`.
Representation: `manufacturer_cad` or `procedural_approximation` when built.
`bounds_m` is `{ "min": [x,y,z], "max": [x,y,z] }` measured from the exported neutral-pose
USDZ in meters, Y-up. Width maps to X, height to Y, depth to Z. Document any different
manufacturer drawing convention before making this mapping.

`origin` describes the chosen mounting/base center and pose; `reference_pose` must agree
with the dimensional reference. `dimension_tolerance_m` is an explicit absolute comparison
tolerance, chosen for source precision (normally 0.002 m or 1% of largest dimension,
whichever is larger; justify anything looser). This is a modeling check, not a rigging
clearance or load certification. Preserve actual sweep/clearance data separately.

Each part names a stable `id`, `prim_path`, and role (`base`, `yoke`, `head`, `lens`, etc.).
Joints reference parent/child IDs with pivot position in meters, unit rotation axis,
neutral transform, mechanical limits and source/estimate status. Emitters identify a prim
path, room-independent local position/quaternion `[x,y,z,w]`, optical axis, sourced optical
facts and approximation notes. Pan/tilt limits are not inferred from a model pivot.

Each artifact has `role` (`authoring`, `runtime`, `generator`, `preview`, `validation`),
`file`, and `sha256`. Paths are relative to the fixture directory and may not escape it.
A ready entry requires all five roles, known sourced dimensions, and a passing USDZ report
that matches the current runtime file hash. Four preview images should be reviewed visually.
Record sources for the model and image reuse status in assumptions / source references.

Preserve manually changed artifacts and retain old versions when updating. A future venue
instance should reference fixture ID + revision and its own transform, chosen mode and patch.
It must not modify this shared library record. Catalog JSON contains metadata and asset paths;
it is not a remote download service or an automatic importer for the current Swift app.
