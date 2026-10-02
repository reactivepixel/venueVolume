# Mid catalog source register

Sources opened for the current acquisition rows (all accessed 2026-10-02):

| Fixture | Official product source | Specific evidence checked |
|---|---|---|
| CHAUVET Rogue R1 FX-B | https://chauvetprofessional.com/product/rogue-r1-fx-b/ | Main product description and Specifications: 5 RGBW heads, beam/field/cutoff, movement, physical dimensions and mass; page links to manual, CAD, DMX chart. |
| CHAUVET Rogue R3 Beam | https://chauvetprofessional.com/product/rogue-r3-beam/ | Product description and Specifications: 300 W lamp, beam/effects, 325 × 220 × 550 mm envelope, 15.6 kg; page links to manual/CAD/DMX chart. |
| CHAUVET Rogue R3X Wash | https://chauvetprofessional.com/product/rogue-r3x-wash/ | Product page for output/image; Rev. 8 official manual in `chauvet-r3x/`, dimensional drawing p. 5: W394 × H470 × D298 mm, 17.5 kg, 21/27/62/71/107-channel modes. |
| Elation PROTEUS MAXIMUS | https://www.elationlighting.com/products/proteus-maximus | Technical specifications and linked CAD/manual downloads; 950 W source, 50,000 lm, DMX footprints, max power, overall dimensions and weight. |
| Elation PROTEUS LUCIUS | https://www.elationlighting.com/products/proteus-lucius | Current manufacturer dimensional drawing and specification sheet in `elation-lucius/`: L468 × W370 × H682 mm, 40.8 kg, 43/68-channel modes; older brochure dimensions are superseded. |
| Cameo OPUS X4 | https://www.cameolight.com/en/solutions/rental/moving-lights/profile-moving-heads/30735/opus-x4 | Full manufacturer technical table, including dimensions, mass, source, beam/zoom, protocols, rated power and effects. Hero image URL is the direct Cameo CDN asset. |
| Cameo OPUS X4 IP | https://www.cameolight.com/en/solutions/rental/moving-lights/profile-moving-heads/31933/opus-x4-ip | Manufacturer product page technical table: dimensions 475 × 860 × 350 mm, 46 kg, 1780 W, IP65; direct Cameo CDN image URL in `mid.json`. |
| PROLIGHTS Astra Hybrid330 | https://prolights.it/en/product/ASTRAHYB330 | Full physical and technical spec table; current DMX chart, manual, 2026 datasheet, CAD/3D files are linked. Direct official product image URL confirmed in HTML markup. |
| ACME TORNADO | https://en.acmelighting.com/item/TORNADO | Technical product page and downloadable assets list; exact model code TB 5 IP, source/head layout, five DMX footprints, max power, dimensions and weight. Hero image URL taken from page's product gallery markup. |
| ACME LIGHTNING | https://en.acmelighting.com/item/LIGHTNING | Technical product page: LED sources/sections, IP66, protocols/DMX modes, 1610 W, 483 × 212 × 224 mm, 13.3 kg. Hero image URL taken from page product gallery markup. |
| High End Systems Lonestar Prime | https://www.etcconnect.com/Lonestar-Prime/ | Product features and image URL from current page markup; May 2026 Datasheet C via https://www.etcconnect.com/WorkArea/DownloadAsset.aspx?id=10737520529 verified lumens, optics, channel count, weight and dimensions. |
| ETC Source Four 36° | https://www.etcconnect.com/Products/Entertainment-Fixtures/Source-Four/ | Official current family page/image; model-specific physical drawing https://www.etcconnect.com/workarea/DownloadAsset.aspx?id=10737460423 provides dimensions and 36° unit weight including C-clamp. |
| Astera Titan Tube FP1-BTB | https://astera-led.com/wp-content/uploads/FP1_Titan-Tube_Datasheet_V3.pdf | Official V3 datasheet and BTB manual in `astera-titan/`; L1035 × Ø43 mm, 1.35 kg, 16 pixels. The first image URL is an isolated manufacturer white/black product render (media record 843); the following image is an application/show photo. |
| Astera Helios Tube FP2-BTB | https://astera-led.com/fr/products/helios-tube/specs/ | Official product specification page, V4 datasheet, BTB manual and DMX profiles in `astera-helios/`; L550 × Ø43 mm, 0.765 kg, 8 pixels. |
| Astera AX5 TriplePAR AX5-BTB | https://astera-led.com/fr/products/ax5-triplepar/specs/ | Official product page, V4 datasheet, manual and DMX profiles in `astera-ax5/`; 3.4 kg and with-/without-bracket dimensions. |
| ETC ColorSource Spot jr | https://www.etcconnect.com/products/entertainment-fixtures/colorsource-spot-jr/documentation.aspx | Datasheet id 10737502586 and physical drawing id 10737502608; local files in `etc-spot-jr/`; dimensions W258 × H331 × D460 mm, 5.4 kg. |
| ETC ColorSource PAR jr | https://www.etcconnect.com/products/entertainment-fixtures/colorsource-par-jr/documentation.aspx | Datasheet id 10737516212, local in `etc-par-jr/`; dimensions H282 × W213 × D251 mm, 2.54 kg. |
| High End Systems Lonestar | https://www.etcconnect.com/lonestar/ | Datasheet id 10737513380 and DMX map id 10737514372; local in `etc-lonestar/`; dimensions H600 × W368 × D221 mm, 23 kg, 48 channels. |
| ACME MANA PROFILE | https://en.acmelighting.com/item/MANA-PROFILE | Official July 2026 leaflet https://en.acmelighting.com/upload/other/20260722/aea9031a33652685164a03651b20b64d.pdf; local in `acme-mana-profile/`; dimensions W380 × D284 × H658 mm, 32.5 kg, five DMX mode footprints. |

Catalog and family pages used to discover ranges are linked in
`../mid-coverage.md`. No local copy of manufacturer media is distributed here; online
 reuse terms are not assumed. Direct image URLs are recorded in the relevant JSON rows.

Known access limitation: Astera's official site blocked automated HTML retrieval during
this pass. The official site and official document URLs are in the coverage file, but no
Astera acquisition row should be considered complete until a human-accessible product page
or manufacturer asset is checked and its direct image URL and exact dimensions captured.
