"""Image-informed show-equipment geometry; shares the proven fixture export path.

No particle, beam, combustion, rigging or electrical operation is implemented.
All small mechanical details are approximations, never engineering specifications.
"""
import importlib.util,math
from pathlib import Path
import bpy
from mathutils import Vector
_s=importlib.util.spec_from_file_location('fixture_detail',Path(__file__).with_name('detailed_fixture.py'))
D=importlib.util.module_from_spec(_s);_s.loader.exec_module(D)
_static=D.static
_linear=D.linear

def extra_material(key,name,color,metallic=0,roughness=.4):
    material=D.material(name,color,metallic,roughness)
    D.M[key]=material
    return material

def beam(name,a,b,r,mat='metal'):
    a,b=Vector(a),Vector(b);o=D.cylinder(name,r,(b-a).length,(a+b)/2,mat,'Z',24)
    o.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler();return o

def feet(w,d,h):
    for x in (-1,1):
        for y in (-1,1):D.cylinder('Rubber foot',min(w,d)*.05,h*.06,(x*w*.36,y*d*.34,h*.03),'rubber','Z',24)

def handles(w,d,h):
    for x in (-1,1):
        for z in (.57,.78):D.box('Handle boss',(w*.04,d*.09,h*.06),(x*w*.485,0,h*z),'trim')
        D.box('Recessed carry handle',(w*.035,d*.06,h*.22),(x*w*.51,0,h*.67),'rubber')

def casing(w,d,h):
    D.PART='Body';D.box('Formed machine enclosure',(w*.94,d*.95,h*.86),(0,0,h*.49),'body',.016)
    feet(w,d,h);handles(w,d,h)
    for x in (-1,1):
        for j in range(10):D.box('Side cooling slot',(.003,d*.028,h*.14),(x*w*.471,-d*.29+j*d*.064,h*.43),'rubber',.0004)
    for x in (-1,1):
        for z in (.2,.8):D.cylinder('Panel fastener',min(w,h)*.011,.003,(x*w*.42,d*.479,h*z),'metal',vertices=12)
    D.controls(w*.8,d*.96,h*.30,True)

