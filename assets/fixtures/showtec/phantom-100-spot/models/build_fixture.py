#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/catalog_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'showtec/phantom-100-spot', 'width_m': 0.325, 'height_m': 0.42, 'depth_m': 0.21, 'profile': {'family': 'moving_spot', 'lens_count': 1, 'body_style': 'compact 100 W LED spot moving head with yoke', 'notes': 'Official model page links current product manual and provides source-backed assembled envelope.', 'generator': 'catalog', 'shell': 'faceted', 'head_depth': 1.45, 'lens_ratio': 0.48, 'yoke_compression': 0.23}, 'source_urls': ['https://www.showtec-lights.com/en/40077-phantom-100-spot.html', 'https://www.highlite.com/media/attachments/MANUAL/40077_MANUAL_GB_V2.pdf', 'https://www.showtec-lights.com/media/catalog/product/cache/cf45802cd465083d13f645e2a66e0ee8/4/0/40077_40.png']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
