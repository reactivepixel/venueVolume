# Bill of materials

Quantities are for one complete Revision A box. Electronic references correspond to the pin-level sheets and connectivity.json. All resistors are at least 0.1 W unless stated; 0-ohm links must carry the relevant fault/test current. Capacitor ratings are minimums and effective capacitance must be verified. This is a reference purchasing list, not an assembly-house release BOM.

Core semiconductor MPNs are selected. Specification-controlled passives and commodity/mechanical items need exact vendor SKUs and footprints before purchase. Optional external LAN equipment has quantity zero and is not included in the base assembly.

## Carrier electronics

| References | Qty | Component and package | Part or selection requirement | Notes |
| --- | --- | --- | --- | --- |
| U1 | 1 | Teensy 4.1 with Ethernet PHY; Module / two 1x24 rows | PJRC TEENSY41 (PHY populated) | Cut VUSB-VIN link. USB device, SDIO and Ethernet kit remain on module. Unused GPIO NC. |
| U2 | 1 | 3.3 V / 1 A LDO; DGN HVSSOP-8 exposed pad | TLV76733DGNR | SNS at OUT; EP to thermal ground plane. |
| U5 | 1 | Schmitt AND gates; TSSOP-14 | SN74HCS08PWR | - |
| F1 | 1 | 1.5 A hold / 16 V PPTC; 1812 | 1812L150/16DR | Check ambient derating and fault clearing. |
| Q1 | 1 | P-channel reverse polarity MOSFET; SOT-23 | AO3401A | Pin 1 gate, 2 source, 3 drain. Drain faces incoming supply. |
| R1 | 1 | 100 kohm 1%; 0603 | Specification controlled | - |
| C1 | 1 | 100 uF / 10 V; Radial electrolytic | Specification controlled | Positive terminal pin 1; reserve exact lead pitch after procurement. |
| C2 | 1 | 1 uF / 16 V X7R; 0603 | Specification controlled | - |
| C3 | 1 | 10 uF / 16 V X7R; 0805 | Specification controlled | - |
| C4 | 1 | 10 uF / 16 V X7R; 0805 | Specification controlled | Check effective capacitance after bias derating. |
| C5, C6, C7, C30, C31, C32, C33, C34, C35 | 9 | 100 nF / 16 V X7R; 0603 | Specification controlled | - |
| R2, R20, R21, R22, R23, R24, R25, R16, R17 | 9 | 1 kohm 1%; 0603 | Specification controlled | - |
| R3, R4, R5, R6, R7, R8, R9, R30, R31, R32, R33, R34, R35 | 13 | 10 kohm 1%; 0603 | Specification controlled | - |
| U3, U4 | 2 | Isolated DMX output; SOIC-20 wide body | ADM2587EBRWZ | Output only. /RE high, RxD NC. Separate isolated supply per port. |
| FB1, FB2, FB3, FB4 | 4 | 600 ohm at 100 MHz ferrite; 0603 | BLM18AG601SN1D | Initial EMI candidate; verify high-frequency curve, current and DCR before release. |
| C10, C20 | 2 | 100 nF / 16 V X7R; 0603 | Specification controlled | IC pins 2/1 |
| C11, C21 | 2 | 10 nF / 16 V X7R; 0603 | Specification controlled | IC pins 2/1 |
| C12, C22 | 2 | 100 nF / 16 V X7R; 0603 | Specification controlled | IC pins 8/9 |
| C13, C23 | 2 | 10 uF / 16 V X7R; 0805 | Specification controlled | IC pins 8/9 |
| C14, C24 | 2 | 100 nF / 16 V X7R; 0603 | Specification controlled | IC pins 12/11 |
| C15, C25 | 2 | 10 uF / 16 V X7R; 0805 | Specification controlled | IC pins 12/11 |
| C16, C26 | 2 | 100 nF / 16 V X7R; 0603 | Specification controlled | IC pins 19/20 |
| C17, C27 | 2 | 10 nF / 16 V X7R; 0603 | Specification controlled | IC pins 19/20 |
| R10, R11, R12, R13 | 4 | 0 ohm; 0805 | Specification controlled | Tuning link. Default 0 ohm; added resistance requires loaded DMX tests. |
| D1, D2 | 2 | RS-485 transient array; SOT-23 | SM712-02HTG | Protection coordination requires bench validation; no claimed surge rating. |
| J2, J3 | 2 | DMX harness; JST-XH 3-pin 2.5 mm | B3B-XH-A(LF)(SN) | - |
| J1 | 1 | Power harness; JST-XH 2-pin 2.5 mm | B2B-XH-A(LF)(SN) | - |
| J4 | 1 | OLED interface; JST-SH 4-pin 1 mm | SM04B-SRSS-TB(LF)(SN) | - |
| J5 | 1 | Panel controls harness; JST-XH 12-pin 2.5 mm | B12B-XH-A(LF)(SN) | - |
| J6 | 1 | Chassis bond point; M3 ring lug / bond pad | Specification controlled | - |
| R40 | 1 | 0 ohm; 0805 | Specification controlled | Single initial logic/chassis bond; never bridge an isolated DMX common. |

