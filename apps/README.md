# Applications

User-facing applications belong here. Likely candidates include a desktop lighting-control application, a web-based remote, and test utilities.

- `design-studio/`: React prototype and screen gallery for the SaaS DMX/Art-Net controller; includes wireframes and high-fidelity mockups. It sends no physical output.
- `marketing/`: Statically rendered Astro alpha-access page using the selected Void direction and a console-only mock signup.
- `visionos/`: Native Swift visionOS prototype with spatial fixture placement, 1–16 DMX channel controls, and a following debug panel with mock HTTP sync. See its [README](visionos/README.md) for Xcode setup and headset checks.
- `mov2splat/`: Headless local Docker pipeline that converts one iPhone Camera video to a standard 3D Gaussian Splatting PLY. See [setup and run instructions](mov2splat/README.md).
- `visionSplat/`: Swift visionOS demo for exploring a Gaussian PLY in a full immersive space on Apple Vision Pro. See [setup and run instructions](visionSplat/README.md).
- `unitySplat/`: Unity desktop demo with Gaussian PLY loading and first-person navigation. See [setup and run instructions](unitySplat/README.md).
- `unrealSplat/`: Unreal Engine 5 desktop demo with Gaussian PLY loading and first-person navigation. See [setup and run instructions](unrealSplat/README.md).

The three viewers share an original [synthetic room](../assets/splats/README.md). See the [viewer guide](../docs/05%20Operations/splat-viewers.md) for platform requirements and a common acceptance checklist.

Create an application directory only when its responsibility and runtime boundary are understood. Record consequential architecture choices in `docs/06 Decisions/`.
