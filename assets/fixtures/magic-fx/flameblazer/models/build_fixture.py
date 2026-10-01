#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/equipment_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'magic-fx/flameblazer', 'width_m': 0.3, 'height_m': 0.28, 'depth_m': 0.41, 'profile': {'family': 'flame', 'notes': 'Physical flame-effect appliance; record contains product geometry and identity only, not operating, firing or channel instructions.', 'body_style': 'rectangular metal effect appliance with side access panels, feet and output/control face', 'generator': 'equipment', 'output_kind': 'flame'}, 'source_urls': ['https://magicfx.com/products/flameblazer', 'https://magicfx.com/cdn/shop/files/FLAMEBLAZER-03_b1e6b1f8-cda1-42e9-a702-83a9c509f9f8.jpg?v=1773150186']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
