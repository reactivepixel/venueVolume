# Local and remote dev integration — v0.2.10

Merged local dev `1aacf4e` with remote dev through `ef7a9f9` (toolbar Palm Map v0.2.9). Retains local touring inventory, viewer navigation, plane movement and viewer-origin palette application alongside remote attribute palettes, phasers, groups and placement links.

Conflict resolutions preserve palette dependencies in saves/audit history, combine touring inclusion masks with palette attributes, render touring phasers through their per-channel bindings, and commit map navigation into the shared viewer pose. Group body/surface movement validates and publishes the full selection atomically. Placement handoff arms the same existing fixture without adding a duplicate. The single bottom controls attachment provides the explicit Palm Map button.

Validation:

- Core: 104 Swift Testing tests and 6 XCTest palette/phaser tests passed.
- All session smoke groups passed, including added touring phaser phase/mask checks and group surface-placement Undo.
- Signed Debug visionOS device build passed with bundle version 0.2.10.
- Asset verification passed for 252 catalog models and all bundled rooms.
- Design studio: npm ci, unit tests and production build passed.
- Marketing: npm ci and production build passed.

Device installation and launch are recorded in the task result. These automated checks do not establish wearer acceptance of physical gestures, comfort or headset performance.
