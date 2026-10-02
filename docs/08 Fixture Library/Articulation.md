# Fixture articulation in visionOS

The expanded library includes 220 packaged models (93 additions to the 127-model baseline). Of these, 162 have moving geometry described by 302 joints; 58 are static. The runtime uses rigid transform hierarchies, with the Mac-validated pilot's scalar interpolation and per-instance pose workflow. This expanded catalog still requires its own native validation.

The machine [runtime catalog](../../assets/fixtures/runtime-catalog.json) identifies every asset, bundle path, dimensions, joint controls and emitter attachments. Each asset directory now contains `models/rig.json` and `validation/rig.json`. The original `fixture.blend`, `fixture.usdz`, source evidence and geometry hashes are preserved. A companion rig is required to animate these USDZ files; they do not contain baked animation clips.

The [complete CSV](../../assets/fixtures/research/show-equipment-catalog.csv) contains 259 items from 47 manufacturers, including 39 research-only rows without invented asset paths. The [packaged-model CSV](../../assets/fixtures/research/major-manufacturer-fixtures.csv) contains 220 models from 42 manufacturers. Both include `animation_state`, `rig_asset`, `rig_joint_count`, `visionos_asset`, `pipelineStatus` and the requested `pipelineErrors`. Errors are concise per-item explanations; locally passing models explicitly retain the pending Mac validation rather than claim full completion. Browse every item and blocker in the [complete review page](../../assets/fixtures/research/pipeline-review.html).

This is an expanded, representative catalog—not every product or regional variant from every manufacturer. The acquisition coverage registers under `research/fixtures/expansion-v2/` document brands, legacy/current variants and remaining gaps (including primary-source access for PR Lighting). High-detail models remain image-informed approximations, not manufacturer CAD or certified clearance models. Visible LED packages, optical lenses and runtime beam anchors are different counts; a single illustrative beam can represent a multi-lens wash.

Visual QA remains open on two packaged models: ColorSource PAR jr and AX5 TriplePAR have correct optical counts but stretched front housing proportions when normalized to the documented assembled envelope. Both are explicitly `visual_review_pending` with explanations in `pipelineErrors`; their successful structural/rig tests do not close this shape review.

| Modeled mechanism | Runtime behavior |
| --- | --- |
| Conventional moving light heads | Yoke pan, head tilt, emitter inheritance and head/mount targeting |
| CHAUVET DJ Intimidator Spot Duo | Two independent pan/tilt chains and two attached emitters; module controls, not single-head targeting |
| Eurolite KLS-120 | Four separate manual head pivots and four emitters; support brackets remain fixed |
| New Chroma-Q battens and ACME LIGHTNING | Manual bracket tilt; source-specific lens/diffuser and matrix details |
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

Linux validation checks OpenUSD references, unique moving-part ownership, neutral pose and rigid geometry through four non-neutral poses for all packaged assets; bundle SHA-256 parity; Swift Core tests, including every moving-head aiming geometry and compound-fixture control isolation; session tests for module overrides, persistence and grouped history. The CSV importer and desktop/mobile review pages are checked independently. RealityKit import and interactive behavior await the Mac check described in [the handoff](../../apps/visionos/docs/TEMP_MAC_VALIDATION_HANDOFF.md).

## Reproduce the expanded catalog

Run from the repository root, in this order (OpenUSD may need the preload above):

```sh
python3 research/fixtures/expand_catalog.py --refresh --workers 4
blender --background --threads 2 --python research/fixtures/audit_geometry.py -- --new-only
python3 research/fixtures/finalize_detailed_catalog.py
python3 research/fixtures/build_show_taxonomy.py
python3 research/fixtures/build_runtime_catalog.py
python3 research/fixtures/check_runtime_rigs.py
python3 research/fixtures/publish_pipeline_status.py
```

`expand_catalog.py` consumes reviewed acquisition JSON, applies explicit model overrides, downloads exact official reference images and builds candidates without overwriting manually changed artifacts. Missing source facts or unsupported geometry stop only that row. The ledger retains detailed causes; the complete CSV is the current inventory. `--only manufacturer/model` narrows a retry. The source-image cache checks both URL identity and stored hashes. Changes to a generator require rebuilding all of its consumers before final publication.
