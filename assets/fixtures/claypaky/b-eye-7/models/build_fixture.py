#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'claypaky/b-eye-7', 'width_m': 0.35, 'height_m': 0.4609, 'depth_m': 0.2048, 'profile': {'family': 'moving_wash', 'lens_count': 7, 'body_style': 'compact seven optic wash head', 'notes': 'Endless pan and tilt behavior is unusual; document axis mechanism separately.'}, 'source_urls': ['https://www.claypaky.it/products/b-eye-7/', 'https://www.claypaky.it/wp-content/uploads/2026/08/Claypaky_B-Eye7_featured.jpg']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
