# Electrical design

Revision A is a four-layer carrier for a Teensy 4.1 with its Ethernet PHY populated. Reference designators and named nets in the SVG sheets are authoritative within this packet. The generated connectivity file is a pin-level handoff specification, not an ECAD netlist or evidence of ERC.

## Power and USB

PS1 is a regulated 5 V, 3 A external adapter, with a 5.5 mm outer / 2.1 mm inner barrel plug, center positive. Mean Well GST18A05-P1J is the selected reference; include the matching regional IEC mains lead. J1 is a locking two-position carrier power connector fed by a panel barrel socket. Specify a socket rated at least 3 A and positively verify plug fit and polarity.

J1.1 -> F1 -> Q1 drain (pin 3); Q1 source (pin 2) -> `+5V_SYS`. Q1 is an AO3401A P-channel MOSFET mounted with its body diode conducting from the input toward the load. Its gate (pin 1) goes through R1, 100 kohm, to `GND_LOGIC`. This orientation provides reverse-polarity protection. F1 is a 1.5 A hold, 16 V PPTC. Neither part protects against plugging in a higher-voltage adapter; label the inlet **5 V DC ONLY**.

C1, 100 uF/10 V electrolytic, and C2, 1 uF X7R/16 V, decouple `+5V_SYS`. Feed U1 VIN directly from this rail. Cut the manufacturer-designated VUSB-to-VIN link on U1 before connecting both external power and USB. Verify the open link and absence of backfeed on every unit. USB VBUS remains connected inside the module to the USB circuitry; it is not routed to the carrier power rail. A computer-only USB connection intentionally cannot start playback.

Use a Neutrik NAUSB-W feedthrough with USB-B facing outward and USB-A inward, plus a short USB-A to Micro-B data cable into U1's device port. This avoids an unverified custom USB-C/PD circuit. The app companion uses USB CDC; firmware updates use the module's service bootloader. Do not connect the USB host header to this inlet. Secure the internal Micro-B plug against vibration.

U2, TLV76733DGNR, supplies only the two transceivers' logic-side power as `+3V3_DMX`. Connect pins 8 IN and 5 EN to `+5V_SYS`; pins 1 OUT and 2 SNS to `+3V3_DMX`; pins 4, 6 and exposed pad to `GND_LOGIC`; leave pins 3 and 7 NC. C3 and C4 are 10 uF X7R/16 V at input/output. Preserve at least the regulator's required effective output capacitance after DC-bias derating. The exposed pad needs a ground copper area and thermal vias.

U1's own 3.3 V output is a separate net, `+3V3_MCU`. It powers only U5, the OLED and controls. Never connect it to `+3V3_DMX` or feed an external regulator into it. The external load target is under 60 mA, below PJRC's 250 mA recommendation. All GPIO is 3.3 V.

## Power allowance

| Load | Design allocation from 5 V |
| --- | --- |
| U1 including Ethernet PHY, CPU and SD bursts | 350 mA |
| OLED, logic, controls and LEDs via U1 regulator | 60 mA |
| Two ADM2587E channels via U2 | 300 mA |
| Margin for component variation | 90 mA |
| Total allocated peak | 800 mA, approximately 4 W |

These allocations are not measured consumption. At 300 mA U2 dissipates approximately (5.0 - 3.3) x 0.30 = 0.51 W. Check actual rail current, enclosure temperature and PPTC derating at the operating temperature target. The external 15 W supply adds margin, not permission to draw 3 A through a 1.5 A fuse. Test VIN at minimum supply voltage with cable, fuse and MOSFET losses.

## Processor pin assignment

