#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/catalog_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'ayrton/eurus-profile-s', 'width_m': 0.445, 'height_m': 0.743, 'depth_m': 0.273, 'profile': {'family': 'moving_spot', 'lens_count': 1, 'body_style': 'large white-source profile moving head', 'notes': 'Official product code 011540 identifies Eurus Profile S.', 'generator': 'catalog', 'shell': 'faceted', 'head_depth': 1.2, 'yoke_compression': 0.18}, 'source_urls': ['https://www.ayrton.eu/produit/eurus/', 'https://www.ayrton.eu/wp-content/uploads/2020/11/Product-Eurus-04.png']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
