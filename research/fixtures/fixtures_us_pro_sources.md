# Fixture research notes: US/UK production fixtures

This file records products across ETC, High End Systems, Vari-Lite, and Martin Professional (HARMAN). These manufacturers have broad adoption in theatrical, touring, broadcast, worship, and live-event venues in the US and UK. The fixture list includes current products and selected older models that remain commonly encountered in venue inventories. It is a representative catalog, not an installation census.

## Primary source domains

- ETC: `etcconnect.com` and its official support subdomain `support.etcconnect.com`. Sources include current Entertainment Fixtures listings, fixture product pages, online manuals, and legacy High End Systems pages now hosted by ETC.
- High End Systems: `highend.com`, especially the official documentation library. Some older model landing pages have been moved or are poorly indexed; where necessary, the file points to the ETC-hosted High End legacy product catalog. Product details are intentionally sparse when first-party technical support could not be found.
- Vari-Lite: `vari-lite.com`, including current product-family/product pages and its official `b-dam` manual/download library.
- Martin Professional: `martin.com`, including product pages and official support/download documents. The site returned 403 to some direct page opens in this research environment; official search-indexed product content was used, and unverified dimensions/power values were omitted.

## Data and image conventions

The `data` cell is valid JSON. Retained rows have a numeric dimensions value with units and an explicit `protocols` field naming DMX or Art-Net. Each JSON object includes a `sources` array so technical claims remain traceable. Product page URLs in `url` are official manufacturer sources. Images are JSON arrays containing direct manufacturer-hosted image URLs when found. Empty arrays mean a direct image asset was not confirmed in official accessible sources, not that the product has no image.

## Known gaps and caveats

- This is a bounded selection of representative digital/LED fixtures rather than a complete catalog. Exact adoption prevalence was not quantified.
- Some fixtures are listed by family or product model where the manufacturer does not publish a separate stock keeping unit. For those, `model_number` repeats the published product name.
- The completeness pass removed rows for which a numeric dimension could not be established from first-party documentation. The final selection is therefore smaller than the initial research pass and is not a representative census of all requested fixture categories.
- Image coverage is partial. Direct official image assets were resolved for additional SolaFrame 3000, VL3600 PROFILE IP, VL2600 SPOT, and Martin models during a follow-up page-DOM pass. `images: []` remains for products where no true product image was identified; in particular, Desire D60, fos/4 Fresnel, and VL5LED WASH remain empty. The fos/4 page's OG image was rejected because it advertises Eos rather than the fixture.
- Row counts in the validated pass: ETC 5, High End Systems 2, Vari-Lite 3, Martin Professional (HARMAN) 7. The HES and Vari-Lite selections fall below the initial six-per-brand target because the retained-row rule required sourced numeric dimensions.
- Fourteen of 17 retained rows have a confirmed direct image asset: three ETC, two High End Systems, two Vari-Lite, and seven Martin Professional fixtures.
- The VL5LED WASH `url` now points to the official Vari-Lite product-family page (`https://www.vari-lite.com/global/vl5led-series`) because its former item URL returns a 404. The manufacturer datasheet remains linked in `data.sources`.