## Panel components

| References | Qty | Component and package | Part or selection requirement | Notes |
| --- | --- | --- | --- | --- |
| XLR1, XLR2 | 2 | 5-pin DMX output socket; Panel D series | NC5FD-LX | - |
| SW2 | 1 | GO momentary switch; 12 mm panel; low-current gold contacts | Specification controlled | SPST-NO; final mechanical SKU and button color selected before panel machining. |
| SW3 | 1 | HOLD momentary switch; 12 mm panel; low-current gold contacts | Specification controlled | SPST-NO; final mechanical SKU and button color selected before panel machining. |
| SW4 | 1 | BACK momentary switch; 12 mm panel; low-current gold contacts | Specification controlled | SPST-NO; final mechanical SKU and button color selected before panel machining. |
| SW5 | 1 | NEXT momentary switch; 12 mm panel; low-current gold contacts | Specification controlled | SPST-NO; final mechanical SKU and button color selected before panel machining. |
| SW6 | 1 | BLACKOUT momentary switch; 12 mm panel; low-current gold contacts | Specification controlled | SPST-NO; final mechanical SKU and button color selected before panel machining. |
| SW7 | 1 | PAIR momentary switch; 12 mm panel; low-current gold contacts | Specification controlled | SPST-NO; final mechanical SKU and button color selected before panel machining. |
| SW1 | 1 | ARM maintained switch + guard; Panel SPST | Specification controlled | Low-current gold contacts. Guard envelope checked in panel CAD. |
| LED1 | 1 | green panel LED; 3 mm LED + insulating bezel | Specification controlled | - |
| LED2 | 1 | red panel LED; 3 mm LED + insulating bezel | Specification controlled | - |
| OLED1 | 1 | 128x64 I2C OLED; 29.2 x 26.7 mm module | Adafruit 326 current STEMMA QT version | Module supplies I2C pullups; verify address. |

## Test features

| References | Qty | Component and package | Part or selection requirement | Notes |
| --- | --- | --- | --- | --- |
| TP1 | 1 | +5V_SYS; 1.5 mm exposed test pad | Specification controlled | Copper feature; no purchased component. |
| TP2 | 1 | +3V3_MCU; 1.5 mm exposed test pad | Specification controlled | Copper feature; no purchased component. |
| TP3 | 1 | +3V3_DMX; 1.5 mm exposed test pad | Specification controlled | Copper feature; no purchased component. |
| TP4 | 1 | GND_LOGIC; 1.5 mm exposed test pad | Specification controlled | Copper feature; no purchased component. |
| TP5 | 1 | ARM_SENSE; 1.5 mm exposed test pad | Specification controlled | Copper feature; no purchased component. |
| TP6 | 1 | DMXA_REQ; 1.5 mm exposed test pad | Specification controlled | Copper feature; no purchased component. |
| TP7 | 1 | DMXB_REQ; 1.5 mm exposed test pad | Specification controlled | Copper feature; no purchased component. |
| TP8 | 1 | DMXA_DE; 1.5 mm exposed test pad | Specification controlled | Copper feature; no purchased component. |
| TP9 | 1 | DMXB_DE; 1.5 mm exposed test pad | Specification controlled | Copper feature; no purchased component. |
| TP10 | 1 | DMXA_TX; 1.5 mm exposed test pad | Specification controlled | Copper feature; no purchased component. |
| TP11 | 1 | DMXB_TX; 1.5 mm exposed test pad | Specification controlled | Copper feature; no purchased component. |
| TP12 | 1 | ISOA_3V3; 1.5 mm exposed test pad | Specification controlled | Copper feature; no purchased component. |
| TP13 | 1 | ISOA_GND; 1.5 mm exposed test pad | Specification controlled | Copper feature; no purchased component. |
| TP14 | 1 | DMXA_P_CABLE; 1.5 mm exposed test pad | Specification controlled | Copper feature; no purchased component. |
| TP15 | 1 | DMXA_N_CABLE; 1.5 mm exposed test pad | Specification controlled | Copper feature; no purchased component. |
| TP16 | 1 | ISOB_3V3; 1.5 mm exposed test pad | Specification controlled | Copper feature; no purchased component. |
| TP17 | 1 | ISOB_GND; 1.5 mm exposed test pad | Specification controlled | Copper feature; no purchased component. |
| TP18 | 1 | DMXB_P_CABLE; 1.5 mm exposed test pad | Specification controlled | Copper feature; no purchased component. |
| TP19 | 1 | DMXB_N_CABLE; 1.5 mm exposed test pad | Specification controlled | Copper feature; no purchased component. |

