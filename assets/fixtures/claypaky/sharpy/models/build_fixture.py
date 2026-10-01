#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'claypaky/sharpy', 'width_m': 0.405, 'height_m': 0.475, 'depth_m': 0.33, 'profile': {'family': 'moving_spot', 'shell': 'faceted', 'lens_ratio': 0.77, 'head_depth': 0.78, 'base_height': 0.15}, 'source_urls': ['https://www.claypaky.it/products/sharpy-legacy/', 'https://www.claypaky.it/wp-content/uploads/2022/10/Claypaky_sharpy_leaflet.pdf', 'https://www.claypaky.it/wp-content/uploads/2022/10/Claypaky_Sharpy.jpg']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
