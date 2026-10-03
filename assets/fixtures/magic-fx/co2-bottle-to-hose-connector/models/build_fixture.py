#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/equipment_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'magic-fx/co2-bottle-to-hose-connector', 'width_m': 0.03, 'height_m': 0.03, 'depth_m': 0.15, 'profile': {'family': 'co2_supply', 'notes': 'Exact MFX1103 cylinder-to-hose fitting. Product page does not specify regional cylinder thread; region-specific fit remains unknown and must not be inferred from its quick connector alone.', 'body_style': 'short metal high-pressure bottle coupling with knurled connector end and tether cap', 'generator': 'equipment', 'output_kind': 'none'}, 'source_urls': ['https://magicfx.com/products/co2-bottle-to-hose-connector', 'https://magicfx.com/cdn/shop/files/CO2Bottletohoseconnector.jpg?v=1773324576&width=3840']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
