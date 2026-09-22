---
type: product
status: prototype
owner: product
updated: 2026-09-20
---

# Marketing Site

## Purpose

The one-page marketing study in `apps/marketing` introduces Venue Volume and collects interest in private alpha access. It is an R&D artifact, not a production acquisition funnel. Revision 02 removes the public style picker and most explanatory content in favor of one mysterious product promise.

The message is derived from the [[Product Brief]] and [[../01 Company/Company Overview|Company Overview]]: Venue Volume is exploring a software-first DMX/Art-Net controller that helps operators move from setup to a controllable live look with less friction and more visible state.

## Message and pain point

Touring designers repeatedly adapt to changing stage dimensions, fixture types, fixture quantities, consoles, and house rigs. That translation consumes scarce time at the venue. Industry guidance recommends advancing each venue and adapting the plot before show day; touring examples describe programming that can accommodate different house rigs as a material reduction in hassle.

Sources:

- [HARMAN: Scaling and Adapting a Touring Lighting Design](https://pro.harman.com/insights/harman-pro/scaling-and-adapting-a-touring-lighting-design-how-to-deliver-a-great-show-in-any-venue/)
- [HARMAN: Lighting Design for Club Level Touring](https://pro.harman.com/insights/performing-arts/lighting-design-for-club-level-touring/)
- [ChamSys: adapting cues across different house rigs](https://chamsyslighting.com/ed-warren-sets-mood-for-mumford-and-sons-tour-before-the-tour-with-chamsys/)

The marketing language compresses that problem into:

> **Pre-program the venue.**  
> Customize each venue’s lighting design on the way there.

The phrase is a product ambition, not a validated capability claim. The alpha must prove how much programming can actually transfer across fixture inventories and venue geometry.

## Primary call to action

**Pre-program any venue** by submitting an email address or phone number for private alpha access. The page headline is the more immediate **Pre-program the venue.**

The current form validates the contact detail in the browser and writes a structured lead to the browser console. It sends no data and stores nothing. A future Gmail-backed workflow must not be connected until account access, ownership, consent language, retention, and failure handling are defined.

## Selected visual direction

**Void** is the sole marketing theme: a black field, restrained acid signal, generous negative space, and an editorial road image of a band traveling while the front passenger works in a spatial-computing headset. It was selected because it is the most distinctive expression of the mysterious brief while keeping the form immediately legible.

The application contains no theme selector, alternate layout logic, or URL-based visual switching. The canonical capture is `assets/design/venue-volume/marketing/selected-void.png`. Prior exploration captures remain in that folder as design history; they are not application options.

### Hero image

The original generated hero photograph is `apps/marketing/src/assets/hero-van-v1.png`. It depicts a band traveling by passenger van at blue hour, with focus on the belted front passenger using an Apple Vision Pro-style spatial-computing headset. Astro processes it into responsive WebP outputs during the static build. The scene connects the product promise to a real touring moment without placing interface text or fictional controls inside the image.

### Search delivery

The page is statically rendered with Astro so the headline, description, signup form, and hero image exist in the delivered HTML without client-side rendering. The document includes a descriptive title and description, Open Graph and Twitter metadata, crawl directives, semantic landmarks, intrinsic image dimensions, and responsive optimized image sources. Canonical, sitemap, `og:url`, and absolute social-image metadata remain deferred until a production domain exists.

## Claims and guardrails

- Treat “Pre-program any venue” as the north-star promise to validate, not a statement that universal fixture translation already works.
- Do not claim production reliability or customer outcomes before they are supported by evidence.
- Do not imply that the visual controller preview produces physical output.
- Keep the signup explicit, optional, and clear about what future contact to expect.

## Next integration

When the receiving Gmail account is available, decide whether submission should feed an email notification, a spreadsheet/CRM, or another durable lead store. Keep credentials and submission logic server-side; do not expose Gmail credentials in the React client.

## Related

- [[Product Brief]]
- [[Design/Design Overview]]
- [[../01 Company/Company Overview|Company Overview]]
