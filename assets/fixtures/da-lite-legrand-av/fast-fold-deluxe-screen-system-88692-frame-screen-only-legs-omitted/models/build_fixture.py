#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/equipment_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'da-lite-legrand-av/fast-fold-deluxe-screen-system-88692-frame-screen-only-legs-omitted', 'width_m': 3.048, 'height_m': 1.7526, 'depth_m': 0.03175, 'profile': {'family': 'screen', 'body_style': 'rectangular vertical screen surface in folding aluminum frame on deployed T-legs', 'notes': 'Model the screen/frame from exact overall/viewing dimensions. Foot/stand geometry is family-view-derived and should be treated as approximate; do not include carrying case.', 'generator': 'equipment', 'output_kind': 'none'}, 'source_urls': ['https://www.legrandav.com/products/screens/fastfold-portable-screens/fast-fold-deluxe-screen-system/88692', 'https://www.legrandav.com/-/media/images/dalite/product/series/resources/fastfold_deluxe_screen_system/fast-fold-deluxe-spec-data.pdf?sc_lang=en', 'https://www.legrandav.com/-/media/images/dalite/product/series/resources/fastfold_deluxe_screen_system/fast-fold-deluxe-spec-data.pdf?sc_lang=en']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
