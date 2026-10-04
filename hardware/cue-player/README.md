# Venue Volume offline cue player

Revision A, engineering reference design, 2026-10-03. This packet specifies a small box that stores a venue-specific show, accepts uploads over local Ethernet or USB, and plays DMX512 and Art-Net without an app, computer, router uplink, or internet connection during the show. The initial upload can also be entirely offline if the show has already been exported.

This is a schematic and implementation specification for a prototype, not a fabricated or tested product. It includes component connections, a bill of materials, enclosure planning, firmware requirements, and a PCB release checklist. There is no routed PCB, Gerber set, implemented device firmware, or claim of console interoperability yet.

## Design target

| Item | Revision A proposal |
| --- | --- |
| Controller | PJRC/SparkFun Teensy 4.1 with Ethernet PHY, mounted on a custom carrier PCB |
| Local storage | Industrial/high-endurance 8-32 GB microSD in the controller's native SDIO socket |
| Physical outputs | Two independently isolated, output-only DMX512 universes on 5-pin XLR sockets |
| Network output | Up to eight logical universes over 100BASE-TX Art-Net; physical ports mirror two of these eight |
| Timing | 40 complete frames/second; 250 kbit/s, 8N2 on each physical DMX port |
| Upload | Local Ethernet through a companion/native app, or USB device serial from a Mac/Windows/Linux companion |
| Front controls | GO, HOLD, BACK, NEXT, BLACKOUT, PAIR; guarded ARM toggle; OLED; run and fault LEDs |
| Power | External regulated 5 V supply, 3 A selected; USB does not power the box |
| Enclosure | Hammond 1455T2201BK, nominal 220 x 165 x 51.5 mm; custom front/rear panels |
| Show operation | Manual GO or locally timed follows; no cloud lease, periodic login, or time server needed to continue playback |

Two physical outputs and eight network universes are explicit starting assumptions, not limits of the Venue Volume product. The USB host is assumed to be a computer until the target host is confirmed. Direct USB loading from visionOS or iPadOS is not promised. A Vision Pro can use the native app over a local Wi-Fi access point connected to the box's Ethernet LAN; that access point does not need internet. The enclosure contains no radio.

The module approach retains the controller's existing USB, memory, clock, Ethernet PHY, bootloader and SD circuitry. The custom PCB adds protected power, control connectors and two isolated line drivers. A later all-in-one MCU PCB is a separate redesign; do not copy this carrier's pin map into a bare processor layout.

## Files in this packet

- `schematics/`: editable SVG sheets with named electrical nets and component pins; identical names connect across sheets.
- `connectivity.json`: reference connectivity, including explicit unconnected pins; module pins use the manufacturer's signal labels.
- `bom.json` and `bom.md`: component quantities, values, packages and procurement notes.
- `electrical.md`: power, isolation, processor pin assignment, wiring and circuit calculations.
- `firmware.md`: local upload, show compilation, playback and failure behavior.
- `manufacturing.md`: enclosure, PCB design rules, assembly and acceptance tests.
- `sources.md`: manufacturer and protocol references, including unverified details to resolve before PCB release.
- `build_packet.py`: reproduces diagrams, connectivity, BOM and the printable packet.
- [Printable schematic and build packet](../../output/pdf/venue-volume-cue-player.pdf).

## How it connects at a venue

The normal route is box -> DMX fixtures or isolated splitter, or box -> Ethernet switch -> Art-Net nodes/fixtures. A console may share the network for monitoring or an explicitly configured handoff. The box performs the cue sequence itself.

If the venue wants the existing console to remain in control, the console must have a documented DMX input or an Art-Net input/merge function that accepts this source. Its universe mapping, channel ownership, merging and input licensing must be checked against that console and software version. A console's ability to output Art-Net does not establish that it can receive or merge it. Connecting two DMX outputs with a gender adapter or Y cable is not an input connection. Use a real input or an external merger with an agreed takeover policy.

