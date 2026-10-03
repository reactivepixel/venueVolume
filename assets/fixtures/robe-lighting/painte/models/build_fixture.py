#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/catalog_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'robe-lighting/painte', 'width_m': 0.367, 'height_m': 0.619, 'depth_m': 0.219, 'profile': {'family': 'moving_spot', 'lens_count': 1, 'body_style': 'compact moving head', 'notes': 'White-source moving profile/beam; verify product generation and options before model production.', 'generator': 'catalog', 'shell': 'faceted', 'head_depth': 1.2, 'yoke_compression': 0.2}, 'source_urls': ['https://www.robe.cz/painte', 'https://cdn.aws.robe.cz/v1/image/resize/cf5f5663bcc52116c460cd120ec31283ac7c867e']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
