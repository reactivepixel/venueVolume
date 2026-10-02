#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/catalog_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'claypaky/arolla-aqua', 'width_m': 0.325, 'height_m': 0.75, 'depth_m': 0.45, 'profile': {'family': 'moving_spot', 'lens_count': 1, 'body_style': 'weather-rated profile head', 'notes': 'This CL3027 is the standard Marine-shield-free model; MG variant CL3047 is separately identified in official product copy.', 'generator': 'catalog', 'shell': 'faceted', 'head_depth': 1.4, 'yoke_compression': 0.15}, 'source_urls': ['https://www.claypaky.it/products/arolla-aqua/', 'https://www.claypaky.it/wp-content/uploads/2025/06/Claypaky_ArollaAqua.jpg']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
