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
./apps/mov2splat/scripts/host.sh --frames 800 /absolute/path/to/clip.mov
./apps/mov2splat/scripts/host.sh --resume /absolute/path/to/clip.mov
```

A relative video path works too. The launcher fingerprints the Dockerfile and all copied build inputs, and rebuilds `mov2splat:4090` when they change or the image is missing. Docker reuses unchanged layers; the first build and dependency changes need internet access. Unchanged images are reused without a build. Processing runs with Docker networking disabled. Run only one GPU job at a time. Output is written as the invoking user's UID/GID, directly beside the source video. An existing `.ply` is protected unless `--force` is given.

Options: `--frames N` (default 800, minimum 150, no upper clamp; requests above 2000 print a cost warning), `--scale PX` (default 1600 maximum long edge), `--steps N` (default 30000), `--exhaustive` (all-pairs matching instead of sequential), and `--blur-threshold V` (optional Laplacian variance cutoff). Blur rejection always retains at least 120 frames. `--resume` reuses extraction only when its completion record matches the source path/size/modification time, requested frame count, scale, blur threshold, and extracted file metadata. Missing records (including older jobs), changed settings, or missing frames trigger extraction and reconstruction again. Changing the matching mode reruns SfM while retaining matching extraction. SfM reuse additionally requires unchanged model files and at least 85% registered frames. A completed trainer PLY can be reused only when reconstruction was reused; otherwise training restarts.

For a roughly 6–7 minute room video, start with 800 frames at 1600 px and sequential matching (the default). This samples roughly twice per second. Try 1200 frames if neighboring views still have too little overlap. Exhaustive matching compares N(N−1)/2 pairs and becomes expensive as N grows; requests above 1000 frames with `--exhaustive` print a warning. More frames do not repair a corrupt recording or guarantee successful reconstruction. The 85% acceptance threshold is unchanged. When COLMAP produces disconnected components, the largest nonempty component is selected as `sparse/0`; other components are preserved.

Changes to the source or extracted files are detected using file size and modification time, not a full media content hash. Preserve neither timestamp nor size when replacing media if you intend to resume.


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
  extract.json, sfm.json  # completed stage fingerprints
```

`pipeline.log` shows extract → colmap → train → export, including registered/total frames. `status.json` records the current stage, frame count, registered count, and exit code. If training runs out of VRAM above 1280 px, the pipeline retries once at 1280 px, rebuilding frames and COLMAP to keep camera intrinsics consistent. The exported PLY is validated before an atomic move to `clip.ply`.

Expect SfM to take several minutes and training roughly 10–30 minutes for about 200 frames and 30,000 steps on an otherwise idle RTX 4090. This is an estimate, not a measured run; scene complexity and storage speed matter.

## Failures

- **Image build reports missing `/usr/bin/iconvert`:** Ubuntu's OpenImageIO CMake package requires `openimageio-tools` alongside `libopenimageio-dev`, even for headless COLMAP. The Dockerfile installs both. Rerun `host.sh`; the launcher rebuilds the image when the Dockerfile changes. Docker reuses completed build layers; no cache purge is needed.
- **Few registered frames:** Read the `registered/total` line in `pipeline.log`. Add stable texture, slower motion, more overlap, and less blur; try `--exhaustive` for short captures. COLMAP retries with SIMPLE_PINHOLE if OPENCV fails.
- **HEVC-only source:** The image's FFmpeg decodes HEVC, but an unreadable or corrupt file will fail at ffprobe/ffmpeg. For repeatable capture, use iPhone Most Compatible/H.264.
- **Portrait sideways:** The script reads both rotate tags and display-matrix rotation, disables FFmpeg autorotation, and applies transpose before JPEG extraction. Check extracted JPEGs in `clip.gsplat/images` if metadata is malformed.
- **CUDA OOM:** Automatic 1280 px retry runs once. If it still fails, rerun with `--force --scale 960` or reduce competing GPU processes.
- **Toolkit/driver mismatch:** Run the CUDA `nvidia-smi` check above. If it fails, repair the host Docker/NVIDIA runtime or update the host driver to one compatible with CUDA 12.8. No driver is installed from this image.

## Regression checks

Run `python -m unittest discover -s tests/mov2splat -v` from the workspace root. These checks use command stubs to exercise frame counts, resume invalidation, complete failure logs, and image refresh; they do not replace a real GPU reconstruction test.
