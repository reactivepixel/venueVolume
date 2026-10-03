#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'cameo/opus-x4', 'width_m': 0.441, 'height_m': 0.83, 'depth_m': 0.312, 'profile': {'family': 'moving_spot', 'shell': 'faceted', 'lens_ratio': 0.65, 'head_depth': 0.82, 'notes': 'Large spot-profile optical head with 182 mm front lens and rotating framing module.'}, 'source_urls': ['https://www.cameolight.com/en/solutions/rental/moving-lights/profile-moving-heads/30735/opus-x4', 'https://cdn-shop.adamhall.com/ORIGINAL/media/MARKEN/CAMEO/CLOX4P/CLOX4P_1.jpg']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
