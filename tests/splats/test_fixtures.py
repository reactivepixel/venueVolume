"""Cross-format contract checks for the demo assets (Python standard library)."""
import json
import math
from pathlib import Path
import struct
import unittest

ROOT = Path(__file__).resolve().parents[2]
ASSETS = ROOT / "assets/splats"


def decode(path):
    raw = path.read_bytes()
    header, body = raw.split(b"end_header\n", 1)
    lines = header.decode("ascii").splitlines()
    count = int(next(line for line in lines if line.startswith("element vertex ")).split()[-1])
    fields = [line.split()[-1] for line in lines if line.startswith("property float ")]
    if "format ascii 1.0" in lines:
        rows = [list(map(float, line.split())) for line in body.splitlines()]
    else:
        assert "format binary_little_endian 1.0" in lines
        rows = list(struct.iter_unpack("<" + "f" * len(fields), body))
    assert len(rows) == count
    assert all(len(row) == len(fields) for row in rows)
    return [dict(zip(fields, row)) for row in rows]


class FixtureContract(unittest.TestCase):
    def test_room_is_finite_normalized_and_center_is_empty(self):
        rows = decode(ASSETS / "demo-room.ply")
        manifest = json.loads((ASSETS / "manifest.json").read_text())["room"]
        self.assertEqual(len(rows), manifest["vertices"])
        self.assertEqual([min(r[c] for r in rows) for c in "xyz"], manifest["bounds_min"])
        self.assertEqual([max(r[c] for r in rows) for c in "xyz"], manifest["bounds_max"])
        for row in rows:
            self.assertTrue(all(math.isfinite(v) for v in row.values()))
            self.assertAlmostEqual(sum(row[f"rot_{i}"] ** 2 for i in range(4)), 1, places=6)
            self.assertTrue(all(0.001 < math.exp(row[f"scale_{i}"]) < 1 for i in range(3)))
            self.assertGreater(math.dist([row[c] for c in "xyz"], manifest["eye_start"]), 1.4)

    def test_ascii_binary_and_reordered_properties_decode_identically(self):
        reference = decode(ASSETS / "tiny-ascii.ply")
        for name in ("tiny-binary.ply", "tiny-reordered-binary.ply"):
            actual = decode(ASSETS / name)
            self.assertEqual(len(actual), len(reference))
            for expected, decoded in zip(reference, actual):
                self.assertEqual(expected.keys(), decoded.keys())
                for field in expected:
                    self.assertAlmostEqual(expected[field], decoded[field], places=6)
        self.assertAlmostEqual(1 / (1 + math.exp(-reference[0]["opacity"])), 0.5)
        for i, row in enumerate(reference):
            color = [0.5 + 0.28209479177387814 * row[f"f_dc_{j}"] for j in range(3)]
            for j in range(3):
                self.assertAlmostEqual(color[j], float(i == j), places=6)


if __name__ == "__main__":
    unittest.main()
