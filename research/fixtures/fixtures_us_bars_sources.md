# Fixture research notes

This file contains 26 fixture records: 8 ADJ, 9 CHAUVET Professional, and 9 Elation Professional. Products were selected as representative fixtures applicable to small venues through professional production, with moving heads, wash/beam/profile, bars, a blinder, and an IP-rated option represented. The source is not a census of venue installations; manufacturer pages do not publish reliable sales or venue adoption counts.

## Official sources

- ADJ product pages: `adj.com`, including product specifications and linked support/manual resources. The discontinued ADJ LED Bar entry is explicitly marked discontinued on its official page.
- CHAUVET Professional pages and linked product PDFs: `chauvetprofessional.com` (and its official `www.chauvetprofessional.com` host). Product data comes from the listed page or official specification PDF.
- Elation product pages and linked support PDFs: `elationlighting.com`, including official legacy product documentation. The Design Wash 1400E's DMX details are from its official manual.

Each row's `url` is the official product page, and `data.source_urls` records the official page or manual supporting the provided fields. Dimensions, power, channel counts, and other metrics are included only where located in the official material consulted. Some official pages expose downloadable specification sheets with additional values not transcribed into this compact dataset.

## Gaps and interpretation

- The image column is a JSON array. Direct official image asset URLs were identified for the two ADJ products whose image links were individually resolved during this pass; remaining arrays are empty because their image CDN targets were not resolved. Product pages themselves show product images, but those page URLs are not represented as image URLs.
- Several Elation/ADJ rows have protocol confirmed from the manufacturer's product page or official manual link but lack dimensions or electrical details in this compact pass. A source URL is included so those details can be filled from the maker's full documentation.
- “Current” is used only where an official product listing presents the model as a current product. Historical status is stated only where the manufacturer explicitly labels the product discontinued or a legacy/manual listing supports legacy status. Do not interpret absence of a lifecycle value as evidence that a product is still manufactured.
- The list includes products of different generations. Availability and firmware/support status can vary by market and should be checked with the manufacturer for procurement decisions.
