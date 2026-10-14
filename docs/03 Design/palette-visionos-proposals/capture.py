from pathlib import Path
import subprocess
import time
import sys

root = Path(__file__).resolve().parent
sim = '37FB51A4-DFF5-40C0-BFE1-32F8AA69EE4F'
for number, name in [(11,'native-composer'),(12,'spatial-console'),(13,'preview-stage'),(14,'step-studio'),(15,'light-score')]:
    if sys.argv[1:] and str(number) not in sys.argv[1:]:
        continue
    subprocess.run(['xcrun','simctl','launch','--terminate-running-process',sim,'com.venuevolume.PaletteProposals','--proposal',str(number)],check=True)
    time.sleep(4)
    subprocess.run(['xcrun','simctl','io',sim,'screenshot',str(root/'Captures'/f'{number}-{name}-full.png')],check=True)
    subprocess.run(['sips','--cropToHeightWidth','1450','1960','--cropOffset','565','945',str(root/'Captures'/f'{number}-{name}-full.png'),'--out',str(root/f'{number}-{name}.png')],check=True)
