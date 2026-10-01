#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'chauvet-professional/colorado-solo-batten', 'width_m': 1.0125, 'height_m': 0.2498, 'depth_m': 0.23, 'profile': {'family': 'batten', 'lens_count': 12, 'diffuser': True}, 'source_urls': ['https://chauvetprofessional.com/product/colorado-solo-batten/', 'https://chauvetprofessional.com/wp-content/uploads/2025/10/COLORADO-SOLO-BATTEN-FRONT-FEAT.png']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
