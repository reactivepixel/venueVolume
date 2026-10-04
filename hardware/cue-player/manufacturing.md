# PCB and enclosure build requirements

## Deliverables before ordering a PCB

Capture the supplied pin-level design in native ECAD, assign exact symbols/footprints and run electrical rules checking. Cross-check every IC pin and every module/header orientation against the source datasheets and physical samples. Generate a routed PCB, passing design-rule report, stack-up, copper/soldermask/silkscreen Gerbers, drill files, IPC-356 netlist if supported, BOM, pick-and-place data, assembly drawings, stencil and fabrication notes. None of those manufacturing files are supplied or implied by the SVG drawings.

Revision A's carrier envelope target is 140 x 110 mm on insulated M3 standoffs inside the selected enclosure. This is a placement allowance, not a final board outline or a claim it fits the enclosure rails. Confirm internal height, panel-to-board distance, SD access, plug bend radii and mounting positions in mechanical CAD before fixing the outline. A carrier is the only new PCB; controller, Ethernet magjack and OLED are bought as complete modules.

## Board construction and placement

Proposed construction: four-layer FR-4, 1.6 mm, 1 oz outer copper, lead-free finish. Obtain the fabricator's stack-up before impedance calculations. L1 carries components/signals; L2 ground; L3 power/ground; L4 low-speed signals. Split every layer at both DMX isolation boundaries. Create separate same-port converter and bus ground areas joined only through the specified ferrite. Never pour the main ground plane under an isolated island.

Reserve at least 8 mm copper clearance between the logic domain and each isolated cable domain, and between cable domains, wherever practicable; the isolator footprint itself must preserve the package's certified barrier dimensions. Treat this as a conservative layout target, not a declared mains insulation class. Keep mounting metal, connector shells, test pads and silkscreen solder bridges out of the barriers. No added capacitor across an isolation barrier is authorized by this reference design. Any EMC stitching-capacitor change needs a reviewed insulation design.

Put transceivers, beads and bypass capacitors at the rear edge near their XLR harnesses. Follow the ADM2587E Rev H capacitor and island arrangement, including the isolated ground ferrite. Do not route display clocks through that area. Give U2 a real thermal plane and vias. Use adequate power trace/plane width for at least 1 A with the chosen stack-up; the fuse and connector ratings must also pass thermal review.

Keep UART traces short with a continuous logic return. USB high-speed pairs and Ethernet analog pairs remain in the purchased modules/cables. Do not route Ethernet PHY pairs through generic carrier headers or long unshielded harnesses. Use the supplied Ethernet kit cable and orientation. A short internal CAT5e patch cable connects the kit RJ45 to a shielded panel RJ45 feedthrough. Secure the kit mechanically; it cannot hang from the ribbon cable. No PoE circuitry is included.

Provide labeled test points for 5V_SYS, 3V3_MCU, 3V3_DMX, GND_LOGIC, both requests/enables/TX signals, and each isolated rail/common/output pair. Each isolated test group stays within its own domain. Debug instruments with common earth leads can defeat isolation; use differential/isolated measurement for cross-domain measurements.

## Enclosure and harness set

Use Hammond 1455T2201BK as the initial housing. Nominal outside dimensions are 220 x 165 x 51.5 mm. Its front and rear end plates need machining and durable labels. The schematic packet includes an arrangement drawing only; obtain the actual panel and connector drawings before cutting. Do not manufacture from a scaled screenshot.

Suggested front placement, measured from the nominal panel's left/bottom: OLED around x=29 mm, y=26 mm; run/fault indicators around x=53 mm; six 12-mm momentary buttons in two rows at x=72, 94, 116 mm and y=16, 36 mm; guarded ARM toggle at x=146 mm, y=26 mm. Choose switch bodies and guard envelopes before finalizing these centers.

Suggested rear placement: DMX A, DMX B, USB and RJ45 centered near x=20, 55, 90, 125 mm at mid-height; power inlet near x=151 mm. Neutrik D-series mounting holes and flanges extend outside the circular cutout and must be checked for clashes. The power plug strain relief must clear the Ethernet plug. If necessary move power to a side panel and keep it clear of the PCB.

