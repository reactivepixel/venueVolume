#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/equipment_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'antari/s-500-snow-machine', 'width_m': 0.551, 'height_m': 0.651, 'depth_m': 0.592, 'profile': {'family': 'snow', 'notes': 'Professional snow machine with case and hose; dimensions/mass refer to S-500, not S-500L. Nominal dimensions are treated as the closed road-case envelope (estimated pose); open-lid product photo does not depict that envelope pose.', 'body_style': 'large black wheeled road case for the snow machine; use closed case geometry for nominal transport envelope', 'generator': 'equipment', 'output_kind': 'snow'}, 'source_urls': ['https://antari.com/products/s-500/', 'https://antari.com/wp-content/uploads/S-500_main-1000x1000-1.jpg']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
