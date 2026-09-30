# Modeling and export for fixture reuse

Inspect the source drawings and downloaded images before modeling. Prefer supplied CAD
when its model identity and reuse terms match. Otherwise write an entry-local Blender
Python generator so the approximation can be rebuilt and dimensions revised. Preserve
manual edits by creating a candidate instead of rerunning a generator over edited files.

## Geometry

- Set Blender metric units with scale_length=1. Authoring can remain Z-up. Record the
  authoring-to-runtime conversion `(x,y,z) → (x,z,-y)` and apply it exactly once.
- Model the assembled fixture in the pose of the dimensional drawing. A moving head's
  bounding box changes with tilt; choose one reference pose and retain sweep/clearance
  specifications separately. Avoid sizing the whole assembled fixture from lens diameter.
- Make a single named fixture root. Keep base, yoke, head and lens independently addressable.
  Use real pan/tilt pivots where drawings support them; label inferred pivot locations.
- Put a stable emitter anchor at the lens, with local -Z pointing along the beam. Store
  anchor position and quaternion in the record. Orienting the entire housing toward -Z
  must not accidentally change the neutral mechanical pose used for dimension checks.
- Use simplified closed collision proxies separate from visible geometry. Preserve mounting
  points and functional silhouette; omit tiny screws unless they materially aid recognition.
- Keep geometry opaque where possible and use shared PBR materials. Create an emissive lens
  material separately from the light anchor. Do not bake production illumination into the body.
- Document all approximations. Known overall dimensions do not establish precise brackets,
  mass distribution, photometry or permissible loads.

## Export and review

Save editable `models/fixture.blend` with sources linked relatively or appropriately packed.
Export only the fixture runtime hierarchy to `models/fixture.usdz`. Keep comparison grids,
reference images, cameras and review lights out. Use Blender's USD exporter or OpenUSD
packaging; preserve Xform parents, evaluated modifiers, normals, materials and meter/Y-up
metadata. Do not flatten moving parts through the static room exporter.

Render and inspect front, side, rear and three-quarter images alongside a 1m scale bar or
labeled dimensions. Check shape against manufacturer images. Reopen the USDZ independently;
check articulation names, origins, material references and actual dimensions. Run:

```sh
/path/to/blender --background --factory-startup --python-exit-code 1 \
  --python /path/to/create-venue-fixture/scripts/check_usdz.py -- \
  /path/to/fixture.json
python /path/to/create-venue-fixture/scripts/library.py validate \
  --root /path/to/venueVolume /path/to/fixture.json
python /path/to/create-venue-fixture/scripts/library.py index --root /path/to/venueVolume
```

`check_usdz.py` expects the runtime artifact path and sourced dimensional facts to be filled
in first. It measures the actual USDZ, writes `validation/usdz.json`, and does not alter the
record. Update bounds and hashes in the record from that report, then validate again. It
requires Blender built with OpenUSD Python bindings (the project's Blender 4.5 runtime has
these). If unavailable, retain the draft and report the missing exporter/validator dependency.

When modifying the record helper, run `python scripts/test_library.py` from the skill
directory. Those tests use temporary records and stub artifacts to exercise evidence,
revision-file integrity and readiness checks; they do not substitute for checking a real USDZ.

RealityKit validation is a separate Mac/headset step: load the USDZ, compare a 1m reference,
verify the root/part/emitter transforms, move the head/yoke through supported ranges, and
inspect lit materials. Mark `verification.realitykit` as `passed` only with an actual test
record. USD compatibility and Blender previews are not that test.

Remote delivery should later package the runtime asset, manifest and permitted textures
independently of venue scans. Keep `.blend`, generators and research references in the
library authoring source. Neither a model nor transcribed DMX values authorizes emitting
live hardware commands; library creation itself performs no device output.
