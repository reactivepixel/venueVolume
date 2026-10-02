#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'elation-professional/proteus-maximus', 'width_m': 0.591, 'height_m': 0.828, 'depth_m': 0.458, 'profile': {'family': 'moving_spot', 'shell': 'faceted', 'lens_ratio': 0.55, 'head_depth': 0.86, 'notes': 'Large weather-sealed framing profile with 180 mm front aperture.'}, 'source_urls': ['https://www.elationlighting.com/products/proteus-maximus', 'https://www.elationlighting.com/media/certipro/articles/p/r/proteus_series-2022.pdf', 'https://www.elationlighting.com/cdn/shop/files/c0cfdc6e8c4020e8d6a8c32b1ba9d9a93bcaa229_PRM992__IMG__002__7152aceb057b.jpg?v=1776815619&width=2048']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
