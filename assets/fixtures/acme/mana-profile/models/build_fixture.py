#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'acme/mana-profile', 'width_m': 0.38, 'height_m': 0.658, 'depth_m': 0.284, 'profile': {'family': 'moving_spot', 'shell': 'faceted', 'lens_ratio': 0.54, 'head_depth': 0.76, 'notes': 'Weather-sealed LED framing profile with internal shutters and rotating optical effects.'}, 'source_urls': ['https://en.acmelighting.com/item/MANA-PROFILE', 'https://en.acmelighting.com/upload/other/20260722/aea9031a33652685164a03651b20b64d.pdf', 'https://en.acmelighting.com/upload/image/20250109/f418501fcbdf3338a8a1164670990feb.png']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
