#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'vari-lite/vl2600-se-wash', 'width_m': 0.464, 'height_m': 0.705, 'depth_m': 0.3, 'profile': {'family': 'moving_wash', 'lens_count': 1, 'body_style': 'mid-size wash head with yoke and automated barn doors', 'notes': 'Do not substitute dimensions of legacy VL2600 Wash for the SE version.'}, 'source_urls': ['https://www.vari-lite.com/global/products/vl2600-wash', 'https://vari-lite.s3.eu-west-1.amazonaws.com/datasheets/vl2600-se-wash.pdf', 'https://www.vari-lite.com/b-dam/vari-lite/products/vl2600-wash/images/vl2600-se-wash-thumbnail.jpg']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
