#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/equipment_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'altman-lighting/altman-par64-al', 'width_m': 0.279, 'height_m': 0.39, 'depth_m': 0.406, 'profile': {'family': 'par_can', 'body_style': 'round metal PAR64 reflector can with yoke', 'notes': 'Traditional passive can; lamp/reflector choice is separate. Discontinued.', 'generator': 'equipment', 'output_kind': 'light'}, 'source_urls': ['https://www.altmanlighting.com/wp-content/uploads/2019/05/PAR64ALSpecification_disc.pdf', 'https://www.altmanlighting.com/wp-content/uploads/2016/04/PAR56-64.pdf', 'https://www.altmanlighting.com/wp-content/uploads/2016/04/PAR56-64.pdf']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
