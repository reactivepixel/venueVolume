#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'robe-lighting/iforte', 'width_m': 0.48, 'height_m': 0.837, 'depth_m': 0.335, 'profile': {'family': 'moving_spot', 'lens_count': 1, 'body_style': 'large sealed moving profile with yoke', 'notes': 'iFORTE standard IP65 body; not FS, Fresnel, or LTX variant.'}, 'source_urls': ['https://www.robe.cz/iforte', 'https://www.robe.cz/res/downloads/catalogues/ROBE_iFORTE_FS_leaflet_online_version.pdf', 'https://www.robe.cz/res/downloads/user_manuals/User_manual_Robin_iForte_iForte_FS.pdf', 'https://cdn.aws.robe.cz/v1/image/resize/6ee70f896810a7721c20db54b45105162a65661c?fit=cover&height=452&width=452&withoutEnlargement=false']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
