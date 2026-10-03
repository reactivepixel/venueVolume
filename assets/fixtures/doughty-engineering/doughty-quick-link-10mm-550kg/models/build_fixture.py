#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/equipment_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'doughty-engineering/doughty-quick-link-10mm-550kg', 'width_m': 0.09, 'height_m': 0.044, 'depth_m': 0.016, 'profile': {'family': 'safety_hardware', 'notes': 'Rigid compact suspension connector, potential visual representative for secondary protection hardware only. Rated values are conflicting source metadata; no operating or rigging directions included. Do not treat product WLL as a selection recommendation.', 'body_style': 'zinc-plated oval steel quick link with threaded closure sleeve', 'generator': 'equipment', 'output_kind': 'none'}, 'source_urls': ['https://doughty-engineering.co.uk/products/quick-link-10mm-550kg/', 'https://doughty-engineering.co.uk/wp-content/uploads/2023/01/T23505-Data-Sheet-US.pdf', 'https://doughty-engineering.co.uk/wp-content/uploads/Product-Images/T23505-Quick-Link-1-700x700-c-default.jpg']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
