#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'robe-lighting/t1-profile', 'width_m': 0.491, 'height_m': 0.542, 'depth_m': 0.344, 'profile': {'family': 'moving_spot', 'shell': 'faceted', 'lens_ratio': 0.73, 'head_depth': 0.86}, 'source_urls': ['https://www.robe.cz/t1-profile', 'https://cdn.aws.robe.cz/print/en_product_654.pdf', 'https://cdn.aws.robe.cz/v1/image/resize/422fbc138a8a68463837f9885cdfbffbc5076d0a?fit=cover&height=452&width=452&withoutEnlargement=false']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
