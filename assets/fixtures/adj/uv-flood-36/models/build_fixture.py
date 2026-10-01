#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/equipment_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'adj/uv-flood-36', 'width_m': 0.3, 'height_m': 0.235, 'depth_m': 0.115, 'profile': {'family': 'uv', 'body_style': 'low-profile rectangular blacklight with 12 LED apertures', 'notes': 'Dedicated UV product; pose transform is image-based estimate; no safety claims inferred.', 'generator': 'equipment', 'output_kind': 'light'}, 'source_urls': ['https://www.adj.com/products/uv-flood-36', 'https://www.adj.com/cdn/shop/files/be63d603fe6a6291fae6243a8d0c98e86819e9bf_UVF021__IMG__001__b2c36e475ed4.jpg?v=1774475468&width=2048']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
