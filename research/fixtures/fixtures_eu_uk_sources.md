# Fixture research notes

The CSV contains 29 DMX/Art-Net-capable fixture records across Robe Lighting, Claypaky, and GLP. Sources were restricted to manufacturer-owned domains: `robe.cz` (including its `cdn.aws.robe.cz` documentation host and official spares catalog), `claypaky.it` (including its official technical-document host), and `glp.de` (including its official file/download paths). Official venue and production case studies on those domains were used only to support market presence; product specifications are linked in each row's `data.source_urls`.

The selection covers moving profiles, spots, washes, beam/hybrid fixtures, strobes, and battens, and includes established legacy products as well as current models. Model naming, published ordering codes, and technical data can vary by regional or firmware revision. Blank or omitted technical fields mean that a suitable official source was not readily available in this research pass; no values were inferred from retailer listings.

Known data limitations:

- Robe's public site uses a dynamic product catalogue, and the rows with only the Robe root URL in `url`/`images` do not yet have direct product-image assets or complete per-model dimensions and electrical specifications. The official manual/catalogue and support links are included in `data.source_urls` where located. The values intentionally remain sparse pending product-specific source confirmation.
- Several Claypaky legacy products are evidenced by official production case studies, while their historical specification PDFs are not linked in this file. Their image arrays currently use official manufacturer product-page URLs as fallbacks rather than direct image files.
- Some GLP image arrays also use official product-page URLs where a direct image URL was not discoverable in the manufacturer page metadata. These are official URLs but may need replacement with direct assets before ingestion into a system that requires image MIME URLs.
- A few older Claypaky or Robe models have product URL paths that may redirect or have been retired. The cited official manufacturer sources establish the model and DMX relevance; if an endpoint has moved, search the official domain by the exact product name.

CSV validation performed with Python's standard `csv` and `json` libraries: 29 data rows, the requested eight-column header, valid JSON in every `data` field, and valid JSON string arrays in every `images` field.
