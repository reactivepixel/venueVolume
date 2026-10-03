#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/equipment_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'robert-juliat/lutin-306lpc', 'width_m': 0.3, 'height_m': 0.385, 'depth_m': 0.43, 'profile': {'family': 'pc', 'body_style': 'compact single-lens plano-convex housing, lens door and yoke', 'notes': 'True PC optical type, not an ERS/profile proxy.', 'generator': 'equipment', 'output_kind': 'light'}, 'source_urls': ['https://www.robertjuliat.com/singlelenslum/lutin.html', 'https://www.robertjuliat.com/Product_Specifications/Fiches_EN/Standard/DSEN004_306LPC.pdf', 'https://www.robertjuliat.com/images/produits_pics/LUTIN_c08.png']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
