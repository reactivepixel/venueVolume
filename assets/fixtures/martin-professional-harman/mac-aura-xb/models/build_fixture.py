#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/catalog_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'martin-professional-harman/mac-aura-xb', 'width_m': 0.222, 'height_m': 0.39, 'depth_m': 0.138, 'profile': {'family': 'moving_wash', 'lens_count': 19, 'body_style': 'compact yoke-mounted Aura fixture', 'notes': '19 front wash lenses plus the forward Aura pixel effect; do not model like larger automated MAC Aura moving-head bodies.', 'generator': 'catalog', 'aura': True, 'yoke_compression': 0.25}, 'source_urls': ['https://www.martin.com/en-US/products/mac-aura-xb', 'https://adn.harmanpro.com/productattachment/4821/product_attachment/x_large-c3352fc68c412cf3ff940047dbe67d37.webp']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
