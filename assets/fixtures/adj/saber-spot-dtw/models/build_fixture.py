#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'adj/saber-spot-dtw', 'width_m': 0.17, 'height_m': 0.087, 'depth_m': 0.088, 'profile': {'family': 'par', 'lens_count': 1, 'body_style': 'compact pinspot housing with ACL lens and scissor bracket', 'notes': 'Small pinspot rather than moving head.', 'floor_yoke': True, 'category_id': 'lighting.static.beam'}, 'source_urls': ['https://www.adj.com/products/saber-spot-dtw', 'https://www.adj.com/blogs/news/adj-saber-spot-dtw-innovative-new-saber-spot-unleashed', 'https://www.adj.com/cdn/shop/files/98f3715e256374fee335f16f73bb79e00a474798_SAB990__IMG__001__7b5b730252c4.jpg?v=1776712483&width=2048']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
