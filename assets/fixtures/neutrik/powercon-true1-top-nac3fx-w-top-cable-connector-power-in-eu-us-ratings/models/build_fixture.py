#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/equipment_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'neutrik/powercon-true1-top-nac3fx-w-top-cable-connector-power-in-eu-us-ratings', 'width_m': 0.032, 'height_m': 0.032, 'depth_m': 0.08, 'profile': {'family': 'power_connector', 'body_style': 'locking female cable connector with molded boot, strain relief and screw-terminal rear section', 'notes': "Exact connector component only; omit cable. Geometric W/H are conservative square maximum envelope around the drawing's 32 mm end-view dimension; the secondary radial dimension is 26.5 mm.", 'generator': 'equipment', 'output_kind': 'none'}, 'source_urls': ['https://www.neutrik.com/en/product/nac3fx-w-top', 'https://www.neutrik.com/media/12872/download/st-nac3fx-w-top.PDF?v=1', 'https://www.neutrik.com/uploads/media/400x/02/12832-NAC3FX-W-TOP.jpg?v=1-0']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
