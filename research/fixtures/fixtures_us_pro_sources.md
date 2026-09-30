# Fixture research notes: US/UK production fixtures

This file records products across ETC, High End Systems, Vari-Lite, and Martin Professional (HARMAN). These manufacturers have broad adoption in theatrical, touring, broadcast, worship, and live-event venues in the US and UK. The fixture list includes current products and selected older models that remain commonly encountered in venue inventories. It is a representative catalog, not an installation census.

## Primary source domains

- ETC: `etcconnect.com` and its official support subdomain `support.etcconnect.com`. Sources include current Entertainment Fixtures listings, fixture product pages, online manuals, and legacy High End Systems pages now hosted by ETC.
- High End Systems: `highend.com`, especially the official documentation library. Some older model landing pages have been moved or are poorly indexed; where necessary, the file points to the ETC-hosted High End legacy product catalog. Product details are intentionally sparse when first-party technical support could not be found.
- Vari-Lite: `vari-lite.com`, including current product-family/product pages and its official `b-dam` manual/download library.
- Martin Professional: `martin.com`, including product pages and official support/download documents. The site returned 403 to some direct page opens in this research environment; official search-indexed product content was used, and unverified dimensions/power values were omitted.

## Data and image conventions

The `data` cell is valid JSON. It includes only dimensions and electrical or performance values when surfaced in the official source content; unknown fields are omitted or set to `null`. Each JSON object includes a `sources` array so technical claims remain traceable. Product page URLs in `url` are official manufacturer sources. Images are JSON arrays containing direct manufacturer-hosted image URLs when found. Empty arrays mean a direct image asset was not confirmed in official accessible sources, not that the product has no image.

## Known gaps and caveats

- This is a bounded selection of representative digital/LED fixtures rather than a complete catalog. Exact adoption prevalence was not quantified.
- Some fixtures are listed by family or product model where the manufacturer does not publish a separate stock keeping unit. For those, `model_number` repeats the published product name.
- Legacy HES models and older Vari-Lite generations have uneven manufacturer archive coverage. Where official product-level technical specs were not discoverable, the row retains only the product identity and documented control eligibility; it does not infer measurements.
- ETC and Martin include a few family-level pages as official source URLs. Consult the manufacturer’s downloads/manual pages for lens, engine, regional power, and version-specific details before building a production record.
- Image coverage is partial. Direct official image assets were available for a few ETC entries; many manufacturer pages expose visual media through a dynamic gallery that did not provide a stable direct asset URL here.

