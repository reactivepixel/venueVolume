#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'jb-lighting/sparx-12', 'width_m': 0.404, 'height_m': 0.491, 'depth_m': 0.265, 'profile': {'family': 'moving_wash', 'shell': 'round', 'lens_count': 19, 'lens_ratio': 0.9, 'head_depth': 0.55}, 'source_urls': ['https://www.jb-lighting.de/en/Sparx12', 'https://www.jb-lighting.de/images/products/Sparx12/Sparx12_seitlich_min_Zoom.png']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
