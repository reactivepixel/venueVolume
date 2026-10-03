#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/equipment_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'enttec/ode-mk3', 'width_m': 0.1288, 'height_m': 0.04, 'depth_m': 0.058, 'profile': {'family': 'node', 'body_style': 'compact rectangular network gateway with DMX connectors on one end and Ethernet/DC connections opposite', 'notes': 'Dimensions cross-checked against drawing 70407-ODE MK3; drawing labels overall 128.8, 58, and 40 mm. A 25 mm body-height detail is also drawn; retain 40 mm overall envelope for the connectors/features shown in the manufacturer overall dimensions. No fictional DMX channel personality applies.', 'generator': 'equipment', 'output_kind': 'none'}, 'source_urls': ['https://www.enttec.com/product/dmx-ethernet/ode-mk3-dmx-ethernet-converter/', 'https://cdn.enttec.com/pdf/assets/70407/70407_ODE_MK3_DATASHEET.pdf', 'https://cdn.enttec.com/cad/70407/70407_ODE_MK3_CAD.pdf', 'https://cdn.enttec.com/website/products/70407-ode-mk3/70407-ode-mk3-render-00.png']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
