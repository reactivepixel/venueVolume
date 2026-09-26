"""Record completed stage inputs so interrupted or changed jobs cannot reuse stale data."""
import argparse
import json
from pathlib import Path


def fingerprint(args):
    source = args.input.resolve()
    stat = source.stat()
    root = args.manifest.parent
    data = {
        "schema": 1,
        "source": [str(source), stat.st_size, stat.st_mtime_ns],
        "frames": args.frames,
        "scale": args.scale,
        "blur": args.blur,
        "images": [
            [p.name, p.stat().st_size, p.stat().st_mtime_ns]
            for p in sorted((root / "images").glob("frame_*.jpg"))
        ],
    }
    if args.matcher:
        data["matcher"] = args.matcher
        data["model"] = [
            [name, p.stat().st_size, p.stat().st_mtime_ns]
            for name in ("cameras.bin", "images.bin", "points3D.bin")
            for p in [root / "sparse" / "0" / name]
        ]
    return data


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=("matches", "save"))
    parser.add_argument("manifest", type=Path)
    parser.add_argument("--input", required=True, type=Path)
    parser.add_argument("--frames", required=True, type=int)
    parser.add_argument("--scale", required=True, type=int)
    parser.add_argument("--blur", required=True, type=float)
    parser.add_argument("--matcher", choices=("sequential", "exhaustive"))
    args = parser.parse_args()
    try:
        data = fingerprint(args)
        if args.action == "matches":
            return 0 if json.loads(args.manifest.read_text()) == data else 1
        temporary = args.manifest.with_suffix(".tmp")
        temporary.write_text(json.dumps(data, indent=2) + "\n")
        temporary.replace(args.manifest)
    except (OSError, ValueError):
        if args.action == "save":
            raise
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
