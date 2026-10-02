#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'robe-lighting/tetra1', 'width_m': 0.508, 'height_m': 0.279, 'depth_m': 0.192, 'profile': {'family': 'batten', 'lens_count': 9, 'tilting': True, 'body_style': 'linear multisource moving luminaire', 'notes': 'Nine discrete RGBW emitters on a single tilting linear bar; 191° tilt from official specification.'}, 'source_urls': ['https://www.robe.cz/tetra1', 'https://www.robe.cz/res/downloads/catalogues/ROBE_Product_Guide_2021.pdf', 'https://cdn.aws.robe.cz/v1/image/resize/0d779a8285c7afd295ab8119df8a6b6b0062a4cc']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
