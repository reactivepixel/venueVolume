#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'claypaky/volero-wave', 'width_m': 1.0, 'height_m': 0.329, 'depth_m': 0.182, 'profile': {'family': 'batten', 'lens_count': 8, 'body_style': 'linear chassis with eight individually tilting optical heads', 'notes': 'Independent modules tilt 220 degrees; product on demand. Render as a fixed bar with separate head pivots.', 'multi_heads': True}, 'source_urls': ['https://www.claypaky.it/products/volero-wave/', 'https://www.claypaky.it/wp-content/uploads/2022/10/Claypaky_VoleroWave.jpg', 'https://ltb.no/media/multicase/documents/claypaky/datablad_claypaky_volerowave_11.2022.pdf']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
