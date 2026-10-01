#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'vari-lite/vl3600-profile-ip', 'width_m': 0.56, 'height_m': 0.799, 'depth_m': 0.34, 'profile': {'family': 'moving_spot', 'shell': 'faceted', 'lens_ratio': 0.77, 'head_depth': 0.85}, 'source_urls': ['https://www.vari-lite.com/global/products/vl3600-profile-ip', 'https://vari-lite.s3.eu-west-1.amazonaws.com/datasheets/VL3600-PROFILE-IP.pdf', 'https://www.vari-lite.com/b-dam/vari-lite/products/vl3600-profile-ip/vl3600-profile-ip_thumb.jpg']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
