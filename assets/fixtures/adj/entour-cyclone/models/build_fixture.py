#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/equipment_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'adj/entour-cyclone', 'width_m': 0.35, 'height_m': 0.422, 'depth_m': 0.131, 'profile': {'family': 'fan', 'notes': 'Buildable DMX fan alternative to unresolved Look-Fan. Product page and manual dimensions are similar; manual diagram resolves front width, height and depth. Product page/manual mass disagree slightly, so mass is recorded with source conflict.', 'body_style': 'compact square axial fan with front/rear grille and dual-purpose scissor/yoke bracket', 'generator': 'equipment', 'output_kind': 'air'}, 'source_urls': ['https://www.adj.com/products/entour-cyclone', 'https://www.adj.com/cdn/shop/files/ADJ_Entour_Cyclone_User_Manual.pdf?v=12488028309515808394', 'https://www.adj.com/cdn/shop/files/ADJ_Entour_Cyclone_User_Manual.pdf?v=12488028309515808394']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
