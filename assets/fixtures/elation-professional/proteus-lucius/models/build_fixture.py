#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'elation-professional/proteus-lucius', 'width_m': 0.37, 'height_m': 0.682, 'depth_m': 0.468, 'profile': {'family': 'moving_spot', 'shell': 'faceted', 'lens_ratio': 0.58, 'head_depth': 0.85, 'notes': 'Weather-sealed profile with internal framing.'}, 'source_urls': ['https://www.elationlighting.com/products/proteus-lucius', 'https://assets.centryngroup.com/dl/files/PRL546__DL__006.pdf', 'https://assets.centryngroup.com/dl/files/PRL546__DL__008.pdf', 'https://www.elationlighting.com/cdn/shop/files/e852a97433e35b21e3ea37860247754dbf5e272c_PRL546__IMG__001__e7dc0c89c4f6.jpg?v=1776815027&width=2048']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
