#!/usr/bin/env bash
set -euo pipefail

usage() {
  printf 'Usage: run.sh [--force] [--resume] [--frames N] [--scale PX] [--steps N] [--exhaustive] [--blur-threshold V] /data/clip.mov\n' >&2
}
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
positive_int() { [[ "$1" =~ ^[0-9]+$ ]] && (( 10#$1 > 0 )); }

FORCE=0 RESUME=0 EXHAUSTIVE=0 TARGET_FRAMES=220 SCALE=1600 STEPS=30000 BLUR_THRESHOLD=0
while (($#)); do
  case "$1" in
    --force) FORCE=1; shift ;;
    --resume) RESUME=1; shift ;;
    --exhaustive) EXHAUSTIVE=1; shift ;;
    --frames|--scale|--steps|--blur-threshold)
      (($# >= 2)) || { usage; exit 2; }
      case "$1" in
        --frames) TARGET_FRAMES=$2 ;; --scale) SCALE=$2 ;;
        --steps) STEPS=$2 ;; --blur-threshold) BLUR_THRESHOLD=$2 ;;
      esac
      shift 2 ;;
    -*) usage; exit 2 ;;
    *) (($# == 1)) || { usage; exit 2; }; MOV=$1; shift ;;
  esac
done
[[ -n "${MOV:-}" ]] || { usage; exit 2; }
[[ -f "$MOV" ]] || die "Input file does not exist: $MOV"
MOV=$(realpath -- "$MOV")
case "${MOV,,}" in *.mov|*.mp4|*.m4v) ;; *) die 'Input must be .mov, .mp4, or .m4v' ;; esac
positive_int "$TARGET_FRAMES" || die '--frames must be a positive integer'
positive_int "$SCALE" || die '--scale must be a positive integer'
positive_int "$STEPS" || die '--steps must be a positive integer'
(( SCALE >= 256 )) || die '--scale must be at least 256 px'
(( TARGET_FRAMES < 150 )) && TARGET_FRAMES=150
(( TARGET_FRAMES > 300 )) && TARGET_FRAMES=300
[[ "$BLUR_THRESHOLD" =~ ^([0-9]+([.][0-9]*)?|[.][0-9]+)$ ]] || die '--blur-threshold must be nonnegative'

OUT=${MOV%.*}.ply
WORK=${MOV%.*}.gsplat
FRAMES=$WORK/images
SPARSE=$WORK/sparse
DB=$WORK/database.db
TRAIN=$WORK/train
LOG=$WORK/pipeline.log
[[ ! -e "$OUT" || "$FORCE" == 1 ]] || die "Output exists: $OUT (use --force)"
mkdir -p "$WORK"
command -v flock >/dev/null || die 'flock is required'
exec 9>"$WORK/.lock"
flock -n 9 || die "Another job is using $WORK"
exec 3>&1
exec > >(awk '{ print strftime("[%Y-%m-%d %H:%M:%S]"), $0; fflush() }' | tee -a "$LOG" >&3) 2>&1

# Cache and temporary writes stay beside the clip, even when HOME=/tmp is passed
# by the host wrapper. The preloaded Torch model weights remain in the image.
export HOME=$WORK/home XDG_CACHE_HOME=$WORK/cache TMPDIR=$WORK/tmp
export TORCH_EXTENSIONS_DIR=$WORK/torch_extensions TORCH_HOME=/opt/torch-cache
export TORCH_CUDA_ARCH_LIST=8.9 CUDAARCHS=89
mkdir -p "$HOME" "$XDG_CACHE_HOME" "$TMPDIR" "$TORCH_EXTENSIONS_DIR"

