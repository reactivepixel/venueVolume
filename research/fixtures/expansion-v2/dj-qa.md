# DJ fixture visual/runtime QA

Review date: 2026-10-02. This was a read-only review of currently built assets in the parent `catalog-expansion-v2` worktree. The machine-readable findings are in [dj-qa.json](dj-qa.json).

I viewed the official product-reference image next to each stored three-quarter render for all 15 built fixtures listed in the JSON report. I also compared each fixture's documented width/height/depth with its exported USDZ bounds and reviewed its part/joint metadata. All 15 bounds agree within about 1 µm. The 12 moving-head assets have pan and tilt joints; the KLS-120 light bar, Hurricane Haze 2D, and Saber Spot DTW have no moving-head joints, as expected for those forms.

## Findings

- **ADJ Focus Spot 6Z — medium:** [source image](../../../assets/fixtures/adj/focus-spot-6z/sources/product-reference-0.jpg) vs. [three-quarter render](../../../assets/fixtures/adj/focus-spot-6z/previews/three-quarter.png). Its long, tapered/faceted optical housing is represented by a short rounded generic shell. Preserve its documented envelope but reshape the housing to match the source silhouette.
- **Showtec Phantom 100 Spot — medium:** [source image](../../../assets/fixtures/showtec/phantom-100-spot/sources/product-reference-0.png) vs. [three-quarter render](../../../assets/fixtures/showtec/phantom-100-spot/previews/three-quarter.png). The source's short angular/tapered head with small lens hood appears as a smooth sphere with an oversized planar ring. Replace the head primitive with a compact faceted/tapered form within the existing envelope.

The remaining 13 viewed assets had no material identity, scale, or moving-part-family error apparent at the requested QA threshold. This is a source-image/render comparison, not a physical measurement, DMX bench test, or RealityKit/headset test. Entries still in research/blocked state were not treated as built assets and were not visually audited.