## Modules hardware cables and accessories

| References | Qty | Component and package | Part or selection requirement | Notes |
| --- | --- | --- | --- | --- |
| ETH1 | 1 | Ethernet kit for Teensy 4.1; Assembly / accessory | PJRC ETHERNET_KIT | Includes magjack, PCB, capacitor, 2x3 headers and ribbon cable; assemble vendor kit. |
| SD1 | 1 | Industrial/high-endurance 8-32 GB microSD; Assembly / accessory | Qualified supplier SKU required | FAT32 initial target; qualify exact model for power interruption/read latency. |
| PS1 | 1 | 5 V 3 A external adapter; Assembly / accessory | Mean Well GST18A05-P1J | Add regional IEC mains lead; no mains wiring in box. |
| USB1 | 1 | Reversible USB A/B panel feedthrough; Assembly / accessory | Neutrik NAUSB-W | B outward, A inward; bond shell to chassis. |
| NET1 | 1 | Shielded RJ45 panel coupler, CAT5e or better; Assembly / accessory | Mechanical SKU to select | Panel grounded shell; internal short patch cable to Ethernet kit; no PoE. |
| DC1 | 1 | Insulated panel barrel socket, 5.5/2.1 mm, >=3 A; Assembly / accessory | Mechanical SKU to select | Center positive; sleeve to logic ground; two-wire harness to J1. |
| CASE1 | 1 | Extruded aluminum enclosure; Assembly / accessory | Hammond 1455T2201BK | 220 x 165 x 51.5 mm nominal; use custom machined end panels. |
| PCB1 | 1 | Custom 4-layer carrier, 140 x 110 mm allowance; Assembly / accessory | Native ECAD and routed PCB required | Not supplied as fabrication-ready artwork. |
| SOCKET | 2 | 1x24 female 2.54 mm module socket; Assembly / accessory | PJRC 24-pin socket or dimensional equivalent | Check controller header lengths and retention bracket. |
| HEADER | 2 | 1x24 male 2.54 mm header; Assembly / accessory | PJRC 24-pin header or dimensional equivalent | For bare Teensy module; omit if purchased already fitted. |
| HARNESS1 | 1 | J1 power mating connector and leads; Assembly / accessory | XHP-2 + 2 x SXH contacts | 22 AWG stranded; verify crimp tooling and pin 1. |
| HARNESS2 | 2 | J2/J3 DMX mating connectors and leads; Assembly / accessory | XHP-3 + 3 x SXH contacts per harness | Short 120-ohm twisted pair + isolated common; heatshrink at XLR. |
| HARNESS3 | 1 | J5 12-way panel harness; Assembly / accessory | XHP-12 + 12 x SXH contacts | 26 AWG signal wiring; <=200 mm; continuity test each switch. |
| CABLE1 | 1 | JST-SH/Qwiic 4-wire OLED cable; Assembly / accessory | Standard keyed cable, <=150 mm | Verify pinout; use assembled cable, no hand-swapped wire colors. |
| CABLE2 | 1 | Internal USB-A male to Micro-B data cable; Assembly / accessory | Short, shielded, <=200 mm | Secure both ends; no charge-only cable. |
| CABLE3 | 1 | Internal CAT5e patch cable; Assembly / accessory | Short shielded patch, <=200 mm | Kit magjack to panel coupler. |
| CABLE4 | 1 | Host USB cable; Assembly / accessory | USB-A/C host to USB-B device data cable | Host-dependent cable; supplied as accessory. |
| CABLE5 | 1 | External CAT5e network cable; Assembly / accessory | Shielding per venue installation | Local Ethernet connection. |
| CABLE6 | 2 | External DMX512 5-pin cable; Assembly / accessory | 120-ohm DMX cable | One for each physical output as required. |
| TERM | 2 | 120-ohm far-end XLR DMX terminator; Assembly / accessory | 5-pin, 0.25 W or greater resistor | External accessory, no source-end shunt termination. |
| MECH | 1 | Mechanical hardware set; Assembly / accessory | Procure to reviewed mechanical CAD | Insulating M3 standoffs, screws, washers, module brackets, feet, OLED window, SD cover, strain reliefs, chassis lead and labels. |
| LAN | 0 | Optional offline Wi-Fi AP / Ethernet switch; Assembly / accessory | Venue-dependent external equipment | Only needed to join wireless app clients or multiple network nodes; internet not required. |
