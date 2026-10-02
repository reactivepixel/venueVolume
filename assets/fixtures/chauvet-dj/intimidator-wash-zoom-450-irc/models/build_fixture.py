#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'chauvet-dj/intimidator-wash-zoom-450-irc', 'width_m': 0.194, 'height_m': 0.363, 'depth_m': 0.277, 'profile': {'family': 'moving_wash', 'lens_count': 12, 'body_style': 'compact moving wash with circular multi-LED aperture', 'notes': 'LED count and RGBW emitters documented.'}, 'source_urls': ['https://www.chauvetdj.com/products/intimidator-wash-zoom-450-irc/', 'https://www.chauvetdj.com/wp-content/uploads/2016/01/cat-Intimidator-Wash-Zoom-450-IRC.jpg']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