| U1 pin label | Net | Function |
| --- | --- | --- |
| VIN; all GND pins | +5V_SYS; GND_LOGIC | Module power |
| Both 3.3V header pins | +3V3_MCU | Output from module regulator |
| 1 / TX1 | DMXA_TX | Hardware UART1 TX to U3.7 |
| 8 / TX2 | DMXB_TX | Hardware UART2 TX to U4.7 |
| 2 | DMXA_REQ | Driver request into U5.1 |
| 3 | DMXB_REQ | Driver request into U5.4 |
| 4 | ARM_SENSE | Read the physical arm permit |
| 5, 6, 7 | BTN_GO, BTN_HOLD, BTN_BACK | Active-low buttons |
| 9, 10, 11 | BTN_NEXT, BTN_BLACKOUT, BTN_PAIR | Active-low buttons |
| 14, 15 | LED_RUN, LED_FAULT | LED drive through 1 kohm |
| 18 / SDA; 19 / SCL | I2C_SDA; I2C_SCL | OLED, 100 kHz target |
| Dedicated 2x3 Ethernet pads | Module kit connection | Supplied keyed/orientation-marked cable and magjack kit |
| Onboard microSD | Native SDIO | No SPI pin assignment |
| Onboard Micro-B | USB device | Upload/service cable |

Other GPIO, VUSB carrier pads, VBAT, On/Off, Program and USB host pads remain unconnected on the carrier. The onboard Program button is accessible through a recessed service opening. A real-time-clock coin cell is not required: sequence timing uses a monotonic timer. Do not use a wall clock to schedule fades.

For socket footprints, orient U1 with its USB connector at the top. The left 24-position row from top to bottom is GND, 0-12, 3.3V, 24-32. The right row is VIN, GND, 3.3V, 23-13, GND, 41-33. Validate row spacing and pad coordinates against the module drawing and an actual board before layout release. Signal labels in this packet do not imply an arbitrary KiCad symbol's pad numbering.

## Physical enable gate

U5 is SN74HCS08PWR, a quad AND gate with Schmitt inputs. SW1 connects `+3V3_MCU` to `ARM_RAW` through the panel harness. R2, 1 kohm, connects ARM_RAW to ARM_SENSE; R3, 10 kohm, pulls ARM_SENSE low; C7, 100 nF, filters it to GND_LOGIC. The Schmitt input accommodates the slow switch edge.

Gate 1: pin 1 DMXA_REQ AND pin 2 ARM_SENSE -> pin 3 DMXA_DE. Gate 2: pin 4 DMXB_REQ AND pin 5 ARM_SENSE -> pin 6 DMXB_DE. Pin 14 is +3V3_MCU; pin 7 is GND_LOGIC; C5 is 100 nF. Unused inputs 9, 10, 12 and 13 go to GND_LOGIC; outputs 8 and 11 are NC. R4/R5 pull requests low and R6/R7 pull enables low, all 10 kohm. R8/R9 pull TX low, 10 kohm, so U3/U4 inputs never float during reset. Firmware sets TX high before asserting a request.

ARM off removes physical DMX drive regardless of the MCU request. Opening the switch takes roughly milliseconds to pass the RC/Schmitt threshold and can truncate a frame. Firmware also stops Art-Net on the observed disarm event; the gate is not in the Ethernet path. An internal MCU watchdog with a proposed 250 ms deadline resets a stalled runtime, with requests returned to inputs and pulled low. Validate that behavior on the selected bootloader and all reset paths. Loss of output can leave fixtures at their last value; neither the gate nor the watchdog provides a safety-rated blackout.

## Isolated DMX channels

U3 and U4 are ADM2587EBRWZ, SOIC-20 wide body, 500 kbit/s devices with integrated isolated power. They are powered at 3.3 V on the logic side. The two external cable domains have separate grounds and isolated rails. Never join them to each other, USB ground, chassis, or GND_LOGIC. The isolation component rating alone does not certify the PCB or assembled product.

The following connections apply independently to U3 / port A and U4 / port B. See sheets 4 and 5 for the exact A/B reference designators.

