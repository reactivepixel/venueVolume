# Fixture research notes

The CSV contains 18 DMX-capable records: six each from ROBE Lighting, Claypaky, and GLP. Research for specifications and imagery was limited to official manufacturer pages and manufacturer-hosted manuals, leaflets, and datasheets on `robe.cz` / `cdn.aws.robe.cz`, `claypaky.it`, and `glp.de`. Each row links to an item-specific product page, and its `data.source_urls` lists the official references used for the technical fields.

All retained rows include dimensions with units, an explicit `protocols` array containing DMX (or DMX512-A), and at least one direct image URL hosted by the manufacturer. The set covers profiles, spots, washes, hybrids, strobes, and battens, including discontinued Robe Pointe, Claypaky Sharpy, and GLP impression X4 Bar 20 alongside current models.

Technical details may differ by market, hardware revision, or control mode. Dimensions are transcribed from official technical drawings/specifications; some moving-head drawings distinguish base, head, yoke, and upright measurements, so the dimension descriptions preserve the manufacturer's relevant orientation rather than asserting a universal packed envelope. `source_urls` is the audit trail for each row. No retailer or distributor data was used. Where the manufacturer's page does not expose a convenient spec table, the row relies on its linked official manual or leaflet.

Validation performed with Python's standard `csv` and `json` libraries: 18 data rows; exact eight-column header; valid JSON in every `data` field and `images` field; all rows have dimensions with units, protocols including DMX/Art-Net, and non-empty image arrays.
