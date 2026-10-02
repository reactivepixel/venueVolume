#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/catalog_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'chroma-q/color-force-3-72', 'width_m': 1.785, 'height_m': 0.215, 'depth_m': 0.18, 'profile': {'family': 'batten', 'generator': 'catalog', 'lens_count': 24, 'diffuser': True, 'sparkle_pixels': 48, 'manual_tilt': True}, 'source_urls': ['https://chroma-q.com/products/color-force-3-72', 'https://chroma-q.com/media/cache/app_top_hero/1b/63/541e6aee1d2fc564aed8e47ae239.jpeg']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
