#!/usr/bin/env python3
"""Generate a deterministic, original Gaussian room and cross-reader fixtures.

Run from any directory with Python 3. No dependencies or downloads. Outputs only
assets/splats (or --output-dir). Room coordinates are metres, Y-up, floor at y=0.
"""
from __future__ import annotations

import argparse
import json
import math
from pathlib import Path
import struct

ROOT = Path(__file__).resolve().parents[2]
FIELDS = (
    "x", "y", "z", "nx", "ny", "nz", "f_dc_0", "f_dc_1", "f_dc_2",
    "opacity", "scale_0", "scale_1", "scale_2", "rot_0", "rot_1", "rot_2", "rot_3",
)
SH_C0 = 0.28209479177387814


def splat(position, color, rotation=(1, 0, 0, 0), scales=(0.105, 0.105, 0.025), alpha=0.92):
    return (*position, 0, 0, 0, *((c - 0.5) / SH_C0 for c in color),
            math.log(alpha / (1 - alpha)), *(math.log(s) for s in scales), *rotation)


def room():
    rows = []
    half = math.sqrt(0.5)
    floor_rotation = (half, half, 0, 0)
    side_rotation = (half, 0, half, 0)
    # Six complete surfaces; grids/color panels make parallax and orientation clear.
    for i in range(41):
        u = -3 + i * 0.15
        for j in range(41):
            v = -3 + j * 0.15
            shade = 0.26 if (i // 5 + j // 5) % 2 else 0.42
            rows.append(splat((u, 0, v), (shade, shade * 1.05, shade * 1.12), floor_rotation))
            rows.append(splat((u, 3, v), (0.20, 0.23, 0.30), floor_rotation))
        for j in range(21):
            y = j * 0.15
            panel = abs(u) < 1.2 and 0.6 < y < 2.4
            rows.append(splat((u, y, -3), (0.08, 0.66, 0.78) if panel else (0.18, 0.28, 0.34)))
            rows.append(splat((u, y, 3), (0.90, 0.44, 0.13) if panel else (0.34, 0.23, 0.18)))
            rows.append(splat((-3, y, u), (0.39, 0.25, 0.63) if panel else (0.25, 0.22, 0.32), side_rotation))
            rows.append(splat((3, y, u), (0.22, 0.62, 0.39) if panel else (0.21, 0.30, 0.24), side_rotation))
    return rows


def write_ply(path, rows, binary=False, fields=FIELDS):
    indices = [FIELDS.index(name) for name in fields]
    encoding = "binary_little_endian" if binary else "ascii"
    header = ["ply", f"format {encoding} 1.0", "comment Original synthetic splats; Y-up metres",
              f"element vertex {len(rows)}", *(f"property float {name}" for name in fields), "end_header"]
    with path.open("wb") as out:
        out.write(("\n".join(header) + "\n").encode("ascii"))
        for row in rows:
            values = [row[i] for i in indices]
            if binary:
                out.write(struct.pack("<" + "f" * len(values), *values))
            else:
                out.write((" ".join(f"{v:.8g}" for v in values) + "\n").encode("ascii"))


def generate(output):
    output.mkdir(parents=True, exist_ok=True)
    rows = room()
    write_ply(output / "demo-room.ply", rows)
    samples = [splat((-1, 0, 2), (1, 0, 0), alpha=0.5),
               splat((0, 1.5, 0), (0, 1, 0), (math.sqrt(0.5), 0, math.sqrt(0.5), 0)),
               splat((1, 3, -2), (0, 0, 1), scales=(0.2, 0.1, 0.05))]
    write_ply(output / "tiny-ascii.ply", samples)
    write_ply(output / "tiny-binary.ply", samples, binary=True)
    write_ply(output / "tiny-reordered-binary.ply", samples, binary=True, fields=tuple(reversed(FIELDS)))
    manifest = {"room": {"vertices": len(rows), "bounds_min": [-3, 0, -3],
                         "bounds_max": [3, 3, 3], "floor_center": [0, 0, 0],
                         "eye_start": [0, 1.5, 0], "units": "metres", "up": "+Y"},
                "tiny": {"vertices": 3, "positions": [list(row[:3]) for row in samples],
                         "colors": [[1, 0, 0], [0, 1, 0], [0, 0, 1]], "first_opacity": 0.5}}
    (output / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print(f"Generated {len(rows)} room splats and three parser fixtures in {output}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output-dir", type=Path, default=ROOT / "assets/splats")
    generate(parser.parse_args().output_dir)
