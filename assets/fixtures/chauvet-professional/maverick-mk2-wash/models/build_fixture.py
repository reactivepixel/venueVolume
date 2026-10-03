#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'chauvet-professional/maverick-mk2-wash', 'width_m': 0.233, 'height_m': 0.471, 'depth_m': 0.323, 'profile': {'family': 'moving_wash', 'lens_count': 12, 'shell': 'round'}, 'source_urls': ['https://chauvetprofessional.com/product/maverick-mk2-wash/', 'https://chauvetprofessional.com/wp-content/uploads/2025/10/MAVERICK-MK2-WASH-FRONT-FEAT.png']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
