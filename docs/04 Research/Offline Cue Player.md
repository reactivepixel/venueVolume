---
type: hardware-design
status: proposed
owner: engineering
updated: 2026-10-03
---

# Offline Cue Player

The proposed Venue Volume cue player stores a compiled venue-specific show locally and emits DMX512 and Art-Net after the uploading app disconnects. Initial loading uses local Ethernet or USB from a computer; an internet connection is not required if the bundle already exists locally.

The [hardware packet](../../hardware/cue-player/README.md) specifies a Teensy 4.1 carrier, two independently isolated physical outputs, eight logical network universes, microSD, front-panel playback, external 5 V power, USB/Ethernet upload contracts, an enclosure, a bill of materials and prototype tests. The [printable schematic and build guide](../../output/pdf/venue-volume-cue-player.pdf) accompanies editable SVG sheets and machine-readable connectivity.

A venue console can receive the player's levels only through an explicitly supported DMX or Art-Net input/merge path. Direct connection to lighting distribution is the default topology. This hardware does not convert Venue Volume cues into a console's native show file or make two DMX outputs safe to connect together.

This is an unbuilt reference design. Native ECAD capture, layout, Gerbers, firmware, real fixture compilation and physical verification remain to be implemented. Current visionOS palettes contain preview mappings, not a safe production export contract.

Art-Net revision 1.4dp deprecates Port-Address zero. New routes in this proposal default Universe 1 to 0:0:1; the existing F08 0:0:0 example is a deliberate legacy compatibility mapping and must never be silently renumbered.

Related requirements: [[../03 Engineering/Service and Runtime Boundaries]], [[../02 Product/Features/F08 - Patch and routing]], [[../02 Product/Features/F11 - Cues and state transitions]], [[../02 Product/Features/F14 - Local bridge and diagnostics]], [[Test Rig Matrix]].
