#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'etc/fos-4-fresnel', 'width_m': 0.313, 'height_m': 0.435, 'depth_m': 0.505, 'profile': {'family': 'fresnel', 'barn_doors': False}, 'source_urls': ['https://www.etcconnect.com/Products/Entertainment-Fixtures/fos/4-Fresnel/Documentation.aspx', 'https://www.etcconnect.com/Products/Lighting-Fixtures/', 'https://www.etcconnect.com/uploadedImages/Main_Site/Images/Products/Entertainment_Fixtures/fos4_Fresnel_Group_960x350.jpg']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
