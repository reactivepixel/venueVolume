#!/usr/bin/env python3
"""Build the reference BOM, logical connectivity, SVG sheets and printable PDF.

Requires reportlab and pypdf for PDF generation. This is documentation
tooling, not ECAD, circuit simulation, firmware or a manufacturing file exporter.
"""
from __future__ import annotations

import argparse
import collections
import html
import json
import math
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent
REPO = ROOT.parents[1]
OUT = REPO / 'output' / 'pdf'
PARTS: list[dict] = []


def part(ref, value, package, pins, category='carrier', mpn=None, note=''):
    p = dict(ref=ref, value=value, package=package, pins=pins,
             category=category, mpn=mpn or 'Specification controlled', note=note)
    PARTS.append(p)
    return p


def resistor(ref, value, a, b, package='0603', note=''):
    return part(ref, value, package, {'1': a, '2': b}, note=note)


def capacitor(ref, value, a, b, package='0603', note=''):
    return part(ref, value, package, {'1': a, '2': b}, note=note)


def design():
    PARTS.clear()
    mcu = {'VIN': '+5V_SYS', 'GND_L': 'GND_LOGIC', 'GND_R1': 'GND_LOGIC',
           'GND_R2': 'GND_LOGIC', '3V3_L': '+3V3_MCU', '3V3_R': '+3V3_MCU'}
    assignments = {1:'DMXA_TX', 8:'DMXB_TX', 2:'DMXA_REQ', 3:'DMXB_REQ',
                   4:'ARM_SENSE', 5:'BTN_GO', 6:'BTN_HOLD', 7:'BTN_BACK',
                   9:'BTN_NEXT', 10:'BTN_BLACKOUT', 11:'BTN_PAIR',
                   14:'LED_RUN', 15:'LED_FAULT', 18:'I2C_SDA', 19:'I2C_SCL'}
    mcu.update({str(n): assignments.get(n) for n in range(42)})
    part('U1', 'Teensy 4.1 with Ethernet PHY', 'Module / two 1x24 rows', mcu,
         mpn='PJRC TEENSY41 (PHY populated)',
         note='Cut VUSB-VIN link. USB device, SDIO and Ethernet kit remain on module. Unused GPIO NC.')
    part('U2', '3.3 V / 1 A LDO', 'DGN HVSSOP-8 exposed pad',
         {'1':'+3V3_DMX','2':'+3V3_DMX','3':None,'4':'GND_LOGIC','5':'+5V_SYS',
          '6':'GND_LOGIC','7':None,'8':'+5V_SYS','EP':'GND_LOGIC'},
         mpn='TLV76733DGNR', note='SNS at OUT; EP to thermal ground plane.')
    part('U5', 'Schmitt AND gates', 'TSSOP-14',
         {'1':'DMXA_REQ','2':'ARM_SENSE','3':'DMXA_DE','4':'DMXB_REQ',
          '5':'ARM_SENSE','6':'DMXB_DE','7':'GND_LOGIC','8':None,
          '9':'GND_LOGIC','10':'GND_LOGIC','11':None,'12':'GND_LOGIC',
          '13':'GND_LOGIC','14':'+3V3_MCU'}, mpn='SN74HCS08PWR')
    part('F1','1.5 A hold / 16 V PPTC','1812',{'1':'DC_IN','2':'DC_FUSED'},
         mpn='1812L150/16DR',note='Check ambient derating and fault clearing.')
    part('Q1','P-channel reverse polarity MOSFET','SOT-23',
         {'1':'PWR_GATE','2':'+5V_SYS','3':'DC_FUSED'},mpn='AO3401A',
         note='Pin 1 gate, 2 source, 3 drain. Drain faces incoming supply.')
    resistor('R1','100 kohm 1%', 'PWR_GATE','GND_LOGIC')
    capacitor('C1','100 uF / 10 V', '+5V_SYS','GND_LOGIC','Radial electrolytic',
              'Positive terminal pin 1; reserve exact lead pitch after procurement.')
    capacitor('C2','1 uF / 16 V X7R', '+5V_SYS','GND_LOGIC')
    capacitor('C3','10 uF / 16 V X7R', '+5V_SYS','GND_LOGIC','0805')
    capacitor('C4','10 uF / 16 V X7R', '+3V3_DMX','GND_LOGIC','0805',
              'Check effective capacitance after bias derating.')
    for ref, net in [('C5','+3V3_MCU'),('C6','+3V3_MCU'),('C7','ARM_SENSE')]:
        capacitor(ref,'100 nF / 16 V X7R',net,'GND_LOGIC')
    resistor('R2','1 kohm 1%','ARM_RAW','ARM_SENSE')
    resistor('R3','10 kohm 1%','ARM_SENSE','GND_LOGIC')
    for n,net in enumerate(['DMXA_REQ','DMXB_REQ','DMXA_DE','DMXB_DE','DMXA_TX','DMXB_TX'],4):
        resistor(f'R{n}','10 kohm 1%',net,'GND_LOGIC')
    for i,x in enumerate('AB'):
        p=f'DMX{x}'; iso=f'ISO{x}'
        pins={'1':'GND_LOGIC','2':'+3V3_DMX','3':'GND_LOGIC','4':None,
              '5':'+3V3_DMX','6':f'{p}_DE','7':f'{p}_TX','8':'+3V3_DMX',
              '9':'GND_LOGIC','10':'GND_LOGIC','11':f'{iso}_CONV_GND',
              '12':f'{iso}_RAW_3V3','13':f'{p}_P_DRV','14':f'{iso}_CONV_GND',
              '15':f'{p}_N_DRV','16':f'{iso}_GND','17':f'{p}_N_DRV',
              '18':f'{p}_P_DRV','19':f'{iso}_3V3','20':f'{iso}_GND'}
        part(f'U{i+3}','Isolated DMX output','SOIC-20 wide body',pins,
             mpn='ADM2587EBRWZ',note='Output only. /RE high, RxD NC. Separate isolated supply per port.')
        for ref,a,b in [(f'FB{1+i*2}',f'{iso}_RAW_3V3',f'{iso}_3V3'),
                        (f'FB{2+i*2}',f'{iso}_CONV_GND',f'{iso}_GND')]:
            part(ref,'600 ohm at 100 MHz ferrite','0603',{'1':a,'2':b},
                 mpn='BLM18AG601SN1D',note='Initial EMI candidate; verify high-frequency curve, current and DCR before release.')
        for off,(val,a,b,loc) in enumerate([
            ('100 nF','+3V3_DMX','GND_LOGIC','IC pins 2/1'),
            ('10 nF','+3V3_DMX','GND_LOGIC','IC pins 2/1'),
            ('100 nF','+3V3_DMX','GND_LOGIC','IC pins 8/9'),
            ('10 uF','+3V3_DMX','GND_LOGIC','IC pins 8/9'),
            ('100 nF',f'{iso}_RAW_3V3',f'{iso}_CONV_GND','IC pins 12/11'),
            ('10 uF',f'{iso}_RAW_3V3',f'{iso}_CONV_GND','IC pins 12/11'),
            ('100 nF',f'{iso}_3V3',f'{iso}_GND','IC pins 19/20'),
            ('10 nF',f'{iso}_3V3',f'{iso}_GND','IC pins 19/20')]):
            capacitor(f'C{10+i*10+off}',val+' / 16 V X7R',a,b,
                      '0805' if val=='10 uF' else '0603',loc)
        for j,pol in enumerate(['P','N']):
            resistor(f'R{10+i*2+j}','0 ohm',f'{p}_{pol}_DRV',f'{p}_{pol}_CABLE','0805',
                     'Tuning link. Default 0 ohm; added resistance requires loaded DMX tests.')
        part(f'D{i+1}','RS-485 transient array','SOT-23',
             {'1':f'{p}_P_CABLE','2':f'{p}_N_CABLE','3':f'{iso}_GND'},
             mpn='SM712-02HTG',note='Protection coordination requires bench validation; no claimed surge rating.')
        part(f'J{i+2}','DMX harness','JST-XH 3-pin 2.5 mm',
             {'1':f'{iso}_GND','2':f'{p}_N_CABLE','3':f'{p}_P_CABLE'},mpn='B3B-XH-A(LF)(SN)')
        part(f'XLR{i+1}','5-pin DMX output socket','Panel D series',
             {'1':f'{iso}_GND','2':f'{p}_N_CABLE','3':f'{p}_P_CABLE',
              '4':None,'5':None,'shell':'CHASSIS'},'off-board','NC5FD-LX')
    raw=[]
    for i,name in enumerate(['GO','HOLD','BACK','NEXT','BLACKOUT','PAIR']):
        a=f'{name}_RAW'; b=f'BTN_{name}'; raw.append(a)
        resistor(f'R{20+i}','1 kohm 1%',a,b)
        resistor(f'R{30+i}','10 kohm 1%',b,'+3V3_MCU')
        capacitor(f'C{30+i}','100 nF / 16 V X7R',b,'GND_LOGIC')
        part(f'SW{i+2}',name+' momentary switch','12 mm panel; low-current gold contacts',
             {'NO':a,'COM':'GND_LOGIC'},'off-board',
             note='SPST-NO; final mechanical SKU and button color selected before panel machining.')
    part('SW1','ARM maintained switch + guard','Panel SPST',
         {'1':'+3V3_MCU','2':'ARM_RAW'},'off-board',
         note='Low-current gold contacts. Guard envelope checked in panel CAD.')
    for ref,name,color in [('LED1','RUN','green'),('LED2','FAULT','red')]:
        part(ref,color+' panel LED','3 mm LED + insulating bezel',
             {'A':f'{name}_LED_A','K':'GND_LOGIC'},'off-board')
    resistor('R16','1 kohm 1%','LED_RUN','RUN_LED_A')
    resistor('R17','1 kohm 1%','LED_FAULT','FAULT_LED_A')
    part('J1','Power harness','JST-XH 2-pin 2.5 mm',
         {'1':'DC_IN','2':'GND_LOGIC'},mpn='B2B-XH-A(LF)(SN)')
    part('J4','OLED interface','JST-SH 4-pin 1 mm',
         {'1':'GND_LOGIC','2':'+3V3_MCU','3':'I2C_SDA','4':'I2C_SCL'},mpn='SM04B-SRSS-TB(LF)(SN)')
    jp={'1':'GND_LOGIC','2':'+3V3_MCU',**{str(3+i):a for i,a in enumerate(raw)},
        '9':'ARM_RAW','10':'RUN_LED_A','11':'FAULT_LED_A','12':'GND_LOGIC'}
    part('J5','Panel controls harness','JST-XH 12-pin 2.5 mm',jp,mpn='B12B-XH-A(LF)(SN)')
    part('J6','Chassis bond point','M3 ring lug / bond pad',{'1':'CHASSIS'})
    resistor('R40','0 ohm','GND_LOGIC','CHASSIS','0805','Single initial logic/chassis bond; never bridge an isolated DMX common.')
    part('OLED1','128x64 I2C OLED','29.2 x 26.7 mm module',
         {'GND':'GND_LOGIC','VIN':'+3V3_MCU','SDA':'I2C_SDA','SCL':'I2C_SCL'},
         'off-board','Adafruit 326 current STEMMA QT version','Module supplies I2C pullups; verify address.')
    for i,net in enumerate(['+5V_SYS','+3V3_MCU','+3V3_DMX','GND_LOGIC','ARM_SENSE',
                           'DMXA_REQ','DMXB_REQ','DMXA_DE','DMXB_DE','DMXA_TX','DMXB_TX',
                           'ISOA_3V3','ISOA_GND','DMXA_P_CABLE','DMXA_N_CABLE',
                           'ISOB_3V3','ISOB_GND','DMXB_P_CABLE','DMXB_N_CABLE'],1):
        part(f'TP{i}',net,'1.5 mm exposed test pad',{'1':net},'PCB feature',
             note='Copper feature; no purchased component.')


