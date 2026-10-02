#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/catalog_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'ayrton/diablo-profile-s', 'width_m': 0.365, 'height_m': 0.591, 'depth_m': 0.208, 'profile': {'family': 'moving_spot', 'lens_count': 1, 'body_style': 'compact white-source profile moving head', 'notes': 'Exact product code 011340 is Diablo Profile S; profile category is represented by moving_spot family.', 'generator': 'catalog', 'shell': 'faceted', 'head_depth': 1.05, 'yoke_compression': 0.18}, 'source_urls': ['https://www.ayrton.eu/produit/diablo/', 'https://www.ayrton.eu/wp-content/uploads/2018/12/Product-Diablo-02.png']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
