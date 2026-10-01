#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'claypaky/hy-b-eye-k25', 'width_m': 0.387, 'height_m': 0.59, 'depth_m': 0.329, 'profile': {'family': 'moving_wash', 'lens_count': 37, 'shell': 'round'}, 'source_urls': ['https://www.claypaky.it/products/hy-b-eye-k25/', 'https://www.claypaky.it/wp-content/uploads/2022/10/Claypaky_HY_B-EYE_K25.jpg']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
