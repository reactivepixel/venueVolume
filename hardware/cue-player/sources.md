# Design sources and verification status

Sources were checked on 2026-10-03. URLs below identify the primary manufacturer or protocol owner. Component choices and calculations are engineering proposals derived from these sources; availability, footprints, firmware behavior and completed-system ratings are not inferred from a part listing.

| Source | Use in this design |
| --- | --- |
| [PJRC Teensy 4.1](https://www.pjrc.com/store/teensy41.html) | MCU module, native USB/SD/Ethernet facilities, VIN/VUSB separation and 3.3 V external-current limit |
| [PJRC pinout card](https://www.pjrc.com/teensy/card11a_rev4_web.pdf) | UART and I2C pin assignments and header signal labels |
| [PJRC Ethernet kit](https://www.pjrc.com/store/ethernet_kit.html) | Complete magjack kit, cable and assembly, retaining the vendor's analog interface |
| [Analog Devices ADM2582E/ADM2587E Rev H](https://www.analog.com/media/en/technical-documentation/data-sheets/adm2582e-2587e.pdf) | U3/U4 pins, isolated power, bypass networks and Figure 35 ferrite/island arrangement |
| [TI TLV767 Rev D](https://www.ti.com/lit/ds/symlink/tlv767.pdf) | U2 fixed 3.3 V DGN package, SNS and thermal-pad connections |
| [TI SN74HCS08 Rev C](https://www.ti.com/lit/ds/symlink/sn74hcs08.pdf) | U5 pinout, AND function and Schmitt-input behavior |
| [AOS AO3401A Rev 3.1](https://www.aosmd.com/sites/default/files/res/datasheets/AO3401A.pdf) | Q1 P-channel MOSFET package and ratings |
| [Littelfuse 1812L family](https://www.littelfuse.com/~/media/electronics/datasheets/resettable_ptcs/littelfuse_ptc_1812l_datasheet.pdf.pdf) | F1 1812L150/16DR electrical ratings |
| [Littelfuse SM712](https://www.littelfuse.com/assetdocs/littelfuse-tvs-diode-array-sm712-datasheet?assetguid=8313a28c-8802-4d47-a2a7-e30b5b1f67d8) | Candidate RS-485 TVS network; clamp coordination remains a test item |
| [Murata ferrite selection guidance](https://article.murata.com/en-us/article/basics-of-noise-countermeasures-lesson-4) | BLM18AG601SN1 family and frequency-dependent impedance; candidate requires final EMI qualification |
| [Adafruit 326](https://www.adafruit.com/product/326) | Current I2C OLED module, outline and wiring; old SPI variants must not be substituted blindly |
| [Neutrik NC5FD-LX](https://www.neutrik.com/en/product/nc5fd-lx) | Five-contact panel output socket and panel drawing |
| [Neutrik NAUSB-W](https://www.neutrik.com/en/product/nausb-w) | Reversible USB A/B panel feedthrough |
| [Hammond 1455T2201BK](https://www.hammfg.com/part/1455T2201BK) | Selected enclosure dimensions and mechanical drawing |
| [Mean Well GST18A](https://www.meanwell.com/Upload/PDF/GST18A/GST18A-SPEC.PDF) | Selected external GST18A05-P1J supply and plug option |
| [Artistic Licence Art-Net 4, release 1.4, revision 1.4dp](https://art-net.org.uk/downloads/art-net.pdf) | Addressing, ArtDmx, unicast subscriptions, discovery, sequence and implementation credit |
| [ESTA published standards index](https://tsp.esta.org/tsp/documents/published_docs.php) | Current DMX512-A baseline is ANSI E1.11-2024; full standard must be reviewed before release |
| [Infineon AN56199 DMX transmitter application note](https://www.infineon.com/dgdl/Infineon-AN56199_001-56199_0B_V-ApplicationNotes-v03_00-EN.pdf?fileId=8ac78c8c7cdc391c017d0d50de186d41) | Historical DMX timing background; the application note is marked obsolete and does not replace the current normative standard |

The ESTA full E1.11-2024 PDF endpoint returned an access error during research. The index establishes the current edition; this packet does not claim a clause-by-clause compliance review. Selected 120-us BREAK and 16-us MAB targets provide margin over historical transmitter timing minima, but must be checked against the current purchased/downloaded standard and measured hardware.

Art-Net product release requires the protocol owner's specified credit and an assigned OEM code. Include the required credit in the eventual user guide: "Art-Net(TM) Designed by and Copyright Artistic Licence" (use the trademark symbol in the final branded guide). Do not reuse another product's OEM code. A USB VID/PID allocation is an independent release requirement.

Unresolved before manufacturing: target console and software version; USB host platform beyond desktop; exact generic panel switch, inlet and RJ45 feedthrough SKUs; ferrite impedance selection and current derating; module footprint measurements; cable clearances; power/thermal margins; complete-system ESD/EMI behavior; native ECAD review. The core MCU, regulator, gate and isolator connections are specified here, while these remaining items are expressly not validated.
