#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/catalog_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'astera/ax5-triplepar', 'width_m': 0.1936, 'height_m': 0.2135, 'depth_m': 0.1481, 'profile': {'family': 'par', 'shell': 'round', 'lens_count': 3, 'notes': 'Compact three-emitter battery PAR with yoke/bracket; body-only and bracketed envelopes differ.', 'generator': 'catalog', 'floor_yoke': True, 'reflector_cups': 3}, 'source_urls': ['https://astera-led.com/fr/products/ax5-triplepar/specs/', 'https://astera-led.com/wp-content/uploads/Datasheet_AX5_TriplePar_V4.pdf', 'https://astera-led.com/wp-content/uploads/AX5_TriplePAR_Manual_EN_DE_IT_ES_FR_CN.pdf', 'https://media.astera-led.com/wp-content/uploads/AX5_TriplePAR_V1.png']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
