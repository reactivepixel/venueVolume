#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/equipment_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'doughty-engineering/twenty-clamp', 'width_m': 0.101, 'height_m': 0.0615, 'depth_m': 0.028, 'profile': {'family': 'clamp', 'body_style': 'cast hook clamp with threaded M10 fixing interface', 'notes': 'The clamp WLL is not a rigging design approval; system-level loads and compatible attachment hardware require independent review.', 'generator': 'equipment', 'output_kind': 'none'}, 'source_urls': ['https://doughty-usa.com/products/twenty-clamp/', 'https://www.doughty-engineering.co.uk/wp-content/uploads/2023/01/T58400-Data-Sheet.pdf', 'https://doughty-usa.com/wp-content/uploads/2023/01/T58400-New-Twenty-Clamp-700x700-c-default.jpg']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
