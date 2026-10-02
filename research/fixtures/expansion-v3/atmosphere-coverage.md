# Expansion v3 atmosphere research

Research pass dated 2026-10-02. `atmosphere.json` currently has 21 candidate records across Antari (15), Look Solutions (2), MDG (2), and ADJ (2). Exact product identity and technical product pages are established for all 21; most have official stills. Not every candidate is ready for modeling: see the acquisition gaps below and per-record `acquisition_errors`.

## De-duplication performed

Checked `assets/fixtures/research/show-equipment-catalog.csv` and `research/fixtures/expansion-v2/*.json` before selection. Excluded existing Antari Z-1000III, B-100 and S-500 entries; excluded expansion-v2 ADJ Entour Faze, Hurricane Haze 2D and SHEHDS hazer rows. Also excluded Antari M-9 fog jet (existing catalog entry) and other cataloged atmosphere appliances. The open-source Antari S-500 dimension discrepancy is not used to create a duplicate candidate.

## Current candidates

| Manufacturer | Exact models | Evidence / status |
|---|---|---|
| Antari | Z-1200III, Z-1500III, Z-3000III, HZ-350, HZ-400, HZ-500, HZ-1000, F-1, S-100X, S-200X, SW-250, SW-300, S-600, B-200, W-101 | Official product pages/manuals and exact CDN stills for all. Unresolved physical conflicts: S-600 dimensions and SW-300 dimensions. Current/legacy HZ-350 body generation must be matched before modeling. S-200X manual confirms one-channel DMX over 3-pin XLR; guide's “3-pin” shorthand is not a conflicting protocol claim. B-200 frontage axis is inferred from its official product still. |
| Look Solutions | Unique 2.1, Tiny S | Official product pages and manufacturer dimension data. Exact stills located on the manufacturer's `/uploads/produkte/` path and captured locally. |
| MDG | ATMOSPHERE APS, MSe1 | Exact product pages, technical specs and official still URLs captured at full available resolution (APS still 960×680; MSe1 still 700×700). ATMOSPHERE requires external CO2 and optional external DMX interface; MSe1 uses external fluid and gas supply. |
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
- Keep blocked pending resolution: current-generation HZ-350 identification (legacy generation differs), S-600 dimensions (current page versus 2026 guide), SW-300 dimensions (page versus manual), Entour Chill dimensions (page versus older news post).
- S-100X's one-channel DMX claim is confirmed by its current shared family manual; the guide's “3-pin” wording identifies connector type. S-200X is also explicitly DMX512, one channel, in that manual.
- The official MDG stills initially labelled “thumb” resolve to 3741×2551 and 700×700 respectively; official full-gallery image paths have also been captured for both models. These image assets are not acquisition blockers.

## Next acquisition targets

Continue toward 25–35 genuinely new candidates, prioritizing current/legacy Look Solutions Viper/Boa/OctaJet/Cobra, Martin/JEM/Magnum, Le Maitre, Rosco and distinct Antari HZ/F/S/B variants. Before adding anything, deduplicate the full CSV and both expansion batch inputs. For each row, require exact product still, product-specific technical source, and a complete sourced W/H/D enclosure; preserve unknown power/mass/control fields as unknown. Reject application/stage photographs as shape references.
