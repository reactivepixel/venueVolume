#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/equipment_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'georgia-stage/prestige-velour-border-curtain-black-sku-7676', 'width_m': 11.43, 'height_m': 0.9398, 'depth_m': 0.005, 'profile': {'family': 'drape', 'body_style': 'wide black velour border with vertical soft folds and sewn top edge', 'notes': 'Exact stock closeout SKU 7676; full width is listed finished span. Thickness and fold amplitude are visualization estimates, not documented fabric dimensions.', 'generator': 'equipment', 'output_kind': 'none'}, 'source_urls': ['https://gastage.com/sale-stage-curtain-valances-and-borders/988-prestige-velour-border-curtain-3-1-x-37-6-black-7676.html', 'https://gastage.com/3512-large_default/prestige-velour-border-curtain-3-1-x-37-6-black-7676.jpg']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
