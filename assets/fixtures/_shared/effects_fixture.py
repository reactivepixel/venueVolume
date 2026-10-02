"""Legacy/effects batch shells informed by exact product reference stills.

Original visual geometry only: no particle system, laser beam, firing sequence,
pressure simulation or real-world safety/clearance model is provided.
"""
import importlib.util
import math
from pathlib import Path

_s=importlib.util.spec_from_file_location('equipment',Path(__file__).with_name('equipment_fixture.py'))
E=importlib.util.module_from_spec(_s);_s.loader.exec_module(E)
D=E.D
_atmosphere=E.atmosphere
_luminous=E.luminous

def yoke(w,d,h,pivot=.42,top=.98):
    D.PART='Yoke'
    for x in (-1,1):
        D.box('Hanging bracket arm',(w*.04,d*.08,h*(top-pivot)),(x*w*.46,0,h*(top+pivot)/2),'body',.003)
        D.cylinder('Manual bracket knob',w*.046,w*.065,(x*w*.477,0,h*pivot),'rubber','X',32)
        for z in (.65,.81):D.box('Bracket elongated mounting recess',(.002,d*.037,h*.085),(x*w*.482,0,z*h),'rubber',.001)
    D.box('Hanging bracket bridge',(w*.94,d*.08,h*.028),(0,0,h*top),'body',.002)

def carrying_handle(w,d,h,z=.90):
    D.PART='Body'
    for y in (-.15,.09):D.box('Handle riser',(w*.07,d*.045,h*.10),(0,y*d,h*(z-.04)),'rubber',.003)
    D.box('Hand grip',(w*.07,d*.29,h*.03),(0,-.03*d,h*z),'rubber',.004)

def tank(w,d,h,z=.79):
    D.PART='Body'
    mat=E.extra_material('tank','Translucent pale reservoir',(.69,.72,.69),0,.35)
    D.box('Fluid tank',(w*.35,d*.24,h*.25),(0,-d*.27,h*z),mat,.013)
    D.cylinder('Tank cap',w*.065,h*.04,(0,-d*.27,h*(z+.14)),'rubber','Z')
    D.box('Reservoir carry loop',(w*.17,d*.038,h*.08),(0,-d*.25,h*(z+.15)),mat,.008)

def silver_machine(spec):
    p=spec['profile'];w,d,h=spec['width_m'],spec['depth_m'],spec['height_m'];snow=p['family']=='snow'
    bracket=p.get('hanging_bracket',True);top=.66 if bracket else .78
    silver=E.extra_material('silver','Satin silver panels',(.42,.44,.46),.62,.36)
    D.PART='Body'
    D.box('Silver stamped housing',(w*.84,d*.94,h*(top-.08)),(0,0,h*(top+.08)/2),silver,.025)
    D.box('Dark upper deck',(w*.81,d*.91,h*.035),(0,0,h*top),'body',.01)
    E.feet(w,d,h);carrying_handle(w,d,h,top+.105)
    tank(w,d,h,top+.07)
    for x in (-1,1):
        for j in range(12):D.box('Side ventilation slot',(.002,d*.015,h*.07),(x*w*.423,d*(-.20+j*.032),h*.44),'rubber',.0005,(math.radians(-20),0,0))
        for y in (-.42,.41):D.cylinder('Silver panel fastener',w*.009,.002,(x*w*.426,d*y,h*.24),'metal','X',12)
    D.controls(w*.7,d*.95,h*.30,True)
    D.PART='Output'
    if snow:
        D.box('Recessed rectangular snow outlet',(w*.40,.012,h*.34),(0,d*.478,h*.33),'rubber',.004)
        D.box('Snow deflector flap',(w*.38,d*.16,h*.017),(0,d*.52,h*.36),'trim',.001)
    else:
        D.cylinder('Front nozzle surround',w*.093,.012,(0,d*.48,h*.36),'trim')
        D.cylinder('Fog outlet',w*.028,.018,(0,d*.49,h*.36),'rubber')
    parts={'Body':(0,0,h*.42),'Output':(0,d*.49,h*.36)}
    if bracket:yoke(w,d,h);parts['Yoke']=(0,0,h*.42)
    return parts,(0,d*.53,h*.36)

