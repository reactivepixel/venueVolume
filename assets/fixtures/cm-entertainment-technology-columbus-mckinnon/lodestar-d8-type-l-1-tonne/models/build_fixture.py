#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/equipment_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'cm-entertainment-technology-columbus-mckinnon/lodestar-d8-type-l-1-tonne', 'width_m': 0.582, 'height_m': 0.532, 'depth_m': 0.321, 'profile': {'family': 'hoist', 'body_style': 'horizontal oval motor/gear housing with upper suspension hook and lower load hook', 'notes': 'Reference body only; chain and lift height are variable instance/configuration properties, not fixed object geometry. This is an optional engineered-rigging category example, not a certified rigging model.', 'generator': 'equipment', 'output_kind': 'none'}, 'source_urls': ['https://www.cmco.com/globalassets/catalogs--documents/emea/cmco-cm-et-product-catalogue-2022.pdf', 'https://www.cmco.com/globalassets/catalogs--documents/emea/cmco-cm-et-product-catalogue-2022.pdf']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
