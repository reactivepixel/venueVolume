"""Select photographic references, not camera calibration or an automatic reconstruction.

Example: python scripts/extract_references.py /path/to/IMG_3153.MOV
HDR captures are tone mapped to SDR; original media is never changed.
"""
import argparse
import concurrent.futures
import hashlib
import json
from pathlib import Path
import shutil
import subprocess

import cv2
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("movie", type=Path, nargs="?")
    parser.add_argument("--contact-sheet-only", action="store_true")
    parser.add_argument("--times", default="6,22,57,70,100,128,152,177,199,225,256,280,303,326,355,371")
    args = parser.parse_args()
    if args.contact_sheet_only:
        make_contact_sheet(json.loads((ROOT / "references/manifest.json").read_text())["references"])
        return
    if args.movie is None:
        parser.error("movie is required unless --contact-sheet-only is used")
    probe = json.loads(subprocess.check_output([
        "ffprobe", "-v", "error", "-show_format", "-show_streams", "-of", "json", str(args.movie)]))
    stream = next(s for s in probe["streams"] if s["codec_type"] == "video")
    duration = float(probe["format"]["duration"])
    targets = [float(t) for t in args.times.split(",")]
    if any(t < 1 or t + 0.7 >= duration for t in targets):
        parser.error("Each reference time must be at least 1 second from the video boundaries")
    refdir = ROOT / "references"
    cache = ROOT / ".cache" / "candidates"
    cache.mkdir(parents=True, exist_ok=True)
    refdir.mkdir(exist_ok=True)
    hdr = stream.get("color_transfer") in ("arib-std-b67", "smpte2084")
    filters = "scale=1600:-2"
    if hdr:
        filters += ",zscale=t=linear:npl=100,format=gbrpf32le,tonemap=tonemap=hable:desat=0,zscale=p=bt709:t=bt709:m=bt709:r=full,format=yuvj420p"

    def extract(job):
        index, seconds = job
        path = cache / f"candidate_{index:03d}.jpg"
        command = ["ffmpeg", "-hide_banner", "-loglevel", "warning", "-threads", "2",
                   "-ss", str(seconds), "-i", str(args.movie), "-an", "-frames:v", "1",
                   "-vf", filters, "-q:v", "2", "-update", "1", "-y", str(path)]
        result = subprocess.run(command, capture_output=True, text=True)
        (cache / f"candidate_{index:03d}.log").write_text(result.stderr)
        pixels = cv2.imread(str(path), cv2.IMREAD_GRAYSCALE) if result.returncode == 0 else None
        if pixels is None:
            return None
        score = float(cv2.Laplacian(pixels, cv2.CV_64F).var())
        errors = sum(any(term in line.lower() for term in ("invalid", "error", "could not find ref"))
                     for line in result.stderr.splitlines())
        return {"requested_seek_seconds": seconds, "sharpness_score": round(score, 2),
                "decoder_error_lines": errors, "path": str(path)}

    jobs = [(i * 3 + j, t + offset) for i, t in enumerate(targets)
            for j, offset in enumerate((-0.6, 0, 0.6))]
    with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
        candidates = list(pool.map(extract, jobs))
    selected = []
    for i, target in enumerate(targets):
        group = [c for c in candidates[i * 3:i * 3 + 3] if c]
        if not group:
            raise RuntimeError(f"No usable frame near {target}s; see .cache/candidates/*.log")
        # Prefer a clean decode; sharpness alone can favor corruption or noise.
        best = max(group, key=lambda c: (c["decoder_error_lines"] == 0, c["sharpness_score"]))
        name = f"reference_{i + 1:02d}_{target:06.1f}s.jpg"
        shutil.copyfile(best["path"], refdir / name)
        selected.append({"file": name, **{k: v for k, v in best.items() if k != "path"}})
        print(name, selected[-1], flush=True)

    with args.movie.open("rb") as movie:
        digest = hashlib.file_digest(movie, "sha256").hexdigest()
    manifest = {"source": args.movie.name, "sha256": digest, "duration_seconds": duration,
                "creation_time": probe["format"].get("tags", {}).get("creation_time"),
                "source_size_bytes": args.movie.stat().st_size, "source_transfer": stream.get("color_transfer"),
                "output_color": "SDR sRGB-compatible BT.709", "hdr_tone_mapped": hdr,
                "selection": "Best Laplacian sharpness of 3 local candidates, preferring clean decodes; manually review every selection.",
                "timestamp_note": "Requested seek positions, not calibrated exposure timestamps; damaged sections may skip frames.",
                "references": selected}
    (refdir / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    make_contact_sheet(selected)


def make_contact_sheet(selected):
    refdir = ROOT / "references"
    sheet = Image.new("RGB", (1600, ((len(selected) + 3) // 4) * 255 + 70), "#121c27")
    draw = ImageDraw.Draw(sheet)
    font = ImageFont.load_default(size=16)
    draw.text((18, 14), "IMG_3153 / CLASSROOM REFERENCE VIEWS", fill="white", font=font)
    draw.text((18, 40), "Selected movie frames / HDR converted to SDR / dimensions remain unmeasured", fill="#a9bdcc", font=font)
    for i, ref in enumerate(selected):
        x, y = (i % 4) * 400, (i // 4) * 255 + 70
        photo = Image.open(refdir / ref["file"])
        photo.thumbnail((392, 221))
        sheet.paste(photo, (x + 4, y))
        draw.text((x + 8, y + 225), f'{i + 1:02d} / ~{ref["requested_seek_seconds"]:.1f}s', fill="white", font=font)
    sheet.save(refdir / "contact-sheet.jpg", quality=93)


if __name__ == "__main__":
    main()
