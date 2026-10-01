#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'elation-professional/sixbar-500', 'width_m': 0.45, 'height_m': 0.155, 'depth_m': 0.2064, 'profile': {'family': 'batten', 'lens_count': 6, 'body_style': 'compact linear die-cast bar with six independent LED cells, dual integrated rigging brackets and glare shield', 'notes': 'Legacy product; stated overall width includes the supplied glare shield.'}, 'source_urls': ['https://www.elationlighting.com/products/sixbar-500', 'https://www.elationlighting.com/cdn/shop/files/d48723d2ee9c88af30a9f643cdbfa40fac578a7b_SIX074__IMG__002__d682ef9e3d1d.jpg?v=1773210028&width=1800']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