EXTRAS = [
    ('ETH1',1,'Ethernet kit for Teensy 4.1','PJRC ETHERNET_KIT',
     'Includes magjack, PCB, capacitor, 2x3 headers and ribbon cable; assemble vendor kit.'),
    ('SD1',1,'Industrial/high-endurance 8-32 GB microSD','Qualified supplier SKU required',
     'FAT32 initial target; qualify exact model for power interruption/read latency.'),
    ('PS1',1,'5 V 3 A external adapter','Mean Well GST18A05-P1J','Add regional IEC mains lead; no mains wiring in box.'),
    ('USB1',1,'Reversible USB A/B panel feedthrough','Neutrik NAUSB-W','B outward, A inward; bond shell to chassis.'),
    ('NET1',1,'Shielded RJ45 panel coupler, CAT5e or better','Mechanical SKU to select',
     'Panel grounded shell; internal short patch cable to Ethernet kit; no PoE.'),
    ('DC1',1,'Insulated panel barrel socket, 5.5/2.1 mm, >=3 A','Mechanical SKU to select',
     'Center positive; sleeve to logic ground; two-wire harness to J1.'),
    ('CASE1',1,'Extruded aluminum enclosure','Hammond 1455T2201BK','220 x 165 x 51.5 mm nominal; use custom machined end panels.'),
    ('PCB1',1,'Custom 4-layer carrier, 140 x 110 mm allowance','Native ECAD and routed PCB required','Not supplied as fabrication-ready artwork.'),
    ('SOCKET',2,'1x24 female 2.54 mm module socket','PJRC 24-pin socket or dimensional equivalent','Check controller header lengths and retention bracket.'),
    ('HEADER',2,'1x24 male 2.54 mm header','PJRC 24-pin header or dimensional equivalent','For bare Teensy module; omit if purchased already fitted.'),
    ('HARNESS1',1,'J1 power mating connector and leads','XHP-2 + 2 x SXH contacts','22 AWG stranded; verify crimp tooling and pin 1.'),
    ('HARNESS2',2,'J2/J3 DMX mating connectors and leads','XHP-3 + 3 x SXH contacts per harness','Short 120-ohm twisted pair + isolated common; heatshrink at XLR.'),
    ('HARNESS3',1,'J5 12-way panel harness','XHP-12 + 12 x SXH contacts','26 AWG signal wiring; <=200 mm; continuity test each switch.'),
    ('CABLE1',1,'JST-SH/Qwiic 4-wire OLED cable','Standard keyed cable, <=150 mm','Verify pinout; use assembled cable, no hand-swapped wire colors.'),
    ('CABLE2',1,'Internal USB-A male to Micro-B data cable','Short, shielded, <=200 mm','Secure both ends; no charge-only cable.'),
    ('CABLE3',1,'Internal CAT5e patch cable','Short shielded patch, <=200 mm','Kit magjack to panel coupler.'),
    ('CABLE4',1,'Host USB cable','USB-A/C host to USB-B device data cable','Host-dependent cable; supplied as accessory.'),
    ('CABLE5',1,'External CAT5e network cable','Shielding per venue installation','Local Ethernet connection.'),
    ('CABLE6',2,'External DMX512 5-pin cable','120-ohm DMX cable','One for each physical output as required.'),
    ('TERM',2,'120-ohm far-end XLR DMX terminator','5-pin, 0.25 W or greater resistor','External accessory, no source-end shunt termination.'),
    ('MECH',1,'Mechanical hardware set','Procure to reviewed mechanical CAD',
     'Insulating M3 standoffs, screws, washers, module brackets, feet, OLED window, SD cover, strain reliefs, chassis lead and labels.'),
    ('LAN',0,'Optional offline Wi-Fi AP / Ethernet switch','Venue-dependent external equipment',
     'Only needed to join wireless app clients or multiple network nodes; internet not required.'),
]


