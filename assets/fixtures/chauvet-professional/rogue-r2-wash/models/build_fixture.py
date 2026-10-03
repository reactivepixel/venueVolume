#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'chauvet-professional/rogue-r2-wash', 'width_m': 0.306, 'height_m': 0.398, 'depth_m': 0.218, 'profile': {'family': 'moving_wash', 'lens_count': 19, 'shell': 'round'}, 'source_urls': ['https://chauvetprofessional.com/product/rogue-r2-wash/', 'https://chauvetprofessional.com/wp-content/uploads/2025/10/ROGUE_R2_WASH-FRONT-FEAT.png']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
