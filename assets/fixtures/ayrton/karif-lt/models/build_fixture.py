#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/catalog_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'ayrton/karif-lt', 'width_m': 0.365, 'height_m': 0.622, 'depth_m': 0.212, 'profile': {'family': 'moving_spot', 'lens_count': 1, 'body_style': 'long-throw beam/spot moving head', 'notes': 'Infinite pan rotation is an unsupported axis convention for ordinary finite-pan spot previews; preserve as an unlimited-pan capability.', 'generator': 'catalog', 'shell': 'faceted', 'head_depth': 1.1, 'yoke_compression': 0.18}, 'source_urls': ['https://www.ayrton.eu/produit/karif-lt/', 'https://www.ayrton.eu/wp-content/uploads/2020/03/Product-Karif-03.png']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
