#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'prolights/astra-hybrid330', 'width_m': 0.411, 'height_m': 0.638, 'depth_m': 0.244, 'profile': {'family': 'moving_spot', 'shell': 'faceted', 'lens_ratio': 0.64, 'head_depth': 0.82, 'notes': 'Hybrid optics with large 140 mm front lens; effects package and substantial head depth distinguish the body from a conventional spot.'}, 'source_urls': ['https://prolights.it/en/product/ASTRAHYB330', 'https://www.prolights.it/images/tmp/1200x630ASTRAHYB330_32760.webp?20250103160054']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
