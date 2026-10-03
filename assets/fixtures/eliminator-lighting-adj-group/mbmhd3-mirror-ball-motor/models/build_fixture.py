#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/equipment_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'eliminator-lighting-adj-group/mbmhd3-mirror-ball-motor', 'width_m': 0.136, 'height_m': 0.08, 'depth_m': 0.136, 'profile': {'family': 'mirror_motor', 'body_style': 'square motor enclosure with shaft and safety attachment', 'notes': 'No ball included, no DMX.', 'generator': 'equipment', 'output_kind': 'none'}, 'source_urls': ['https://www.adj.com/products/mbmhd3', 'https://www.adj.com/cdn/shop/files/7d54dc275a1647abdf9352693a3edddb6e35fd7d_MBMHD3_web_01.jpg?v=1784181815&width=2048']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
