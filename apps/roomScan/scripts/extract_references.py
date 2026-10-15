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


def extract(movie, root, times=None, count=16):
    movie, root = Path(movie), Path(root)
    probe = json.loads(subprocess.check_output([
        "ffprobe", "-v", "error", "-show_format", "-show_streams", "-of", "json", str(movie)]))
    stream = next(s for s in probe["streams"] if s["codec_type"] == "video")
    duration = float(probe["format"]["duration"])
    if not 0.15 < duration < 86400:
        raise ValueError("Video duration must be between 0.15 seconds and 24 hours")
    targets = list(times) if times else [(i+0.5)*duration/count for i in range(count)]
    if not targets or len(targets) > 128 or any(not 0 < t < duration for t in targets):
        raise ValueError("Select 1–128 reference times strictly within the movie duration")
    delta = min(0.6, min(min(t, duration-t) for t in targets)/2, duration/(len(targets)*6))
    refdir = root / "references"
    cache = root / ".cache" / "candidates"
    cache.mkdir(parents=True, exist_ok=True)
    refdir.mkdir(exist_ok=True)
    hdr = stream.get("color_transfer") in ("arib-std-b67", "smpte2084")
    filters = "scale=w='min(1600,iw)':h=-2"
    if hdr:
        filters += ",zscale=t=linear:npl=100,format=gbrpf32le,tonemap=tonemap=hable:desat=0,zscale=p=bt709:t=bt709:m=bt709:r=full,format=yuvj420p"

    def extract(job):
        index, seconds = job
        path = cache / f"candidate_{index:03d}.jpg"
        path.unlink(missing_ok=True)
        command = ["ffmpeg", "-hide_banner", "-loglevel", "warning", "-threads", "2",
                   "-ss", str(seconds), "-i", str(movie), "-an", "-frames:v", "1",
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
            for j, offset in enumerate((-delta, 0, delta))]
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

    with movie.open("rb") as source_file:
        digest = hashlib.file_digest(source_file, "sha256").hexdigest()
    manifest = {"source": movie.name, "sha256": digest, "duration_seconds": duration,
                "creation_time": probe["format"].get("tags", {}).get("creation_time"),
                "source_size_bytes": movie.stat().st_size, "source_transfer": stream.get("color_transfer"),
                "output_color": "SDR sRGB-compatible BT.709", "hdr_tone_mapped": hdr,
                "selection": "Best Laplacian sharpness of 3 local candidates, preferring clean decodes; manually review every selection.",
                "timestamp_note": "Requested seek positions, not calibrated exposure timestamps; damaged sections may skip frames.",
                "sampling": {"target_seconds": targets, "candidate_offset_seconds": delta, "filter": filters},
                "references": selected}
    (refdir / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    make_contact_sheet(selected, root, movie.name, hdr)
    return manifest


def make_contact_sheet(selected, root, title="Reference views", hdr=False):
    refdir = root / "references"
    sheet = Image.new("RGB", (1600, ((len(selected) + 3) // 4) * 255 + 70), "#121c27")
    draw = ImageDraw.Draw(sheet)
    font = ImageFont.load_default(size=16)
    draw.text((18, 14), title + " / REFERENCE VIEWS", fill="white", font=font)
    draw.text((18, 40), ("HDR converted to SDR" if hdr else "SDR references") + " / dimensions remain unmeasured", fill="#a9bdcc", font=font)
    for i, ref in enumerate(selected):
        x, y = (i % 4) * 400, (i // 4) * 255 + 70
        photo = Image.open(refdir / ref["file"])
        photo.thumbnail((392, 221))
        sheet.paste(photo, (x + 4, y))
        draw.text((x + 8, y + 225), f'{i + 1:02d} / ~{ref["requested_seek_seconds"]:.1f}s', fill="white", font=font)
    sheet.save(refdir / "contact-sheet.jpg", quality=93)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("movie", type=Path)
    parser.add_argument("--project", type=Path, default=ROOT)
    parser.add_argument("--count", type=int, default=16)
    parser.add_argument("--times", help="Comma-separated explicit reference times in seconds")
    args = parser.parse_args()
    if not 1 <= args.count <= 128:
        parser.error("--count must be between 1 and 128")
    extract(args.movie, args.project, [float(t) for t in args.times.split(',')] if args.times else None, args.count)
