#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/equipment_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'adj/m-2020-mirror-ball', 'width_m': 0.508, 'height_m': 0.508, 'depth_m': 0.508, 'profile': {'family': 'mirror_ball', 'body_style': 'spherical mirror-tiled ball with top suspension loop', 'notes': 'Separate from MBMHD3 motor. Suspension hardware/load rating unknown; no complete rigging assembly implied.', 'generator': 'equipment', 'output_kind': 'none'}, 'source_urls': ['https://www.adj.com/m-2020', 'https://www.adj.com/cdn/shop/files/6f6095a0527f5c470d06959344a15172076cf0c2_M_2020__IMG__001__1171d2bbbf43.jpg?v=1776712813&width=2048']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
