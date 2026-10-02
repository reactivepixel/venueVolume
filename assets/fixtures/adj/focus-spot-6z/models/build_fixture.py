#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/catalog_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'adj/focus-spot-6z', 'width_m': 0.234, 'height_m': 0.562, 'depth_m': 0.36, 'profile': {'family': 'moving_spot', 'lens_count': 1, 'body_style': 'compact LED spot mover with dual gobo/color wheels, prisms and yoke', 'notes': 'The single optical axis remains one moving spot despite rich beam shaping.', 'generator': 'catalog', 'shell': 'faceted', 'head_depth': 1.55, 'lens_ratio': 0.62, 'yoke_compression': 0.23}, 'source_urls': ['https://www.adj.com/products/focus-spot-6z', 'https://www.adj.com/cdn/shop/files/95ee89cff1e445d51cb614ec245ed52d33baaae6_FOCUS_SPOT_6Z_red_RT.jpg?v=1778306534&width=2048', 'https://www.adj.com/cdn/shop/files/95ee89cff1e445d51cb614ec245ed52d33baaae6_FOCUS_SPOT_6Z_red_RT.jpg?v=1778306534&width=2048']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