def index():
    return {p['ref']:p for p in PARTS}


def verify():
    by=index()
    assert len(by)==len(PARTS), 'Duplicate reference'
    assert len(by['U1']['pins'])==48
    assert set(by['U3']['pins'])==set(map(str,range(1,21)))
    assert set(by['U4']['pins'])==set(map(str,range(1,21)))
    for ref in ['U3','U4']:
        p=by[ref]['pins']; assert p['4'] is None and p['5']=='+3V3_DMX'
        assert p['11']==p['14'] and p['16']==p['20'] and p['11']!=p['16']
        assert p['12']!=p['19']; assert p['13']==p['18']; assert p['15']==p['17']
    assert by['U2']['pins']['2']==by['U2']['pins']['1']=='+3V3_DMX'
    assert by['Q1']['pins']=={'1':'PWR_GATE','2':'+5V_SYS','3':'DC_FUSED'}
    for x,u,j,xx,base in [('A','U3','J2','XLR1',10),('B','U4','J3','XLR2',20)]:
        assert by[j]['pins']['1']==f'ISO{x}_GND'
        assert by[xx]['pins']['2']==f'DMX{x}_N_CABLE'
        assert by[xx]['pins']['3']==f'DMX{x}_P_CABLE'
        assert by[xx]['pins']['4'] is None and by[xx]['pins']['5'] is None
        assert len([by[f'C{base+n}'] for n in range(8)])==8
    # Check conductive passive paths do not collapse isolation or regulator rails.
    parent={}
    def root(n):
        parent.setdefault(n,n)
        if parent[n]!=n: parent[n]=root(parent[n])
        return parent[n]
    def union(a,b): parent[root(a)]=root(b)
    for p in PARTS:
        if (p['ref'].startswith('R') or p['ref'].startswith('FB')) and len(p['pins'])==2:
            union(*p['pins'].values())
    for a,b in [('ISOA_GND','GND_LOGIC'),('ISOB_GND','GND_LOGIC'),
                ('ISOA_GND','ISOB_GND'),('ISOA_3V3','ISOB_3V3'),
                ('+3V3_MCU','+3V3_DMX')]:
        assert root(a)!=root(b), f'Unintended passive short {a} / {b}'
    assert root('ISOA_CONV_GND')==root('ISOA_GND')
    assert root('ISOB_CONV_GND')==root('ISOB_GND')
    for p in PARTS:
        if p['ref'].startswith(('R','C','FB','D')):
            nets=[n for n in p['pins'].values() if n]
            assert not (any(n.startswith('ISOA') for n in nets) and any(n.startswith('ISOB') for n in nets))
    timing=120+16+513*11/250000*1000000
    assert timing==22708 and timing<25000
    return dict(component_records=len(PARTS), test_pads=sum(p['category']=='PCB feature' for p in PARTS),
                named_nets=len({n for p in PARTS for n in p['pins'].values() if n}),
                dmx_active_us=int(timing), dmx_idle_us=int(25000-timing),
                checks='Reference/pin coverage, named-net isolation, rail separation, polarity and frame arithmetic only; not ERC or physical validation')


