#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/equipment_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'magic-fx/co2-jet-ii', 'width_m': 0.232, 'height_m': 0.1245, 'depth_m': 0.196, 'profile': {'family': 'co2_jet', 'notes': 'Genuine liquid-CO2 jet. The official manual distinguishes main product dimensions/weight from larger package dimensions/weight, resolving the conflicting product-page figures. Use the outlet-pipe configuration visible in the exact product photo; do not substitute a removable alternate nozzle or add baseplate/rigging hardware.', 'body_style': 'compact angular black metal box housing with attached short outlet pipe, mounting plate and side connectors', 'generator': 'equipment', 'output_kind': 'co2'}, 'source_urls': ['https://magicfx.com/products/co2jet-ii', 'https://magicfx.com/cdn/shop/files/CO2jet_II_manual.pdf?v=5588412156141481997', 'https://magicfx.com/cdn/shop/files/CO2JETII-01.jpg?v=1773148408&width=3840']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
