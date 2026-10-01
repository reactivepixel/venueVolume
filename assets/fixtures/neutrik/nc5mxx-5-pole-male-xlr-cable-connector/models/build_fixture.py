#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/equipment_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'neutrik/nc5mxx-5-pole-male-xlr-cable-connector', 'width_m': 0.019, 'height_m': 0.019, 'depth_m': 0.0701, 'profile': {'family': 'data_connector', 'body_style': 'circular 5-pin XLR male connector with strain-relief boot', 'notes': 'Use the dimension drawing for outer size and official product image for appearance. Connector only; do not add a cable or claim wiring/termination behavior.', 'generator': 'equipment', 'output_kind': 'none'}, 'source_urls': ['https://www.neutrik.com/en/product/nc5mxx', 'https://www.neutrik.com/media/8230/download/nc5mxx-1.pdf?v=1', 'https://www.neutrik.com/uploads/media/400x/02/322-nc5mxx.jpg?v=1-0']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
