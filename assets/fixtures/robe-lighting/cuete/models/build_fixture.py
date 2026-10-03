#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/catalog_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'robe-lighting/cuete', 'width_m': 0.343, 'height_m': 0.51, 'depth_m': 0.22, 'profile': {'family': 'moving_spot', 'lens_count': 1, 'body_style': 'compact profile moving head', 'notes': 'Use moving_spot family for articulated profile heads; source shows compact housing.', 'generator': 'catalog', 'shell': 'faceted', 'head_depth': 1.15, 'yoke_compression': 0.2}, 'source_urls': ['https://www.robe.cz/cuete', 'https://cdn.aws.robe.cz/v1/image/resize/30cea14efb6f539abb3d297a63aa28ad574d10c4']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
