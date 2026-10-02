# Mid-catalog visual QA

Reviewed on 2026-10-02 against the generated `*-sources-batchtouring-dj-2026-10.jpg`
and `*-models-batchtouring-dj-2026-10.jpg` contact sheets, then checked available
full-size official reference images and model previews for the specific optical concerns.
The parent expansion worktree was read-only. Findings and fixture-by-fixture paths are in
[`mid-qa.json`](mid-qa.json).

## Substantive issues

- **ETC ColorSource PAR jr:** the reference image shows four large reflector/lens apertures,
  while the generated preview exposes 16 small projecting discs. This changes the most
  recognizable part of the face; revise the visible optics to four reflector cups.
- **ETC ColorSource Spot jr:** the preview adds a broad square plate ahead of the barrel.
  The reference has a circular recessed lens/rim at the end of its round zoom tube. Remove
  or reduce the unsupported plate.
- **Astera AX5 TriplePAR:** the three reference optics are broad concave reflector bowls;
  the preview reads as three much smaller flat discs. Increase their visible area and model
  the recessed reflective cups.

No other substantive lens or silhouette mismatch was apparent in the reviewed pairs. That
does not assert fine-detail or CAD-level agreement. The contacted files expose 16 identifiable
pairs in this requested brand/model slice; no seventeenth pair was present among the ACME,
Astera, Elation, ETC jr, HES, Cameo, PROLIGHTS, and Rogue R3/R3X sheets. A blank `model.joints`
field was not treated as evidence that articulation failed.
