---
type: operations
status: experimental
owner: engineering
updated: 2026-09-30
---

# mov2splat operations

This is an optional Gaussian reconstruction experiment. For the current venue pipeline,
use [room2blender](../../apps/room2blender/README.md): reviewed geometry → Blender/USDZ.
The Gaussian trainer is not part of that pipeline. [Cleanup review](mov2splat-review.md).

`apps/mov2splat` is a local, headless Docker pipeline for converting one iPhone Camera `.mov`, `.mp4`, or `.m4v` to a 3D Gaussian Splatting `.ply`. It uses CUDA 12.8, COLMAP 4.0.4, and gsplat 1.5.3 on an NVIDIA RTX 4090. The video and output stay in the same directory. The container has no network access while processing.

## Host setup on Omarchy

The host needs its working NVIDIA driver, Docker, and NVIDIA Container Toolkit. Install only the Docker packages below; do not install Python, CUDA, or a second driver on the host for this app.

```bash
sudo pacman -S --needed docker nvidia-container-toolkit
sudo systemctl enable --now docker
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
nvidia-smi
docker info
docker run --rm --gpus all nvidia/cuda:12.8.0-base-ubuntu24.04 nvidia-smi
```

If `docker info` is denied, add your user to the Docker group and start a new login session:

```bash
sudo usermod -aG docker "$USER"
```

Then rerun `docker info` and the CUDA `nvidia-smi` container check. The host wrapper requires both checks to pass. The first image build needs internet access; all subsequent video runs use `--network none`.

## Capture and process one clip

In the stock iPhone Camera app, choose Most Compatible/H.264 and 4K30. Lock AE/AF, keep the scene static, and walk a slow loop with about 60% overlap. Avoid Cinematic and Action mode. Portrait video is supported; rotation is baked into the extracted JPEGs.

From the workspace root:

```bash
./apps/mov2splat/scripts/host.sh /absolute/path/to/clip.mov
```

The wrapper resolves relative paths too. It builds `mov2splat:4090` when the image is absent or its build-input fingerprint changes, mounts the video's parent directory, and runs with the caller's UID/GID. Run one GPU job at a time.

Expected output:

```text
/absolute/path/to/clip.mov
/absolute/path/to/clip.ply
/absolute/path/to/clip.gsplat/
  images/frame_00001.jpg ...
  database.db
  sparse/0/{cameras,images,points3D}.bin
  train/{trainer.log,ckpts/,ply/,stats/,tb/}
  pipeline.log
  status.json
```

`pipeline.log` records extract → colmap → train → export and the registered/total image count. `status.json` records stage, frames, registered images, and exit code. For about 200 frames at 30,000 steps on an idle 4090, budget several minutes for SfM plus roughly 10–30 minutes for training; this is an estimate, not a measured benchmark.

## Rerun and recovery

An existing `clip.ply` is protected. Use `--force` to replace it. Use `--resume` to reuse extracted frames only when the source, extraction settings and frame metadata match the completion record. SfM additionally requires matching mode/model metadata, a valid `sparse/0` and at least 85% registered frames. A completed trainer PLY is reusable only when SfM was reused. If training is incomplete, it starts again from the beginning.

```bash
./apps/mov2splat/scripts/host.sh --resume /absolute/path/to/clip.mov
./apps/mov2splat/scripts/host.sh --force --resume /absolute/path/to/clip.mov
./apps/mov2splat/scripts/host.sh --force --frames 800 --scale 1600 --steps 30000 /absolute/path/to/clip.mov
./apps/mov2splat/scripts/host.sh --force --exhaustive /absolute/path/to/clip.mov
```

The default is 800 frames, with a minimum of 150 and no upper clamp, at a maximum 1600 px long edge. `--exhaustive` substitutes all-pairs matching for sequential matching. Optional `--blur-threshold V` rejects blurry frames while retaining at least 120. If training hits CUDA OOM above 1280 px, the pipeline retries once at 1280 px, rebuilding frames and COLMAP so intrinsics stay aligned.

## Failure checks

| Symptom | Check or action |
| --- | --- |
| Docker permission denied | Confirm `docker info` works as your user after a new login session. |
| GPU or toolkit mismatch | Run both `nvidia-smi` and the CUDA container check above. Repair the host driver or toolkit before processing. |
| Fewer than 85% of frames registered | Read `registered/total` in `pipeline.log`; capture with more texture, overlap, and steadier motion. Try `--exhaustive` on short clips. |
| HEVC or corrupt source cannot decode | Inspect the ffprobe/ffmpeg error in `pipeline.log`; recapture with Most Compatible/H.264 when possible. |
| Portrait frames appear sideways | Inspect `clip.gsplat/images` and the logged rotation. The pipeline reads rotate tags and display-matrix rotation before applying transpose. |
| CUDA OOM after the automatic retry | Stop competing GPU processes and rerun with `--force --scale 960`. |

The [application README](../../apps/mov2splat/README.md) describes all command options and the pinned image. The [Dockerfile](../../apps/mov2splat/Dockerfile) and [pins.txt](../../apps/mov2splat/pins.txt) define the build.
