#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'vari-lite/vl800-eventprofile', 'width_m': 0.375, 'height_m': 0.624, 'depth_m': 0.408, 'profile': {'family': 'moving_spot', 'lens_count': 1, 'body_style': 'compact framing profile on yoke', 'notes': 'Black and white body variants; housing shape otherwise same.'}, 'source_urls': ['https://www.vari-lite.com/global/products/vl800-eventprofile', 'https://vari-lite.s3.eu-west-1.amazonaws.com/datasheets/vl800-eventprofile.pdf', 'https://vari-lite.s3.eu-west-1.amazonaws.com/graphics/product-images/vl800-eventprofile-high-res.jpg']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