def atmosphere(spec):
    p=spec['profile'];f=p['family'];w,d,h=spec['width_m'],spec['depth_m'],spec['height_m']
    ident=spec['id'];D.PART='Body'
    if 'mdg/' in ident:
        purple=extra_material('violet','Violet powder coat',(.20,.095,.28),.22,.36)
        D.box('Long atomizer enclosure',(w*.94,d*.91,h*.79),(0,0,h*.435),purple,.008)
        D.box('Raised outlet chamber',(w*.96,d*.20,h*.65),(0,d*.395,h*.58),purple,.004)
        D.box('Open chamber recess',(w*.79,d*.17,.008),(0,d*.395,h*.912),'rubber',.001)
        D.cylinder('Reservoir cap',w*.16,h*.065,(0,-d*.27,h*.865),'metal','Z')
        for y in (-.15,.08):D.box('Top handle upright',(w*.09,d*.03,h*.16),(0,y*d,h*.90),'rubber',.003)
        D.box('Top carry handle',(w*.09,d*.26,h*.035),(0,-d*.035,h*.981),'rubber',.003)
        for x in (-1,1):
            for y in (-.39,.1):D.cylinder('Housing screw',w*.02,.003,(x*w*.476,y*d,h*.16),'metal','X',12)
        return {'Body':(0,0,0)},(0,d*.5,h*.86)
    if f=='fogger':
        silver=extra_material('silver','Brushed silver enclosure',(.40,.43,.46),.7,.32)
        D.box('Silver fogger enclosure',(w*.82,d*.94,h*.59),(0,0,h*.37),silver,.015)
        D.box('Black upper engine',(w*.76,d*.72,h*.12),(0,-d*.07,h*.715),'body',.024)
        D.box('Reservoir',(w*.34,d*.23,h*.23),(0,-d*.27,h*.72),'highlight',.014)
        D.cylinder('Tank cap',w*.075,h*.06,(0,-d*.27,h*.856),'rubber','Z')
        feet(w,d,h)
        for i in range(11):D.box('Upper cooling slot',(w*.18,d*.009,.002),(-w*.21,d*(-.17+i*.038),h*.773),'rubber',0)
        D.PART='Yoke'
        for x in (-1,1):
            D.box('Pivoting bracket side',(w*.045,d*.07,h*.55),(x*w*.455,-d*.02,h*.695),'body',.004)
            D.cylinder('Bracket locking knob',w*.05,w*.075,(x*w*.475,-d*.02,h*.43),'rubber','X')
        D.box('Bracket bridge',(w*.96,d*.07,h*.035),(0,-d*.02,h*.98),'body',.003)
        D.PART='Output';D.box('Front nozzle block',(w*.27,d*.065,h*.27),(0,d*.485,h*.42),'body',.008)
        D.cylinder('Small fog outlet',w*.035,.009,(0,d*.525,h*.42),'rubber')
        return {'Body':(0,0,0),'Yoke':(0,0,h*.43),'Output':(0,d*.525,h*.42)},(0,d*.53,h*.42)
    if f=='co2_jet':
        if 'co2jet-ii' in ident or 'co2-jet-ii' in ident:
            D.box('Formed main valve enclosure',(w*.96,d*.57,h*.94),(0,d*.17,h*.50),'body',.008)
            D.box('Rear mounting plate',(w*.96,d*.03,h*.98),(0,-d*.477,h*.50),'body',.002)
            D.box('Base tray',(w*.96,d*.96,h*.03),(0,0,h*.018),'body',.002)
            D.cylinder('Recessed upward outlet',w*.11,h*.74,(0,-d*.31,h*.52),'trim','Z')
            D.cylinder('Unlit outlet bore',w*.098,.001,(0,-d*.31,h*.896),'rubber','Z')
            for x in (-1,1):
                for z in (.12,.86):D.cylinder('Housing fastener',w*.014,.003,(x*w*.40,d*.461,h*z),'metal',vertices=12)
                D.box('Power connector weather cap',(w*.15,.011,h*.32),(w*(-.24+x*.085),d*.477,h*.27),'rubber',.003)
            D.cylinder('Unconnected gas inlet',w*.040,.025,(w*.29,d*.49,h*.32),'metal')
            return {'Body':(0,0,0)},(0,-d*.31,h*.90)
        D.box('Jet base plate',(w,d*.91,h*.035),(0,0,h*.02),'metal',.001)
        D.box('Valve housing',(w*.62,d*.43,h*.60),(0,-d*.18,h*.32),'body',.003)
        D.PART='Output';a=(0,d*.10,h*.10);b=(0,d*.32,h*.94);r=w*.14
        tube=beam('Angled jet outlet tube',a,b,r,'body')
        tip=D.cylinder('Unlit outlet bore',r*.79,.004,b,'rubber','Z');tip.rotation_euler=tube.rotation_euler
        return {'Body':(0,0,0),'Output':a},b
    if f=='snow':
        D.box('Road case body',(w*.95,d*.93,h*.70),(0,0,h*.49),'body',.006)
        for z in (.15,.80,.88):
            for x in (-1,1):D.box('Case edge trim',(w*.025,d*.95,h*.025),(x*w*.48,0,h*z),'metal',.001)
            for y in (-1,1):D.box('Case edge trim',(w*.95,d*.025,h*.025),(0,y*d*.47,h*z),'metal',.001)
        for x in (-1,1):
            for y in (-1,1):
                D.box('Vertical case corner',(w*.023,d*.023,h*.72),(x*w*.48,y*d*.47,h*.51),'metal',.001)
                D.cylinder('Case caster',h*.063,w*.05,(x*w*.36,y*d*.35,h*.073),'rubber','X',24)
        D.box('Closed transport lid',(w*.95,d*.94,h*.08),(0,0,h*.92),'body',.004)
        D.box('Recessed side handle',(.009,d*.26,h*.13),(w*.483,0,h*.53),'metal',.003)
        return {'Body':(0,0,0)},(0,d*.48,h*.75)
    if f=='bubble':
        silver=extra_material('silver','Silver bubble machine enclosure',(.43,.45,.46),.55,.34)
        D.box('Bubble machine chassis',(w*.86,d*.94,h*.60),(0,0,h*.36),silver,.009)
        D.box('Dark bubble opening',(w*.73,.01,h*.30),(0,d*.478,h*.47),'rubber',.002)
        for i in range(12):
            a=i*math.tau/12;D.ring('Bubble wheel loop',w*.040,.002,(w*.24*math.sin(a),d*.486,h*.40+w*.24*math.cos(a)),'trim')
        D.box('Angled output hood',(w*.85,d*.26,h*.04),(0,d*.42,h*.63),'body',.002,(math.radians(-32),0,0))
        for x in (-1,1):D.box('Raised hanging bracket',(w*.036,d*.075,h*.54),(x*w*.46,-d*.03,h*.71),'body',.003)
        D.box('Bracket top',(w*.95,d*.075,h*.03),(0,-d*.03,h*.975),'body',.003)
        feet(w,d,h);return {'Body':(0,0,0)},(0,d*.5,h*.48)
    casing(w,d,h);D.PART='Output';r=min(w,h)*.15
    if f in ('jet','co2_jet','spark','flame'):
        D.cylinder('Vertical outlet collar',r*.75,h*.035,(0,0,h*.94),'trim','Z')
        D.cylinder('Unlit outlet aperture',r*.48,h*.01,(0,0,h*.965),'rubber','Z')
        if p.get('led_ring',f=='jet'):
            for j in range(3):
                for i in range(9):D.cylinder('Accent LED lens',min(w*.034,d*.09),.007,(w*(-.38+i*.095),d*(-.25+j*.24),h*.94),'glass','Z',24)
            for z in (.34,.65):D.box('Stacked housing seam',(w*.95,d*.956,h*.012),(0,0,h*z),'rubber',.001)
        outlet=(0,0,h*.98)
    elif f=='bubble':
        D.cylinder('Bubble fan recess',min(w,h)*.30,.015,(0,d*.482,h*.55),'rubber')
        for k in range(3):D.ring('Outlet fan guard',min(w,h)*(.13+k*.055),.003,(0,d*.495,h*.55),'metal')
        for i in range(10):
            a=i*math.tau/10;D.ring('Bubble wheel ring',min(w,h)*.045,.003,(w*.23*math.sin(a),d*.50,h*.52+w*.23*math.cos(a)),'trim')
        D.box('Fluid tray rim',(w*.78,d*.18,h*.08),(0,d*.40,h*.17),'trim');outlet=(0,d*.53,h*.55)
    elif f=='hazer':
        D.box('Haze output recess',(w*.52,.02,h*.32),(0,d*.48,h*.40),'rubber',.004)
        D.box('Recessed output scoop',(w*.48,d*.08,h*.03),(0,d*.49,h*.25),'trim',.001,(math.radians(15),0,0))
        for y in (-.15,.11):D.box('Carry handle foot',(w*.12,d*.035,h*.13),(0,y*d,h*.96),'rubber',.003)
        D.box('Carry handle',(w*.12,d*.30,h*.035),(0,-d*.02,h*1.016),'rubber',.003)
        outlet=(0,d*.52,h*.64)
    else:
        if f=='low_fog':r=min(w,h)*.25
        if f=='snow':r=min(w,h)*.22
        D.cylinder('Outlet pipe',r,d*.10,(0,d*.46,h*.52),'trim')
        D.cylinder('Dark nozzle bore',r*.79,.006,(0,d*.515,h*.52),'rubber')
        D.ring('Nozzle lip',r*.95,r*.055,(0,d*.522,h*.52),'metal')
        outlet=(0,d*.53,h*.52)
    D.PART='Body'
    if f not in ('co2_jet','spark','flame'):
        D.box('Reservoir inspection window',(w*.12,.006,h*.34),(w*.28,-d*.483,h*.66),'screen',.002)
        D.cylinder('Fluid cap',min(w,d)*.085,h*.045,(w*.25,-d*.22,h*.955),'rubber','Z',32)
    if f=='low_fog':
        for z in range(22):
            for x in (-1,1):D.box('Moulded horizontal case rib',(w*.023,d*.91,h*.010),(x*w*.475,0,h*(.12+z*.034)),'trim',.001)
        for x in (-1,1):
            for y in (-1,1):
                for z in (.11,.89):D.box('Protective corner',(w*.16,d*.12,h*.14),(x*w*.43,y*d*.43,h*z),'trim',.015)
    return {'Body':(0,0,0),'Output':outlet},outlet

def fan(spec):
    w,d,h=spec['width_m'],spec['depth_m'],spec['height_m'];r=min(w*.45,h*.40);z=h*.56;D.PART='Body'
    D.cylinder('Fan drum',r,d*.72,(0,0,z),'body');D.cylinder('Dark fan opening',r*.95,.008,(0,d*.368,z),'rubber')
    if 'entour-cyclone' in spec['id']:
        for x in (-1,1):D.box('Square front frame side',(w*.11,.015,r*2.15),(x*w*.43,d*.36,z),'body',.02)
        for side in (-1,1):D.box('Square front frame edge',(w*.89,.015,h*.07),(0,d*.36,z+side*r*1.035),'body',.015)
    D.PART='Rotor'
    D.cylinder('Motor hub',r*.19,d*.50,(0,0,z),'trim')
    for i in range(7):
        a=i*math.tau/7;D.box('Fan blade',(r*.20,.015,r*.65),(r*.45*math.sin(a),d*.32,z+r*.45*math.cos(a)),'trim',.008,(0,a,.16))
    D.PART='Guard'
    for side in (-1,1):
        for i in range(1,9):D.ring('Circular wire guard',r*i/9,r*.009,(0,side*d*.38,z),'metal')
        for i in range(8):
            a=i*math.tau/8;beam('Radial guard wire',(0,side*d*.38,z),(r*.94*math.sin(a),side*d*.38,z+r*.94*math.cos(a)),r*.008)
    D.PART='Stand'
    for side in (-1,1):
        D.box('Floor skid',(w*.09,d*.91,h*.045),(side*w*.38,0,h*.025),'rubber')
        D.box('Tilt bracket',(w*.045,d*.10,h*.5),(side*w*.465,0,h*.29),'body')
    return {'Body':(0,0,z),'Rotor':(0,0,z),'Guard':(0,0,z),'Stand':(0,0,0)},(0,d*.4,z)

