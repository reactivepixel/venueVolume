#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/equipment_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'adj/dp-415r', 'width_m': 0.26, 'height_m': 0.076, 'depth_m': 0.209, 'profile': {'family': 'dimmer', 'body_style': 'compact enclosed pack with reversible hanging bracket and Edison outlets', 'notes': 'Product page identifies selectable dimmer/switch modes and mounting options; electrical power remains distinct from DMX control data.', 'generator': 'equipment', 'output_kind': 'none'}, 'source_urls': ['https://www.adj.com/products/dp-415r', 'https://www.adj.com/blogs/news/adj-dp-415r-a-classic-adj-control-product-gets-an-upgrade', 'https://www.adj.com/cdn/shop/files/11936d54e77e05407d8d2c922efdb285134d609c_DPR415__IMG__001__d6965eb649aa.jpg?v=1776712969&width=2048']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
