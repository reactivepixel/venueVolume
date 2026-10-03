#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'etc/desire-d60', 'width_m': 0.309, 'height_m': 0.361, 'depth_m': 0.29, 'profile': {'family': 'par', 'lens_count': 60}, 'source_urls': ['https://www.etcconnect.com/workarea/DownloadAsset.aspx?id=10737512649', 'https://www.etcconnect.com/Products/Lighting-Fixtures/', 'https://www.etcconnect.com/uploadedImages/Main_Site/Images/Products/Lighting_Fixtures/Selador/D60_Lustr_clip.jpg']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