STAGE=init REGISTERED=0 FRAME_COUNT=0
EXTRACTED=0 SFM_RAN=0
status() {
  python - "$WORK/status.json" "$STAGE" "$REGISTERED" "$FRAME_COUNT" "$1" <<'PY'
import datetime, json, os, sys
path, stage, registered, frames, exit_code = sys.argv[1:]
data = {"stage": stage, "registered": int(registered), "frames": int(frames),
        "exit": None if exit_code == "null" else int(exit_code),
        "updated_at": datetime.datetime.now(datetime.timezone.utc).isoformat()}
tmp = path + ".tmp"
with open(tmp, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
os.replace(tmp, path)
PY
}
set_stage() { STAGE=$1; status null; echo "stage: $STAGE"; }
on_exit() {
  local code=$1
  trap - EXIT
  if (( code != 0 )); then echo "pipeline failed at $STAGE (exit $code)"; fi
  status "$code" || true
}
trap 'on_exit $?' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
status null
echo "input: $MOV"

frame_count() { find "$FRAMES" -maxdepth 1 -type f -name 'frame_*.jpg' | wc -l; }
model_counts() {
  python - "$SPARSE/0" "$FRAME_COUNT" <<'PY'
import pathlib, struct, sys
p = pathlib.Path(sys.argv[1])
total = int(sys.argv[2])
try:
    counts = [struct.unpack('<Q', (p / name).open('rb').read(8))[0]
              for name in ('cameras.bin', 'images.bin', 'points3D.bin')]
    cameras, registered, points = counts
    valid = cameras > 0 and registered > 0 and points > 0 and registered <= total
except (OSError, struct.error):
    registered, valid = 0, False
print(registered, int(valid))
PY
}
check_model() {
  read -r REGISTERED MODEL_VALID < <(model_counts)
  echo "COLMAP registered/total: $REGISTERED/$FRAME_COUNT"
  (( MODEL_VALID == 1 && REGISTERED * 100 >= FRAME_COUNT * 85 )) || return 1
  colmap model_analyzer --path "$SPARSE/0" >"$WORK/model_analyzer.log" 2>&1 || return 1
}
validate_ply() {
  python - "$1" <<'PY'
import pathlib, re, sys
p = pathlib.Path(sys.argv[1])
try:
    with p.open('rb') as f:
        header = f.read(16384)
    end = header.index(b'end_header\n') + len(b'end_header\n')
    h = header[:end].decode('ascii')
    count = int(re.search(r'^element vertex (\d+)$', h, re.M).group(1))
    props = set(re.findall(r'^property float (\S+)$', h, re.M))
    needed = {'x', 'y', 'z', 'f_dc_0', 'f_dc_1', 'f_dc_2',
              'opacity', 'scale_0', 'scale_1', 'scale_2',
              'rot_0', 'rot_1', 'rot_2', 'rot_3'}
    needed.update({f'f_rest_{i}' for i in range(45)})
    good = ('format binary_little_endian 1.0' in h and count > 0
            and needed <= props and p.stat().st_size >= end + count * len(props) * 4)
except (OSError, ValueError, AttributeError):
    good = False
sys.exit(0 if good else 1)
PY
}

extract() {
  set_stage extract
  EXTRACTED=1
  local probe fps rotation_filter vf
  readarray -t probe < <(python - "$MOV" "$TARGET_FRAMES" <<'PY'
import json, math, subprocess, sys
info = json.loads(subprocess.check_output([
    'ffprobe', '-v', 'error', '-select_streams', 'v:0',
    '-show_entries', 'stream=width,height,duration:stream_tags=rotate:stream_side_data=rotation:format=duration',
    '-of', 'json', sys.argv[1]], text=True))
streams = info.get('streams', [])
if not streams:
    raise SystemExit('No video stream in input')
s = streams[0]
duration = float(s.get('duration') or info.get('format', {}).get('duration') or 0)
if duration <= 0 or not math.isfinite(duration):
    raise SystemExit('ffprobe could not determine video duration')
rotation = next((d.get('rotation') for d in s.get('side_data_list', [])
                 if 'rotation' in d), s.get('tags', {}).get('rotate', 0))
rotation = int(round(float(rotation))) % 360
if rotation not in (0, 90, 180, 270):
    raise SystemExit(f'Unsupported non-right-angle rotation: {rotation}')
w, h = int(s['width']), int(s['height'])
display_w, display_h = (h, w) if rotation in (90, 270) else (w, h)
print(f'{int(sys.argv[2]) / duration:.9f}')
print(rotation)
print(f'{w}x{h} -> {display_w}x{display_h}')
PY
  )
  ((${#probe[@]} == 3)) || die 'ffprobe failed to inspect video'
  fps=${probe[0]}
  case "${probe[1]}" in
    0) rotation_filter='' ;; 90) rotation_filter='transpose=cclock,' ;;
    180) rotation_filter='hflip,vflip,' ;; 270) rotation_filter='transpose=clock,' ;;
  esac
  echo "rotation: ${probe[1]} degrees; dimensions: ${probe[2]}; sampling fps: $fps"
  mkdir -p "$FRAMES"
  find "$FRAMES" -maxdepth 1 -type f -name 'frame_*.jpg' -delete
  vf="${rotation_filter}fps=${fps},scale=if(gte(iw\\,ih)\\,min(iw\\,${SCALE})\\,-2):if(gte(iw\\,ih)\\,-2\\,min(ih\\,${SCALE})):flags=lanczos"
  ffmpeg -hide_banner -loglevel error -nostdin -noautorotate -i "$MOV" \
    -an -sn -vf "$vf" -frames:v "$TARGET_FRAMES" -q:v 2 -start_number 1 \
    "$FRAMES/frame_%05d.jpg"
  if [[ "$BLUR_THRESHOLD" != 0 ]]; then
    python - "$FRAMES" "$BLUR_THRESHOLD" <<'PY'
import pathlib, sys
import cv2
files = sorted(pathlib.Path(sys.argv[1]).glob('frame_*.jpg'))
scores = []
for path in files:
    image = cv2.imread(str(path), cv2.IMREAD_GRAYSCALE)
    if image is None:
        raise SystemExit(f'Cannot read extracted frame {path}')
    scores.append((float(cv2.Laplacian(image, cv2.CV_64F).var()), path))
threshold = float(sys.argv[2])
keep = {path for score, path in scores if score >= threshold}
if len(keep) < min(120, len(files)):
    keep = {path for _, path in sorted(scores, reverse=True)[:min(120, len(files))]}
for path in files:
    if path not in keep:
        path.unlink()
print(f'blur filter kept {len(keep)}/{len(files)} frames')
PY
  fi
  FRAME_COUNT=$(frame_count)
  (( FRAME_COUNT >= 120 )) || die "Only $FRAME_COUNT frames extracted; need at least 120"
  echo "extract complete: $FRAME_COUNT frames"
  status null
}