DMX and Art-Net carry channel values, not a portable console cue database. This box does not install Venue Volume cues into an arbitrary desk's native show file. Triggering the desk's own cue list through OSC, MIDI or a vendor API is a different integration and is outside Revision A.

For simultaneous console and box control, assign distinct universes, use an explicit merger, or configure a documented exclusive handoff. HTP can make blackout ineffective when another source keeps intensities high; it is unsuitable as a general merge rule for pan, tilt, color wheels or control channels. Never infer exclusive ownership merely because discovery found no competing controller.

## Operator workflow

1. In Venue Volume, select the venue, actual fixture personalities, patch, script and output routes. Compile and validate a complete playback bundle.
2. Power the box with ARM off. Connect a computer by USB, or join its local Ethernet network. Physically enable pairing for the first network upload.
3. Upload into the inactive storage slot. The box verifies integrity, format, resource limits and patch. Its display reports the show name, venue, revision and readiness.
4. Explicitly select the validated bundle while disarmed. Connect the approved lighting route. Check the displayed IP, universe mapping and output ownership at low intensity with the venue operator.
5. Turn ARM on and press GO. Disconnect the uploading computer and internet uplink. Cues and follows continue on the box's clock. GO and HOLD remain available on the front panel.
6. BLACKOUT sends the show's compiled dark state and latches until explicit restoration. ARM off releases transmission; fixtures may hold their last look when data stops. ARM is not a guaranteed blackout command.

The controls are for lighting playback. This revision does not implement safety-rated stops or allow pyro, hoists, lasers or other hazardous actuators to be armed through generic DMX channel data.

## What exists in Venue Volume today

The repository already describes a venue-local bridge in `docs/03 Engineering/Service and Runtime Boundaries.md`, patch routing in F08, non-tracking cue states in F11, and continuity/command ownership in F14-F18. The design studio simulates those behaviors. The visionOS app explicitly labels its preview as having no physical output. Its `DMXPreset` currently validates only 1-16 preview channels, and `FixtureAiming` uses a pilot mapping rather than manufacturer personalities.

Therefore real fixture profile compilation, the portable show bundle, authenticated uploader, MCU playback runtime and physical output tests are new engineering work. Do not send preview arrays directly to venue equipment. This packet proposes those interfaces without claiming they are implemented.

## Prototype purchasing budget

Allow approximately USD 350-650 for a first enclosed prototype, excluding engineering time, instruments, shipping, taxes and certification. This is a planning allowance, not a supplier quote. Major cost groups are the controller/SD/display, two isolated transceivers, carrier fabrication/assembly, panel connectors and harnesses, enclosure machining, and the power adapter. Obtain a fresh quantity-specific quote from `bom.md` after CAD review; generic panel parts still require a mechanical supplier selection.

## Completion criteria

A bench prototype is ready for a supervised lighting test after the pin/footprint review, power and isolation checks, frame timing measurement, interrupted-upload tests and offline soak in `manufacturing.md` pass. Production ordering additionally needs native ECAD capture, ERC, a routed board, DRC, enclosure fit confirmation, firmware validation and emissions/immunity testing. These are required next development stages, not tests performed by this document.

## Rebuilding and checking this packet

Run `python3 hardware/cue-player/build_packet.py --check` from the repository root for the dependency-free reference checks. PDF generation uses `reportlab`, `pypdf` and installed Liberation fonts: run `python3 hardware/cue-player/build_packet.py`. Use `--no-pdf` to regenerate only SVG, JSON and BOM files. Install dependencies in an environment inside the assigned worktree.

The checks cover 107 component/feature records, 50 named nets, six SVG documents, the isolated-domain separation, regulator-rail separation, selected pin assignments and DMX frame arithmetic. They do not run circuit simulation, ERC, DRC or hardware tests. Rendered PDF pages were visually reviewed for readability and clipping. The 19 test-pad records are copper features, not 19 extra purchased parts.
