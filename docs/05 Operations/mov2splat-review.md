---
type: operations
status: reviewed
owner: engineering
updated: 2026-09-30
---

# mov2splat cleanup review

The current venue workflow is [room2blender](../../apps/room2blender/README.md):
movie reference extraction, a reviewed room specification, Blender review views and a
USDZ/environment manifest for the Swift visionOS application. It does not invoke
mov2splat, COLMAP, PyTorch or Docker.

mov2splat remains an optional Gaussian reconstruction experiment. This cleanup removes
its unused launch path and idle local Docker resources, rather than deleting the
reproducible experiment or its historical inputs/results. It does not change the
three standalone Gaussian viewer demos.

## Application review

| Component | Finding and disposition |
| --- | --- |
| `scripts/host.sh` | Retained as the only supported entry point. Checks Docker/GPU access, fingerprints build inputs, builds on demand and runs offline with caller UID/GID. |
| `compose.yml` | Removed. No repository caller or documented workflow used it. Its independent build path omitted the host launcher's source label/refresh logic and duplicated mounting/GPU configuration. |
| `scripts/run.sh` | Retained. All command options and stages are reachable: 800-frame extraction, optional blur filtering, sequential/exhaustive matching, camera fallback, component selection, training, OOM retry, resume and atomic PLY export. |
| `scripts/state.py` | Retained. Called by extraction and SfM resume checks and copied into the image; not an orphan helper. |
| `Dockerfile` / `pins.txt` | Retained as the on-demand build recipe. CUDA/COLMAP and the upstream gsplat trainer remain necessary for Gaussian output, but are not current venue dependencies. |
| `.dockerignore` | Retained. Part of the image fingerprint and exclusion of media/cache from build context. |
| `tests/mov2splat/test_pipeline.py` | Retained. Five command-stub regressions exercise frame budgets, resume metadata, component selection and image refresh without Docker. |
| Documentation | Current venue pipeline promoted in the root README. mov2splat marked optional. Removed the obsolete 220-frame / 150–300 clamp description and corrected image refresh and resume documentation. |

The installed gsplat 1.5.3 trainer was inspected before image removal. It imports
`viser`, `nerfview`, `gsplat_viewer`, TensorBoard and torchmetrics at startup even when
`--disable-viewer` and `--disable-video` are used. Its dataset loader imports OpenCV,
Pillow, imageio and the pinned `pycolmap.SceneManager`; its utilities import sklearn
and matplotlib. Headless operation is not sufficient evidence that those packages
can be removed. The upstream dependency pins and offline model-weight setup were
preserved. Slimming that trainer would be a separate implementation and GPU-validation task.

## Local Docker cleanup

The following was verified and performed on the development host, not automatically
on other machines:

- No containers or Docker volumes existed before cleanup.
- Removed idle `mov2splat:4090`, image ID
  `sha256:326a8899c4d77c8565d9a5a156ef92525393f0488a47d3f8364a90dd8fbfcea3`.
- Pruned 24 exact BuildKit cache record IDs traced from mov2splat build descriptions
  and their parent chains, including the abandoned OpenImageIO build attempt.
- Docker reported **31.07 GB reclaimed** by that cache prune after image removal.
  This includes layers previously shared with the 29.7 GB image; the two sizes must
  not be added together.
- Kept `swift:6.0` and `dockurr/windows:latest`.
- Kept three unattributed local-source cache records totaling **32.77 kB**.
  No broad image, volume or system prune was run.

The next explicit mov2splat invocation will rebuild its image and dependencies, requiring
network access and substantial build time/disk space. Runtime processing remains offline.
The Blender/USDZ venue workflow does not rebuild or require that image.

## Preserved data and verification

Raw recordings, existing `.gsplat` reconstruction folders, logs, reference images,
Blender/USDZ outputs and other tasks' worktrees were retained. In particular,
`assets/raw_room_videos/1.gsplat/status.json` still records an old incomplete COLMAP
run (`exit: null`); the absence of a Docker container means that file is not proof of
an active job. It was preserved as historical evidence, not rewritten as a success.

Five mov2splat regression tests passed after removing Compose. Bash syntax checks passed
for both launch scripts. No live GPU reconstruction or fresh image build was run during
cleanup; these checks do not establish that the supplied videos can reconstruct a room.

See [the optional experiment runbook](mov2splat.md) and
[the application README](../../apps/mov2splat/README.md) to intentionally use it again.
