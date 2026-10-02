#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'chauvet-dj/sentinel-wash-q120', 'width_m': 0.219, 'height_m': 0.296, 'depth_m': 0.143, 'profile': {'family': 'moving_wash', 'lens_count': 1, 'body_style': 'miniature RGBW Fresnel wash head with yoke', 'notes': 'New-generation unit; do not conflate with similarly named Sentinel Wash Q7Z ILS.', 'fresnel': True, 'head_depth': 0.75}, 'source_urls': ['https://www.chauvetdj.com/products/sentinel-wash-q120/', 'https://www.chauvetdj.com/wp-content/uploads/pdf/en/sentinel-wash-q120.pdf', 'https://www.chauvetdj.com/wp-content/uploads/2026/04/SENTINEL-WASH-Q120-FRONT-OFF-FEATURE.png']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
