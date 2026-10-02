#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'jb-lighting/p18-profile-mk2-hp', 'width_m': 0.475, 'height_m': 0.755, 'depth_m': 0.307, 'profile': {'family': 'moving_spot', 'shell': 'faceted', 'lens_ratio': 0.65, 'head_depth': 0.88}, 'source_urls': ['https://www.jb-lighting.de/en/P18Profile', 'https://www.jb-lighting.de/images/products/P18/P18_seitlich_MK2.png']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
