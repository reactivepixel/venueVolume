#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/equipment_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'enttec/d-split', 'width_m': 0.116, 'height_m': 0.052, 'depth_m': 0.087, 'profile': {'family': 'splitter', 'body_style': 'small rounded rectangular isolated splitter with DMX and DC connectors on end face', 'notes': 'Use overall 116 x 87 x 52 mm. Datasheet supplies envelope dimensions but not a dimensioned orthographic drawing; pose is image-inferred.', 'generator': 'equipment', 'output_kind': 'none'}, 'source_urls': ['https://www.enttec.com/es/product/dmx-isolated-splitter-din-rail/d-split-dmx-opto-splitter-isolator/', 'https://cdn.enttec.com/pdf/assets/70574_70578_70579/70574_70578_70579_D-SPLIT_DATASHEET.pdf', 'https://cdn.enttec.com/wp-content/uploads/2021/10/10015010/2024_0003_dsplit_Isometric-Top-view-A-3-pin.png']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
