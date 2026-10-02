#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'showtec/phantom-65', 'width_m': 0.23, 'height_m': 0.365, 'depth_m': 0.2, 'profile': {'family': 'moving_spot', 'lens_count': 1, 'body_style': 'compact LED spot head with yoke', 'notes': 'Manufacturer documentation is Highlite manual; product identity is Showtec Phantom 65, order code 40070.'}, 'source_urls': ['https://www.highlite.com/media/attachments/MANUAL/40070_MANUAL_GB_V1.pdf', 'https://www.showtec-lights.com/media/catalog/product/cache/87bb4254b6bb8fe881d0a120867e629d/4/0/40070_43.png']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