def confetti(spec):
    w,d,h=spec['width_m'],spec['depth_m'],spec['height_m'];D.PART='Base'
    D.box('Launcher appliance body',(w*.88,d*.78,h*.83),(0,-d*.06,h*.44),'body',.010)
    for x in (-1,1):D.box('U bracket side',(w*.07,d*.95,h*.83),(x*w*.46,0,h*.45),'trim',.004)
    D.PART='Output';r=min(w,d)*.27;a=(0,d*.10,h*.20);b=(0,d*.28,h*.91)
    tube=beam('Unloaded cannon socket',a,b,r,'body')
    hole=D.cylinder('Empty cannon socket bore',r*.85,.003,b,'rubber','Z');hole.rotation_euler=tube.rotation_euler
    return {'Base':(0,0,0),'Output':a},b

def luminous(spec):
    p=spec['profile'];f=p['family'];w,d,h=spec['width_m'],spec['depth_m'],spec['height_m'];D.PART='Body'
    if f=='mirror_motor':
        D.cylinder('Circular mounting flange',w*.49,h*.10,(0,0,h*.94),'body','Z')
        D.cylinder('Motor housing',w*.43,h*.44,(0,0,h*.67),'body','Z')
        D.shell('Tapered motor cap',[(-h*.19,w*.27,w*.27),(h*.19,w*.36,w*.36)],(0,0,0),'body')
        # Cap is a Z-oriented truncated cone; the shaft is shown unconnected.
        for o in D.OBJECTS[-1:]:o.rotation_euler.x=math.pi/2;o.location.z=h*.37
        D.cylinder('Output shaft',w*.035,h*.21,(0,0,h*.105),'metal','Z',24)
        return {'Body':(0,0,0)},(0,0,0)
    if f=='mirror_ball':
        r=min(w,d,h)*.499;center=Vector((0,0,h/2));step=math.pi/32
        bpy.ops.mesh.primitive_uv_sphere_add(segments=64,ring_count=32,location=center)
        o=bpy.context.object;o.scale=(r*.996,)*3;D.register(o,'Sphere beneath mirror mosaic','trim',True)
        for j in range(32):
            theta=step*(j+.5);n=max(6,round(math.tau*math.sin(theta)/step));verts=[];faces=[]
            for i in range(n):
                phi=math.tau*i/n;normal=Vector((math.sin(theta)*math.cos(phi),math.sin(theta)*math.sin(phi),math.cos(theta)))
                tangent=Vector((-math.sin(phi),math.cos(phi),0));vertical=normal.cross(tangent)
                a=math.tau*r*math.sin(theta)/n*.96;b=r*step*.96;c=center+normal*r;offset=len(verts)
                verts.extend(tuple(c+tangent*(sx*a/2)+vertical*(sy*b/2)+normal*(sz*.0005)) for sx in (-1,1) for sy in (-1,1) for sz in (-1,1))
                faces.extend(tuple(offset+k for k in f) for f in ((0,1,3,2),(4,6,7,5),(0,4,5,1),(2,3,7,6),(0,2,6,4),(1,5,7,3)))
            mesh=bpy.data.meshes.new('Mirror tile ring');mesh.from_pydata(verts,[],faces);mesh.update()
            o=bpy.data.objects.new('Individual mirror tiles latitude '+str(j),mesh);bpy.context.collection.objects.link(o);D.register(o,o.name,'metal')
        # Sphere-only dimensional variant; undimensioned suspension excluded.
        return {'Body':(0,0,h*.49)},(0,0,h*.49)
    if f in ('tube','pixel_strip','uv'):
        if f=='tube':
            horizontal=w>h
            length=w if horizontal else h;r=min(d,h if horizontal else w)*.47;axis='X' if horizontal else 'Z'
            D.cylinder('Diffused pixel tube',r,length*.95,(0,0,h*.5),'highlight',axis)
            for s in (-1,1):
                center=(s*w*.487,0,h*.5) if horizontal else (0,0,h*(.5+s*.487))
                D.cylinder('Tube end cap',r*1.025,length*.024,center,'trim',axis)
        elif f=='pixel_strip':
            D.box('Flexible tape substrate',(w,d,h*.25),(0,0,h*.125),'rubber',0)
            n=p.get('lens_count',170)
            for i in range(n):
                x=-w/2+(i+.5)*w/n
                D.box('Pixel package',(min(w*.8/n,d*.45),d*.5,h*.75),(x,0,h*.625),'highlight',0)
                D.box('Driver package',(min(w*.25/n,d*.18),d*.3,h*.3),(x+w*.32/n,0,h*.40),'trim',0)
        else:
            D.box('Linear chassis',(w,d*.9,h*.8),(0,0,h*.5),'body',.003)
            for j in range(3):
                for i in range(4):
                    x=w*(-.32+i*.215);z=h*(.25+j*.25)
                    D.box('UV emitter surround',(w*.125,.012,h*.16),(x,d*.46,z),'metal',.002)
                    D.box('UV optic',(w*.093,.015,h*.125),(x,d*.472,z),'aura',.001)
            for x in (-1,1):
                D.box('Floor yoke foot',(w*.06,d*.95,h*.027),(x*w*.47,0,h*.024),'body',.002)
                D.box('Yoke arm',(w*.04,d*.09,h*.46),(x*w*.47,0,h*.25),'body',.002)
        return {'Body':(0,0,0)},(0,d*.51,h*.5)
    if f=='practical':
        D.cylinder('Edison screw base',w*.19,h*.22,(0,0,h*.12),'metal','Z')
        for i in range(6):D.ring('Base thread',w*.19,w*.012,(0,0,h*(.035+i*.034)),'trim','Z')
        bpy.ops.mesh.primitive_cone_add(vertices=64,radius1=w*.20,radius2=w*.49,depth=h*.40,location=(0,0,h*.43));D.register(bpy.context.object,'Electronic lamp housing','body',True)
        bpy.ops.mesh.primitive_uv_sphere_add(segments=48,ring_count=24,location=(0,0,h*.73));o=bpy.context.object;o.scale=(w*.5,d*.5,h*.27);D.register(o,'Diffusing bulb dome','highlight',True)
        D.box('Small lamp control strip',(w*.14,.002,h*.15),(0,d*.352,h*.46),'trim',.001)
        D.cylinder('Lamp pushbutton',w*.035,.003,(0,d*.358,h*.47),'rubber',vertices=20)
        return {'Body':(0,0,0)},(0,0,h*.80)
    if f in ('laser','scanner'):
        if f=='scanner':
            r=min(w*.42,h*.34);z=h*.40
            D.shell('Scanner lamp body',[(-d*.48,r*.6,r*.6),(-d*.36,r,r),(d*.15,r,r),(d*.29,r*.65,r*.65)],(0,0,z),'body',32)
            for i in range(9):D.ring('Lamp housing cooling rib',r*.99,r*.012,(0,d*(-.33+i*.026),z),'trim')
            D.PART='Lens';D.optics(r*.64,d*.29,z)
            D.PART='Mirror';D.box('Mirror carrier',(w*.80,.014,h*.41),(0,d*.44,h*.63),'body',.012,(math.radians(-25),0,0))
            D.box('Moving scanner mirror',(w*.71,.016,h*.34),(0,d*.452,h*.63),'metal',.004,(math.radians(-25),0,0))
            return {'Body':(0,0,z),'Lens':(0,d*.29,z),'Mirror':(0,d*.44,h*.63)},(0,d*.47,h*.63)
        casing(w,d,h)
        if f=='laser':
            D.box('Laser output bezel',(w*.30,.015,h*.30),(-w*.15,d*.48,h*.60),'trim')
            D.box('Unlit scanning aperture',(w*.22,.018,h*.22),(-w*.15,d*.495,h*.60),'rubber')
            D.cylinder('Key-switch surround',w*.025,.005,(w*.29,-d*.48,h*.65),'metal')
        else:
            D.PART='Mirror';D.box('Moving mirror carrier',(w*.63,.022,h*.23),(0,d*.46,h*.81),'trim',.007)
            D.box('Scanner mirror',(w*.55,.024,h*.18),(0,d*.48,h*.81),'metal',.003)
        D.PART='Yoke'
        for x in (-1,1):D.box('Laser hanging frame side',(w*.035,d*.07,h*.80),(x*w*.46,0,h*.73),'body',.002)
        D.box('Laser frame bridge',(w*.96,d*.07,h*.03),(0,0,h*1.115),'body',.002)
        return {'Body':(0,0,0),'Yoke':(0,0,h*.5)},(0,d*.52,h*.6)
    # PC/Fresnel, conventional PAR, cyc flood and manual followspot.
    if f=='cyc':
        for x in (-1,1):D.cheek('Curved housing side',x*w*.45,w*.08,[(-d*.47,0),(d*.47,0),(d*.38,h*.70),(-d*.17,h*.95),(-d*.47,h*.88)])
        D.box('Asymmetric reflector housing',(w*.89,d*.73,h*.54),(0,-d*.03,h*.34),'body',.012)
        for i in range(14):D.box('Convection heatsink fin',(w*.025,d*.5,h*.08),(w*(-.40+i*.061),-d*.12,h*.66),'trim',.001)
        D.PART='Lens'
        for i in range(6):D.box('Linear optic strip',(w*.84,.01,h*.028),(0,d*.39,h*(.21+i*.060)),'glass',.001)
        D.box('Spill-control flap',(w*.92,d*.29,h*.018),(0,d*.41,h*.87),'body',.002,(math.radians(-35),0,0))
        return {'Body':(0,0,0),'Lens':(0,d*.42,h*.46)},(0,d*.44,h*.46)
    if f=='blinder':
        D.box('Four-pod chassis',(w*.65,d*.68,h*.68),(0,0,h*.52),'body',.012)
        for x in (-1,1):
            for z in (.25,.75):
                D.PART='Pod_'+str(x)+'_'+str(z)
                r=min(w,h)*.22;cx=x*w*.25;cz=z*h
                D.cylinder('Independent blinder pod',r,d*.78,(cx,0,cz),'body')
                D.ring('Pod retaining ring',r*.92,r*.045,(cx,d*.4,cz),'trim')
                D.cylinder('Reflector',r*.88,.012,(cx,d*.401,cz),'metal')
                D.cylinder('COB source',r*.54,.014,(cx,d*.411,cz),'highlight')
                for j in range(-4,5):
                    t=j*r*.19;span=math.sqrt(max(0,(r*.89)**2-t*t))
                    beam('Protective grille',(cx+t,d*.432,cz-span),(cx+t,d*.432,cz+span),.0011,'trim')
        pivots={'Body':(0,0,0)}
        for x in (-1,1):
            for z in (.25,.75):pivots['Pod_'+str(x)+'_'+str(z)]=(x*w*.25,0,z*h)
        # USD prim components must be valid identifiers.
        fixed={k.replace('-','n').replace('.','_'):v for k,v in pivots.items()}
        for o in D.OBJECTS:o['fixture_part']=o['fixture_part'].replace('-','n').replace('.','_')
        return fixed,(0,d*.44,h*.5)
    if f=='flood':
        z=h*.38;r=min(w*.47,h*.36)
        D.shell('Open concave scoop reflector',[(-d*.47,r*.15,r*.15),(-d*.35,r*.63,r*.63),(-d*.12,r*.9,r*.9),(d*.45,r,r),(d*.45,r*.96,r*.96),(-d*.12,r*.86,r*.86),(-d*.31,r*.59,r*.59),(-d*.40,r*.14,r*.14)],(0,0,z),'metal')
        D.cylinder('Incandescent lamp socket',r*.14,d*.15,(0,-d*.30,z),'trim')
        bpy.ops.mesh.primitive_uv_sphere_add(segments=32,ring_count=16,location=(0,-d*.15,z));o=bpy.context.object;o.scale=(r*.18,d*.15,r*.18);D.register(o,'Incandescent bulb envelope','highlight',True)
        for x in (-1,1):D.box('Color frame edge',(w*.035,d*.026,h*.74),(x*w*.47,d*.46,z),'body',.001)
        D.PART='Yoke'
        for x in (-1,1):D.box('Suspension yoke',(w*.028,d*.04,h*.60),(x*w*.19,-d*.36,h*.68),'metal',.002)
        D.box('Yoke bridge',(w*.4,d*.04,h*.03),(0,-d*.36,h*.975),'metal',.001)
        return {'Body':(0,0,0),'Yoke':(0,-d*.36,h*.40)},(0,d*.46,z)
    if f=='followspot':
        r=min(w*.34,h*.30);z=h*.46
        D.shell('Long followspot body',[(-d*.46,r*.74,r*.78),(-d*.32,r,r),(d*.12,r,r),(d*.46,r*.74,r*.74)],(0,0,z),'body',16)
        for y in (-.28,-.2,-.12):D.ring('Engine cooling collar',r*.99,r*.025,(0,d*y,z),'trim')
        for x in (-1,1):D.box('Operator handle',(w*.08,d*.55,h*.045),(x*w*.43,-d*.06,z),'rubber')
        D.PART='Yoke';D.box('Cradle',(w*.87,d*.18,h*.06),(0,0,h*.06),'body')
        for x in (-1,1):D.box('Cradle side',(w*.07,d*.14,h*.37),(x*w*.4,0,h*.24),'body')
        D.PART='Lens';D.optics(r*.71,d*.47,z)
        for x in (-1,1):D.box('Color boomerang cheek',(w*.025,d*.13,h*.54),(x*w*.33,d*.41,z),'body',.003)
        D.box('Color boomerang lower rail',(w*.70,d*.13,h*.035),(0,d*.41,z-r*.95),'body',.003)
        return {'Body':(0,0,z),'Yoke':(0,0,h*.06),'Lens':(0,d*.47,z)},(0,d*.49,z)
    if f=='pc':
        z=h*.35
        D.box('PC lantern housing',(w*.72,d*.87,h*.48),(0,0,z),'body',.028)
        for i in range(12):
            for x in (-1,1):D.box('Cooling slit',(.003,d*.025,h*.09),(x*w*.364,-d*.30+i*d*.055,z),'rubber',.0005)
        D.PART='Lens';D.optics(min(w*.28,h*.22),d*.45,z,1,False)
        for x in (-1,1):D.box('Front cassette side',(w*.025,.014,h*.47),(x*w*.36,d*.46,z),'trim',.001)
        D.PART='Yoke'
        for x in (-1,1):
            D.box('Tall yoke',(w*.035,d*.075,h*.64),(x*w*.435,-d*.06,h*.66),'body',.002)
            D.cylinder('Tilt knob',w*.055,w*.1,(x*w*.45,-d*.06,z),'rubber','X')
        D.box('Yoke bridge',(w*.91,d*.075,h*.025),(0,-d*.06,h*.985),'body',.002)
        return {'Body':(0,0,z),'Lens':(0,d*.45,z),'Yoke':(0,-d*.06,z)},(0,d*.47,z)
    if f in ('par_can','pinspot'):
        r=min(w*.40,h*.29);z=h*.32
        D.shell('Simple lamp can',[(-d*.49,r*.60,r*.60),(-d*.39,r*.9,r*.9),(-d*.29,r,r),(d*.46,r,r)],(0,0,z),'body',48)
        D.ring('Front rolled lip',r,r*.036,(0,d*.468,z),'metal')
        D.PART='Lens';D.cylinder('Lamp face',r*.91,.006,(0,d*.47,z),'glass')
        if f=='par_can':
            for i in range(18):
                a=i*math.tau/18
                D.cylinder('Rear ventilation aperture',r*.035,.002,(r*.94*math.sin(a),-d*.40,z+r*.94*math.cos(a)),'rubber',vertices=12)
            for x in (-1,1):D.box('Color frame runner',(w*.035,d*.04,r*2.16),(x*r*1.04,d*.465,z),'trim',.001)
        D.PART='Yoke'
        for x in (-1,1):
            D.box('Simple yoke side',(w*.038,d*.05,h*.61),(x*w*.455,-d*.1,h*.665),'body',.002)
            D.cylinder('Yoke locking fastener',w*.04,w*.08,(x*w*.47,-d*.1,z),'metal','X',24)
        D.box('Yoke mounting bridge',(w*.95,d*.05,h*.028),(0,-d*.1,h*.985),'body',.002)
        return {'Body':(0,0,z),'Lens':(0,d*.47,z),'Yoke':(0,-d*.1,z)},(0,d*.478,z)
    proxy=dict(spec);proxy['profile']={**p,'family':'par' if f in ('par_can','pinspot','pc') else 'fresnel','lens_count':1}
    return _static(proxy)