class Sheet:
    def __init__(self, number, title, subtitle):
        self.number=number; self.title=title; self.items=[]; self.refs=set()
        self.rect(0,0,1800,1200,'#ffffff','none')
        self.rect(0,0,1800,14,'#137d84','none')
        self.text(55,62,'VENUE VOLUME  /  OFFLINE CUE PLAYER',22,'#137d84',bold=True)
        self.text(55,108,title,34,bold=True)
        self.text(55,143,subtitle,18,'#52606d')
        self.line(55,166,1745,166,'#cad5df')
        self.line(55,1120,1745,1120,'#cad5df')
        self.text(55,1154,'REV A  |  2026-10-03  |  ENGINEERING REFERENCE - NOT FOR FABRICATION',18,'#52606d')
        self.text(55,1182,'Same net name = electrical connection. NC = deliberately unconnected. Read electrical.md and sources.md.',17,'#52606d')
        self.text(1660,1154,f'SHEET {number}/6',18,'#137d84',bold=True)
    def text(self,x,y,s,size=20,color='#182d40',bold=False,anchor='start'):
        self.items.append(f'<text x="{x}" y="{y}" font-family="Liberation Sans, Arial, sans-serif" font-size="{size}" fill="{color}" text-anchor="{anchor}" font-weight="{700 if bold else 400}">{html.escape(str(s))}</text>')
    def line(self,x1,y1,x2,y2,color='#294b62',width=2,dash=''):
        self.items.append(f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="{color}" stroke-width="{width}"'+(f' stroke-dasharray="{dash}"' if dash else '')+'/>')
    def rect(self,x,y,w,h,fill='#f2f6f9',stroke='#94a9ba',radius=0):
        self.items.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{radius}" fill="{fill}" stroke="{stroke}" stroke-width="2"/>')
    def circle(self,x,y,r,fill='#ffffff',stroke='#294b62'):
        self.items.append(f'<circle cx="{x}" cy="{y}" r="{r}" fill="{fill}" stroke="{stroke}" stroke-width="2"/>')
    def note(self,x,y,lines,size=20,color='#52606d',leading=29):
        for i,s in enumerate(lines): self.text(x,y+i*leading,s,size,color)
    def box(self,x,y,w,h,title,lines,color='#137d84'):
        self.rect(x,y,w,h,'#f2f6f9',color,8)
        self.text(x+18,y+35,title,23,color,True)
        self.note(x+18,y+70,lines,19,leading=29)
    def arrow(self,x1,y1,x2,y2,label=None):
        self.line(x1,y1,x2,y2,'#137d84',3)
        length=math.hypot(x2-x1,y2-y1)
        dx,dy=(x2-x1)/length,(y2-y1)/length
        for sign in [-1,1]:self.line(x2,y2,x2-12*dx+sign*7*dy,y2-12*dy-sign*7*dx,'#137d84',3)
        if label:self.text((x1+x2)/2,y1-13,label,18,'#137d84',anchor='middle')
    def pinblock(self,ref,x,y,w,left,right,step=42):
        p=index()[ref]; self.refs.add(ref)
        h=105+max(len(left),len(right))*step
        self.rect(x,y,w,h,'#f7fafc','#496d84')
        heading=f'{ref}  {p["mpn"]}'
        size=min(21,(w-20)/max(len(heading)*.56,1))
        self.text(x+w/2,y+34,heading,size,bold=True,anchor='middle')
        subsize=min(18,(w-20)/max(len(p['value'])*.52,1))
        self.text(x+w/2,y+61,p['value'],subsize,'#52606d',anchor='middle')
        for side,items in [('left',left),('right',right)]:
            for i,(pin,desc) in enumerate(items):
                py=y+100+i*step; net=p['pins'][pin]
                if side=='left':
                    self.line(x-30,py,x,py); self.text(x+12,py+6,f'{pin}  {desc}',18)
                    self.text(x-42,py+6,net or 'NC',18,'#137d84' if net else '#aa5c42',anchor='end')
                else:
                    self.line(x+w,py,x+w+30,py);self.text(x+w-12,py+6,f'{desc}  {pin}',18,anchor='end')
                    self.text(x+w+42,py+6,net or 'NC',18,'#137d84' if net else '#aa5c42')
        return h
    def passive(self,ref,x,y,width=355):
        p=index()[ref]; self.refs.add(ref)
        self.text(x,y,ref+'  '+p['value'],18,bold=True)
        a,b=p['pins'].values()
        self.text(x,y+30,a,16,'#137d84')
        self.line(x,y+50,x+120,y+50)
        if ref.startswith('C'):
            self.line(x+120,y+35,x+120,y+65)
            self.line(x+130,y+35,x+130,y+65)
            self.line(x+130,y+50,x+width-10,y+50)
        else:
            self.rect(x+120,y+40,40,20,'#ffffff','#294b62')
            self.line(x+160,y+50,x+width-10,y+50)
        self.text(x+width-10,y+83,b,16,'#137d84',anchor='end')
    def save(self,name):
        path=ROOT/'schematics'/name
        path.write_text('<svg xmlns="http://www.w3.org/2000/svg" width="1800" height="1200" viewBox="0 0 1800 1200">'+''.join(self.items)+'</svg>\n')
        return path


def diagrams():
    (ROOT/'schematics').mkdir(exist_ok=True)
    files=[]
    s=Sheet(1,'System interconnect','Store the show once. Local timing and output continue after the uploading client disconnects.')
    s.box(65,220,340,190,'Venue Volume app', ['Resolve real fixture profiles','Export venue-specific .vvshow','Desktop/native uploader'])
    s.box(65,490,340,175,'Local Ethernet LAN',['Optional offline Wi-Fi AP','No internet gateway needed','Console input only if supported'])
    s.box(650,220,480,200,'U1  Teensy 4.1 + SD1',['Real-time state engine and timers','microSD: verified A/B show slots','8 logical universes; physical A/B mirror two'])
    s.box(650,520,480,190,'Custom carrier PCB',['U2: separate DMX logic power','U3/U4: independent isolated drivers','U5: physical ARM permission gates'])
    s.box(1370,220,355,180,'ETH1 + NET1',['100BASE-TX magjack kit','Panel RJ45; UDP Art-Net','Up to 8 universes at 40 Hz'])
    s.box(1370,520,355,190,'XLR1 / XLR2 outputs',['5-pin DMX sockets','250 kbit/s, 8N2','Far-end termination required'])
    s.arrow(405,290,650,290,'USB data')
    s.line(405,570,465,570,'#137d84',3)
    s.line(465,570,465,375,'#137d84',3)
    s.arrow(465,375,650,375,'Ethernet to U1')
    s.arrow(1130,310,1370,310,'Ethernet')
    s.arrow(890,420,890,520)
    s.arrow(1130,605,1370,605,'DMX A/B')
    s.box(65,820,440,205,'Power path',['PS1 5 V / 3 A -> panel DC1 -> J1','F1 / Q1 -> +5V_SYS -> U1 VIN','U2 -> +3V3_DMX -> U3/U4','USB VBUS-to-VIN link CUT on U1'])
    s.box(635,820,515,205,'Local operation',['OLED; GO / HOLD / BACK / NEXT','BLACKOUT; PAIR; guarded ARM','Buttons and OLED work without host','ARM off releases data, not guaranteed dark'])
    s.box(1270,820,455,205,'Mechanical and limits',['Hammond 1455T2201BK housing','USB-B for loading; external DC required','No Wi-Fi, PoE, RDM or console show import','Reference design; hardware tests pending'])
    files.append(s.save('01-system.svg'))

    s=Sheet(2,'Power regulation and USB supply separation','Logic ground and both DMX cable grounds remain separate. No USB-derived carrier power.')
    s.pinblock('J1',185,220,225,[('1','+5V IN'),('2','RETURN')],[],step=40)
    s.passive('F1',520,220,345)
    s.pinblock('Q1',1180,215,280,[('3','DRAIN'),('1','GATE')],[('2','SOURCE')],40)
    s.passive('R1',1180,465,360)
    s.pinblock('U2',450,435,340,[('8','IN'),('5','EN'),('4','GND'),('6','GND'),('EP','PAD')],
               [('1','OUT'),('2','SNS'),('3','NC'),('7','NC')],39)
    for ref,x,y in [('C1',65,825),('C2',490,825),('C3',915,825),('C4',1340,825)]:s.passive(ref,x,y,335)
    s.note(70,1020,['U1 VIN = +5V_SYS. U1 3.3 V output = +3V3_MCU. Never join +3V3_MCU and +3V3_DMX.',
                   'C1 positive terminal faces +5V_SYS. Cut U1 VUSB/VIN link; retain USB VBUS at the module device port.'],21)
    s.note(1100,650,['Power-only circuit on this sheet.','U5 gates and panel ARM are on sheet 3.','Supply tolerance and heat require testing.'],20)
    files.append(s.save('02-power.svg'))

    s=Sheet(3,'Controller, enable gates and panel connections','Module pins use Teensy labels. All unspecified GPIO are NC; full header mapping is in electrical.md.')
    s.pinblock('U1',270,195,450,
               [('VIN','VIN'),('3V3_L','3.3V'),('GND_L','GND'),('1','TX1'),('8','TX2'),('2','REQUEST A'),('3','REQUEST B'),('4','ARM INPUT')],
               [('5','GO'),('6','HOLD'),('7','BACK'),('9','NEXT'),('10','BLACKOUT'),('11','PAIR'),('18','SDA'),('19','SCL')],38)
    s.pinblock('U5',1260,205,275,[('1','1A'),('2','1B'),('4','2A'),('5','2B'),('14','VCC'),('7','GND')],
               [('3','1Y'),('6','2Y'),('8','NC'),('11','NC')],38)
    s.note(1000,570,['U5 unused inputs 9/10/12/13 -> GND_LOGIC.','C5: 100 nF across U5 pins 14/7.',
                      'R4/R5: 10k requests to GND; R6/R7: 10k enables to GND.','R8/R9: 10k UART TX to GND. Initialize TX high before DE.'],18,leading=28)
    s.box(65,710,760,350,'Panel harness J5  /  JST-XH 12-way',[
        '1 GND; 2 +3V3_MCU; 3 GO_RAW; 4 HOLD_RAW; 5 BACK_RAW',
        '6 NEXT_RAW; 7 BLACKOUT_RAW; 8 PAIR_RAW; 9 ARM_RAW',
        '10 RUN_LED_A; 11 FAULT_LED_A; 12 GND',
        'SW2-SW7: each RAW signal -> normally-open button -> GND',
        'R20-R25: RAW -> 1k -> BTN; R30-R35: BTN -> 10k -> 3.3V',
        'C30-C35: each BTN -> 100 nF -> GND. Debounce in firmware.',
        'U1 pins 14/15 -> R16/R17 1k -> LED1/LED2 anodes; cathodes GND',
        'U1 other GND and 3.3V header pins join corresponding module nets.'
    ])
    s.box(890,710,835,350,'ARM, OLED and chassis',[
        'SW1: +3V3_MCU -> maintained switch -> ARM_RAW',
        'R2: ARM_RAW -> 1k -> ARM_SENSE; R3: ARM_SENSE -> 10k -> GND',
        'C7: ARM_SENSE -> 100 nF -> GND; MCU pin 4 reads ARM_SENSE',
        'J4: 1 GND, 2 +3V3_MCU, 3 SDA, 4 SCL -> OLED1 (Adafruit 326)',
        'C6: 100 nF at J4 supply; module supplies I2C pullups',
        'R40: GND_LOGIC -> 0 ohm -> CHASSIS; J6 bonds enclosure',
        'USB / Ethernet / XLR connector shells -> CHASSIS',
        'No DMX isolated common joins this chassis or logic ground.'
    ])
    files.append(s.save('03-control.svg'))

    for i,x in enumerate('AB'):
        s=Sheet(i+4,f'Isolated DMX output {x}',f'U{i+3} is ADM2587EBRWZ. The ISO{x} cable domain is isolated from logic and from the other port.')
        left=[(str(n),desc) for n,desc in [(1,'GND1'),(2,'VCC'),(3,'GND1'),(4,'RxD'),(5,'/RE'),(6,'DE'),(7,'TxD'),(8,'VCC'),(9,'GND1'),(10,'GND1')]]
        right=[(str(n),desc) for n,desc in [(20,'GND2'),(19,'VISOIN'),(18,'A'),(17,'B'),(16,'GND2'),(15,'Z'),(14,'CONV GND'),(13,'Y'),(12,'VISOOUT'),(11,'CONV GND')]]
        s.pinblock(f'U{i+3}',530,195,465,left,right,36)
        s.line(763,280,763,660,'#bf6d42',2,'9 6')
        s.text(685,696,'ISOLATION BARRIER',18,'#bf6d42')
        s.box(1370,205,365,450,f'Cable wiring: J{i+2} -> XLR{i+1}',[
            f'1 -> pin 1: ISO{x}_GND',f'2 -> pin 2: DMX{x}_N_CABLE',f'3 -> pin 3: DMX{x}_P_CABLE',
            'XLR 4/5: NC; shell: CHASSIS',f'R{10+i*2}: P_DRV -> 0R -> P_CABLE',
            f'R{11+i*2}: N_DRV -> 0R -> N_CABLE',f'D{i+1}: SM712-02HTG TVS',
            'TVS pin 1=P; 2=N; 3=ISO GND','Far-end 120-ohm termination','No source terminator / bias','Receiver disabled; RxD NC'
        ])
        s.note(65,235,[f'FB{1+i*2}: ISO{x}_RAW_3V3',f'  -> bead -> ISO{x}_3V3','',
                       f'FB{2+i*2}: ISO{x}_CONV_GND',f'  -> bead -> ISO{x}_GND','',
                       '600 ohm at 100 MHz initial','candidate; final EMI review.','',
                       '11/14 and 16/20 are NOT','one copper pour. Join only','through the ground bead.'],18,leading=29)
        for n in range(8):s.passive(f'C{10+i*10+n}',65+(n%4)*420,765+(n//4)*165,345)
        s.text(70,1096,'Caps by pin pair: first two 2/1; next two 8/9; next two 12/11; last two 19/20. Place at each pair.',18,'#52606d')
        files.append(s.save(f'0{i+4}-dmx-{x.lower()}.svg'))

    s=Sheet(6,'Enclosure and PCB placement allowance','Arrangement study only. Nominal dimensions and positions are not a machining or drill drawing.')
    for yy,label in [(230,'FRONT PANEL - 165 x 51.5 mm nominal'),(610,'REAR PANEL - 165 x 51.5 mm nominal')]:
        s.text(70,yy-20,label,24,bold=True)
        s.rect(70,yy,990,309,'#f7fafc','#496d84',10)
    s.rect(154,290,180,120,'#213a48','#294b62',6);s.text(178,355,'OLED',28,'#ffffff',True)
    for xx in [502,634,766]:
        for yy in [326,446]:s.circle(xx,yy,36)
    for xx,txt in [(502,'GO'),(634,'HOLD'),(766,'BACK')]:s.text(xx,326+7,txt,17,anchor='middle')
    for xx,txt in [(502,'NEXT'),(634,'DARK'),(766,'PAIR')]:s.text(xx,446+7,txt,17,anchor='middle')
    s.circle(946,384,34);s.text(946,458,'ARM',20,anchor='middle')
    s.circle(388,335,9,'#137d84');s.circle(388,424,9,'#b8584f')
    for xx,txt in [(190,'DMX A'),(400,'DMX B'),(610,'USB-B'),(820,'RJ45')]:
        s.circle(xx,765,72);s.text(xx,772,txt,22,anchor='middle')
    s.circle(976,765,29);s.text(976,830,'5 V',20,anchor='middle')
    s.box(1140,230,595,310,'Carrier placement target',[
        '140 x 110 mm on insulating standoffs','U1 / SD in center; display harness forward',
        'U3/U4 at rear, separate isolated islands','Rear XLR harnesses short and twisted',
        'Ethernet kit on a retained bracket','Do not hang modules from their cables','Check actual internal envelope in CAD'
    ])
    s.box(1140,610,595,310,'Before any panel is cut',[
        'Use manufacturer end-plate drawings','Check D-series flanges and screw holes',
        'Select switch bodies and ARM guard','Check DC plug and RJ45 cable clearance',
        'Secure internal USB and microSD','Test closed-enclosure temperatures','No production fit verification performed'
    ])
    s.note(70,1020,['Enclosure: Hammond 1455T2201BK, 220 mm depth. No mains supply or Wi-Fi radio inside.',
                   'This drawing communicates arrangement. Manufacturing requires native mechanical CAD and ECAD.'],23)
    files.append(s.save('06-enclosure.svg'))
    return files


def write_data():
    data={'revision':'A','date':'2026-10-03','status':'Unbuilt reference; not native ECAD',
          'components':PARTS,'checks':verify()}
    (ROOT/'connectivity.json').write_text(json.dumps(data,indent=2)+'\n')
    groups=collections.OrderedDict()
    for p in PARTS:
        key=(p['value'],p['package'],p['mpn'],p['category'],p['note'])
        groups.setdefault(key,[]).append(p['ref'])
    bom=[dict(refs=refs,qty=len(refs),value=k[0],package=k[1],mpn=k[2],category=k[3],note=k[4])
         for k,refs in groups.items()]
    extras=[dict(refs=[ref],qty=qty,value=val,package='Assembly / accessory',mpn=mpn,
                 category='assembly',note=note) for ref,qty,val,mpn,note in EXTRAS]
    (ROOT/'bom.json').write_text(json.dumps({'revision':'A','items':bom+extras},indent=2)+'\n')
    lines=['# Bill of materials','',
        'Quantities are for one complete Revision A box. Electronic references correspond to the pin-level sheets and connectivity.json. All resistors are at least 0.1 W unless stated; 0-ohm links must carry the relevant fault/test current. Capacitor ratings are minimums and effective capacitance must be verified. This is a reference purchasing list, not an assembly-house release BOM.','',
        'Core semiconductor MPNs are selected. Specification-controlled passives and commodity/mechanical items need exact vendor SKUs and footprints before purchase. Optional external LAN equipment has quantity zero and is not included in the base assembly.','']
    for cat,title in [('carrier','Carrier electronics'),('off-board','Panel components'),('PCB feature','Test features'),('assembly','Modules hardware cables and accessories')]:
        lines += ['## '+title,'','| References | Qty | Component and package | Part or selection requirement | Notes |','| --- | --- | --- | --- | --- |']
        for item in bom+extras:
            if item['category']!=cat:continue
            lines.append('| '+', '.join(item['refs'])+' | '+str(item['qty'])+' | '+item['value']+'; '+item['package']+' | '+item['mpn']+' | '+(item['note'] or '-')+' |')
        lines.append('')
    (ROOT/'bom.md').write_text('\n'.join(lines).rstrip()+'\n')


def inline(text):
    # Preserve ordinary Markdown link labels as actual PDF links.
    text=html.escape(text)
    text=re.sub(r'\[([^\]]+)\]\((https?://[^)]+)\)',r'<link href="\2" color="#137d84">\1</link>',text)
    text=re.sub(r'\[([^\]]+)\]\(([^)]+)\)',r'\1',text)
    text=re.sub(r'`([^`]+)`',r'<font name="VVMono">\1</font>',text)
    text=re.sub(r'\*\*([^*]+)\*\*',r'<b>\1</b>',text)
    return text


def make_pdf(svg_files):
    from reportlab.pdfgen import canvas
    from reportlab.lib import colors
    from reportlab.lib.pagesizes import A4, landscape
    from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
    from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, PageBreak, Table, TableStyle, CondPageBreak
    from reportlab.graphics import renderPDF
    from reportlab.graphics.shapes import Drawing, Rect, Line, Circle, String
    from xml.etree import ElementTree as ET
    from pypdf import PdfReader, PdfWriter
    from reportlab.pdfbase import pdfmetrics
    from reportlab.pdfbase.ttfonts import TTFont
    font_candidates=[Path('/usr/share/fonts/liberation'),Path('/usr/share/fonts/truetype/liberation2'),Path('/usr/share/fonts/truetype/liberation')]
    font_dir=next((p for p in font_candidates if (p/'LiberationSans-Regular.ttf').exists()),None)
    if font_dir is None:raise RuntimeError('Install Liberation fonts for reproducible PDF rendering, or use --no-pdf.')
    for name,filename in [('VV','LiberationSans-Regular.ttf'),('VV-Bold','LiberationSans-Bold.ttf'),('VVMono','LiberationMono-Regular.ttf')]:
        pdfmetrics.registerFont(TTFont(name,str(font_dir/filename)))
    pdfmetrics.registerFontFamily('VV',normal='VV',bold='VV-Bold',italic='VV',boldItalic='VV-Bold')
    tmp=ROOT/'research-tmp';tmp.mkdir(exist_ok=True)
    OUT.mkdir(parents=True,exist_ok=True)
    diagram_pdf=tmp/'schematics.pdf'
    c=canvas.Canvas(str(diagram_pdf),pagesize=landscape(A4))
    def svg_drawing(path):
        # These source drawings use only explicit SVG geometric primitives.
        svg=ET.parse(path).getroot();w=float(svg.attrib['width']);h=float(svg.attrib['height'])
        drawing=Drawing(w,h)
        def color(v): return None if v=='none' else colors.HexColor(v)
        for el in svg:
            a=el.attrib;tag=el.tag.rsplit('}',1)[-1]
            f=lambda k,default=0:float(a.get(k,default))
            common=dict(fillColor=color(a.get('fill','#000000')),strokeColor=color(a.get('stroke','none')),strokeWidth=f('stroke-width',1))
            if tag=='rect':shape=Rect(f('x'),h-f('y')-f('height'),f('width'),f('height'),rx=f('rx'),ry=f('rx'),**common)
            elif tag=='circle':shape=Circle(f('cx'),h-f('cy'),f('r'),**common)
            elif tag=='line':
                shape=Line(f('x1'),h-f('y1'),f('x2'),h-f('y2'),strokeColor=common['strokeColor'],strokeWidth=common['strokeWidth'])
                if a.get('stroke-dasharray'):shape.strokeDashArray=[float(n) for n in a['stroke-dasharray'].split()]
            elif tag=='text':shape=String(f('x'),h-f('y'),el.text or '',fontName='VV-Bold' if a.get('font-weight')=='700' else 'VV',fontSize=f('font-size'),textAnchor=a.get('text-anchor','start'),fillColor=common['fillColor'])
            else:raise ValueError('Unsupported SVG primitive '+tag)
            drawing.add(shape)
        return drawing
    for f in svg_files:
        drawing=svg_drawing(f);factor=min((A4[1]-28)/drawing.width,(A4[0]-24)/drawing.height)
        drawing.scale(factor,factor)
        renderPDF.draw(drawing,c,14,12);c.showPage()
    c.save()
    styles=getSampleStyleSheet()
    styles.add(ParagraphStyle(name='VVBody',fontName='VV',fontSize=9,leading=13,spaceAfter=7,allowWidows=0,allowOrphans=0,textColor=colors.HexColor('#182d40')))
    styles.add(ParagraphStyle(name='VVCell',fontName='VV',fontSize=7.3,leading=10,spaceAfter=1,textColor=colors.HexColor('#182d40')))
    for name,size in [('Heading1',22),('Heading2',14),('Heading3',11)]:
        styles[name].fontName='VV-Bold';styles[name].fontSize=size;styles[name].leading=size+4
        styles[name].textColor=colors.HexColor('#137d84');styles[name].spaceAfter=9
        styles[name].keepWithNext=False
    def para(s,style='VVBody'):return Paragraph(inline(s),styles[style])
    story=[para('Venue Volume offline cue player','Heading1'),
           para('Schematic and build packet | Revision A | 3 October 2026'),
           Spacer(1,16),para('A self-contained venue playback box','Heading2'),
           para('Load a compiled cue sequence over local Ethernet or USB, then disconnect the uploading device. The box stores the show and generates DMX512 and Art-Net from its own clock.'),
           para('Two isolated DMX outputs. Eight logical universes. Local microSD. Physical GO, HOLD and BLACKOUT. External 5 V power. No internet required for playback.'),
           Spacer(1,14),para('Design maturity','Heading2'),
           para('Engineering reference design with selected core components, pin-level schematic sheets, a purchasing list and implementation requirements. The hardware is unbuilt. Native ECAD, layout, Gerbers, firmware and physical tests remain development work.'),
           para('Use at a venue','Heading2'),
           para('Connect directly to DMX distribution or Art-Net receivers. Connection through a console requires a documented input and merge policy for that exact desk. Channel playback does not import a native console show file.'),
           Spacer(1,14),para('Packet contents','Heading2'),
           para('The next six landscape sheets show the system, power circuit, controller and control wiring, both isolated DMX circuits, and the enclosure arrangement. The following pages contain the product/build guide, electrical details, upload/runtime contract, manufacturing requirements, full BOM and source references.'),
           para('Editable sources and the machine-readable reference connections live in hardware/cue-player. Documentation consistency checks are not electrical or manufacturing certification.')]
    cover=tmp/'cover.pdf'
    SimpleDocTemplate(str(cover),pagesize=A4,rightMargin=45,leftMargin=45,topMargin=45,bottomMargin=45).build(story)
    story=[]
    for doc in ['README.md','electrical.md','firmware.md','manufacturing.md','bom.md','sources.md']:
        if story:story.append(PageBreak())
        lines=(ROOT/doc).read_text().splitlines();i=0
        while i<len(lines):
            line=lines[i].strip()
            if not line:i+=1;continue
            if line.startswith('|'):
                tablelines=[]
                while i<len(lines) and lines[i].lstrip().startswith('|'):
                    cells=[x.strip() for x in lines[i].strip().strip('|').split('|')]
                    if not all(re.fullmatch(r'[-: ]+',x) for x in cells):tablelines.append(cells)
                    i+=1
                n=len(tablelines[0]); avail=A4[0]-90
                ratios={2:[.30,.70],3:[.19,.27,.54],5:[.18,.05,.25,.23,.29]}.get(n,[1/n]*n)
                table=Table([[para(x,'VVCell') for x in row] for row in tablelines],
                            colWidths=[avail*x for x in ratios],repeatRows=1,hAlign='LEFT')
                table.setStyle(TableStyle([
                    ('BACKGROUND',(0,0),(-1,0),colors.HexColor('#dceff0')),
                    ('ROWBACKGROUNDS',(0,1),(-1,-1),[colors.white,colors.HexColor('#f4f7f9')]),
                    ('VALIGN',(0,0),(-1,-1),'TOP'),('LEFTPADDING',(0,0),(-1,-1),6),
                    ('RIGHTPADDING',(0,0),(-1,-1),6),('TOPPADDING',(0,0),(-1,-1),6),
                    ('BOTTOMPADDING',(0,0),(-1,-1),6),('LINEBELOW',(0,0),(-1,0),.6,colors.HexColor('#94a9ba'))]))
                story.extend([table,Spacer(1,10)]);continue
            if line.startswith('#'):
                level=len(line)-len(line.lstrip('#'))
                story.append(CondPageBreak(100))
                story.append(para(line[level:].strip(),'Heading'+str(min(level,3))));i+=1;continue
            if line.startswith('- '):story.append(para('- '+line[2:]));i+=1;continue
            text=[line];i+=1
            while i<len(lines) and lines[i].strip() and not lines[i].startswith(('#','|','- ')) and not re.match(r'\d+\. ',lines[i]):
                text.append(lines[i].strip());i+=1
            story.append(para(' '.join(text)))
    def footer(canv,doc):
        canv.setStrokeColor(colors.HexColor('#cad5df'));canv.line(45,36,A4[0]-45,36)
        canv.setFont('VV',8);canv.setFillColor(colors.HexColor('#52606d'))
        canv.drawString(45,24,'VENUE VOLUME  |  Rev A reference design  |  Physical validation pending')
        canv.drawRightString(A4[0]-45,24,f'Guide {doc.page}')
    body=tmp/'guide.pdf'
    SimpleDocTemplate(str(body),pagesize=A4,rightMargin=45,leftMargin=45,topMargin=40,bottomMargin=50).build(story,onFirstPage=footer,onLaterPages=footer)
    writer=PdfWriter()
    for path,label in [(cover,'Overview'),(diagram_pdf,'Schematic sheets'),(body,'Build guide and BOM')]:
        writer.append(str(path),outline_item=label)
    writer.add_metadata({'/Title':'Venue Volume offline cue player - Revision A',
                         '/Author':'Venue Volume','/Subject':'Reference hardware schematic and build specification'})
    final=OUT/'venue-volume-cue-player.pdf'
    with final.open('wb') as f:writer.write(f)
    return dict(path=str(final),pages=len(PdfReader(str(final)).pages))


def main():
    ap=argparse.ArgumentParser();ap.add_argument('--check',action='store_true');ap.add_argument('--no-pdf',action='store_true');args=ap.parse_args()
    design();result=verify()
    if args.check:
        saved=json.loads((ROOT/'connectivity.json').read_text())
        assert saved['components']==PARTS,'Generated connectivity differs; rebuild packet'
        from xml.etree import ElementTree as ET
        paths=sorted((ROOT/'schematics').glob('*.svg'));assert len(paths)==6
        for p in paths:ET.parse(p)
        result['svg_documents']=len(paths)
        print(json.dumps(result,indent=2));return
    write_data();files=diagrams()
    if not args.no_pdf:result['pdf']=make_pdf(files)
    print(json.dumps(result,indent=2))


if __name__=='__main__':main()
