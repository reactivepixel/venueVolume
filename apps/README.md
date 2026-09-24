# Applications

User-facing applications belong here. Likely candidates include a desktop lighting-control application, a web-based remote, and test utilities.

- `design-studio/`: React prototype and screen gallery for the SaaS DMX/Art-Net controller; includes wireframes and high-fidelity mockups. It sends no physical output.
- `marketing/`: Statically rendered Astro alpha-access page using the selected Void direction and a console-only mock signup.
- `visionos/`: Native Swift visionOS prototype with spatial fixture placement, 1–16 DMX channel controls, and a following debug panel with mock HTTP sync. See its [README](visionos/README.md) for Xcode setup and headset checks.

Create an application directory only when its responsibility and runtime boundary are understood. Record consequential architecture choices in `docs/06 Decisions/`.
