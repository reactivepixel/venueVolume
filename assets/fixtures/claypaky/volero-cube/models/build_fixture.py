#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/catalog_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'claypaky/volero-cube', 'width_m': 0.245, 'height_m': 0.476, 'depth_m': 0.338, 'profile': {'family': 'moving_wash', 'lens_count': 4, 'body_style': 'compact square multi-optic head with crossing strobe strips', 'notes': 'Nonstandard square optics and crossed strip effects require geometry flags beyond current circular-head defaults; preserve explicit limitation.', 'generator': 'catalog', 'square_optics': True, 'head_depth': 0.65}, 'source_urls': ['https://www.claypaky.it/products/volero-cube/', 'https://www.claypaky.it/wp-content/uploads/2025/06/Claypaky_VoleroCube_featured.jpg']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
