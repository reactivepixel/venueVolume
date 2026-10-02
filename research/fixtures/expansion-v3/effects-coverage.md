# Expansion v3 — stage effects coverage

This batch contains 25 non-duplicate product records across laser projectors, cold-spark units, CO₂, confetti, flame and smoke/low-fog equipment. The records are research-only enclosure and interface inventory. Laser and effect families must not acquire simulated ordinary spotlight emission.

## Coverage

| Family | Products | Coverage notes |
|---|---|---|
| Laser | CHAUVET DJ Scorpion Dual RGB, Scorpion Dual, Scorpion Bar RG, Scorpion Storm FXRG | Manufacturer pages establish product class and selected control specs. The Dual RGB has an official manual dimensional drawing. Bar RG aperture count is left unknown; Storm FXRG envelope/electrical facts need a manual. DMX channel maps are not transcribed. |
| Cold spark | SHOWVEN SPARKULAR mini, SPARKULAR, SPARKULAR WP, SPARKULAR MAX, SPARKULAR Cyclone II, SPARKULAR JET II | Manufacturer sources provide dimensions and technical highlights. JET II's dedicated 9–60 V trigger is distinguished from DMX. The original product category listing is the available source for MAX, Cyclone II and JET II. |
| CO₂ | SHOWVEN CO2 JET X-C1, MAGICFX CO2 JET II | X-C1 has both DMX and direct voltage control; MAGICFX manual documents direct output only. No unsupported DMX claim was added to the latter. |
| Flame | MAGICFX FLAMEBLAZER Standalone | Manual documents DMX/RDM and separate dedicated trigger terminals. Dimensions are assembled machine dimensions, excluding packaging. No firing details recorded. |
| Laser | ADJ X-Move Laser, Galaxian, Startec Rayzer, Stinger, Boom Box FX2, Laser Widow | Manufacturer pages provide physical dimensions for five models. Laser Widow is manual/sound/auto controlled and carries `visual_inventory_only` with its control path documented. Exact optical outlet counts remain unknown where product pages describe laser diodes/beam fields rather than visible lenses. |
| Smoke / low fog | Le Maitre G300-Smart, G300, GForce 3, GForce 2, Freezefog Pro | Manufacturer comparison/manual sources provide cabinet sizes and control dependencies. G300 vs G300-Smart DMX distinction is preserved; Freezefog is explicitly a tethered processor, not a standalone DMX fixture. |
| Flame | TBF 5-Master (Le Maitre distribution) | Manufacturer page documents five outlets, DMX presence and assembled standard-system envelope. Channel footprint and dimension-axis confirmation remain open. |
| Confetti | Ultratec Cyclofetti | Manufacturer gives length, width, mass and external CO₂ dependency, but not height or activation interface; marked visual-inventory-only. |

## Data limitations and acquisition notes

- Exact manufacturer-hosted still URLs are included for the four CHAUVET laser records, six SHOWVEN spark/CO₂ records, and six ADJ laser/multi-effect records. Remaining rows with empty image arrays are missing exact stills, not guessed.
- Scorpion Dual RGB has a manufacturer dimension drawing. Scorpion Dual, Bar RG and Storm FXRG manufacturer pages supply size, weight and source/control details; the Bar RG page explicitly documents four lasers. The user-requested lens count remains separate from source diode count.
- SHOWVEN product-page dimension ordering is retained verbatim in `dimensions.axis_note`; reference pose/orientation should be checked against source illustrations by the modeler.
- Exact laser aperture count is included only where the manufacturer explicitly documents dual mirror output. LED/diode counts are not treated as visible lens counts. Spark/nozzle counts are described cautiously where the image/spec does not establish an exact count.
- Control protocols are manufacturer-stated. Laser show protocols such as ILDA, FB4 or Art-Net are not inferred from DMX channel support; only ILDA-specific and dedicated-control claims backed by product sources should be added in a later evidence pass.
- Equipment whose non-DMX or tethered control is manufacturer-documented includes `data.visual_inventory_only` and a source-backed `data.control_path`. No firing sequence, channel firing map, pyrotechnic composition, exposure calculation, safety bypass, or operational hardware control is included.

Source references and access-date notes are in [effects-sources/README.md](effects-sources/README.md). The source list targets distinct products absent from the inspected existing catalog rows; this checkpoint was not a complete historical alias audit.
