#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/equipment_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'enttec/pixelator-mini', 'width_m': 0.2, 'height_m': 0.042, 'depth_m': 0.12, 'profile': {'family': 'pixel_controller', 'body_style': 'low black rectangular controller with front-panel display and multiple output connectors', 'notes': 'This distributes pixel data using ENTTEC PLink; PLink injectors and their pixel-power connections are separate equipment.', 'generator': 'equipment', 'output_kind': 'none'}, 'source_urls': ['https://www.enttec.com/product/led-pixel-control/pixelator-mini-lighting-controller-ethernet-to-spi-pixel-converter/', 'https://cdn.enttec.com/pdf/assets/70067/70067_PIXELATOR_MINI_DATASHEET.pdf', 'https://cdn.enttec.com/wp-content/uploads/2022/02/09060535/product_pixelatormini__004.png']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
