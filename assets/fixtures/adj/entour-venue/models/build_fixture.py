#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/effects_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'adj/entour-venue', 'width_m': 0.394, 'height_m': 0.253, 'depth_m': 0.434, 'profile': {'family': 'hazer', 'body_style': 'portable rectangular all-metal faze machine with top handle, fluid window and adjustable nozzle', 'notes': 'External anti-spill fluid tank is a separate dependency; do not model it as an internal compartment.', 'generator': 'effects', 'enclosure': 'venue_hazer', 'manual_equipment_tilt': True, 'output_kind': 'haze'}, 'source_urls': ['https://www.adj.com/products/entour-venue', 'https://www.adj.com/cdn/shop/files/8240dffd98db7012ef4f30d6239ba76cd5f16666_ENT610__IMG__001__e3470b1106c0.jpg?v=1776712354&width=850']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