def road_case(spec):
    p=spec['profile'];w,d,h=spec['width_m'],spec['depth_m'],spec['height_m']
    wheels=p.get('casters',False);bottom=.14 if wheels else .035;top=.98
    D.PART='Body';D.box('Black plywood road case',(w*.96,d*.96,h*(top-bottom)),(0,0,h*(top+bottom)/2),'body',.006)
    for z in (bottom,top,.79):
        for x in (-1,1):D.box('Aluminum case rail',(w*.027,d*.99,h*.033),(x*w*.478,0,h*z),'metal',.001)
        for y in (-1,1):D.box('Aluminum case rail',(w*.99,d*.026,h*.033),(0,y*d*.478,h*z),'metal',.001)
    for x in (-1,1):
        for y in (-1,1):
            D.box('Vertical aluminum edge',(w*.025,d*.026,h*(top-bottom)),(x*w*.478,y*d*.477,h*(top+bottom)/2),'metal',.001)
            for z in (bottom,top):D.box('Case corner protector',(w*.093,d*.090,h*.073),(x*w*.45,y*d*.45,h*z),'metal',.008)
            if wheels:D.cylinder('Caster tire',h*.058,w*.065,(x*w*.36,y*d*.35,h*.065),'rubber','X',32)
        D.box('Recessed side handle',(.009,d*.23,h*.16),(x*w*.497,0,h*.53),'metal',.003)
        D.box('Dark handle grip',(.012,d*.17,h*.035),(x*w*.501,0,h*.53),'rubber',.002)
    for x in (-.32,.32):
        D.box('Butterfly latch backing',(w*.13,.007,h*.19),(x*w,d*.50,h*.80),'metal',.004)
        D.box('Butterfly latch center',(w*.053,.012,h*.08),(x*w,d*.507,h*.80),'trim',.002)
    D.PART='Output'
    count=p.get('outlet_count',2)
    for i in range(count):
        x=w*((i+.5)/count-.5)*.58
        D.box('Open upper haze outlet',(w*.55/count,d*.30,.006),(x,d*.08,h*.986),'rubber',.001)
        D.box('Haze outlet lid',(w*.55/count,d*.23,.005),(x,-d*.09,h*1.015),'metal',.001,(math.radians(-18),0,0))
    return {'Body':(0,0,0),'Output':(0,0,h)},(0,0,h)

def laser(spec):
    p=spec['profile'];w,d,h=spec['width_m'],spec['depth_m'],spec['height_m'];D.PART='Body'
    count=p.get('lens_count',1);body_top=.72
    metal=E.extra_material('laser_finish','Anodized enclosure reference finish',(.35,.10,.26),.68,.32) if p.get('dual_mirror_window') else 'body'
    D.box('Laser projector enclosure',(w*.90,d*.96,h*.58),(0,0,h*.34),metal,.007)
    E.feet(w,d,h)
    for x in (-1,1):
        for j in range(10):D.box('Enclosure cooling slot',(.002,d*.018,h*.20),(x*w*.453,d*(-.33+j*.070),h*.40),'rubber',.0005)
    if p.get('dual_mirror_window'):
        D.box('Shared front aperture surround',(w*.49,.012,h*.41),(w*.08,d*.488,h*.34),'metal',.005)
        D.box('Dark dual-mirror cavity',(w*.43,.014,h*.35),(w*.08,d*.497,h*.34),'rubber',.003)
        for x in (-.045,.205):
            D.cylinder('Visible unlit scanner mirror',w*.064,.006,(x*w,d*.508,h*.29),'metal',vertices=40)
            D.box('Internal mirror support',(w*.032,.008,h*.13),(x*w,d*.511,h*.24),'trim',.001,(0,0,math.radians(20)))
        D.cylinder('Infrared remote receiver',w*.021,.004,(-w*.32,d*.497,h*.47),'rubber',vertices=24)
    else:
        for i in range(count):
            x=w*((i+.5)/count-.5)*.80
            size=min(w*.58/count,h*.30)
            D.box('Laser scanning aperture bezel',(size*1.20,.012,size*1.20),(x,d*.488,h*.39),'trim',.003)
            D.box('Unlit laser output window',(size,.015,size),(x,d*.497,h*.39),'rubber',.001)
    D.controls(w*.8,d*.97,h*.29,True)
    D.cylinder('Unconnected safety key surround',w*.023,.005,(w*.31,-d*.486,h*.49),'metal')
    yoke(w*.61,d,h,pivot=.72)
    return {'Body':(0,0,h*.72),'Yoke':(0,0,h*.72)},(0,d*.51,h*.39)

