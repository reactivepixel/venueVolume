#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'vari-lite/vl10-beamwash', 'width_m': 0.704, 'height_m': 0.501, 'depth_m': 0.32, 'profile': {'family': 'moving_spot', 'lens_count': 1, 'body_style': 'hybrid beam/wash effect head with 180 mm lens', 'notes': 'Uses a discharge lamp and layered optical effects; source-driven outer silhouette still requires model construction and image review.'}, 'source_urls': ['https://www.vari-lite.com/global/products/vl10-beamwash', 'https://www.vari-lite.com/b-dam/vari-lite/products/vl10-beamwash/guides-and-manuals/VariLite_VL10_BeamWash_UserManual.pd-revised.pdf-%28final%29.pdf', 'https://www.vari-lite.com/b-dam/vari-lite/products/vl10-beamwash/VLS_PRODUCTS_VL10FRONT_700x410px.jpg']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
