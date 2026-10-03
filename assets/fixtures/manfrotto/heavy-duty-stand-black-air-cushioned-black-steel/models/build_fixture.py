#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/equipment_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'manfrotto/heavy-duty-stand-black-air-cushioned-black-steel', 'width_m': 1.25, 'height_m': 3.33, 'depth_m': 1.25, 'profile': {'family': 'stand', 'body_style': 'three-leg base, telescoping upright risers and leveling leg', 'notes': 'Footprint width/depth is the maximum deployed circle from secondary retail listing; keep that attribution visible and replace with manufacturer drawing evidence if available.', 'generator': 'equipment', 'output_kind': 'none'}, 'source_urls': ['https://www.manfrotto.com/global-uk/black-steel-air-cushioned-heavy-duty-stand-126bsuac/', 'https://www.bhphotovideo.com/c/product/512653-REG/Manfrotto_126BSUAC_126BSUAC_Heavy_Duty_Air.html', 'https://www.manfrotto.com/media/catalog/product/m/a/manfrotto-heavy-duty-stand-air-cushioned-black-steel-126bsuac.jpg']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
