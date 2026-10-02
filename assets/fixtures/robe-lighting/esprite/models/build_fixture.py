#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/catalog_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'robe-lighting/esprite', 'width_m': 0.443, 'height_m': 0.733, 'depth_m': 0.264, 'profile': {'family': 'moving_spot', 'lens_count': 1, 'body_style': 'white-source moving head', 'notes': 'Product page exposes dimensions and image asset; profile-like moving-head geometry maps to moving_spot, not static profile.', 'generator': 'catalog', 'shell': 'faceted', 'head_depth': 1.25, 'yoke_compression': 0.2}, 'source_urls': ['https://www.robe.cz/esprite', 'https://cdn.aws.robe.cz/v1/image/resize/e2bc84495f13fc1251b5151cbc3313c6145b2d23']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
