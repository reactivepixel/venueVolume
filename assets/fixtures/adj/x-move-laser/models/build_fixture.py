#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'adj/x-move-laser', 'width_m': 0.19, 'height_m': 0.285, 'depth_m': 0.205, 'profile': {'family': 'moving_spot', 'lens_count': 1, 'output_kind': 'laser_aperture', 'body_style': 'small yoke-mounted laser projector', 'notes': 'Pan/tilt moving head (manufacturer lists 540° pan / 220° tilt and stepper motors). Retain dark/output-only laser_aperture semantics; do not create ordinary visible spotlight output.', 'category_id': 'lighting.effects.laser', 'shell': 'faceted', 'lens_ratio': 0.45}, 'source_urls': ['https://www.adj.com/products/x-move-laser', 'https://www.adj.com/cdn/shop/files/e7333973f25e0385bc10441d2975406234e62f28_XMOVE_LASER__IMG__001__238d14f3295f.jpg?v=1776715879&width=350']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
