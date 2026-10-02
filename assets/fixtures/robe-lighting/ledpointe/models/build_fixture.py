#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/catalog_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'robe-lighting/ledpointe', 'width_m': 0.363, 'height_m': 0.667, 'depth_m': 0.24, 'profile': {'family': 'moving_spot', 'lens_count': 1, 'body_style': 'compact multi-purpose moving head with 155 mm front lens', 'notes': 'Moving-head profile/beam hybrid; exact front and barrel silhouette should follow image references.', 'generator': 'catalog', 'shell': 'faceted', 'head_depth': 1.3, 'yoke_compression': 0.2}, 'source_urls': ['https://www.robe.cz/ledpointe', 'https://cdn.aws.robe.cz/v1/image/resize/de81a3be704d0b859c06149498f5d3b2d357d1cd']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
