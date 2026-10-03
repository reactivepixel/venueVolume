#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/equipment_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'global-truss/gt-stage-adjust-1-x-2-m', 'width_m': 2.0, 'height_m': 0.9779, 'depth_m': 1.0, 'profile': {'family': 'deck', 'body_style': 'rectangular modular deck with four adjustable supports', 'notes': 'Height selection reflects maximum setting on current product page; catalog PDF has a slight height-range discrepancy, so verify the exact selected leg configuration before precision modeling. Not a rigging/load-plan model.', 'generator': 'equipment', 'output_kind': 'none'}, 'source_urls': ['https://www.globaltruss.com/gt-stage-adjust', 'https://www.globaltruss.com/pub/media/globaltrdownloads/downloads/g/t/gta_catalog_feb_2019_online-compressed.pdf', 'https://www.globaltruss.com/media/catalog/product/cache/6517c62f5899ad6aa0ba23ceb3eeff97/1/0/1000x1000-20gt-20stage-201x2-41237.jpg']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
