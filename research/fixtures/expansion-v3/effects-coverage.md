# Expansion v3 — stage effects coverage

This batch contains 13 product records across laser projectors, cold-spark units, a CO₂ jet and a liquid flame effect unit. The records are research-only enclosure and interface inventory. Laser and effect families must not acquire simulated ordinary spotlight emission.

## Coverage

| Family | Products | Coverage notes |
|---|---|---|
| Laser | CHAUVET DJ Scorpion Dual RGB, Scorpion Dual, Scorpion Bar RG, Scorpion Storm FXRG | Manufacturer pages establish product class and selected control specs. The Dual RGB has an official manual dimensional drawing. Bar RG aperture count is left unknown; Storm FXRG envelope/electrical facts need a manual. DMX channel maps are not transcribed. |
| Cold spark | SHOWVEN SPARKULAR mini, SPARKULAR, SPARKULAR WP, SPARKULAR MAX, SPARKULAR Cyclone II, SPARKULAR JET II | Manufacturer sources provide dimensions and technical highlights. JET II's dedicated 9–60 V trigger is distinguished from DMX. The original product category listing is the available source for MAX, Cyclone II and JET II. |
| CO₂ | SHOWVEN CO2 JET X-C1, MAGICFX CO2 JET II | X-C1 has both DMX and direct voltage control; MAGICFX manual documents direct output only. No unsupported DMX claim was added to the latter. |
| Flame | MAGICFX FLAMEBLAZER Standalone | Manual documents DMX/RDM and separate dedicated trigger terminals. Dimensions are assembled machine dimensions, excluding packaging. No firing details recorded. |

## Data limitations and acquisition notes

- Exact official still-image URLs were not recoverable with sufficient confidence in this checkpoint, so `images` arrays are empty. No image URLs were guessed.
- Scorpion Dual RGB has a manufacturer dimension drawing. Scorpion Dual product page supplies its size; the remaining compact laser products need dimensional drawings/manuals before modeling.
- SHOWVEN product-page dimension ordering is retained verbatim in `dimensions.axis_note`; reference pose/orientation should be checked against source illustrations by the modeler.
- Exact laser aperture count is included only where the manufacturer explicitly documents dual mirror output. LED/diode counts are not treated as visible lens counts. Spark/nozzle counts are described cautiously where the image/spec does not establish an exact count.
- Control protocols are manufacturer-stated. Laser show protocols such as ILDA, FB4 or Art-Net are not inferred from DMX channel support; only ILDA-specific and dedicated-control claims backed by product sources should be added in a later evidence pass.
- Models requiring direct-output, pyro signal or liquid CO₂ remain visual inventory. No firing sequence, channel firing map, pyrotechnic composition, exposure calculation, safety bypass, or operational hardware control is included.

Source references and access-date notes are in [effects-sources/README.md](effects-sources/README.md). The source list targets distinct products absent from the inspected existing catalog rows; this checkpoint was not a complete historical alias audit.