def compact_hazer(spec):
    p=spec['profile'];w,d,h=spec['width_m'],spec['depth_m'],spec['height_m'];variant=p['enclosure'];D.PART='Body'
    blue=E.extra_material('blue','Blue powder coated shell',(.075,.13,.25),.28,.38)
    silver=E.extra_material('silver','Satin alloy shell',(.43,.45,.46),.62,.36)
    if variant=='tiny_fogger':
        D.box('Compact blue fogger',(w*.98,d*.95,h*.96),(0,0,h*.50),blue,.004)
        D.box('Front metal panel',(w*.96,.002,h*.72),(0,d*.48,h*.43),silver,.002)
        D.cylinder('Tiny unlit nozzle',w*.13,.005,(0,d*.49,h*.39),'rubber')
        for x in (-1,1):
            for j in range(15):D.box('Fine cooling perforation',(.001,d*.017,h*.20),(x*w*.493,d*(-.4+j*.05),h*.76),'rubber',.0001)
        return {'Body':(0,0,0)},(0,d*.50,h*.39)
    if variant=='unique_hazer':
        D.box('Blue hazer housing',(w*.93,d*.72,h*.74),(0,d*.10,h*.43),blue,.008)
        D.box('Dark front panel',(w*.91,.01,h*.69),(0,d*.464,h*.42),'body',.004)
        D.box('Fan outlet recess',(w*.35,.01,h*.34),(-w*.14,d*.475,h*.47),'rubber',.002)
        for i in range(9):D.box('Front fan grille wire',(w*.32,.002,.002),(-w*.14,d*.483,h*(.32+i*.035)),'metal',.0002)
        for x in (-1,1):
            D.box('Large side mesh recess',(.004,d*.47,h*.46),(x*w*.469,d*.11,h*.43),'rubber',.002)
            for j in range(12):D.box('Side grille bar',(.005,d*.011,h*.44),(x*w*.472,d*(-.10+j*.037),h*.43),'trim',.0003)
        carrying_handle(w,d,h,.97);tank(w,d,h,.51)
    elif variant=='venue_hazer':
        D.box('Open frame appliance',(w*.93,d*.94,h*.72),(0,0,h*.39),'body',.006)
        D.box('Fluid bay recess',(w*.37,d*.32,h*.53),(-w*.27,d*.33,h*.41),'rubber',.002)
        tank(w*.75,d,h,.40)
        D.controls(w*.62,d*.96,h*.25)
        for j in range(10):
            for k in range(6):D.box('Vent lattice cell',(.002,d*.05,h*.033),(w*.475,d*(-.34+j*.073),h*(.29+k*.062)),'rubber',.0003)
        yoke(w,d,h,pivot=.65)
        return {'Body':(0,0,h*.65),'Yoke':(0,0,h*.65)},(w*.2,d*.5,h*.16)
    elif variant=='fazer_wedge':
        # Distinct high sloping outlet enclosure; no fabricated hanging bracket.
        coords=[(-d*.48,h*.05),(d*.48,h*.05),(d*.48,h*.94),(d*.19,h*.84),(-d*.05,h*.53),(-d*.48,h*.42)]
        for x in (-1,1):D.cheek('Fazer sculpted side',x*w*.475,w*.04,coords)
        D.box('Fazer lower enclosure',(w*.94,d*.95,h*.45),(0,0,h*.26),'body',.015)
        D.box('Raised output chamber',(w*.94,d*.28,h*.80),(0,d*.31,h*.46),'body',.012)
        D.box('Wide dark air outlet',(w*.83,.01,h*.13),(0,d*.46,h*.84),'rubber',.002)
        D.box('Wide outlet baffle',(w*.88,d*.10,.008),(0,d*.44,h*.91),'trim',.001)
        carrying_handle(w,d,h,.79)
    else:
        D.box('Silver lower hazer',(w*.96,d*.95,h*.64),(0,0,h*.36),silver,.008)
        D.box('Dark upper chamber',(w*.96,d*.96,h*.19),(0,0,h*.77),'body',.012)
        carrying_handle(w,d,h,.99)
        D.cylinder('Reservoir cap',w*.065,h*.04,(w*.27,-d*.24,h*.90),'rubber','Z')
        D.box('Horizontal haze output',(w*.80,.015,h*.16),(0,d*.49,h*.72),'rubber',.001)
        for i in range(7):D.box('Outlet louver',(.007,.02,h*.13),(w*(-.32+i*.106),d*.50,h*.72),'trim',.001)
    E.feet(w,d,h)
    return {'Body':(0,0,0)},(0,d*.51,h*.60)

