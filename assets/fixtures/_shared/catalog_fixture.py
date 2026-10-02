"""Additive 2026 catalog geometry profiles; leaves published generator bytes intact."""
from pathlib import Path
import importlib.util
import bpy
import math
from mathutils import Matrix

spec=importlib.util.spec_from_file_location('catalog_detail',Path(__file__).with_name('detailed_fixture.py'))
detail=importlib.util.module_from_spec(spec);spec.loader.exec_module(detail)
original_linear=detail.linear
original_moving=detail.moving
original_static=detail.static

def static(spec):
    pivots,emitter=original_static(spec)
    p=spec['profile'];w,h,d=spec['width_m'],spec['height_m'],spec['depth_m']
    if p.get('round_front'):
        for obj in list(detail.OBJECTS):
            if obj.name.startswith('Gel frame holder'):
                detail.OBJECTS.remove(obj);bpy.data.objects.remove(obj,do_unlink=True)
    if p.get('reflector_cups'):
        for obj in list(detail.OBJECTS):
            if obj.get('fixture_part')=='Lens':
                detail.OBJECTS.remove(obj);bpy.data.objects.remove(obj,do_unlink=True)
        detail.PART='Lens';radius=min(w*.35,h*.28)*.86;z=h*.43;y=d*.65*.52+.028
        detail.cylinder('Black optical mask',radius*1.04,.008,(0,y-.029,z),'rubber')
        count=p['reflector_cups']
        centers=[(x*.46,z*.46) for x in (-1,1) for z in (-1,1)] if count==4 else [(math.cos(a)*.52,math.sin(a)*.52) for a in (math.pi/2,7*math.pi/6,11*math.pi/6)]
        cup=radius*(.41 if count==4 else .43)
        for x,zz in centers:
            x*=radius;zz=z+zz*radius
            vertices=[];segments=48
            for ring,(rad,depth) in enumerate(((cup*.22,-.022),(cup*.58,-.014),(cup,-.002))):
                vertices.extend((x+rad*math.cos(i*math.tau/segments),y+depth,zz+rad*math.sin(i*math.tau/segments)) for i in range(segments))
            faces=[(j*segments+i,j*segments+(i+1)%segments,(j+1)*segments+(i+1)%segments,(j+1)*segments+i) for j in range(2) for i in range(segments)]
            mesh=bpy.data.meshes.new('Concave reflector');mesh.from_pydata(vertices,[],faces);mesh.update()
            obj=bpy.data.objects.new('Concave reflector',mesh);bpy.context.collection.objects.link(obj)
            detail.register(obj,'Concave reflector','metal')
            detail.ring('Reflector rim',cup,cup*.025,(x,y-.002,zz),'highlight')
            detail.cylinder('Recessed LED glass',cup*.21,.003,(x,y-.021,zz),'glass',vertices=32)
        emitter=(0,y+.006,z)
    return pivots,emitter

def linear(spec):
    if spec['profile'].get('dual_movers'):return dual_movers(spec)
    if spec['profile'].get('spot_bar'):return spot_bar(spec)
    pivots,emitter=original_linear(spec)
    p=spec['profile'];w,h,d=spec['width_m'],spec['height_m'],spec['depth_m']
    if p.get('matrix_cells'):
        for obj in list(detail.OBJECTS):
            if obj.get('fixture_part')=='Lens':
                detail.OBJECTS.remove(obj);bpy.data.objects.remove(obj,do_unlink=True)
        detail.PART='Lens';cy=h*.61;hh=h*.72
        for z in range(3):
            for x in range(10):
                px=-w*.44+(x+.5)*w*.88/10;pz=cy-hh*.39+(z+.5)*hh*.78/3
                detail.cylinder('White beam cell',min(w*.019,hh*.061),.005,(px,d*.425,pz),'highlight',vertices=24)
        for z in range(9):
            for x in range(30):
                px=-w*.44+(x+.5)*w*.88/30;pz=cy-hh*.42+(z+.5)*hh*.84/9
                detail.cylinder('RGB matrix pixel',min(w*.006,hh*.020),.003,(px,d*.415,pz),'aura',vertices=12)
    if p.get('sparkle_pixels'):
        detail.PART='Lens';cy=h*.61;hh=h*.62;n=p['sparkle_pixels']//2
        for side in (-1,1):
            for i in range(n):
                x=-w*.45+(i+.5)*w*.9/n
                detail.cylinder('SparQle accent emitter',min(hh*.035,w*.25/n),.004,
                                (x,d*.395,cy+side*hh*.395),'highlight',vertices=16)
    return pivots,emitter