def infrastructure(spec):
    p=spec['profile'];f=p['family'];w,d,h=spec['width_m'],spec['depth_m'],spec['height_m'];D.PART='Body'
    if f=='power_supply':
        D.box('Perforated metal supply enclosure',(w*.98,d*.97,h*.90),(0,0,h*.49),'metal',.002)
        for i in range(3):
            for j in (-1,1):D.box('Cover ventilation slot',(w*.028,d*.28,.001),(w*(-.37+i*.048),j*d*.22,h*.945),'rubber',.0003)
        for i in range(13):D.box('Side ventilation slot',(w*.012,.001,h*.34),(w*(-.41+i*.061),d*.487,h*.44),'rubber',.0003)
        r=d*.33;D.cylinder('Cooling fan recess',r,.001,(w*.22,0,h*.95),'rubber','Z')
        for k in range(1,6):D.ring('Fan wire guard',r*k/6,.001,(w*.22,0,h*.98),'metal','Z')
        D.box('Terminal insulator',(w*.06,d*.91,h*.45),(-w*.48,0,h*.33),'rubber',.001)
        for j in range(9):
            D.box('Terminal divider',(w*.07,d*.011,h*.42),(-w*.48,d*(-.41+j*.102),h*.35),'trim',.0003)
            D.cylinder('Terminal screw',.0026,.003,(-w*.48,d*(-.365+j*.102),h*.48),'metal','Z',16)
        D.box('Blank identification label',(w*.34,d*.62,.001),(-w*.20,0,h*.954),'highlight',0)
        return {'Body':(0,0,0)},(0,0,0)
    if f in ('data_connector','power_connector'):
        r=min(w,h)*.48;z=h/2
        D.cylinder('Connector shell',r,d*.64,(0,d*.14,z),'metal' if f=='data_connector' else 'body')
        D.cylinder('Cable strain-relief boot',r*.79,d*.40,(0,-d*.285,z),'rubber')
        for j in range(9):D.ring('Boot grip rib',r*.81,r*.035,(0,d*(-.46+j*.032),z),'trim')
        D.cylinder('Connector insert',r*.84,.002,(0,d*.461,z),'rubber')
        n=5 if f=='data_connector' else 3
        for i in range(n):
            a=math.tau*i/n
            D.cylinder('Unconnected contact',r*.09,d*.025,(r*.47*math.sin(a),d*.473,z+r*.47*math.cos(a)),'metal' if f=='data_connector' else 'rubber',vertices=16)
        if f=='power_connector':D.box('Locking release latch',(w*.30,d*.26,h*.16),(0,d*.10,h*.90),'highlight',.001)
        return {'Body':(0,0,z)},(0,0,0)
    if f=='tracking_camera':
        D.box('Tracking camera base',(w*.92,d*.93,h*.17),(0,0,h*.085),'body',.016)
        D.PART='Yoke';D.cylinder('Pan pivot',w*.15,h*.08,(0,0,h*.205),'trim','Z')
        D.cylinder('Camera tilt axle',w*.04,w*.86,(0,0,h*.64),'metal','X')
        for x in (-1,1):
            D.box('Camera yoke arm',(w*.10,d*.34,h*.55),(x*w*.43,0,h*.50),'body',.012)
            D.cylinder('Tilt pivot',w*.075,w*.1,(x*w*.435,0,h*.64),'trim','X')
        D.PART='Camera';r=min(w*.28,d*.46)
        D.cylinder('Upright cylindrical camera housing',r,h*.49,(0,0,h*.70),'body','Z')
        D.cylinder('Camera lens surround',r*.83,h*.045,(0,0,h*.967),'trim','Z')
        D.cylinder('Upward camera optical window',r*.65,.004,(0,0,h*.991),'glass','Z')
        for i in range(6):D.box('Base cooling vent',(w*.32,.002,h*.012),(-w*.23,d*.468,h*(.035+i*.019)),'rubber',.0002)
        return {'Body':(0,0,0),'Yoke':(0,0,h*.205),'Camera':(0,0,h*.64)},(0,0,h)
    if f=='drape':
        D.box('Flattened velour inventory silhouette',(w,d,h),(0,0,h/2),'rubber',0)
        D.box('Sewn top webbing',(w,d*.15,h*.06),(0,d*.53,h*.968),'body',0)
        D.box('Lower hem',(w,d*.12,h*.025),(0,d*.53,h*.014),'body',0)
        for i in range(72):
            x=-w/2+(i+.5)*w/72
            D.ring('Top grommet',.009,.002,(x,d*.58,h*.973),'metal')
        return {'Body':(0,0,0)},(0,0,0)
    if f=='hoist':
        D.cylinder('Motor barrel',d*.37,w*.67,(-w*.08,0,h*.48),'body','X')
        D.box('Gear casing',(w*.35,d*.96,h*.42),(w*.30,0,h*.49),'body',.025)
        for x in (-.39,.17):D.cylinder('Motor end collar',d*.39,w*.045,(x*w,0,h*.48),'trim','X')
        for i in range(12):
            a=i*math.tau/12
            D.cylinder('End housing fastener',d*.017,.007,(-w*.423,d*.31*math.sin(a),h*.48+d*.31*math.cos(a)),'metal','X',12)
        D.box('Identification plate',(w*.29,.005,h*.13),(-w*.03,d*.377,h*.52),'metal',.001)
        for z,flip in ((h*.85,1),(h*.15,-1)):
            r=h*.115
            D.cylinder('Hook swivel neck',r*.32,h*.12,(w*.1,0,z-flip*h*.09),'metal','Z')
            points=[(w*.1+r*math.cos(math.radians(35+i*280/24)),0,z+flip*r*math.sin(math.radians(35+i*280/24))) for i in range(25)]
            for a,b in zip(points,points[1:]):beam('Open hook casting',a,b,r*.19,'metal')
        return {'Body':(0,0,0)},(0,0,0)
    if f=='truss':
        r=.025
        for y in (-1,1):
            for z in (r,h-r):beam('Main truss chord',(-w/2,y*(d/2-r),z),(w/2,y*(d/2-r),z),r)
        sections=max(1,round(w/.5))
        for i in range(sections):
            a=-w/2+i*w/sections;b=a+w/sections
            for y in (-1,1):beam('Lattice brace',(a,y*(d/2-r),r if i%2 else h-r),(b,y*(d/2-r),h-r if i%2 else r),.01)
            for z in (r,h-r):beam('Lattice brace',(a,-d/2+r,z),(b,d/2-r,z),.01)
        for x in (-w/2,w/2):
            for y in (-1,1):
                for z in (r,h-r):D.cylinder('Conical end coupling',.018,.038,(x,y*(d/2-r),z),'metal','X')
        return {'Body':(0,0,0)},(0,0,0)
    if f=='stand':
        radius=min(w,d)*.48;hub=h*.17
        for i in range(3):
            a=math.tau*i/3;end=(radius*math.sin(a),radius*math.cos(a),h*.006)
            beam('Deployed tripod leg',(0,0,hub),end,.016,'body')
            beam('Leg spreader',(0,0,h*.055),(end[0]*.62,end[1]*.62,hub*.36),.009,'trim')
            D.cylinder('Rubber foot',.023,.045,end,'rubber','Z')
        for j,(lo,hi,r) in enumerate(((.08,.50,.020),(.45,.77,.016),(.73,.98,.012))):
            D.cylinder('Telescopic riser',r,h*(hi-lo),(0,0,h*(hi+lo)/2),'body','Z')
            D.cylinder('Riser lock collar',r*1.6,h*.014,(0,0,h*hi),'trim','Z')
            D.box('Riser locking handle',(.075,.022,.025),(.042,0,h*hi),'rubber')
        D.cylinder('Top stud',.008,h*.02,(0,0,h*.99),'metal','Z')
        return {'Body':(0,0,0)},(0,0,h)
    if f=='clamp':
        # Open cast jaw, not a closed ring: the gap and threaded fixing define it.
        ro=h*.48;ri=h*.36;center=(-w*.04,0,h*.53);segments=28
        angles=[math.radians(55)+i*math.radians(260)/segments for i in range(segments+1)]
        coords=[(center[0]+ro*math.cos(a),center[2]+ro*math.sin(a)) for a in angles]+[(center[0]+ri*math.cos(a),center[2]+ri*math.sin(a)) for a in reversed(angles)]
        # D.cheek extrudes X; rotate it to a Y-thick side profile.
        o=D.cheek('Continuous cast open jaw',0,d,coords);o.rotation_euler.z=math.pi/2
        D.box('Clamp fixing boss',(w*.26,d,h*.28),(w*.34,0,h*.26),'body',.006)
        D.cylinder('Fixing bolt',h*.055,w*.40,(w*.38,0,h*.50),'metal','X',24)
        D.box('Hand wheel',(w*.07,d*.75,h*.52),(w*.49,0,h*.50),'metal',.004)
        D.cylinder('Luminaire fixing screw',h*.06,h*.23,(-w*.20,0,h*.08),'metal','Z',24)
        return {'Body':(0,0,0)},(0,0,0)
    if f=='deck':
        D.box('Stage platform rim',(w,d,h*.065),(0,0,h*.963),'metal',.003)
        D.box('Deck surface',(w*.996,d*.992,h*.012),(0,0,h*.998),'rubber',.001)
        for x in (-1,1):
            for y in (-1,1):
                D.cylinder('Adjustable leg',.026,h*.91,(x*w*.46,y*d*.43,h*.48),'metal','Z')
                D.cylinder('Leg clamp collar',.036,h*.04,(x*w*.46,y*d*.43,h*.39),'trim','Z')
                D.cylinder('Rubber leg foot',.029,h*.04,(x*w*.46,y*d*.43,h*.025),'rubber','Z')
        return {'Body':(0,0,0)},(0,0,0)
    if f=='screen':
        t=.03175
        for x in (-1,1):D.box('Square-tube upright',(t,d,h),(x*(w-t)/2,0,h/2),'metal',.001)
        for z in (t/2,h-t/2):D.box('Square-tube cross rail',(w-t*2,d,t),(0,0,z),'metal',.001)
        D.PART='Surface'
        D.box('Black screen border',(w-.01,.002,h-.01),(0,d*.48,h/2),'rubber',0)
        D.box('Unlit projection fabric',(w-.1397,.002,h-.1397),(0,d*.52,h/2),'highlight',0)
        return {'Body':(0,0,0),'Surface':(0,d*.52,h/2)},(0,d*.53,h/2)
    if f=='pixel_driver':
        D.box('Driver body',(w,d,h),(0,0,h/2),'body',.002)
        D.box('Address display',(w*.31,.003,h*.42),(-w*.12,d*.505,h*.55),'screen',.001)
        for i in range(4):D.box('Display key',(w*.045,.004,h*.18),(w*(-.28+i*.11),d*.51,h*.20),'rubber',.0003)
        for x in (-1,1):
            for y in (-.24,.24):D.box('Terminal block',(w*.12,d*.24,h*.55),(x*w*.44,y*d,h*.52),'trim',.001)
        return {'Body':(0,0,0)},(0,0,0)
    if f in ('led_panel','scenic_panel'):
        D.box('Outer frame',(w,d,h),(0,0,h/2),'trim',.005)
        D.PART='Surface';D.box('Unlit display surface',(w*.975,.004,h*.975),(0,d*.505,h/2),'rubber' if f=='led_panel' else 'highlight',.001)
        D.PART='Body'
        if f=='led_panel':
            D.box('Rear electronics cartridge',(w*.45,d*.35,h*.45),(0,-d*.55,h*.5),'body')
            for x in (-1,1):D.box('Panel handling grip',(w*.10,d*.18,h*.45),(x*w*.34,-d*.56,h*.5),'rubber')
            for x in (-1,1):
                for z in (.07,.93):D.cylinder('Panel latch',w*.04,.01,(x*w*.42,-d*.65,h*z),'metal')
        return {'Body':(0,0,0),'Surface':(0,d*.51,h*.5)},(0,d*.52,h*.5)
    D.box('Equipment enclosure',(w*.96,d*.91,h*.86),(0,0,h*.49),'body',.012)
    feet(w,d,h)
    if f=='projector':
        for side in (-1,1):
            for i in range(20):D.box('Side grille slot',(.002,d*.026,h*.52),(side*w*.483,-d*.32+i*d*.032,h*.52),'rubber',.0005)
        for i in range(14):D.box('Front intake slat',(w*.19,.005,h*.018),(-w*.34,d*.46,h*(.24+i*.039)),'rubber',.0004)
        D.PART='Lens';r=min(w,h)*.32;D.cylinder('Projection lens barrel',r,d*.18,(-w*.20,d*.48,h*.54),'trim')
        D.ring('Projection lens ring',r,r*.04,(-w*.20,d*.575,h*.54),'metal');D.cylinder('Projection optic',r*.89,.006,(-w*.20,d*.58,h*.54),'glass')
        return {'Body':(0,0,0),'Lens':(-w*.2,d*.58,h*.54)},(-w*.2,d*.59,h*.54)
    if f=='console':
        D.box('Touchscreen bezel',(w*.37,d*.48,.006),(w*.23,d*.08,h*.93),'rubber',.004)
        D.box('Console screen',(w*.32,d*.37,.009),(w*.23,d*.08,h*.965),'screen',.001)
        for row in range(2):
            for i in range(10):
                x=-w*.42+i*w*.041;y=-d*.24+row*d*.40
                D.box('Fader slot',(w*.006,d*.22,.003),(x,y,h*.935),'rubber',.0005)
                D.box('Fader cap',(w*.020,d*.026,.009),(x,y+d*.01,h*.97),'metal',.001)
                D.box('Channel key',(w*.019,d*.035,.006),(x,y+d*.145,h*.94),'trim',.001)
        for i in range(4):
            x=w*(.14+i*.044);D.box('Master fader slot',(w*.006,d*.20,.003),(x,-d*.28,h*.94),'rubber',.0005)
            D.box('Master fader cap',(w*.020,d*.026,.009),(x,-d*.28,h*.97),'metal',.001)
        for i in range(6):D.box('Screen soft key',(w*.019,d*.031,.006),(w*(.065+i*.063),d*.38,h*.94),'highlight',.001)
    elif f in ('node','splitter'):
        D.box('Blue identity panel',(w*.86,d*.83,.002),(0,0,h*.93),'screen',.001)
        for y in (-.20,.20):
            D.cylinder('Five pin DMX socket',min(h*.36,d*.21),w*.08,(w*.48,y*d,h*.53),'trim','X')
            D.cylinder('Socket recess',min(h*.30,d*.17),w*.012,(w*.522,y*d,h*.53),'rubber','X')
        D.box('Ethernet socket',(.004,d*.26,h*.42),(-w*.49,-d*.18,h*.52),'rubber',.001)
        D.cylinder('DC power input',h*.10,.004,(-w*.49,d*.24,h*.55),'rubber','X')
        if f=='splitter':
            for y in (-.20,.20):D.cylinder('Isolated output socket',min(h*.3,d*.17),.009,(-w*.49,y*d,h*.5),'trim','X')
    elif f=='dimmer':
        for side in (-1,1):
            for i in range(4):
                y=-d*.32+i*d*.215
                D.cylinder('Edison outlet body',h*.23,.006,(side*w*.484,y,h*.5),'trim','X',32)
                for z in (-1,1):D.box('Outlet contact slot',(.009,h*.10,h*.045),(side*w*.490,y+h*.05,h*(.5+z*.07)),'rubber',0)
            D.box('Reversible mounting flange',(w*.045,d*.96,h*.14),(side*w*.495,0,h*.91),'metal',.002)
        for i in range(3):D.cylinder('Data socket',h*.13,.007,(w*(-.25+i*.22),d*.463,h*.43),'rubber')
        D.box('LCD control window',(w*.19,d*.11,.004),(0,d*.24,h*.94),'screen',.001)
        for i in range(4):D.box('Control key',(w*.045,d*.043,.007),(w*(-.12+i*.08),d*.36,h*.95),'rubber',.001)
    elif f in ('power','media_server','pixel_controller'):
        for i in range(6):D.box('Rear connection panel',(w*.07,.005,h*.23),(w*(-.35+i*.14),-d*.46,h*.50),'rubber',.001)
        if f=='media_server':
            D.box('Processor display',(w*.22,.006,h*.33),(-w*.23,d*.459,h*.63),'screen',.002)
            for i in range(19):D.box('Front intake vent',(w*.009,.007,h*.60),(w*(-.06+i*.021),d*.46,h*.51),'rubber',.001)
            for side in (-1,1):D.box('Rack ear',(w*.032,d*.075,h*.87),(side*w*.492,d*.43,h*.5),'metal',.002)
        if f=='pixel_controller':
            for i in range(8):D.box('Pixel data output',(.003,d*.045,h*.30),(-w*.489,d*(-.35+i*.10),h*.50),'rubber',.001)
            D.box('Yellow Ethernet surround',(w*.1,.005,h*.69),(w*.12,d*.459,h*.56),'highlight',.002)
    return {'Body':(0,0,0)},(0,0,0)

