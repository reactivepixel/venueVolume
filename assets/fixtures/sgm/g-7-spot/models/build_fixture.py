#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/catalog_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'sgm/g-7-spot', 'width_m': 0.37, 'height_m': 0.622, 'depth_m': 0.433, 'profile': {'family': 'moving_spot', 'shell': 'faceted', 'lens_count': 1, 'lens_ratio': 0.65, 'head_depth': 1.3, 'generator': 'catalog', 'yoke_compression': 0.35}, 'source_urls': ['https://www.sgmlighting.com/products/architecture/g%C2%B77-spot', 'https://www.sgmlighting.com/files/images/perfion/G7Spot_STD_Discontinued%20Products.png']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
