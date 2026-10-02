#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'ayrton/nando-502-wash', 'width_m': 0.342, 'height_m': 0.467, 'depth_m': 0.268, 'profile': {'family': 'moving_wash', 'lens_count': 12, 'body_style': 'compact multi-source optical cluster wash', 'notes': 'Twelve discrete 70 mm truncated lens elements in a 210 mm cluster; use a clustered optic layout rather than one lens.'}, 'source_urls': ['https://www.ayrton.eu/produit/nando-502-wash/', 'https://www.ayrton.eu/wp-content/uploads/2023/04/NANDO-502-WASH-Specification-Sheet-V5.pdf', 'https://www.ayrton.eu/wp-content/uploads/2024/03/Nando-3.png']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
