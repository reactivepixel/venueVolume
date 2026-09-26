# mov2splat

Headless, local Docker pipeline: one iPhone Camera video to a standard binary 3D Gaussian Splatting PLY in the video's directory. The image contains CUDA 12.8, COLMAP 4.0.4, PyTorch CUDA 12.8, and gsplat 1.5.3. The host needs Docker and NVIDIA Container Toolkit; no host Python installation is needed.

## Omarchy host setup

Install the Arch packages and configure the NVIDIA Docker runtime. Keep the existing host NVIDIA driver; the container does not install one.

```bash
sudo pacman -S --needed docker nvidia-container-toolkit
sudo systemctl enable --now docker
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
nvidia-smi
docker run --rm --gpus all nvidia/cuda:12.8.0-base-ubuntu24.04 nvidia-smi
```

Your user must be able to run `docker info` without `sudo`. On a standard Docker setup, add the user to the `docker` group with `sudo usermod -aG docker "$USER"`, then log out and back in. Verify `docker info` before running the script. [Arch's Docker guide](https://wiki.archlinux.org/title/Docker) and [NVIDIA's runtime setup](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html) describe these host steps.

## Capture

Use the stock iPhone Camera app. Set **Most Compatible** (H.264), 4K30, and lock AE/AF. Walk a slow loop around a static subject with roughly 60% view overlap. Avoid Cinematic and Action mode. Keep exposure and focus steady. Portrait clips are accepted; extraction bakes the video rotation into the JPEG pixels.

## Run

From the workspace root:

```bash
./apps/mov2splat/scripts/host.sh /absolute/path/to/clip.mov
./apps/mov2splat/scripts/host.sh --force --frames 250 /absolute/path/to/clip.mov
./apps/mov2splat/scripts/host.sh --resume /absolute/path/to/clip.mov
```

A relative video path works too. The first invocation builds `mov2splat:4090` and needs internet access. Later runs use the built image with Docker networking disabled. Run only one GPU job at a time. Output is written as the invoking user's UID/GID, directly beside the source video. An existing `.ply` is protected unless `--force` is given.

Options: `--frames N` (default 220, clamped to 150–300), `--scale PX` (default 1600 maximum long edge), `--steps N` (default 30000), `--exhaustive` (all-pairs matching instead of sequential), and `--blur-threshold V` (optional Laplacian variance cutoff). Blur rejection always retains at least 120 frames. `--resume` reuses extracted frames and skips SfM only when `sparse/0` has valid camera, image, and point binaries with at least 85% of extracted frames registered. It also reuses a completed trainer PLY; otherwise training starts again.

```text
clip.mov
clip.ply
clip.gsplat/
  images/frame_00001.jpg ...
  database.db
  sparse/0/{cameras,images,points3D}.bin
  train/{trainer.log,ckpts/,ply/,stats/,tb/}
  pipeline.log
  status.json
```

`pipeline.log` shows extract → colmap → train → export, including registered/total frames. `status.json` records the current stage, frame count, registered count, and exit code. If training runs out of VRAM above 1280 px, the pipeline retries once at 1280 px, rebuilding frames and COLMAP to keep camera intrinsics consistent. The exported PLY is validated before an atomic move to `clip.ply`.

Expect SfM to take several minutes and training roughly 10–30 minutes for about 200 frames and 30,000 steps on an otherwise idle RTX 4090. This is an estimate, not a measured run; scene complexity and storage speed matter.

## Failures

- **Image build reports missing `/usr/bin/iconvert`:** Ubuntu's OpenImageIO CMake package requires `openimageio-tools` alongside `libopenimageio-dev`, even for headless COLMAP. The Dockerfile installs both. After updating it, rebuild with `docker build -t mov2splat:4090 apps/mov2splat` from the workspace root, then rerun `host.sh`. Docker reuses completed build layers; no cache purge is needed.
- **Few registered frames:** Read the `registered/total` line in `pipeline.log`. Add stable texture, slower motion, more overlap, and less blur; try `--exhaustive` for short captures. COLMAP retries with SIMPLE_PINHOLE if OPENCV fails.
- **HEVC-only source:** The image's FFmpeg decodes HEVC, but an unreadable or corrupt file will fail at ffprobe/ffmpeg. For repeatable capture, use iPhone Most Compatible/H.264.
- **Portrait sideways:** The script reads both rotate tags and display-matrix rotation, disables FFmpeg autorotation, and applies transpose before JPEG extraction. Check extracted JPEGs in `clip.gsplat/images` if metadata is malformed.
- **CUDA OOM:** Automatic 1280 px retry runs once. If it still fails, rerun with `--force --scale 960` or reduce competing GPU processes.
- **Toolkit/driver mismatch:** Run the CUDA `nvidia-smi` check above. If it fails, repair the host Docker/NVIDIA runtime or update the host driver to one compatible with CUDA 12.8. No driver is installed from this image.
