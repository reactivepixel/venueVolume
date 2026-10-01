#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/equipment_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'antari/m-9-jet-fog-machine', 'width_m': 0.321, 'height_m': 0.42, 'depth_m': 0.393, 'profile': {'family': 'jet', 'notes': 'Produces a forceful heated fog plume with integrated LEDs. Antari markets it as a CO2-style visual effect, but its documented consumable is FLC fog fluid; it is not a real CO2 jet.', 'body_style': 'large faceted black fog machine with top emitter tray containing 27 multicolor LED modules, carry handles and base feet', 'generator': 'equipment', 'output_kind': 'fog_jet'}, 'source_urls': ['https://antari.com/products/m-9/', 'https://antari.com/wp-content/uploads/M-9_01.jpg']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
