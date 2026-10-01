#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'claypaky/sharpy-plus', 'width_m': 0.375, 'height_m': 0.635, 'depth_m': 0.307, 'profile': {'family': 'moving_spot', 'shell': 'faceted', 'lens_ratio': 0.64, 'head_depth': 0.87}, 'source_urls': ['https://www.claypaky.it/products/sharpy-plus/', 'https://www.claypaky.it/wp-content/uploads/2022/10/Claypaky_SharpyPlus.jpg']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
