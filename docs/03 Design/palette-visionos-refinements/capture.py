from pathlib import Path
import subprocess, time, sys, json
root = Path(__file__).resolve().parent
all_devices = json.loads(subprocess.check_output(['xcrun','simctl','list','devices','booted','--json']))['devices']
sim = next(d['udid'] for runtime, devices in all_devices.items() if 'visionOS' in runtime or 'xrOS' in runtime for d in devices)
names = ['balanced-split','output-first','library-sidebar','step-drawer','focused-tabs','source-shelf','step-focus','result-and-rhythm','compact-editor','fixture-score']
(root/'Captures').mkdir(exist_ok=True)
for number, name in enumerate(names,16):
    if sys.argv[1:] and str(number) not in sys.argv[1:]: continue
    subprocess.run(['xcrun','simctl','launch','--terminate-running-process',sim,'com.venuevolume.PaletteRefinements','--proposal',str(number)],check=True)
    time.sleep(6)
    subprocess.run(['xcrun','simctl','io',sim,'screenshot',str(root/'Captures'/f'{number}-{name}-full.png')],check=True)
    crop_width, crop_x = (1700, 1070) if number == 24 else (2000, 920)
    subprocess.run(['sips','--cropToHeightWidth','1550',str(crop_width),'--cropOffset','500',str(crop_x),str(root/'Captures'/f'{number}-{name}-full.png'),'--out',str(root/f'{number}-{name}.png')],check=True)
