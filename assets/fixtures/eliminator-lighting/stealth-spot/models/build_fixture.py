#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'eliminator-lighting/stealth-spot', 'width_m': 0.17, 'height_m': 0.355, 'depth_m': 0.239, 'profile': {'family': 'moving_spot', 'lens_count': 1, 'body_style': 'small LED spot mover with indexed gobo wheel and yoke', 'notes': 'Manufacturer page links cut sheet and user manual.'}, 'source_urls': ['https://www.eliminatorlighting.com/products/stealth-spot', 'https://www.eliminatorlighting.com/cdn/shop/files/e9cc2f1941b7f92d0f54e5119f2fa3af2a1ff5df_STEALTH_SPOT__IMG__001__bdb2c102a9b5.jpg?v=1777055789&width=2048']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
