#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'chauvet-professional/colordash-batten-quad-6', 'width_m': 0.56, 'height_m': 0.164, 'depth_m': 0.065, 'profile': {'family': 'batten', 'lens_count': 6}, 'source_urls': ['https://chauvetprofessional.com/product/colordash-batten-quad-6/', 'https://chauvetprofessional.com/wp-content/uploads/2025/10/COLORdash-Batten-Quad-6-FRONT-FEAT.png']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
