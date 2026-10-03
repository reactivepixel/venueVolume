#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/equipment_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'etc/colorsource-20', 'width_m': 0.465, 'height_m': 0.06, 'depth_m': 0.279, 'profile': {'family': 'console', 'body_style': 'low tabletop console with 20 faders and central touchscreen', 'notes': 'Official product image shows both CS20 and CS40; use the smaller upper CS20 image. Dimensions are typical values from ColorSource Console Spec Sheet rev G; exact physical drawing DWG retained but not parsed in this pass.', 'generator': 'equipment', 'output_kind': 'none'}, 'source_urls': ['https://www.etcconnect.com/products/consoles/colorsource/features.aspx', 'https://www.etcconnect.com/about/drawing-library/consoles/colorsource.aspx', 'https://goknight.com/content/documentation/ColorSource_Console_Spec_Sheet_revG.pdf', 'https://www.etcconnect.com/uploadedImages/Main_Site/Images/Products/ColorSource/CS20_CS40.png']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
