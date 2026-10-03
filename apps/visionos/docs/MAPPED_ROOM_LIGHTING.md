# mappedRoom lighting comparison

`mappedRoom` is a separately identified classroom, with independent saved setups. Six small photo-derived base-color textures use the existing opaque mesh. The original classroom package and The Fortress are unchanged. [Assets, four cutaways and desktop results](../../room2blender/mappedRoom/README.md).

## Rendering policy

- Keep all room geometry, mesh normals, 96 collider boxes, 11 placement surfaces and the original spawn. Opaque PBR materials write depth, receive light and cast shadows. No invisible occlusion material, emissive photo surface, transparent layer or lightmap is used.
- Reuse six textures (two 512², four 256²); roughly 4 MiB as uncompressed RGBA8 including mipmaps. This is an estimate, not measured residency. No per-object image duplicates, normal maps, added geometry or material batches.
- All granted beams retain `SpotLightComponent.Shadow`. Twelve-meter attenuation bounds their influence; automatic shadow far clipping follows that radius. Black/dimmed/unloaded fixtures consume no budget. The selected fixture has priority and multi-emitter fixtures consume one slot per emitter.
- Cache light appearance/budget changes, input target mode and applied joint angles. Pan/tilt changes no longer rewrite unchanged light/shadow components; resting joints do not rewrite transforms every frame. Moving lights still update their actual transforms and shadows.
- The default remains 8 shadow beams. Diagnostics exposes 0/1/2/4/8/16/32/64. The app checks `supportsFamily(.apple6)` before allowing more than 8. Thermal policy caps fair at 16, serious at 4, critical at 0, with recovery to the requested budget as conditions improve. These are conservative policy choices, not measured thresholds. Saved fixture/DMX values remain intact.

Apple's current [SpotLightComponent documentation](https://developer.apple.com/documentation/realitykit/spotlightcomponent) describes lifted dynamic-light limits on Apple GPU family 6 and later, and warns that count, coverage and thermal state affect performance. Hardware capability is not proof that a particular OS/scene renders 64 shadow lights correctly or smoothly. Verify the emitted count visually on the supported OS range. See [reducing RealityKit rendering cost](https://developer.apple.com/documentation/visionos/reducing-the-rendering-cost-of-realitykit-content-on-visionos) for native profiling guidance.

## Repeatable native workload

Run from `apps/visionos` on a Mac with Xcode. Simulator is an import/UI smoke test only:

```sh
./scripts/run-demo.sh --lighting-benchmark=baseline --benchmark-lights=8
./scripts/run-demo.sh --lighting-benchmark=mappedRoom --benchmark-lights=8
```

For a paired, worn Vision Pro, build/sign the Release configuration in Xcode and launch with these arguments (or add them to the scheme). The benchmark flag selects temporary demo state and automatically enters the room. `VV_DEVICE` is the identifier from `xcrun devicectl list devices`:

```sh
xcrun devicectl device process launch --device "$VV_DEVICE" --terminate-existing \
  com.venuevolume.VenueVolume --lighting-benchmark=mappedRoom \
  --benchmark-lights=16 --benchmark-seconds=30 --benchmark-motion
```

Use `baseline` and `mappedRoom`, each at **0, 1, 2, 4, 8, 16, 32, 64** lights. Repeat static and `--benchmark-motion` runs three times, alternating room order. Each run uses the same 64 one-emitter Rogue fixtures, fixed UUIDs, transforms, RGB/intensity and wide beams, original material mode (`White model` off), and room light 0.05. The intentionally dense stress grid may intersect furniture; it is not a lighting plan. Geometry count stays fixed when the beam budget changes. No normal placements, presets or history are written. Scene edits invalidate the run.

A five-second warmup begins only after room alignment and all 64 rigs are ready. Then it collects 30 seconds by default (`--benchmark-seconds=5…300`). Diagnostics provides **Share benchmark JSON**; the app also saves unique JSON files under Documents/Benchmarks and emits `VV_LIGHTING_BENCHMARK` to its console. Reports include room/version/hash, OS/GPU, requested and allocated shadow counts, thermal states, update-cadence percentiles, and component/transform write counts.

**SceneEvents.Update intervals are not displayed FPS or GPU frame time.** The JSON leaves those fields null and makes no smoothness verdict. If the device/thermal cap grants fewer lights, that is not a successful test of the requested count. Changing the beam budget manually is disabled during a benchmark. Do not treat a component count as proof every beam contributes visibly.

## Headset acceptance still required

1. Capture **RealityKit Trace** in Instruments for Release builds on the oldest supported Vision Pro and current supported visionOS versions. Record hardware, OS, app commit, refresh rate and asset hashes. Use the same view/route, window state and fixtures for A/B. Stand still for a matched timing pass, then repeat while looking/walking around, aiming lights and placing objects.
2. Confirm the texture, RGB response and sharp occlusion boundaries on walls, floor and furniture. Each visible beam must light its intended surface; occluders must block it. Repeat blackout and multi-emitter cases. Do not disable shadows to inflate the light count.
3. Compare actual GPU and app CPU timings, missed compositor deadlines, memory and cold/warm loading. Target sufficient margin below the headset's current frame deadline (for example, 11.1 ms at 90 Hz; 8.3 ms at 120 Hz). Scene-update cadence alone cannot establish that margin.
4. Soak the highest passing candidate for at least ten minutes in each room. Retest during hand tracking and fixture movement. Reject sustained thermal degradation or deadline misses. The shipped default should rise only after these measurements; a budget that only works briefly is not the result we want.

## Evidence from this Linux task

49 Swift Core tests and six session check groups passed, including library upgrade/history behavior, material overrides, benchmark save isolation, thermal/hardware allocation and identical benchmark placements. Modified native files passed Swift syntax parsing; **RealityKit/SwiftUI type checking, Simulator import and physical headset execution were unavailable** here. OpenUSD validation, round-trip Blender import and exact geometry/interaction parity passed. The separate desktop experiment swept both USDZs through 0–64 synthetic spotlights; its timings are explicitly offline Cycles render costs, not headset performance. The maximum smooth Vision Pro shadow-light count remains unmeasured.
