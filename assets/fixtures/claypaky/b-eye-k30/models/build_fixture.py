#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'claypaky/b-eye-k30', 'width_m': 0.43, 'height_m': 0.609, 'depth_m': 0.4, 'profile': {'family': 'moving_wash', 'lens_count': 37, 'body_style': 'large-format RGBL multi-optic wash/effect head', 'notes': '37 individually addressable emitters; bi-directional rotating front lenses, endless pan and 230° tilt/safety brake require nonstandard effect/motion treatment.'}, 'source_urls': ['https://www.claypaky.it/products/b-eye-k30/', 'https://www.claypaky.it/wp-content/uploads/2026/08/Claypaky_B-EyeK30.jpg']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
