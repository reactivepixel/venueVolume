#!/usr/bin/env bash
set -euo pipefail
vv_app="$(cd "$(dirname "$0")/.." && pwd)"
vv_blender="${VV_BLENDER:-blender}"
vv_render=()
vv_compare=()
for vv_arg in "$@"; do
    case "$vv_arg" in
        --render) vv_render=(--render) ;;
        --benchmark) vv_compare=(--render) ;;
        *) echo "Usage: $0 [--render] [--benchmark] (VV_BLENDER selects Blender)" >&2; exit 2 ;;
    esac
done
uv run --locked --project "$vv_app" python "$vv_app/scripts/mapped_textures.py"
"$vv_blender" -b "$vv_app/output/classroom.blend" --python-exit-code 1 --python "$vv_app/scripts/build_mapped_room.py" -- "${vv_render[@]}"
"$vv_blender" -b --python-exit-code 1 --python "$vv_app/scripts/compare_mapped_room.py" -- "${vv_compare[@]}"
python3 "$vv_app/scripts/mapped_gallery.py"
vv_bundle="$vv_app/../visionos/VenueVolume/Environments/MappedRoom"
mkdir -p "$vv_bundle"
cp "$vv_app/mappedRoom/output/environment.json" "$vv_app/mappedRoom/output/environment.usdz" "$vv_bundle/"
python3 "$vv_app/../visionos/Tests/verify-assets.py"
