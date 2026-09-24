#!/usr/bin/env bash
set -euo pipefail

usage() {
  printf 'Usage: %s [--force] [--resume] [--frames N] [--scale PX] [--steps N] [--exhaustive] [--blur-threshold V] /path/to/clip.mov\n' "$0" >&2
}
APP_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
ARGS=()
while (($#)); do
  case "$1" in
    --force|--resume|--exhaustive) ARGS+=("$1"); shift ;;
    --frames|--scale|--steps|--blur-threshold)
      (($# >= 2)) || { usage; exit 2; }
      ARGS+=("$1" "$2"); shift 2 ;;
    -*) usage; exit 2 ;;
    *) (($# == 1)) || { usage; exit 2; }; INPUT=$1; shift ;;
  esac
done
[[ -n "${INPUT:-}" ]] || { usage; exit 2; }
[[ -f "$INPUT" ]] || { printf 'Input file not found: %s\n' "$INPUT" >&2; exit 1; }
MOV=$(realpath -- "$INPUT")
case "${MOV,,}" in *.mov|*.mp4|*.m4v) ;; *) printf 'Expected a .mov, .mp4, or .m4v file\n' >&2; exit 2 ;; esac
command -v nvidia-smi >/dev/null || { echo 'nvidia-smi is not installed' >&2; exit 1; }
nvidia-smi -L >/dev/null || { echo 'nvidia-smi cannot see an NVIDIA GPU' >&2; exit 1; }
command -v docker >/dev/null || { echo 'Docker is not installed' >&2; exit 1; }
docker info >/dev/null || { echo 'Cannot reach the Docker daemon; check service and permissions' >&2; exit 1; }

IMAGE=mov2splat:4090
if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
  docker build -t "$IMAGE" -f "$APP_DIR/Dockerfile" "$APP_DIR"
fi
MOV_DIR=$(dirname -- "$MOV")
docker run --rm --gpus all --network none \
  -u "$(id -u):$(id -g)" -e HOME=/tmp \
  -v "$MOV_DIR:$MOV_DIR" \
  "$IMAGE" "${ARGS[@]}" "$MOV"
printf '%s\n' "${MOV%.*}.ply"
