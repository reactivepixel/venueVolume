#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'high-end-systems/lonestar-prime', 'width_m': 0.35, 'height_m': 0.584, 'depth_m': 0.23, 'profile': {'family': 'moving_spot', 'shell': 'faceted', 'lens_ratio': 0.6, 'head_depth': 0.86, 'notes': 'Compact automated profile with four-plane framing module and full-curtain shutters.'}, 'source_urls': ['https://www.etcconnect.com/Lonestar-Prime/', 'https://www.etcconnect.com/WorkArea/DownloadAsset.aspx?id=10737520529', 'https://www.etcconnect.com/uploadedImages/Main_Site/Images/Products/Live_Events/Lighting_Fixtures/Lonestar_Prime/LonestarPrime_547x400.jpg']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
