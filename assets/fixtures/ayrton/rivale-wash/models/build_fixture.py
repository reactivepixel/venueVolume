#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/catalog_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'ayrton/rivale-wash', 'width_m': 0.36, 'height_m': 0.676, 'depth_m': 0.316, 'profile': {'family': 'moving_wash', 'lens_count': 1, 'body_style': 'sealed Fresnel wash moving head', 'notes': "Continuous pan and tilt rotation requires unlimited-axis support; don't fabricate mechanical end stops.", 'generator': 'catalog', 'shell': 'faceted', 'head_depth': 1.05, 'fresnel': True, 'yoke_compression': 0.18}, 'source_urls': ['https://www.ayrton.eu/produit/rivale-wash/', 'https://www.ayrton.eu/wp-content/uploads/2024/06/RivaleW-3.png']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