def accessory(spec):
    p=spec['profile'];f=p['family'];w,d,h=spec['width_m'],spec['depth_m'],spec['height_m'];D.PART='Body'
    if f=='safety_hardware':
        # Raw 70 x 20 mm internal opening and 10 mm rod are source-backed.
        # Sleeve outer extent is explicitly a drawing-calibrated approximation.
        points=[]
        for side in (1,-1):
            for i in range(33):
                a=(-math.pi/2 if side==1 else math.pi/2)+math.pi*i/32
                points.append((side*.025+.015*math.cos(a),0,.020+.015*math.sin(a)))
        curve=bpy.data.curves.new('Closed quick-link rod','CURVE');curve.dimensions='3D';curve.bevel_depth=.005;curve.bevel_resolution=4
        spline=curve.splines.new('POLY');spline.points.add(len(points)-1)
        for point,co in zip(spline.points,points):point.co=(*co,1)
        spline.use_cyclic_u=True
        obj=bpy.data.objects.new('Closed oval rod',curve);bpy.context.collection.objects.link(obj)
        bpy.ops.object.select_all(action='DESELECT');obj.select_set(True);bpy.context.view_layer.objects.active=obj;bpy.ops.object.convert(target='MESH');D.register(bpy.context.object,'Zinc-plated oval rod','metal',True)
        D.cylinder('Hexagonal closure sleeve',.008,.028,(.004,0,.005),'metal','X',6)
        D.cylinder('Closure collar',.006,.005,(-.015,0,.005),'trim','X',32)
        return {'Body':(0,0,0)},(0,0,0)
    if f=='fluid_container':
        white=extra_material('container','Translucent white container approximation',(.82,.84,.83),0,.32)
        D.cylinder('Sealed gallon jug body',min(w,d)*.48,h*.66,(0,0,h*.35),white,'Z')
        bpy.ops.mesh.primitive_cone_add(vertices=64,radius1=min(w,d)*.48,radius2=min(w,d)*.14,depth=h*.22,location=(0,0,h*.79));D.register(bpy.context.object,'Sloped jug shoulder',white,True)
        D.cylinder('Sealed ribbed cap',w*.14,h*.08,(0,0,h*.96),'rubber','Z')
        for i in range(24):
            a=i*math.tau/24;D.cylinder('Cap grip ridge',w*.007,h*.069,(w*.138*math.cos(a),w*.138*math.sin(a),h*.96),'trim','Z',8)
        for a,b in [((w*.13,0,h*.89),(w*.38,0,h*.77)),((w*.38,0,h*.77),(w*.40,0,h*.60))]:beam('Moulded jug handle',a,b,w*.05,white)
        D.cylinder('Plain product label band',min(w,d)*.481,h*.47,(0,0,h*.36),'screen','Z')
    elif f=='co2_supply':
        r=min(w,h)*.44
        for a,b,m,rr in [(-.50,-.06,'metal',1),(-.06,.08,'trim',.65),(.08,.22,'metal',.88),(.22,.38,'metal',1),(.38,.50,'trim',.65)]:
            D.cylinder('Quick-connect segment',r*rr,d*(b-a),(0,d*(a+b)/2,h*.5),m)
        for j in range(15):D.ring('Knurled coupling grip',r*.98,r*.015,(0,d*(-.45+j*.025),h*.5),'trim')
        D.cylinder('Unconnected coupler bore',r*.47,.002,(0,-d*.502,h*.5),'rubber')
    return {'Body':(0,0,0)},(0,0,0)

