#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/catalog_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'eurolite/led-kls-120-compact-light-set', 'width_m': 0.616, 'height_m': 0.226, 'depth_m': 0.1, 'profile': {'family': 'batten', 'lens_count': 4, 'body_style': 'four-head RGBW spot bar with central control/mounting crossbar', 'notes': 'Four spots are individually controllable; no derby or laser is part of this model. Manual not transcribed in this pass; product page provides core DMX modes, dimensions and control behavior.', 'generator': 'catalog', 'multi_heads': True, 'spot_bar': True, 'head_mode': 'manual'}, 'source_urls': ['https://www.steinigke.de/mpn42109606-eurolite-led-kls-120-kompakt-lichtset.html', 'https://media.steinigke.de/images/7640p/09/42109606a.webp', 'https://media.steinigke.de/images/7640p/09/42109606a.webp']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
