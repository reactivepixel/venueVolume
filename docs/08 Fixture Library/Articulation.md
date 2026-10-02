# Fixture articulation in visionOS

All 127 existing packaged models are included in the visionOS library. Of these, 72 have moving geometry described by 128 joints; 55 use their existing static geometry. The runtime uses rigid transform hierarchies, with the Mac-validated pilot's scalar interpolation and per-instance pose workflow. New catalog integration still requires its own native validation.

The machine [runtime catalog](../../assets/fixtures/runtime-catalog.json) identifies every asset, bundle path, dimensions, joint controls and emitter attachments. Each asset directory now contains `models/rig.json` and `validation/rig.json`. The original `fixture.blend`, `fixture.usdz`, source evidence and geometry hashes are preserved. A companion rig is required to animate these USDZ files; they do not contain baked animation clips.

The [show equipment CSV](../../assets/fixtures/research/show-equipment-catalog.csv) and [manufacturer CSV](../../assets/fixtures/research/major-manufacturer-fixtures.csv) include `animation_state`, `rig_asset`, `rig_joint_count`, and `visionos_asset`. The nine research-only rows retain their status and have no invented runtime assets. The [rollout summary](../../assets/fixtures/research/articulation-rollout.json) and [OpenUSD validation](../../assets/fixtures/research/articulation-validation.json) provide complete coverage and per-model results.

| Modeled mechanism | Runtime behavior |
| --- | --- |
| 46 moving light heads | Yoke pan, head tilt, emitter inheritance and head/mount targeting |
| GLP X4 Bar 20, X5 Bar 1000, JDC1 | Housing tilt with the base and support brackets fixed |
| Claypaky Volero Wave | Eight independent head pivots and emitter anchors; supports remain fixed |
| ADJ Dynasty Scan DMX | Two mirror axes; illustrative ray follows the mirror |
| Conventional fixtures with modeled yokes | Manual bracket tilt controls |
| RoboSpot MotionCamera | Pan and camera tilt; no light output |
| ADJ Entour Cyclone | Manual bracket tilt and continuous rotor speed; no light output |
| Mirror motor and ball | Shaft or ball rotation; separate assets, no attached motor/ball assembly |
| Other equipment | Static geometry and instance mount transforms |

Joint pivots and synthetic travel remain estimates. `VV Preview 16` is a visualization personality; rig channels are not manufacturer DMX offsets. The Rogue pilot retains its roughly 270°/120° preview travel even though its [manufacturer specification](https://chauvetprofessional.com/product/rogue-r1x-spot/) lists larger physical travel. Existing manufacturer evidence and unknown mechanical limits are preserved. Scanner reflection, photometry, gobos, internal optics, smoke particles and effect firing are not calibrated or simulated by this rollout.

The app supports 64 placed objects and eight simultaneous beam previews, allocated to the selected fixture first. All placed joints animate even when a beam is outside that preview budget. Model loading is lazy. Physical headset performance still needs measurement.

Regenerate companions and bundle copies from the repository root with an OpenUSD Python runtime:

```sh
python3 research/fixtures/build_runtime_catalog.py
python3 research/fixtures/check_runtime_rigs.py
python3 research/fixtures/build_runtime_catalog.py --check
```

On this Arch host OpenUSD needs `LD_PRELOAD=/usr/lib/libjemalloc.so.2`. The builder refuses to overwrite or package source artifacts whose recorded hashes no longer match. It generates `GeneratedFixtureCatalog.swift` for the Core module; the app's existing folder resource includes every USDZ under `FixtureAssets/Catalog/`. No Xcode source-file registration is required for generated Core files.

Linux validation passed: OpenUSD references, unique moving-part ownership, neutral pose and rigid geometry through four non-neutral poses for all 127 assets; bundle SHA-256 parity; Swift Core tests, including all moving-head aiming geometries; session tests for module overrides, persistence and grouped history. `swiftc -frontend -parse` checks syntax only for the Apple UI sources. RealityKit import and interactive behavior of this rollout await the Mac check described in [the handoff](../../apps/visionos/docs/TEMP_MAC_VALIDATION_HANDOFF.md).
