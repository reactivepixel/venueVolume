#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/catalog_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'sgm/g-4-wash', 'width_m': 0.255, 'height_m': 0.465, 'depth_m': 0.219, 'profile': {'family': 'moving_wash', 'shell': 'faceted', 'lens_count': 1, 'fresnel': True, 'head_depth': 1.15, 'generator': 'catalog', 'yoke_compression': 0.35}, 'source_urls': ['https://www.sgmlighting.com/products/g%C2%B74-wash', 'https://www.sgmlighting.com/files/images/perfion/G4%20Wash_STD-Discontinued%20Products.png']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
