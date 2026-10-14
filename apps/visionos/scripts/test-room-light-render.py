#!/usr/bin/env python3
"""Capture a running --demo --room-light-smoke Simulator run (requires Pillow).

Start this before launching the app with --console-pty redirected to LOG:
  python3 scripts/test-room-light-render.py SIMULATOR_ID LOG OUTPUT_PREFIX
Use a fresh log and the default demo camera; the sampled area excludes fixtures/UI.
"""
import subprocess
import sys
import time
from pathlib import Path

from PIL import Image, ImageStat

device, log_name, prefix = sys.argv[1:]
log = Path(log_name)
for stage in ("LOW", "HIGH"):
    deadline = time.monotonic() + 90
    while f"ROOM_LIGHT_CAPTURE_{stage}" not in (log.read_text() if log.exists() else ""):
        if time.monotonic() > deadline:
            raise SystemExit(f"Missing {stage} capture stage")
        time.sleep(0.25)
    subprocess.run(["xcrun", "simctl", "io", device, "screenshot",
                    f"{prefix}-{stage.lower()}.png"], check=True, capture_output=True)

low = Image.open(f"{prefix}-low.png").convert("L")
high = Image.open(f"{prefix}-high.png").convert("L")
w, h = low.size
roi = (int(w * .05), int(h * .15), int(w * .30), int(h * .65))
a = ImageStat.Stat(low.crop(roi)).mean[0]
b = ImageStat.Stat(high.crop(roi)).mean[0]
print(f"Room luminance: 0%={a:.2f}, 100%={b:.2f}, difference={b-a:.2f}")
if b - a < 15:
    raise SystemExit("ROOM_LIGHT_RENDER_FAIL: room does not brighten across the slider range")
print("ROOM_LIGHT_RENDER_PASS")
