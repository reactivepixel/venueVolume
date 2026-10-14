#!/usr/bin/env python3
"""Capture --demo --gizmo-smoke and verify handles remain visible over its blocker.

Requires Pillow. Start before launching with --console-pty to a fresh log:
  python3 scripts/test-gizmo-render.py SIMULATOR_ID LOG OUTPUT_PREFIX
"""
import subprocess
import sys
import time
from pathlib import Path
from PIL import Image

device, log_name, prefix = sys.argv[1:]
log = Path(log_name)
for mode in ("MOVE", "ROTATE"):
    counts = []
    for visibility in ("CLEAR", "BLOCKED"):
        stage = f"{mode}_{visibility}"
        deadline = time.monotonic() + 120
        while f"GIZMO_CAPTURE_{stage}" not in (log.read_text() if log.exists() else ""):
            output = log.read_text() if log.exists() else ""
            if "GIZMO_SMOKE_FAIL" in output:
                raise SystemExit(output)
            if time.monotonic() > deadline:
                raise SystemExit(f"Missing {stage} capture stage")
            time.sleep(.2)
        time.sleep(.5)  # Let the compositor present the stage.
        path = f"{prefix}-{stage.lower()}.png"
        subprocess.run(["xcrun", "simctl", "io", device, "screenshot", path], check=True, capture_output=True)
        capture = Image.open(path).convert("RGB")
        w, h = capture.size
        pixels = list(capture.crop((int(w*.57), int(h*.46), int(w*.85), int(h*.78))).getdata())
        red = sum(r > 1.7*g and r > 1.7*b and r > 60 for r,g,b in pixels)
        green = sum(g > 1.7*r and g > 1.3*b and g > 20 for r,g,b in pixels)
        blue = sum(b > 1.7*r and b > 1.4*g and b > 20 for r,g,b in pixels)
        counts.append((red, green, blue))
        print(f"{stage}: visible X/Y/Z pixels = {red}/{green}/{blue}", flush=True)
    clear, blocked = counts
    if min(clear) < 100 or any(after < before*.90 for before,after in zip(clear,blocked)):
        raise SystemExit(f"GIZMO_RENDER_FAIL: {mode} geometry disappears behind the blocker")
print("GIZMO_RENDER_PASS", flush=True)
