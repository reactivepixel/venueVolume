#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'adj/focus-spot-4z', 'width_m': 0.2786, 'height_m': 0.4574, 'depth_m': 0.1815, 'profile': {'family': 'moving_spot', 'shell': 'round', 'lens_ratio': 0.5, 'head_depth': 0.7}, 'source_urls': ['https://www.adj.com/products/focus-spot-4z', 'https://www.adj.com/cdn/shop/files/a74bd932582c95b0204ab23388d7dc7f7fe9e08b_FOC200__IMG__001__3dc23d06cee1.jpg?v=1776751364&width=800']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
