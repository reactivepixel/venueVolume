#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'claypaky/arolla-profile-mp', 'width_m': 0.36, 'height_m': 0.593, 'depth_m': 0.25, 'profile': {'family': 'moving_spot', 'shell': 'faceted', 'lens_ratio': 0.63, 'head_depth': 0.88}, 'source_urls': ['https://www.claypaky.it/products/arolla-profile-mp/', 'https://www.claypaky.it/wp-content/uploads/2022/10/Claypaky_Arolla_Profile_MP.jpg']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