def bubble_bank(spec):
    w,d,h=spec['width_m'],spec['depth_m'],spec['height_m'];D.PART='Body'
    silver=E.extra_material('silver','Brushed silver bubble chassis',(.44,.46,.48),.65,.34)
    D.box('Bubble fluid tray',(w*.90,d*.92,h*.30),(0,0,h*.19),silver,.005)
    D.box('Black rotor opening',(w*.88,.008,h*.25),(0,d*.46,h*.43),'rubber',.001)
    D.box('Rear fan enclosure',(w*.90,d*.48,h*.20),(0,-d*.23,h*.45),silver,.006)
    D.box('Raised output hood',(w*.92,d*.14,h*.04),(0,d*.36,h*.59),silver,.002,(math.radians(-20),0,0))
    D.PART='Rotor';r=min(h*.18,d*.40)
    for bank in range(3):
        for twin in (-1,1):
            x=w*((bank-1)*.28+twin*.026)
            D.ring('Double bubble wheel',r,.002,(x,d*.10,h*.40),'trim','X')
            for k in range(12):
                a=k*math.tau/12
                D.ring('Bubble wand opening',r*.16,.0015,(x,d*.10+r*.77*math.sin(a),h*.40+r*.77*math.cos(a)),'trim','X')
    yoke(w,d,h,pivot=.40)
    E.feet(w,d,h)
    return {'Body':(0,0,h*.40),'Rotor':(0,d*.10,h*.40),'Yoke':(0,0,h*.40)},(0,d*.49,h*.42)

def spark_box(spec):
    p=spec['profile'];w,d,h=spec['width_m'],spec['depth_m'],spec['height_m'];D.PART='Body'
    D.box('Spark appliance metal enclosure',(w*.97,d*.97,h*.94),(0,0,h*.49),'body',.007)
    E.feet(w,d,h)
    for x in (-1,1):
        D.box('Inset side handle',(.006,d*.25,h*.12),(x*w*.49,-d*.10,h*.74),'rubber',.002)
        D.box('Side handle grip',(.012,d*.18,h*.034),(x*w*.496,-d*.10,h*.74),'trim',.002)
        for z in range(8):
            for y in range(12):D.box('Vent perforation',(.003,d*.013,h*.01),(x*w*.489,d*(-.29+y*.050),h*(.15+z*.025)),'rubber',.0002)
        for y in (-1,1):D.cylinder('Lid screw',w*.009,.003,(x*w*.43,y*d*.41,h*.967),'metal','Z',12)
    # Distinct closed fill cap and separate unlit output collar, not optics.
    D.cylinder('Closed hopper cap',min(w,d)*.125,h*.030,(-w*.21,-d*.22,h*.977),'trim','Z')
    D.PART='Output'
    D.cylinder('Unlit effect outlet',min(w,d)*.055,h*.029,(w*.19,d*.19,h*.977),'trim','Z')
    D.cylinder('Dark outlet bore',min(w,d)*.038,.002,(w*.19,d*.19,h*.993),'rubber','Z')
    return {'Body':(0,0,0),'Output':(w*.19,d*.19,h*.99)},(w*.19,d*.19,h)

def sealed_cabinet(spec):
    w,d,h=spec['width_m'],spec['depth_m'],spec['height_m'];D.PART='Body'
    grey=E.extra_material('cabinet','Grey coated steel cabinet',(.40,.42,.35),.15,.43)
    D.box('Weather enclosure',(w*.94,d*.96,h*.91),(0,0,h*.46),grey,.004)
    D.box('Hinged front door',(w*.95,.008,h*.89),(0,d*.493,h*.46),grey,.003)
    for z in (.12,.76):
        D.box('Door latch plate',(w*.048,.009,h*.075),(w*.43,d*.515,h*z),'metal',.003)
        D.cylinder('Latch center',w*.011,.004,(w*.43,d*.522,h*z),'trim',vertices=24)
    for x in (-1,1):
        D.box('Rear mounting tab',(w*.16,.008,h*.09),(x*w*.32,-d*.44,h*.955),grey,.001)
        D.cylinder('Mounting hole',w*.018,.009,(x*w*.32,-d*.43,h*.963),'rubber',vertices=20)
    D.box('Plain identification plate',(w*.25,.001,h*.26),(w*.23,d*.505,h*.48),'highlight',.001)
    return {'Body':(0,0,0)},(0,-d*.5,h*.25)

def atmosphere(spec):
    variant=spec['profile'].get('enclosure')
    if variant=='silver_machine':return silver_machine(spec)
    if variant=='road_case':return road_case(spec)
    if variant in ('tiny_fogger','unique_hazer','venue_hazer','fazer_wedge','silver_hazer'):return compact_hazer(spec)
    if variant=='bubble_bank':return bubble_bank(spec)
    if variant=='spark_box':return spark_box(spec)
    if variant=='sealed_cabinet':return sealed_cabinet(spec)
    return _atmosphere(spec)

def luminous(spec):
    if spec['profile'].get('enclosure')=='laser_box':return laser(spec)
    return _luminous(spec)

def build(spec,folder):
    E.atmosphere=atmosphere;E.luminous=luminous
    return E.build(spec,folder)
