#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/equipment_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'magic-fx/sparxtar-ii', 'width_m': 0.254, 'height_m': 0.254, 'depth_m': 0.226, 'profile': {'family': 'spark', 'notes': 'Cold-spark effect appliance; only its physical product metadata is recorded. Manufacturer listing identifies this exact model as Sparxtar II. No operational or firing details included.', 'body_style': 'compact cuboid black enclosure with front access panel, ventilation, feet and top handling features', 'generator': 'equipment', 'output_kind': 'spark'}, 'source_urls': ['https://magicfx.com/products/sparxtar-ii', 'https://magicfx.com/cdn/shop/files/SPARXTAR_II_VIEW-HERO.jpg?v=1783682020&width=3840']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