Assembly includes: six low-current SPST-NO momentary panel switches; one maintained ARM switch/guard; green and red LEDs with bezels; two NC5FD-LX sockets; NAUSB-W feedthrough; shielded RJ45 feedthrough; insulated center-positive barrel inlet; OLED bezel/window; all mating connector housings/crimps; two short twisted DMX harnesses; 12-way controls harness; OLED cable; internal USB and CAT5e cables; Ethernet kit ribbon; M3 standoffs/screws/lock washers; module brackets; SD retention/service cover; non-slip feet; labels and a chassis bond lead. Exact commodity/mechanical SKUs are procurement choices with the electrical requirements listed in the BOM. Do not omit them from a build quotation.

A removable service panel gives access to the microSD and Program button. The card is not hot-swappable during a show. Restrain all internal cables, avoid sharp panel edges, and retain the controller with a bracket in addition to its sockets. Do not pot the isolation area or add conductive mounting hardware across it. Ventilation and a small controller heatsink can be added if thermal testing requires them; they are not substitutes for the regulator thermal design.

## Assembly sequence

1. Inspect bare boards against the fabrication drawing. Assemble and inspect power components first, without U1 or DMX modules populated. Check polarity, exposed pad soldering and shorts.
2. Apply current-limited 5 V. Check +5V_SYS and +3V3_DMX. Remove power and populate U3/U4/U5 and all passives/connectors.
3. Cut and inspect U1's VUSB-VIN link, fit headers and sockets, and mechanically retain the module. Install the Ethernet kit following its assembly guide. Install SD and OLED.
4. Reapply current-limited power with ARM off; confirm rails, gate states and isolated voltages. Install firmware through the service USB path. Never enable outputs with unreviewed test channel values.
5. Build and continuity-test harnesses off-board, including XLR pin numbers rather than visual left/right assumptions. Install panels, strain reliefs and chassis bonds.
6. Perform the following acceptance tests. Record hardware serial, board revision, firmware hash, card type and all instruments/settings with the results.

## Prototype acceptance tests

| Test | Required evidence before venue use |
| --- | --- |
| Power | Current and rail voltage at idle, network/SD peaks and both loaded outputs; no brownout within the reviewed supply range |
| USB coexistence | No carrier-to-host VBUS backfeed with external power; plugging/unplugging USB does not restart or pause an armed show |
| Isolation | No DC continuity from either XLR signal common to logic/chassis or the other port; formal insulation test procedure reviewed separately |
| Physical enable | ARM off and reset disable both drivers; no unsolicited ArtDmx before explicit GO; GPIO/rail sequencing checked with a scope |
| DMX electrical | Correct XLR polarity and loaded differential levels; far-end 120-ohm termination; 32-unit-load equivalent and representative cable lengths |
| DMX timing | Capture both ports: baud, two stop bits, BREAK, MAB, all 512 slots, 25 ms period; target period jitter within +/-100 us under admitted load |
| Art-Net | Packet capture confirms ports, byte order, sequence wrap, mapping and subscriber unicast; test known node plus intended console if used |
| Upload/storage | Corrupt, oversized and wrong-version bundles rejected; power removal throughout upload/selection never chooses partial data |
| Offline operation | At least 24 hours with WAN removed and uploader disconnected, both DMX ports and eight network universes active; no skipped/duplicated transitions |
| Control semantics | Button bounce, double GO, HOLD, BLACKOUT, restore, follows, restarts, stale remote commands and lease expiration match contract |
| Failure handling | Pull Ethernet, remove/fault SD, force watchdog reset and vary power; measure actual fixture hold/dark behavior and display errors |
| Mechanical/thermal | Enclosure closed at proposed 0-40 C ambient target; touch/component temperatures within limits; cable retention and panel fit verified |
| EMC | Pre-scan emissions and immunity with the real metal enclosure and attached cables; revise layout/protection if required |

The jitter, soak duration and ambient range are proposed acceptance targets, not published product specifications. A JSON consistency check cannot establish any row in this table. Production release requires measured results, supply-chain review, regulatory assessment for the intended markets and a documented factory test fixture.

## Development order

First build a module-based bench unit and verify one real fixture with a fixed known channel pattern. Then implement the compiler/uploader and local state engine, verify both physical outputs and an Art-Net receiver, and exercise all offline failure cases. Capture/review the carrier in ECAD before ordering five assembled boards. Fit the panels and run the closed-enclosure tests before a supervised venue trial. Add console-specific adapters only after documenting the target desk's supported input and takeover behavior.