def geometry(spec):
    f=spec['profile']['family']
    if f in ('fluid_container','co2_supply','safety_hardware'):return accessory(spec)
    if f in ('fogger','hazer','low_fog','jet','bubble','snow','co2_jet','spark','flame'):return atmosphere(spec)
    if f=='fan':return fan(spec)
    if f=='confetti':return confetti(spec)
    if f in ('truss','screen','led_panel','scenic_panel','deck','projector','console','node','dimmer','power','media_server','stand','clamp','splitter','pixel_controller','pixel_driver','hoist','power_supply','data_connector','power_connector','tracking_camera','drape'):return infrastructure(spec)
    return luminous(spec)

def previews(spec,folder):
    scene=bpy.context.scene;w,d,h=spec['width_m'],spec['depth_m'],spec['height_m'];e=max(w,d,h)
    scene.view_settings.view_transform='Standard';scene.view_settings.exposure=.6
    before=set(bpy.data.objects);D.PART='Preview'
    D.box('Review floor',(e*4,e*4,.002),(0,0,-e*.018),'floor',0)
    bar=min(.5,e*.55)
    for i in range(10):D.box('Review scale segment',(bar/10,e*.014,e*.014),(-bar/2+(i+.5)*bar/10,d*.70,e*.009),'highlight' if i%2==0 else 'rubber',0)
    bpy.ops.object.camera_add();cam=bpy.context.object;scene.camera=cam;cam.data.type='ORTHO';cam.data.ortho_scale=e*1.6
    target=Vector((0,0,h*.48));views={'front':(0,e*3,h*.51),'side':(e*3,0,h*.51),'rear':(0,-e*3,h*.51),'three-quarter':(e*2.2,e*2.6,e*1.8)}
    bpy.ops.object.text_add();label=bpy.context.object;label.name='Review-only dimensions';label.data.size=e*.030;label.data.align_x='CENTER';label.data.materials.append(D.M['highlight'])
    label.data.body=f'{w*1000:g} W  x  {h*1000:g} H  x  {d*1000:g} D mm | bar {bar*1000:g} mm'
    folder.joinpath('previews').mkdir(exist_ok=True)
    for name,loc in views.items():
        cam.location=loc;cam.rotation_euler=(target-Vector(loc)).to_track_quat('-Z','Y').to_euler()
        quat=cam.rotation_euler.to_quaternion();label.rotation_euler=cam.rotation_euler;label.location=target+quat@Vector((0,-e*.67,e*2))
        scene.render.filepath=str(folder/'previews'/f'{name}.png');bpy.ops.render.render(write_still=True)
    for o in set(bpy.data.objects)-before:
        if o in D.OBJECTS:D.OBJECTS.remove(o)
        bpy.data.objects.remove(o,do_unlink=True)

def build(spec,folder):
    D.static=geometry
    D.linear=lambda s:luminous(s) if s['profile']['family']=='blinder' else _linear(s)
    D.previews=previews
    # New equipment families route through D.static; established lighting families
    # keep their existing detail geometry. No original fixture assets are changed.
    D.build(spec,folder)
