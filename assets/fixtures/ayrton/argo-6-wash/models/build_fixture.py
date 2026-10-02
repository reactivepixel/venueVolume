#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'ayrton/argo-6-wash', 'width_m': 0.436, 'height_m': 0.536, 'depth_m': 0.28, 'profile': {'family': 'moving_wash', 'lens_count': 19, 'body_style': 'compact 19-emitter RGBW wash head with 280 mm cluster', 'notes': '19 discrete truncated lenses and glass light guides; independent pixel effects; unlimited pan/tilt.'}, 'source_urls': ['https://www.ayrton.eu/produit/argo-6-wash/', 'https://www.ayrton.eu/wp-content/uploads/2023/04/Argo-6-WASH-V103-DMX.pdf', 'https://www.ayrton.eu/wp-content/uploads/2023/04/Argo6FX-2-1.jpg']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
