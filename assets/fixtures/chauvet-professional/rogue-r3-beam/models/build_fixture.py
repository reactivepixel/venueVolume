#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'chauvet-professional/rogue-r3-beam', 'width_m': 0.325, 'height_m': 0.55, 'depth_m': 0.22, 'profile': {'family': 'moving_spot', 'shell': 'faceted', 'lens_ratio': 0.72, 'head_depth': 0.8, 'notes': 'Discharge beam fixture with compact front aperture and long optical barrel.'}, 'source_urls': ['https://chauvetprofessional.com/product/rogue-r3-beam/', 'https://chauvetprofessional.com/wp-content/uploads/2025/10/ROGUE_R3_BEAM-FRONT-FEAT.png']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
