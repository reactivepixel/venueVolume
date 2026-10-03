#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/equipment_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'roe-visual/black-pearl-bp2v2', 'width_m': 0.5, 'height_m': 0.5, 'depth_m': 0.09, 'profile': {'family': 'led_panel', 'body_style': '500 mm square modular display with 90 mm rear housing', 'notes': 'Optional visual-equipment example. Catalog inclusion should follow user-approved scope; one representative panel does not imply a full LED wall, processor, hanging hardware, or all vendors are included.', 'generator': 'equipment', 'output_kind': 'video_surface'}, 'source_urls': ['https://www.roevisual.com/en/products/black-pearl-2v2', 'https://www.roevisual.com/uploads/files/Product%20File/Black%20Pearl/bp2v2-brochure-en-feb.-3-2024.pdf', 'https://www.roevisual.com/uploads/Images/Products/Black%20Pearl%202%20V2/bp2v2-list1.png']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
