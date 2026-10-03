#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/equipment_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'chauvet-dj/hurricane-haze-1dx', 'width_m': 0.15, 'height_m': 0.223, 'depth_m': 0.278, 'profile': {'family': 'hazer', 'notes': 'Water-based heated hazer with HFG fluid. Manufacturer page lists one DMX channel and provides the direct right-side product photo; product page does not map the dimension triplet to axes.', 'body_style': 'compact low-profile metal hazer with top handle, adjustable output scoop and rear controls', 'generator': 'equipment', 'output_kind': 'haze'}, 'source_urls': ['https://fr.chauvetdj.com/products/hurricane-haze-1dx/', 'https://fr.chauvetdj.com/wp-content/uploads/2016/12/wsi-imageoptim-Hurricane-Haze-1DX-RIGHT.jpg']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
