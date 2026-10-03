#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'elation-professional/fuze-wash-500', 'width_m': 0.4079, 'height_m': 0.5505, 'depth_m': 0.3895, 'profile': {'family': 'moving_spot', 'shell': 'round', 'lens_ratio': 0.92, 'head_depth': 0.83, 'fresnel': True}, 'source_urls': ['https://www.elationlighting.com/products/fuze-wash-500', 'https://www.elationlighting.com/cdn/shop/files/f261b7f937117cee2f18bcc03abd483d9a2ed232_FUZ567__IMG__005__607642e601ac.jpg?v=1776815760&width=1200']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
