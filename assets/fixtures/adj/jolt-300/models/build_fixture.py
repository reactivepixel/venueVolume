#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'adj/jolt-300', 'width_m': 0.389, 'height_m': 0.213, 'depth_m': 0.143, 'profile': {'family': 'strobe', 'lens_count': 288, 'body_style': 'short rectangular strobe panel with central white LED row, flanking RGB LED rows, and single yoke', 'notes': 'Official page gives 144 white and 144 RGB SMD LEDs; emitter group count does not define lens geometry.'}, 'source_urls': ['https://www.adj.com/products/jolt-300', 'https://www.adj.com/cdn/shop/files/24123b2ef30540e21651ee792a1dda543061fbbb_JOL300__IMG__001__fc31c3261e23.jpg?v=1776712495&width=800']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
