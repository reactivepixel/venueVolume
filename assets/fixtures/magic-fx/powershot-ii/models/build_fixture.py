#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/equipment_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'magic-fx/powershot-ii', 'width_m': 0.127, 'height_m': 0.19, 'depth_m': 0.09, 'profile': {'family': 'confetti', 'notes': 'Launcher is a reusable electrical shot appliance; disposable electric cannons/consumables are separate products.', 'body_style': 'small black box-shaped powered shot unit with top-facing cannon socket, angle indicator and mounting clamps', 'generator': 'equipment', 'output_kind': 'confetti'}, 'source_urls': ['https://magicfx.com/products/powershot-ii', 'https://magicfx.com/cdn/shop/files/Powershot_II_manual.pdf?v=2824067315526127119', 'https://magicfx.com/cdn/shop/files/POWERSHOTII_66533f85-fbf1-4057-ae70-44f6163f6649.jpg?v=1774941991&width=3840']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
