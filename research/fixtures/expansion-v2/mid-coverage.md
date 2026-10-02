# Mid-market and touring professional fixture coverage

Research checkpoint: 2026-10-02. Scope is CHAUVET Professional, Elation Professional,
High End Systems, ETC, Astera, ACME, PR Lighting, PROLIGHTS, and Cameo. The acquisition
array in `mid.json` is deliberately deduplicated against `assets/fixtures/catalog.json`.
This inventory records discovered candidates even when imagery, a dimensional drawing,
or a complete spec sheet has not yet been acquired. Product links below are manufacturer
pages or official range/documentation pages unless identified as a legacy archive.

## Acquired in this batch

| Manufacturer | Model | Record | State |
|---|---|---|---|
| CHAUVET Professional | Rogue R1 FX-B | `mid.json` | Official image and product specs; five independently articulated optics make joint geometry a blocker. |
| CHAUVET Professional | Rogue R3 Beam | `mid.json` | Official image, product specs, dimensions and mass. |
| CHAUVET Professional | Rogue R3X Wash | `mid.json` | Official image, Rev. 8 manual, channel modes, 37-lens count, exact assembled dimensions and mass. |
| Elation Professional | PROTEUS MAXIMUS | `mid.json` | Official image/specs/dimensions/mass; profile fixture. |
| Elation Professional | PROTEUS LUCIUS | `mid.json` | Official current 2023 dimension drawing/spec sheet; 370×682×468 mm, 40.8 kg, 43/68-channel modes. |
| Cameo | OPUS X4 | `mid.json` | Official product image, full specs and dimensions. |
| Cameo | OPUS X4 IP | `mid.json` | Official product page/image and full physical specification table. |
| PROLIGHTS | Astra Hybrid330 | `mid.json` | Official image, page specs, 29-channel footprint and physical dimensions. |
| ACME | TORNADO | `mid.json` | Official image, specs and dimensions; head-pivot geometry remains to be checked. |
| ACME | LIGHTNING | `mid.json` | Official image, exact dimensions, power, mass, effects and control modes. |
| High End Systems | Lonestar Prime | `mid.json` | Official image and May 2026 datasheet; exact dimensions, mass and 52-channel footprint. |
| ETC | Source Four 36° Ellipsoidal | `mid.json` | Official image and model-specific dimensional drawing; classic rental/theatre fixture. |
| Astera | Titan Tube FP1-BTB | `mid.json` | Official V3 datasheet, BTB manual, exact direct product image, 1035 × Ø43 mm envelope. |
| Astera | Helios Tube FP2-BTB | `mid.json` | Official V4 datasheet, BTB manual, DMX profiles, exact image, 550 × Ø43 mm envelope. |
| Astera | AX5 TriplePAR AX5-BTB | `mid.json` | Official V4 datasheet, manual, DMX profiles, exact image, bracketed and body-only dimensions. |
| ETC | ColorSource Spot jr | `mid.json` | Official datasheet and physical drawing, exact image, dimensions/mass; four DMX modes reported but exact footprints are not in the accessed datasheet. |
| ETC | ColorSource PAR jr | `mid.json` | Official datasheet and exact image; emitter count, beam, DMX mode span, dimensions and mass. |
| High End Systems | Lonestar | `mid.json` | Official June 2025 datasheet, channel map, exact image, dimensions/mass and 48-channel footprint. |
| ACME | MANA PROFILE | `mid.json` | Official 2026 leaflet and product page; output, dimensions/mass, five DMX footprints, protocols and image URL. |

## Official catalog inventory and candidate models

These names were discovered on official product/range pages, official manufacturer
documentation, or product navigation. Existing exact records in the runtime catalog are
not re-added. The list is a useful coverage set, not a claim that every model is current
in every region; range listings sometimes retain legacy products.

### CHAUVET Professional

