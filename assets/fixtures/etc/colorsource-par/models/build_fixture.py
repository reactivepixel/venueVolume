#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'etc/colorsource-par', 'width_m': 0.203, 'height_m': 0.31, 'depth_m': 0.24, 'profile': {'family': 'par', 'lens_count': 7, 'body_style': 'compact round LED PAR with yoke', 'notes': 'Original ColorSource PAR RGB-L array, black housing; not Deep Blue or Pearl color-array options.'}, 'source_urls': ['https://www.etcconnect.com/Products/Lighting-Fixtures/ColorSource/PAR.aspx', 'https://www.etcconnect.com/Products/Entertainment-Fixtures/ColorSource-PAR/Tech-Specs.aspx', 'https://www.etcconnect.com/uploadedImages/Main_Site/Images/Products/Lighting_Fixtures/ColorSource/en-CS-PAR-Leaderlines-960x300.jpg']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
