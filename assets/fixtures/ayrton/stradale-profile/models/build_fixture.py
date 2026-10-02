#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/catalog_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'ayrton/stradale-profile', 'width_m': 0.339, 'height_m': 0.593, 'depth_m': 0.298, 'profile': {'family': 'moving_spot', 'lens_count': 1, 'body_style': 'compact sealed profile moving head', 'notes': 'Continuous pan and tilt rotation; do not invent mechanical stops. Moving profile uses moving_spot family.', 'generator': 'catalog', 'shell': 'faceted', 'head_depth': 1.1, 'yoke_compression': 0.18}, 'source_urls': ['https://www.ayrton.eu/produit/stradale-profile/', 'https://www.ayrton.eu/wp-content/uploads/2025/03/StradaleP.png']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
