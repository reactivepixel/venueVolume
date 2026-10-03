#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'chauvet-professional/rogue-rh1-hybrid', 'width_m': 0.327, 'height_m': 0.638, 'depth_m': 0.409, 'profile': {'family': 'moving_spot', 'shell': 'faceted', 'lens_ratio': 0.72, 'head_depth': 0.75}, 'source_urls': ['https://chauvetprofessional.com/product/rogue-rh1-hybrid/', 'https://chauvetprofessional.com/wp-content/uploads/2025/10/Rogue-R1-Hybrid-FRONT-FEAT.png']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
