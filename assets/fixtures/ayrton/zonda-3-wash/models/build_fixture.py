#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'ayrton/zonda-3-wash', 'width_m': 0.365, 'height_m': 0.404, 'depth_m': 0.233, 'profile': {'family': 'moving_wash', 'lens_count': 7, 'body_style': 'compact RGBW multi-source moving head with truncated lenses in a 170 mm cluster', 'notes': 'Seven discrete light guides; use 7 emitters rather than one circular optic.'}, 'source_urls': ['https://www.ayrton.eu/produit/zonda-3-wash/', 'https://www.ayrton.eu/wp-content/uploads/2022/12/Zonda-3-Wash-3.png']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
