#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/catalog_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'ayrton/bora-tc', 'width_m': 0.494, 'height_m': 0.737, 'depth_m': 0.28, 'profile': {'family': 'moving_wash', 'lens_count': 1, 'body_style': 'large spherical-lens high-CRI wash with framing shutters', 'notes': 'Official product code 010650 identifies Bora TC.', 'generator': 'catalog', 'shell': 'faceted', 'head_depth': 1.1, 'yoke_compression': 0.18}, 'source_urls': ['https://www.ayrton.eu/produit/bora/', 'https://www.ayrton.eu/wp-content/uploads/2015/02/Product-Bora-01-Produit.png']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
