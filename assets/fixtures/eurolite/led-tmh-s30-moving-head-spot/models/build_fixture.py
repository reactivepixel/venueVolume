#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'eurolite/led-tmh-s30-moving-head-spot', 'width_m': 0.17, 'height_m': 0.24, 'depth_m': 0.15, 'profile': {'family': 'moving_spot', 'lens_count': 1, 'body_style': 'small LED spot mover with compact yoke and replaceable rotating gobo wheel', 'notes': "Steinigke product page is the EUROLITE brand owner's official store and provides source details, image gallery, DMX profile and dimensions."}, 'source_urls': ['https://www.steinigke.de/mpn51786070-eurolite-led-tmh-s30-moving-head-spot.html', 'https://www.steinigke.de/download/Move-Magazine-2-2020-E_00131465.pdf', 'https://media.steinigke.de/images/7640p/86/51786070a.webp']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
