# visionOS validation checklist

This is the current Mac and headset acceptance checklist. It replaces the temporary handoff without converting historical passes into acceptance of newer assets or physical interactions. Follow the repository AGENTS.md in an assigned worktree before making changes.

## Recorded results

The [dated Mac archive](validation/2026-10-01-to-03-mac-validation.md) preserves commands, fixes and screenshot links. Its final integration report, dated 2026-10-03 for v0.1.27, records 45 passing Core tests, five session check groups, verification of 252 bundled models and rig companions, and a successful Simulator build. Earlier pilot runtime and Toolbox window smoke checks passed. A signed headset install passed, but the latest recorded remote launch timed out; an earlier Toolbox build launched successfully.

These results do not establish full-catalog RealityKit import, physical gesture acceptance or live scanning. The v0.2.0 version bump does not supply new validation evidence.

## Mac validation

Run the reusable commands in the [README validation runbook](../README.md#validation) from apps/visionos, in the assigned worktree. Record the tested commit, Xcode and OS versions, commands, counts, failures and evidence in a new dated report under docs/validation. Archive useful logs there or in an agreed durable location; Mac-local /tmp paths alone are not durable evidence.

- [ ] Core tests, all session check groups and bundle verifier pass on the tested commit.
- [ ] Unsigned Simulator and device builds pass. Confirm the built bundle version matches the release settings; do not treat source-only checks as a new Xcode build.
- [ ] Run ./scripts/run-demo.sh --blue --catalog-smoke and capture the console. At this checkpoint expect 252 CATALOG_RIG_PASS lines and CATALOG_SMOKE_PASS assets=252. Any CATALOG_SMOKE_FAIL is a failure, even if the app continues. Reconcile expectations with the current catalog if it changes.
- [ ] Run the history and input smoke paths and record ROOM_LIBRARY_SMOKE_PASS, AUDIT_HISTORY_SMOKE_PASS, TOOLBOX_WINDOW_SMOKE_PASS and SPATIAL_INPUT_SMOKE_PASS.
- [ ] Visually inspect imported geometry and moving parts. Import success does not prove shape fidelity or simulated gesture behavior.

The checkpoint contains 323 research rows, 252 packaged models, 175 articulated models and 322 preview joints. Use the [pipeline status](../../../assets/fixtures/research/pipeline-status.json) and [CSV](../../../assets/fixtures/research/show-equipment-catalog.csv) as the current per-item authority. Update native_validation only for assets actually tested and republish pipeline status. Do not clear pipelineErrors or visual findings merely because a build passed.

## Representative asset checks

- [ ] Rogue R1X, older Robe ColorSpot and ColorWash AT, and MAC 2000: fixed base, correctly attached yoke, head and optics, pan and tilt limits, and eligible head targeting.
- [ ] Intimidator Spot Duo: independently moving heads and matching emitters; no single-head target solver offered for the compound fixture.
- [ ] KLS-120, tilting bars, GLP JDC1, Volero Wave and manual PAR or Fresnel brackets: correct independent modules, fixed supports and explicit manual versus motorized controls.
- [ ] Volero Cube, MAC Aura Raven XIP and MAC One Beam: preserve model-specific optics through import and articulation.
- [ ] Antari B-200: six rotating wheels share the axle; manual bracket tilt carries the assembly while the support stays fixed. No particle or light emission.
- [ ] Antari Z-1200III, S-100X, S-200X and SW-250: manual bracket tilt is not labeled as a physical motor.
- [ ] X-Move Laser: two preview joints, no ordinary light emitter and no head targeting. Scorpion Dual RGB: manual bracket only, no simulated scanning pattern or laser beam.
- [ ] Fans, mirror mechanisms and cameras: intended pivots and fixed supports. SHOWVEN SPARKULAR, MDG, Look Solutions and Le Maitre equipment remain stable and do not emit unintended spotlights.
- [ ] ETC ColorSource PAR jr, Astera AX5, F-1, HZ-1000, Entour Venue, G300, GForce 3, MAC 2000 Profile and MAC 2000 Wash retain their nine visual-review flags until separately resolved against sources. See the expansion-v2 and expansion-v3 visual-review issue registries.

## Interaction and headset acceptance

- [ ] Confirm actual fixture gaze/pinch selection, background deselection, axis drags, preset drops, item editing, naming and Clear all confirmation.
- [ ] Test held Target preview and Save/Cancel. Current Save writes Pan/Tilt to the shared preset and updates affected assignments; legacy per-fixture overrides are cleared. Test new drafts, shared assignments, selection changes, Undo/Redo and saved setup restoration. Mount targeting menus were removed; use axis controls for mount transforms.
- [ ] Confirm palm recall opens the normal repositionable Toolbox window once per raised-hand edge. Lowering the hand leaves it open; close while raised stays closed; lowering and raising recalls it. Verify manual recall and movement. Wrist-following is obsolete, not an acceptance requirement.
- [ ] Retry or manually confirm normal-mode launch on a worn, unlocked headset without demo/reset flags. Preserve existing user arrangements.
- [ ] Grant World Sensing permission, capture a real room, save and reopen the scan, place fixtures on scanned surfaces, target them and verify relaunch persistence. Synthetic mesh replay is not live scan evidence.
- [ ] Exercise search/filter, cold loading and selection during loading, room switching, old Rogue setups, joint overrides and grouped Undo/Redo.
- [ ] Test a mixed 64-object scene, eight-beam allocation with selection priority, and a multi-emitter model. Measure loading, memory, frame time, tracking alignment, comfort and thermal behavior on headset.
- [ ] Confirm fixture and global blackout scope, unchanged channel data, animation comfort and Reduce Motion behavior.

## Visualization boundaries

Rig companions drive preview joints; these are not baked USDZ animation clips or manufacturer control profiles. VV Preview 16 remains synthetic. Manufacturer DMX personalities, ILDA, external/manual controls, calibrated photometry, unlimited physical rotation, pixel programming, gobos, smoke particles, laser patterns and safety-critical effect firing are not implemented. Never infer safe hardware operation from these visual assets.

## Fortress review

The [Fortress review gallery](../../../outputs/the-fortress/index.html) contains an estimated venue blockout with four cutaways and a floor plan. Blender and USDZ structural checks are recorded, but physical dimensions are unmeasured and RealityKit import remains pending. Validate it separately; do not substitute it for live scanned-room acceptance or alter its evidence to make tests pass.

## mappedRoom and expanded lighting budgets

The [mappedRoom lighting runbook](MAPPED_ROOM_LIGHTING.md) records the new work and the exact A/B procedure. Linux Core/session checks and Blender tests do not replace the unchecked native acceptance below.

- [ ] Build this revision in Xcode for Simulator and device; confirm both bundled rooms import, including all six mapped textures.
- [ ] Open mappedRoom on an existing installation; confirm old history does not hide it, placements remain isolated, and saved white/material overrides persist.
- [ ] Test static and moving 64-fixture scenes in both rooms at 0/1/2/4/8/16/32/64 requested shadow beams. Verify the visible active count, not just component allocation.
- [ ] Record RealityKit Trace GPU/CPU timing, compositor misses, memory, ten-minute thermal soak and visual shadow/occlusion correctness. Select the highest repeatably smooth budget on the oldest supported headset.
- [ ] Verify selection priority, multi-emitter budget, blackout, non-emitting fixtures, and thermal reduction/recovery without losing fixture data.