def dual_movers(spec):
    w,h,d=spec['width_m'],spec['height_m'],spec['depth_m'];bh=h*.21;r=min(w*.095,h*.19)
    detail.PART='Body'
    detail.box('Shared control base',(w,d*.84,bh),(0,0,bh*.55),'body',.006)
    detail.controls(w*.62,d*.84,bh*.56);detail.controls(w*.75,d*.84,bh*.56,True)
    for x in (-1,1):
        for y in (-1,1):detail.cylinder('Rubber foot',.015,.014,(x*w*.44,y*d*.30,.007),'rubber','Z',24)
    pivots={'Body':(0,0,0)}
    for i,x in enumerate((-w*.315,w*.315),1):
        pan=f'Yoke_{i:02d}';head=f'Head_{i:02d}';lens=head+'/Lens'
        z=h*.69;depth=d*.75
        detail.PART=pan;pivots[pan]=(x,0,bh*1.1)
        detail.cylinder('Independent pan bearing',r*.9,.022,(x,0,bh*1.1),'trim','Z')
        detail.box('Yoke bridge',(r*3.0,d*.4,h*.055),(x,0,bh*1.2),'body',.006)
        for side in (-1,1):
            detail.cheek('Independent yoke cheek',x+side*r*1.35,r*.35,
                [(-d*.22,bh*1.18),(d*.22,bh*1.18),(d*.19,z+h*.03),(-d*.19,z+h*.03)])
            detail.cylinder('Independent tilt cap',r*.28,.012,(x+side*r*1.56,0,z),'trim','X')
            for zz in (bh*1.4,z):detail.cylinder('Yoke fixing screw',.003,.014,(x+side*r*1.55,0,zz),'metal','X',12)
        detail.PART=head;pivots[head]=(x,0,z)
        detail.shell('Compact optical head',[(-depth*.5,r*.55,r*.6),(-depth*.36,r,r),(depth*.2,r*.92,r*.92),(depth*.48,r*.74,r*.74)],(x,0,z),'body',16)
        for j in range(7):detail.ring('Head cooling fin',r*.87,r*.018,(x,-depth*.39+j*depth*.05,z),'trim')
        detail.PART=lens;pivots[lens]=(x,depth*.50,z)
        detail.ring('Optic retaining ring',r*.77,r*.04,(x,depth*.50,z),'trim')
        detail.cylinder('Independent spot glass',r*.70,.010,(x,depth*.52,z),'glass')
    return pivots,(0,d*.4,h*.69)

def spot_bar(spec):
    p=spec['profile'];w,h,d=spec['width_m'],spec['height_m'],spec['depth_m'];n=p.get('lens_count',4)
    detail.PART='Body'
    detail.box('Control crossbar',(w,d*.5,h*.22),(0,0,h*.87),'body',.004)
    detail.box('Stand receiver',(w*.08,d*.5,h*.32),(0,0,h*.68),'trim',.003)
    detail.controls(min(w,.5),d*.5,h*.87,True)
    pivots={'Body':(0,0,0)};radius=min(w*.39/n,h*.25)
    for i in range(n):
        x=-w*.43+(i+.5)*w*.86/n;z=h*.29;name=f'Head_{i+1:02d}'
        detail.PART=name;pivots[name]=(x,0,z)
        detail.cylinder('Round PAR housing',radius,d*.70,(x,0,z),'body',vertices=48)
        for j in range(7):detail.ring('Head cooling rib',radius*1.02,radius*.025,(x,-d*.29+j*d*.085,z),'trim')
        for side in (-1,1):
            detail.box('Head_support_cheek',(.007,d*.14,h*.42),(x+side*radius*1.08,0,h*.50),'body',.003)
            detail.cylinder('Head_pivot_cap',radius*.18,.016,(x+side*radius*1.10,0,z),'rubber','X',24)
        detail.box('Head_support_cheek_bridge',(radius*2.2,d*.14,h*.025),(x,0,h*.70),'body',.002)
        detail.cylinder('Front lens mask',radius*.94,.012,(x,d*.37,z),'rubber')
        # The official KLS-120 still has three visible lens elements per spot.
        for angle in (math.pi/2,math.pi*7/6,math.pi*11/6):
            detail.cylinder('Independent_beam_optic',radius*.37,.008,
                (x+math.cos(angle)*radius*.44,d*.39,z+math.sin(angle)*radius*.44),'glass')
    return pivots,(0,d*.40,h*.29)

