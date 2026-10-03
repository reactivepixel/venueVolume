# Mid-catalog visual QA

Reviewed on 2026-10-02 against the generated `*-sources-batchtouring-dj-2026-10.jpg`
and `*-models-batchtouring-dj-2026-10.jpg` contact sheets, then checked available
full-size official reference images and model previews for the specific optical concerns.
The parent expansion worktree was read-only. Findings and fixture-by-fixture paths are in
[`mid-qa.json`](mid-qa.json).

## Recheck of requested changes

- **ETC ColorSource PAR jr:** the corrected preview now has four concave reflectors, and
  front-view inspection confirms the emitters are centered. The previous 16-disc mismatch
  is resolved. A remaining proportion issue is that the front orthographic preview reads
  vertically oval, while the official product image shows a circular housing/face.
- **ETC ColorSource Spot jr:** the square plate has been removed; the revised circular lens
  and rim match the official zoom barrel silhouette. The previous issue is resolved.
- **Astera AX5 TriplePAR:** the revised three-cup optics and floor-yoke are present, and
  front-view inspection confirms centered emitters (the apparent offset in three-quarter
  view was parallax). The prior optical issue is resolved. The front orthographic preview
  still shows a noticeably vertically oval housing face rather than the source's circular
  optical body; this is the remaining substantive AX5 proportion concern.

No other substantive lens or silhouette mismatch was apparent in the reviewed pairs. That
does not assert fine-detail or CAD-level agreement. The contacted files expose 16 identifiable
pairs in this requested brand/model slice; no seventeenth pair was present among the ACME,
Astera, Elation, ETC jr, HES, Cameo, PROLIGHTS, and Rogue R3/R3X sheets. A blank `model.joints`
field was not treated as evidence that articulation failed. The revised front, side and
three-quarter previews for the three requested fixes were checked directly in the parent
worktree, which remains unmodified by this QA task.