Official family pages: [Rogue](https://chauvetprofessional.com/family/rogue/),
[Maverick](https://chauvetprofessional.com/family/maverick/),
[Ovation](https://chauvetprofessional.com/family/ovation/),
[COLORado](https://chauvetprofessional.com/family/colorado/),
[STRIKE](https://chauvetprofessional.com/family/strike/).

Product pages confirmed during this pass:

- [Rogue R1 FX-B](https://chauvetprofessional.com/product/rogue-r1-fx-b/) — acquired.
- [Rogue R1 BeamWash](https://chauvetprofessional.com/product/rogue-r1-beamwash/).
- [Rogue R1X Wash](https://chauvetprofessional.com/product/rogue-r1x-wash/).
- [Rogue R1X Spot](https://chauvetprofessional.com/product/rogue-r1x-spot/) — existing exact catalog variant; skipped.
- [Rogue R2 Wash](https://chauvetprofessional.com/product/rogue-r2-wash/) — existing exact catalog variant; skipped.
- [Rogue R2X Spot](https://chauvetprofessional.com/product/rogue-r2x-spot/).
- [Rogue R2X Beam](https://chauvetprofessional.com/product/rogue-r2x-beam/).
- [Rogue R2E Spot](https://chauvetprofessional.com/product/rogue-r2e-spot/).
- [Rogue R3 Beam](https://chauvetprofessional.com/product/rogue-r3-beam/) — acquired.
- [Rogue R3 Spot](https://chauvetprofessional.com/product/rogue-r3-spot/).
- [Rogue R3X Wash](https://chauvetprofessional.com/product/rogue-r3x-wash/) — acquired.
- [Rogue RH1 Hybrid](https://chauvetprofessional.com/product/rogue-rh1-hybrid/) — existing exact catalog variant; skipped.
- [Rogue R1 FX-B](https://chauvetprofessional.com/product/rogue-r1-fx-b/) — acquired.
- [Maverick MK3 Wash](https://chauvetprofessional.com/product/maverick-mk3-wash/).
- [Maverick MK3 Profile](https://chauvetprofessional.com/product/maverick-mk3-profile/) — page not confirmed in this pass; retain as search candidate only.
- [Maverick MK3 Spot](https://chauvetprofessional.com/product/maverick-mk3-spot/) — page not confirmed in this pass; retain as search candidate only.
- [Maverick MK2 Wash](https://chauvetprofessional.com/product/maverick-mk2-wash/) — existing exact catalog variant; skipped.
- [COLORado Solo Batten](https://chauvetprofessional.com/product/colorado-solo-batten/) — existing exact catalog variant; skipped.
- [COLORado PXL Curve 12](https://chauvetprofessional.com/product/colorado-pxl-curve-12/) — URL needs confirmation.
- [STRIKE Array 2C](https://chauvetprofessional.com/product/strike-array-2c/) — URL needs confirmation.
- [STRIKE 4](https://chauvetprofessional.com/product/strike-4/) — existing exact catalog variant; skipped.
- [Ovation Rêve E-3](https://chauvetprofessional.com/product/ovation-reve-e-3/) — URL needs confirmation.

The official Rogue range page reports 23 products, including a separate Legacy Rogue
category. The pages directly checked identify R1/R2/R3 beam, spot, wash and hybrid roles;
individual older Rogue product URLs/spec versions need a follow-up inventory pass.

### Elation Professional

Official collection pages: [Proteus](https://www.elationlighting.com/collections/proteus),
[Fuze](https://www.elationlighting.com/collections/fuze); official
[Proteus Series brochure](https://www.elationlighting.com/proteus-series-brochure).

- Current PROTEUS collection product links: [Excalibur OPS](https://www.elationlighting.com/products/proteus-excalibur-ops),
  [Rayzor 760 WMG](https://www.elationlighting.com/products/proteus-rayzor-760-wmg),
  [Rayzor 1960](https://www.elationlighting.com/products/proteus-rayzor-1960),
  [Rayzor Blade L](https://www.elationlighting.com/products/proteus-rayzor-blade-l),
  [Excalibur](https://www.elationlighting.com/products/proteus-excalibur),
  [Maximus](https://www.elationlighting.com/products/proteus-maximus),
  [Atlas](https://www.elationlighting.com/products/proteus-atlas),
  [Brutus](https://www.elationlighting.com/products/proteus-brutus),
  [Rayzor Blade S](https://www.elationlighting.com/products/proteus-rayzor-blade-s),
  [Hybrid MAX WMG](https://www.elationlighting.com/products/proteus-hybrid-max-wmg),
  [Lucius](https://www.elationlighting.com/products/proteus-lucius),
  [Rayzor 760](https://www.elationlighting.com/products/proteus-rayzor-760),
  [Brutus FS](https://www.elationlighting.com/products/proteus-brutus-fs),
  [Radius](https://www.elationlighting.com/products/proteus-radius),
  [Hybrid MAX](https://www.elationlighting.com/products/proteus-hybrid-max), and
  [Odeon](https://www.elationlighting.com/products/proteus-odeon).
- Current FUZE collection product links: [Max Profile](https://www.elationlighting.com/products/fuze-max-profile),
  [Pendant HW](https://www.elationlighting.com/products/fuze-pendant-hw),
  [PFX](https://www.elationlighting.com/products/fuze-pfx),
  [PFX WH](https://www.elationlighting.com/products/fuze-pfx-wh),
  [Profile](https://www.elationlighting.com/products/fuze-profile-1),
  [SFX](https://www.elationlighting.com/products/fuze-sfx),
  [Teatro](https://www.elationlighting.com/products/fuze-teatro),
  [Wash 250](https://www.elationlighting.com/products/fuze-wash-250),
  [Wash 500](https://www.elationlighting.com/products/fuze-wash-500),
  [Wash 500 Motorized Barndoors](https://www.elationlighting.com/products/fuze-wash-500-motorized-barndoors),
  [Wash 500 Ovalizer](https://www.elationlighting.com/products/fuze-wash-500-ovalizer),
  [Wash 500 Radial Frost](https://www.elationlighting.com/products/fuze-wash-500-radial-frost),
  and [Wash 500 WH](https://www.elationlighting.com/products/fuze-wash-500-wh).
- Other professional candidates on the official range/product pages include KL Core IP,
  KL Profile Compact, KL PAR FC, Paragon S/M/LT, Rebel Profile, and Artiste Mondrian.
- Existing exact records skipped: DARTZ 360, Fuze SFX, Fuze Wash 500, KL Fresnel 8,
  Proteus Radius, SixBar 1000.

### High End Systems (ETC)

Official pages: [Automated Lighting](https://www.etcconnect.com/products/automated-fixtures/),
[SolaFrame](https://www.etcconnect.com/Products/Automated-Lighting/SolaFrame/SolaFrame.aspx),
[Lonestar](https://www.etcconnect.com/lonestar/), and [Lonestar Prime announcement](https://www.etcconnect.com/about/news/etc-introduces-high-end-systems-lonestar-prime.aspx).

- Current/announced range names: Lonestar, Lonestar Prime, Hyperstar, SolaFrame 3000,
  SolaFrame 2000, SolaFrame 1000, SolaFrame 750, SolaFrame Theatre, SolaSpot 3000,
  SolaSpot 2000, SolaSpot 1000, SolaWash 2000, SolaWash 1000, SolaHyBeam 3000,
  SolaHyBeam 2000, SolaPix 7/19/37, Ministar, MegaPix, GigaPix.
- Existing exact records skipped: SolaFrame 1000/2000/3000 and SolaWash 2000.
- Current Lonestar and SolaFrame product landing pages provide range descriptions, but
  complete per-model sources and image URLs remain to be collected for this batch.

### ETC

Official pages: [Entertainment Fixtures](https://www.etcconnect.com/Products/Lighting-Fixtures/),
[Source Four LED Series 3 documentation](https://www.etcconnect.com/Products/Entertainment-Fixtures/Source-Four-LED-Series-3/Documentation.aspx).

- Current Series 3: Source Four LED Series 3 Lustr X8 / Daylight HDR / Tungsten HD,
  5°/10°/14°/19°/26°/36°/50°/70° fixed lens tubes, XDLT zoom tubes, Fresnel, and CYC.
- Current ColorSource additions worth coverage: Spot jr, PAR jr, Fresnel V, Spot V,
  PAR, CYC, and Linear.
- Existing exact records skipped: ColorSource Fresnel V, ColorSource Spot V,
  Source Four LED Series 3 Lustr X8, ColorSource PAR, ColorSource CYC Floor.
- Legacy rental/theatre anchors for possible later inclusion: Source Four tungsten ERS,
  Source Four PAR, Source Four PARNel, Source Four Fresnel, Source Four HID.
- [Source Four 36°](https://www.etcconnect.com/Products/Entertainment-Fixtures/Source-Four/) — acquired as a legacy rental anchor; exact physical drawing checked.
- [ColorSource Spot jr](https://www.etcconnect.com/products/entertainment-fixtures/colorsource-spot-jr/documentation.aspx) and [ColorSource PAR jr](https://www.etcconnect.com/products/entertainment-fixtures/colorsource-par-jr/documentation.aspx) — acquired from official docs/specs.
- Official Series 3 documentation index includes 2025/2026 datasheets, manuals, CAD
  blocks and physical drawings by lens-tube variant. It should be treated as a family
  of distinct outer envelopes where the tube materially changes depth.

### Astera

Official home/range: [Astera Products](https://astera-led.com/products/).
Product-specific manufacturer pages/resources verified in search results include
[Helios Tube specifications](https://astera-led.com/fr/products/helios-tube/specs/),
[AX5 TriplePAR](https://astera-led.com/fr/products/ax5-triplepar/),
[AX9 PowerPAR](https://astera-led.com/zh/products/ax9-powerpar/), and the
[HydraPanel datasheet](https://astera-led.com/wp-content/uploads/FP6_HydraPanel_Datasheet_V1.pdf).
The manufacturer also provides a [Titan Tube / AX1 PixelTube accessory page](https://astera-led.com/fr/products/snapgrid-for-titan-tube-ax1-pixeltube/).
Official product resources and image assets were retrieved and checked despite intermittent
automated HTML blocking. Acquired current models: Titan Tube FP1-BTB, Helios Tube FP2-BTB,
and AX5 TriplePAR AX5-BTB; their exact image URLs and primary datasheet/manual sources are
recorded in `mid.json` and `mid-sources/`.

- Core professional battery fixtures to cover: Titan Tube, Helios Tube, Hyperion Tube,
  AX1 PixelTube, AX5 TriplePAR, AX9 PowerPAR, AX3 Lightdrop, HydraPanel, QuikBeam,
  QuikSpot, LeoFresnel, and LunaBulb.
- The HydraPanel datasheet is manufacturer documentation and includes dimensions,
  mass, LED/source/color data, IP65 rating, wireless protocol support and output. It does
  not substitute for a direct product image URL and human-readable product page.
- Existing exact record skipped: NYX Bulb.

### ACME

Official manufacturer catalog: [ACME home](https://en.acmelighting.com/index). Model links
from current product navigation (where a card linked to a non-product series page, that is
called out): [SUPERNOVA LT](https://en.acmelighting.com/item/SUPERNOVA-LT),
[SUPERNOVA](https://en.acmelighting.com/item/SUPERNOVA),
[LYRA](https://en.acmelighting.com/item/LYRA),
[MANA PROFILE](https://en.acmelighting.com/item/MANA-PROFILE),
[SANA PROFILE](https://en.acmelighting.com/item/SANA-PROFILE),
[AECO 30 IP](https://en.acmelighting.com/item/AECO-30-IP),
[AECO 15](https://en.acmelighting.com/item/AECO-15),
[MANA HYBRID](https://en.acmelighting.com/item/MANA-HYBRID),
[WILLOW 500](https://en.acmelighting.com/item/WILLOW-500),
[LYRA BW](https://en.acmelighting.com/item/LYRA-BW),
[AUTOLUX](https://en.acmelighting.com/item/AUTOLUX),
[SANA BEAM](https://en.acmelighting.com/item/SANA-BEAM),
[HUE 6 IP](https://en.acmelighting.com/item/HUE-6-IP),
[HYPERZONE](https://en.acmelighting.com/item/HYPERZONE),
[THETA](https://en.acmelighting.com/item/THETA),
[SANDANE FROST](https://en.acmelighting.com/item/SANDANE-FROST),
[TORNADO](https://en.acmelighting.com/item/TORNADO),
[SUPER DOTLINE](https://en.acmelighting.com/item/SUPER-DOTLINE),
[PULSAR PLUS S2](https://en.acmelighting.com/item/PULSAR-PLUS-S2),
[PULSAR S2](https://en.acmelighting.com/item/PULSAR-S2),
[CYCLONE](https://en.acmelighting.com/item/CYCLONE),
[PIXEL LINE IP](https://en.acmelighting.com/item/PIXEL-LINE-IP),
[PIXEL LINE IP 500](https://en.acmelighting.com/item/PIXEL-LINE-IP-500),
[LIGHTNING X](https://en.acmelighting.com/item/LIGHTNING-X),
[LIGHTNING](https://en.acmelighting.com/item/LIGHTNING),
[THUNDERBOLT](https://en.acmelighting.com/item/THUNDERBOLT),
[VOLTKA](https://en.acmelighting.com/item/VOLTKA),
[ULTRA PAR IP](https://en.acmelighting.com/item/ULTRA-PAR-IP),
[ULTRA BLINDER IP](https://en.acmelighting.com/item/ULTRA-BLINDER-IP),
[ZEUS](https://en.acmelighting.com/item/ZEUS),
[ARES IP](https://en.acmelighting.com/item/ARES-IP),
[SAGITTA IP](https://en.acmelighting.com/item/SAGITTA-IP),
[ARES](https://en.acmelighting.com/item/ARES),
[BEAMONE PRO](https://en.acmelighting.com/item/BEAMONE-PRO),
[PHOTON HYBRID 500](https://en.acmelighting.com/item/PHOTON-HYBRID-500),
[SKYTRK](https://en.acmelighting.com/item/SKYTRK), and
[COMET](https://en.acmelighting.com/item/COMET). NEOZONE, OXYGEN, STAGE PAR 400 ZOOM IP,
ELLIPSOIDAL 300/40, THEATRE SPOT 500/300, TV LIGHT PANEL 3000/1000, TANGO, and additional
line/blinder products appear in the navigation but their direct links were not resolved
in this pass.
- [TORNADO](https://en.acmelighting.com/item/TORNADO) — acquired.
- [LIGHTNING](https://en.acmelighting.com/item/LIGHTNING) — acquired.
- [MANA PROFILE](https://en.acmelighting.com/item/MANA-PROFILE) — acquired from July 2026 manufacturer leaflet and product page.
- [PIXEL LINE IP](https://en.acmelighting.com/item/PIXEL-LINE-IP) and
  [LIGHTNING](https://en.acmelighting.com/item/LIGHTNING) are strong bar/strobe rental
  candidates. Image/drawing extraction and exact body dimensions not included yet.
- ACME's official pages usually publish model-specific images, downloadable DMX charts,
  manuals, and dimension drawings; avoid using shipping-case dimensions as fixture size.

### PR Lighting

Official site: [PR Lighting](https://www.pr-lighting.com/).

- Important range/model candidates surfaced in official legacy case history and official
  product listings: XLED 1037, XLED 1037 PR-8157, XLED 2007 BE, XLED 3007, XR 1000
  BWS, XR 1000 Framing, Aqua 480 BWS, Aqua 580 BWS, XR 330 BWS, and XR 440 BWS.
- Official legacy story [XLED 1037 in touring use](https://www.pr-lighting.com/case/index121.html)
  confirms an RGBW zoom wash model. Current model pages, exact manual revisions and images
  were not verified in this checkpoint; legacy/current status needs follow-up.

### PROLIGHTS

Official product index: [Moving Lights: Beam & Hybrid](https://prolights.it/products/Moving%20Lights?categories%5B%5D=Beam+%26+Hybrid).
The index's products include [Jet Beam120IP](https://www.prolights.it/en/product/JETBEAM120IP),
[Astra Hybrid260IP](https://www.prolights.it/en/product/ASTRAHYB260IP),
[Astra Beam120IP](https://www.prolights.it/en/product/ASTRABEAM120IP),
[Astra Hybrid330](https://www.prolights.it/en/product/ASTRAHYB330),
[Astra Hybrid330IP](https://www.prolights.it/en/product/ASTRAHYB330IP),
[Jet Hybrid200](https://www.prolights.it/en/product/JETHYB200),
[Astra Beam260IP](https://www.prolights.it/en/product/ASTRABEAM260IP),
[Astra Hybrid420](https://www.prolights.it/en/product/ASTRAHYB420),
[Astra Hybrid420IP](https://www.prolights.it/en/product/ASTRAHYB420IP),
[PanoramaIP AirBeam](https://www.prolights.it/en/product/PANORAMAIPAB),
[Razor 440](https://www.prolights.it/en/product/RAZOR440),
[Pixie Beam](https://www.prolights.it/en/product/PIXIEBEAM),
[Jade](https://www.prolights.it/en/product/JADE),
[Onyx](https://www.prolights.it/en/product/ONYX),
[Ruby](https://www.prolights.it/en/product/RUBYBK),
[Ruby FCX](https://www.prolights.it/en/product/RUBYFCX),
[Mini Ruby](https://www.prolights.it/en/product/MINIRUBY), and
[Jet Beam1](https://www.prolights.it/en/product/JETBEAM1).

- Astra Hybrid330 — acquired.
- This is the Beam & Hybrid category, not a complete PROLIGHTS inventory. Follow-on work
  should include Profile, Wash, Stage Lights, Strobes/Blinders, LED Bars, and Pixel Mapping.
- Astra Hybrid330 official page exposes full specs, DMX personalities, manuals, CAD and
  3D files. The specification page's revision listing is current through 2026-08.

### Cameo

Official [OPUS series](https://www.cameolight.com/en/series/opus-series/),
[profile moving head category](https://www.cameolight.com/en/solutions/rental/moving-lights/profile-moving-heads/),
and [outdoor rental category](https://www.cameolight.com/en/solutions/rental/outdoor-lighting/outdoor-lights/).

- OPUS X4 and OPUS X4 IP — acquired.
- OPUS range listing also surfaced [OPUS X PROFILE](https://www.cameolight.com/en/solutions/rental/moving-lights/profile-moving-heads/20663/opus-x-profile),
  [OPUS SP5 FC](https://www.cameolight.com/en/solutions/rental/moving-lights/profile-moving-heads/19892/opus-sp5-fc),
  [OPUS SP5](https://www.cameolight.com/en/solutions/rental/moving-lights/profile-moving-heads/29239/opus-sp5),
  [OPUS SP6 FC](https://www.cameolight.com/en/solutions/rental/moving-lights/profile-moving-heads/32179/opus-sp6-fc),
  [OPUS SP6 IP](https://www.cameolight.com/en/solutions/rental/moving-lights/profile-moving-heads/32180/opus-sp6-ip),
  [OPUS S5](https://www.cameolight.com/en/solutions/rental/moving-lights/spot-moving-heads/19890/opus-s5),
  [OPUS X WASH](https://www.cameolight.com/en/solutions/rental/moving-lights/wash-moving-heads/25498/opus-x-wash),
  and [OPUS W5](https://www.cameolight.com/en/solutions/rental/moving-lights/wash-moving-heads/25590/opus-w5).
- OTOS outdoor range: [OTOS W12](https://www.cameolight.com/en/solutions/rental/moving-lights/wash-moving-heads/30744/otos-w12),
  [OTOS W3](https://www.cameolight.com/en/solutions/rental/moving-lights/wash-moving-heads/30745/otos-w3),
  [OTOS W6](https://www.cameolight.com/en/solutions/rental/moving-lights/wash-moving-heads/30746/otos-w6),
  [OTOS B5](https://www.cameolight.com/en/solutions/rental/moving-lights/beam-moving-heads/29085/otos-b5),
  [OTOS H5](https://www.cameolight.com/en/solutions/rental/moving-lights/beam-moving-heads/26039/otos-h5),
  and [OTOS SP6](https://www.cameolight.com/en/solutions/rental/moving-lights/profile-moving-heads/29049/otos-sp6).
- Other professional/rental candidates with official product links include [ZENIT W600](https://www.cameolight.com/en/solutions/rental/outdoor-lighting/outdoor-lights/18383/zenit-w600),
  [ZENIT W600 G2](https://www.cameolight.com/en/solutions/rental/outdoor-lighting/outdoor-lights/31963/zenit-w600-g2),
  [ZENIT W300](https://www.cameolight.com/en/solutions/rental/outdoor-lighting/outdoor-lights/19856/zenit-w300),
  [ZENIT W1200 G2](https://www.cameolight.com/en/series/zenit-series/32161/zenit-w1200-g2),
  and [PIXBAR 600 IP G2](https://www.cameolight.com/en/solutions/dj-musicians/outdoor-lighting/outdoor-lights/29370/pixbar-600-ip-g2).
- Catalog candidates are listed for follow-up; only the two acquired records above have
  full source-backed specs in this batch.

## Research gaps and next steps

- Continue exact-variant deduplication against `assets/fixtures/catalog.json` as each
  candidate becomes an acquisition record; this batch's array has no exact duplicates.
- Some catalog models are long-running/legacy rental stock. Mark production status from
  the maker's archive/product page, rather than silently treating them as current.
- Acquire source image URLs directly from manufacturer page markup, then check dimensions
  against the official drawing/manual. Do not infer physical scale from product images.
- For linked manufacturer pages where an exact image/model asset or dimension source has
  not been inspected yet, this coverage file records discovery only; those models are not
  yet research-complete.
