#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'elation-professional/fuze-sfx', 'width_m': 0.233, 'height_m': 0.595, 'depth_m': 0.362, 'profile': {'family': 'moving_spot', 'shell': 'faceted', 'lens_ratio': 0.84, 'head_depth': 0.82}, 'source_urls': ['https://www.elationlighting.com/products/fuze-sfx', 'https://www.elationlighting.com/cdn/shop/files/89ae202fa3170c155988939b4acfa394ce85a29f_FUZ406__IMG__002__58ee88d3a569_51e85a0c-274f-454a-b2f6-ac00dc5f19c3.jpg?v=1783577951&width=1200']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
