# Venue Volume marketing

A statically rendered Astro marketing page for the Venue Volume private alpha. The public page is intentionally sparse and presents one promise: **Pre-program the venue.**

## Run

Requires Node.js 22.19 or newer and npm.

```sh
npm install
npm run dev
```

Open the URL printed by Astro. The app has one fixed visual direction with no theme or layout switching.

The hero photograph is processed from `src/assets/hero-van-v1.png`; Astro emits responsive WebP variants at build time. Its provenance and creative brief are recorded in `docs/02 Product/Marketing Site.md`.

```sh
npm test
npm run build
```

## Signup behavior

The form accepts an email address or phone number, performs lightweight client-side validation, and logs a structured mock lead to the browser console. It intentionally has no network request or durable storage. Replace the logging line in `src/pages/index.astro` with the selected lead-capture integration after the Gmail workflow and consent language are decided.

The page is generated as complete static HTML. Only the small form-validation script runs in the browser; no UI framework runtime is shipped.

Each mock lead contains the submitted contact, detected contact type, source, and capture time.
