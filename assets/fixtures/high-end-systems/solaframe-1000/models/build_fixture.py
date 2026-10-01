#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'high-end-systems/solaframe-1000', 'width_m': 0.46, 'height_m': 0.726, 'depth_m': 0.324, 'profile': {'family': 'moving_spot', 'lens_count': 1, 'body_style': 'moving framing profile with yoke', 'notes': 'Fixture variant available with different LED engine options; not a geometry variant.'}, 'source_urls': ['https://www.etcconnect.com/Products/Legacy/Live-Events-High-End-Systems/Lighting-Fixtures/SolaFrame/1000/Documentation.aspx', 'https://www.etcconnect.com/WorkArea/DownloadAsset.aspx?id=10737503529', 'https://www.etcconnect.com/WorkArea/DownloadAsset.aspx?id=10737504840', 'https://shop.etcconnect.com/solaframe-1000-black-molded-insert/', 'https://cdn11.bigcommerce.com/s-cr8amw/images/stencil/1280x1280/products/781/2244/SolaFrame_1000_prod_right_1__26691.1680192507.png?c=2']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