| IC pins | Connection |
| --- | --- |
| 1, 3, 9, 10 GND1 | GND_LOGIC |
| 2, 8 VCC | +3V3_DMX |
| 4 RxD | NC, receiver not used |
| 5 /RE | +3V3_DMX, receiver disabled |
| 6 DE | Corresponding gated enable |
| 7 TxD | Corresponding UART TX |
| 11, 14 converter ground | ISOx_CONV_GND, a local island |
| 12 VISOOUT | ISOx_RAW_3V3 |
| 13 Y, 18 A | DMXx_P_DRV |
| 15 Z, 17 B | DMXx_N_DRV |
| 16, 20 bus ground | ISOx_GND |
| 19 VISOIN | ISOx_3V3 |

Two ferrites per port follow the manufacturer's Rev H arrangement: ISOx_RAW_3V3 -> FB -> ISOx_3V3, and ISOx_CONV_GND -> FB -> ISOx_GND. Do not directly short pins 11/14 to pins 16/20 around the ground ferrite. Use a high-frequency 0603 bead with adequate current and impedance, initially BLM18AG601SN1D; final impedance choice is subject to the EMI test. The ground ferrite connects only the two islands of that same isolated domain.

Each IC has eight bypass capacitors: 100 nF + 10 nF at pins 2/1; 100 nF + 10 uF at 8/9; 100 nF + 10 uF at 12/11; 100 nF + 10 nF at 19/20. Place each pair at its own pin pair even where the net names repeat. These are included in the BOM, not implied optional capacitors.

Each output goes through two 0-ohm 0805 tuning links to its cable connector; do not populate arbitrary series resistance without rechecking loaded output voltage. An SM712-02HTG TVS array connects its pins 1/2 to cable D+/D- and pin 3 to that port's ISOx_GND. This is a prototype transient network, not a demonstrated surge rating: the TVS clamp can exceed the transceiver's DC absolute maximum. Pulse coordination and system-level ESD/EFT/surge tests may require a revised protection stage.

Carrier J2/J3 pin 1 is isolated common, pin 2 D-, pin 3 D+. Wire these to matching pins 1/2/3 of the NC5FD-LX panel output sockets. XLR pins 4 and 5 are unconnected. XLR shells connect to metal chassis, separately from pin 1. Preserve the pair twist to the connector and keep these internal leads short. DMX512 cable is nominal 120 ohm; terminate only the far receiver end with a 120-ohm terminator for this output-only topology. No source-end parallel terminator or bias divider is fitted. Each external line is one daisy chain; use an isolated splitter for branches. RDM and DMX reception are not implemented by this circuit.

## Control and display harnesses

J4 is a four-pin JST-SH/Qwiic connector: 1 GND_LOGIC, 2 +3V3_MCU, 3 SDA, 4 SCL. Use a standard cable to the current Adafruit 326 I2C/STEMMA QT OLED. Its I2C pullups are provided by that module; do not add a second pullup pair without measuring the combined resistance. Confirm 0x3C/0x3D during assembly. C6 is 100 nF at J4.

J5 is a 12-position JST-XH carrier connector: 1 ground, 2 +3V3_MCU, 3 GO_RAW, 4 HOLD_RAW, 5 BACK_RAW, 6 NEXT_RAW, 7 BLACKOUT_RAW, 8 PAIR_RAW, 9 ARM_RAW, 10 RUN_LED_A, 11 FAULT_LED_A, 12 ground. Each button shorts its raw input to ground. Each raw input has a 1-kohm series resistor to the MCU net; each MCU net has a 10-kohm pullup and 100-nF capacitor to ground. Debounce for 20 ms and require a release before a second GO; BLACKOUT gets highest service priority. LED anodes come from pins 14/15 through 1 kohm; cathodes return to panel ground. Limit cable length to 200 mm and keep it inside the enclosure. This is not an external remote-control port.

J6 is a single chassis bond tab. R40, 0 ohm, joins GND_LOGIC to CHASSIS at this one point in Revision A. Bond USB and Ethernet connector shells and XLR shells to chassis at their panels. Maintain all DMX isolation boundaries even if USB ground is earthed by a computer. Review additional internal shield/ground connections in the purchased Ethernet/USB modules during EMC work; this starting bond arrangement is not a claim of an optimized enclosure.
