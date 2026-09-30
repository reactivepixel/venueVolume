# Fixture research notes

This file contains 18 fixture records: 6 ADJ, 6 CHAUVET Professional, and 6 Elation Professional. Products were selected as representative fixtures applicable to small venues through professional production, with moving heads, washes/beams, battens, and IP-rated options represented. The source is not a census of venue installations; manufacturer pages do not publish reliable sales or venue adoption counts.

## Official sources

- ADJ product pages: `adj.com`, including product specifications and linked support/manual resources. The discontinued ADJ LED Bar entry is explicitly marked discontinued on its official page.
- CHAUVET Professional pages and linked product PDFs: `chauvetprofessional.com` (and its official `www.chauvetprofessional.com` host). Product data comes from the listed page or official specification PDF.
- Elation product pages and linked support PDFs: `elationlighting.com`, including official legacy product documentation. The Design Wash 1400E's DMX details are from its official manual.

Each row's `url` is the official product page, and `data.source_urls` records the official page supporting the supplied facts. Every retained row now has a non-empty `images` array of direct manufacturer-hosted product image URLs, dimensions with units, and an explicit `protocols` array naming DMX or Art-Net support. Dimensions, power, channel counts, and other metrics are included only where located in the official material consulted. Some official pages expose downloadable specification sheets with additional values not transcribed into this compact dataset.

## Gaps and interpretation

- All image URLs point to direct product image assets hosted on the relevant manufacturer's domain. Manufacturer site pages and their product asset metadata/images were inspected to resolve them.
- Dimensions are provided with the units stated in official pages or manufacturer drawings. Power and channel data are included when available from the same pages.
- “Current” is used only where an official product listing presents the model as a current product. Historical status is stated only where the manufacturer explicitly labels the product discontinued or a legacy/manual listing supports legacy status. Do not interpret absence of a lifecycle value as evidence that a product is still manufactured.
- The list includes products of different generations. Availability and firmware/support status can vary by market and should be checked with the manufacturer for procurement decisions.