def moving(spec):
    pivots,emitter=original_moving(spec)
    p=spec['profile']
    w,h,d=spec['width_m'],spec['height_m'],spec['depth_m']
    r=min(w*.33,h*.26);zc=h-r;depth=d*p.get('head_depth',.50)
    if p.get('aura_pixels'):
        detail.PART='Head/Lens'
        # A separate accent layer; pixel spacing is image-informed, not CAD.
        count=p['aura_pixels']
        for i in range(count):
            radius=r*.86*math.sqrt((i+.5)/count);angle=i*2.399963
            detail.cylinder('Aura background pixel',r*.013,.003,
                (radius*math.cos(angle),depth*.501+.009,zc+radius*math.sin(angle)),
                'aura',vertices=10)
    if p.get('light_guide_rings'):
        detail.PART='Head/Lens'
        for row,radius in enumerate((r*.67,r*.90)):
            for i in range(24):
                angle=math.tau*i/24
                detail.box('Light guide segment',(r*.10,.007,r*.14),
                    (radius*math.sin(angle),depth*.525,zc+radius*math.cos(angle)),
                    'aura' if row else 'glass',.001,(0,angle,0))
    if p.get('large_head'):
        # A separate scaling of the oversized optical module, about its existing
        # pivot, preserves articulation and avoids scaling the stationary base.
        for obj in detail.OBJECTS:
            if str(obj.get('fixture_part','')).startswith('Head'):
                obj.location.x*=1.18;obj.location.z=zc+(obj.location.z-zc)*1.18
                obj.scale.x*=1.18;obj.scale.z*=1.18
    if not p.get('square_optics'):return finish_moving(spec,pivots,emitter)
    for obj in list(detail.OBJECTS):
        if str(obj.get('fixture_part','')).startswith('Head'):
            detail.OBJECTS.remove(obj);bpy.data.objects.remove(obj,do_unlink=True)
    detail.PART='Head'
    detail.box('Square weather sealed optical head',(r*1.98,depth,r*1.98),(0,0,zc),'body',r*.13)
    detail.box('Four optic front mask',(r*1.88,.015,r*1.88),(0,depth*.5,zc),'rubber',.009)
    for i in range(8):
        detail.box('Rear thermal fin',(r*1.8,.009,r*.05),(0,-depth*.51,zc+(i-3.5)*r*.21),'trim',.001)
    detail.PART='Head/Lens'
    for x in (-1,1):
        for z in (-1,1):
            detail.box('Square homogenized lens',(r*.82,.012,r*.82),(x*r*.47,depth*.525,zc+z*r*.47),'glass',r*.07)
    detail.box('Vertical white strobe strip',(r*.065,.005,r*1.8),(0,depth*.55,zc),'highlight',.001)
    detail.box('Horizontal white strobe strip',(r*1.8,.005,r*.065),(0,depth*.552,zc),'highlight',.001)
    return finish_moving(spec,pivots,(0,depth*.57,zc))

def finish_moving(spec,pivots,emitter):
    """Shorten image-reviewed yokes while preserving matching joint origins."""
    fraction=spec['profile'].get('yoke_compression',0)
    if not fraction:return pivots,emitter
    base=pivots['Yoke'][2];old=pivots['Head'][2];shift=(old-base)*fraction
    for obj in detail.OBJECTS:
        part=str(obj.get('fixture_part',''))
        if part=='Yoke':
            world=obj.matrix_world.copy()
            for vertex in obj.data.vertices:
                position=world@vertex.co
                position.z=base+(position.z-base)*(1-fraction)
                vertex.co=position
            obj.matrix_world=Matrix.Identity(4)
        elif part.startswith('Head'):obj.location.z-=shift
    for part,position in list(pivots.items()):
        if part.startswith('Head'):pivots[part]=(position[0],position[1],position[2]-shift)
    return pivots,(emitter[0],emitter[1],emitter[2]-shift)

def build(spec,folder):
    detail.linear=linear;detail.moving=moving;detail.static=static
    return detail.build(spec,folder)
