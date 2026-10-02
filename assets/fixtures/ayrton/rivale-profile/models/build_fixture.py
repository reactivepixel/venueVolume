#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/catalog_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'ayrton/rivale-profile', 'width_m': 0.36, 'height_m': 0.676, 'depth_m': 0.316, 'profile': {'family': 'moving_spot', 'lens_count': 1, 'body_style': 'sealed profile moving head', 'notes': 'Continuous pan and tilt rotation requires nonstandard unlimited-axis support; do not fabricate mechanical stops. Exact digital geometry beyond envelope awaits modeling.', 'generator': 'catalog', 'shell': 'faceted', 'head_depth': 1.1, 'yoke_compression': 0.18}, 'source_urls': ['https://www.ayrton.eu/produit/rivale-profile/', 'https://www.ayrton.eu/wp-content/uploads/2024/04/RivaleProfile-Specification-Sheet.pdf', 'https://www.ayrton.eu/wp-content/uploads/2023/04/ayrton_plus_vignettes_rivalep-819x630.jpg']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
