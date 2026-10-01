#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/equipment_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'brompton-technology/tessera-sx40', 'width_m': 0.4826, 'height_m': 0.0889, 'depth_m': 0.4064, 'profile': {'family': 'media_server', 'body_style': '2U rackmount video/LED processor with front status display and rear I/O', 'notes': 'An optional visual department example; this is not a fixture or generic DMX node.', 'generator': 'equipment', 'output_kind': 'none'}, 'source_urls': ['https://www.bromptontech.com/product/sx40/', 'https://www.bromptontech.com/wp-content/uploads/2025/07/Brompton-SX40-Data-Sheet-Feb2025-EN.pdf', 'https://www.bromptontech.com/wp-content/uploads/2019/05/SX40_front_elevated_Final-1536x810.png.webp']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
