#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'adj/hydro-beam-x1', 'width_m': 0.21, 'height_m': 0.43, 'depth_m': 0.336, 'profile': {'family': 'moving_spot', 'shell': 'round', 'lens_ratio': 0.63, 'head_depth': 0.7}, 'source_urls': ['https://www.adj.com/products/hydro-beam-x1', 'https://www.adj.com/cdn/shop/files/2ca9d5892d774450aa191f321349e6f771ee8f18_HYDRO_BEAM_X1_red_RT.jpg?v=1778306536&width=800']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