run_colmap_model() {
  local camera=$1
  echo "COLMAP camera model: $camera"
  rm -f "$DB"
  rm -rf "$SPARSE"
  mkdir -p "$SPARSE"
  colmap feature_extractor --database_path "$DB" --image_path "$FRAMES" \
    --ImageReader.single_camera 1 --ImageReader.camera_model "$camera" \
    --FeatureExtraction.use_gpu 1 || return 1
  if (( EXHAUSTIVE )); then
    colmap exhaustive_matcher --database_path "$DB" --FeatureMatching.use_gpu 1 || return 1
  else
    colmap sequential_matcher --database_path "$DB" --FeatureMatching.use_gpu 1 || return 1
  fi
  colmap mapper --database_path "$DB" --image_path "$FRAMES" --output_path "$SPARSE" || return 1
}
sfm() {
  set_stage colmap
  SFM_RAN=1
  if run_colmap_model OPENCV && check_model; then
    echo 'COLMAP OPENCV reconstruction accepted'
  else
    echo 'COLMAP OPENCV failed or registered too few frames; retrying SIMPLE_PINHOLE'
    if ! run_colmap_model SIMPLE_PINHOLE || ! check_model; then
      die "COLMAP failed: registered $REGISTERED/$FRAME_COUNT; need at least 85% and nonempty sparse points"
    fi
  fi
  status null
}

train() {
  set_stage train
  rm -rf "$TRAIN"
  mkdir -p "$TRAIN"
  echo "training gsplat: $STEPS steps at max long edge $SCALE"
  # The pinned official example's default strategy performs densification and
  # prunes opacity below 0.005. Export and checkpoint happen at the final step.
  python /opt/gsplat-source/examples/simple_trainer.py default \
    --disable-viewer --disable-video --save-ply \
    --data-dir "$WORK" --data-factor 1 --result-dir "$TRAIN" \
    --max-steps "$STEPS" --eval-steps 999999999 \
    --save-steps "$STEPS" --ply-steps "$STEPS" \
    2>&1 | tee "$TRAIN/trainer.log" || return 1
  validate_ply "$TRAIN/ply/point_cloud_$((STEPS - 1)).ply" || return 1
  echo 'train complete'
}

set_stage init
if (( RESUME )) && [[ -d "$FRAMES" ]]; then
  FRAME_COUNT=$(frame_count)
fi
if (( RESUME )) && (( FRAME_COUNT >= 120 )); then
  echo "extract: reusing $FRAME_COUNT frames"
else
  extract
fi
if (( RESUME && ! EXTRACTED )) && check_model; then
  echo 'colmap: valid sparse/0 found; skipping SfM'
else
  sfm
fi

TRAIN_PLY=$TRAIN/ply/point_cloud_$((STEPS - 1)).ply
if (( RESUME && ! SFM_RAN )) && validate_ply "$TRAIN_PLY"; then
  echo 'train: reusing completed PLY'
else
  if train; then
    :
  else
    if grep -Eiq 'CUDA.*out of memory|OutOfMemoryError|CUDNN_STATUS_ALLOC_FAILED' "$TRAIN/trainer.log" && (( SCALE > 1280 )); then
      echo 'CUDA OOM: retrying once at 1280 px; rebuilding frames and SfM'
      SCALE=1280
      extract
      sfm
      train
    else
      die 'Training failed; inspect train/trainer.log and pipeline.log'
    fi
  fi
fi

set_stage export
validate_ply "$TRAIN_PLY" || die 'Refusing to export an empty or invalid PLY'
TMP_OUT="$OUT.tmp.$$"
trap 'code=$?; rm -f -- "$TMP_OUT"; on_exit "$code"' EXIT
cp -- "$TRAIN_PLY" "$TMP_OUT"
validate_ply "$TMP_OUT" || die 'Copied PLY failed validation'
mv -f -- "$TMP_OUT" "$OUT"
STAGE=complete
status 0
echo "export complete: $OUT"
