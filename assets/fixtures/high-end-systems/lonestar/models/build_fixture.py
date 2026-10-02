#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'high-end-systems/lonestar', 'width_m': 0.368, 'height_m': 0.6, 'depth_m': 0.221, 'profile': {'family': 'moving_spot', 'shell': 'faceted', 'lens_ratio': 0.56, 'head_depth': 0.78, 'notes': 'Compact white-LED framing profile; preserve yoke, pan/tilt base and internal framing module.'}, 'source_urls': ['https://www.etcconnect.com/lonestar/', 'https://www.etcconnect.com/WorkArea/DownloadAsset.aspx?id=10737513380', 'https://www.etcconnect.com/WorkArea/DownloadAsset.aspx?id=10737514372', 'https://www.etcconnect.com/uploadedImages/Main_Site/Images/Products/Live_Events/Lighting_Fixtures/Lonestar/Lonestar_Prod_Left_Red_547x400.jpg']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
