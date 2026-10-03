#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'vari-lite/vl2600-spot', 'width_m': 0.464, 'height_m': 0.715, 'depth_m': 0.3, 'profile': {'family': 'moving_spot', 'shell': 'faceted', 'lens_ratio': 0.68, 'head_depth': 0.84}, 'source_urls': ['https://www.vari-lite.com/global/products/vl2600-spot', 'https://www.vari-lite.com/b-dam/vari-lite/products/vl2600-wash/guides-and-manuals/vl2600-series_user-manual.pdf', 'https://www.vari-lite.com/b-dam/vari-lite/products/vl2600-spot/vl2600-spot-thumbnail.jpg']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
