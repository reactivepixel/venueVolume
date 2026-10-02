# Expansion v3 atmosphere research

Research pass dated 2026-10-02. `atmosphere.json` currently has 21 candidate records across Antari (15), Look Solutions (2), MDG (2), and ADJ (2). Exact product identity and technical product pages are established for all 21; most have official stills. Not every candidate is ready for modeling: see the acquisition gaps below and per-record `acquisition_errors`.

## De-duplication performed

Checked `assets/fixtures/research/show-equipment-catalog.csv` and `research/fixtures/expansion-v2/*.json` before selection. Excluded existing Antari Z-1000III, B-100 and S-500 entries; excluded expansion-v2 ADJ Entour Faze, Hurricane Haze 2D and SHEHDS hazer rows. Also excluded Antari M-9 fog jet (existing catalog entry) and other cataloged atmosphere appliances. The open-source Antari S-500 dimension discrepancy is not used to create a duplicate candidate.

## Current candidates

| Manufacturer | Exact models | Evidence / status |
|---|---|---|
| Antari | Z-1200III, Z-1500III, Z-3000III, HZ-350, HZ-400, HZ-500, HZ-1000, F-1, S-100X, S-200X, SW-250, SW-300, S-600, B-200, W-101 | Official product pages/manuals and exact CDN stills for all. Unresolved physical/control conflicts: S-600 dimensions; SW-300 dimensions; S-100X DMX presence. Current/legacy HZ-350 body generation must be matched before modeling. |
| Look Solutions | Unique 2.1, Tiny S | Official product pages and manufacturer dimension data. Exact stills located on the manufacturer's `/uploads/produkte/` path and captured locally. |
| MDG | ATMOSPHERE APS, MSe1 | Exact product pages, technical specs and official gallery image URLs. Resolved as tiny gallery renditions only so far; seek full-resolution images before detailed modeling. ATMOSPHERE requires external CO2 and optional external DMX interface; MSe1 uses external fluid and gas supply. |
| ADJ | Entour Chill (ENT791), Entour Venue (ENT610) | Product pages, published dimensions, controls and exact SKU-matching official stills. Chill product page and older ADJ news post disagree on dimensions; follow linked dimensional drawing. Entour Venue has an external 5.6 L anti-spill fluid container, distinct from machine body. |

## Source and modeling cautions

- All dimensions are assembled device dimensions where the manufacturer labels them. L/W/H is mapped to depth/width/height for a standing forward-facing pose; no package size is substituted.
- Antari S-600 current page states 462 × 596 × 630 mm / 24.0 kg, while 2026 guide states 464 × 624 × 661 mm / 26.0 kg. Keep the conflict visible and defer final dimensions until revision is confirmed.
- Antari S-500 is an existing catalog entry and excluded. The prior record raises a case-versus-machine envelope question; do not reuse that record as dimensional evidence for S-600.
- Antari products may have optional wireless controls, W-DMX, remote units, fluid tanks, hoses, bottle holders and brackets. Model only the exact machine configuration represented by sourced dimensions; preserve accessories and consumable dependencies as notes.
- MDG's 2-channel DMX accessory is optional for ATMOSPHERE APS. CO2 pressure-dependent consumption claims retain their stated pressure conditions. External gas cylinders are outside this task's scope.
- Official reference images downloaded to `atmosphere-sources/` have SHA-256 hashes and reuse status recorded in its README. Rights to reuse are unknown unless separately established.
- These are visual enclosure and technical metadata candidates only. No operation or effect firing procedures or fluid recipes are included.

## Buildable versus blocked candidates

- Source-complete physical starting points: Z-1200III, Z-1500III, Z-3000III, HZ-400, HZ-500, HZ-1000, F-1, SW-250, B-200, W-101, Unique 2.1, Tiny S, Entour Venue.
- Keep blocked pending resolution or better primary imagery: current-generation HZ-350 identification (legacy generation differs), S-100X DMX claim (current page versus 2026 guide), S-600 dimensions (current page versus 2026 guide), SW-300 dimensions (page versus manual), Entour Chill dimensions (page versus older news post), ATMOSPHERE APS and MSe1 (only tiny product thumbnails located).
- S-200X has known exact model still and dimensions; DMX remains unknown, so it is inventory-only with manual/remote control data.

## Next acquisition targets

Continue toward 25–35 genuinely new candidates, prioritizing current/legacy Look Solutions Viper/Boa/OctaJet/Cobra, Martin/JEM/Magnum, Le Maitre, Rosco and distinct Antari HZ/F/S/B variants. Before adding anything, deduplicate the full CSV and both expansion batch inputs. For each row, require exact product still, product-specific technical source, and a complete sourced W/H/D enclosure; preserve unknown power/mass/control fields as unknown. Reject application/stage photographs as shape references.
