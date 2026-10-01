"""Detailed editable fixture geometry; export the SAME evaluated meshes to OpenUSD.

Outer dimensions are sourced. Local contours, fasteners, vents and pivots are
visual approximations. Blender: +Y optical forward, +Z up. USD: -Z forward, +Y up.
"""
from pathlib import Path
import hashlib
import json
import math
import re
import bpy
from mathutils import Vector, Matrix
from pxr import Gf, Sdf, Usd, UsdGeom, UsdShade, UsdUtils

OBJECTS=[]
PART='Body'
M={}

def material(name,color,metallic=0,roughness=.4,emission=0):
    m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True
    n=m.node_tree.nodes.get('Principled BSDF')
    n.inputs['Base Color'].default_value=(*color,1)
    n.inputs['Metallic'].default_value=metallic;n.inputs['Roughness'].default_value=roughness
    n.inputs['Emission Color'].default_value=(*color,1);n.inputs['Emission Strength'].default_value=emission
    return m

def register(o,name,mat,smooth=False):
    o.name=name;o['fixture_part']=PART;o.data.materials.append(M[mat] if isinstance(mat,str) else mat)
    if smooth:
        for p in o.data.polygons:p.use_smooth=True
    OBJECTS.append(o);return o

def box(name,size,loc,mat='body',bevel=.008,rotation=(0,0,0)):
    bpy.ops.mesh.primitive_cube_add(location=loc,rotation=rotation);o=bpy.context.object;o.dimensions=size
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    if bevel:
        b=o.modifiers.new('Manufactured edge radii','BEVEL');b.width=min(bevel,min(size)*.2);b.segments=3
    return register(o,name,mat)

def cylinder(name,radius,length,loc,mat='body',axis='Y',vertices=48):
    rot={'Y':(math.pi/2,0,0),'X':(0,math.pi/2,0),'Z':(0,0,0)}[axis]
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices,radius=radius,depth=length,location=loc,rotation=rot)
    o=register(bpy.context.object,name,mat)
    for p in o.data.polygons:p.use_smooth=len(p.vertices)==4
    return o

def ring(name,radius,thickness,loc,mat='trim',axis='Y'):
    rot={'Y':(math.pi/2,0,0),'X':(0,math.pi/2,0),'Z':(0,0,0)}[axis]
    bpy.ops.mesh.primitive_torus_add(major_segments=48,minor_segments=8,major_radius=radius,minor_radius=thickness,location=loc,rotation=rot)
    return register(bpy.context.object,name,mat,True)

def shell(name,rings,center,mat='body',segments=48):
    # Radius rings along Y; elliptical cross sections give fixture-specific shells.
    verts=[];faces=[]
    for y,rx,rz in rings:
        verts.extend((center[0]+rx*math.cos(i*math.tau/segments),center[1]+y,center[2]+rz*math.sin(i*math.tau/segments)) for i in range(segments))
    faces.append(tuple(range(segments-1,-1,-1)))
    for j in range(len(rings)-1):
        for i in range(segments):
            k=(i+1)%segments;faces.append((j*segments+i,j*segments+k,(j+1)*segments+k,(j+1)*segments+i))
    faces.append(tuple(range((len(rings)-1)*segments,len(rings)*segments)))
    mesh=bpy.data.meshes.new(name);mesh.from_pydata(verts,[],faces);mesh.update()
    o=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(o)
    # Winding above is inward for the chosen ring order; reverse once.
    for p in mesh.polygons:p.flip()
    return register(o,name,mat,segments>16)

def cheek(name,x,thickness,coords,mat='body'):
    verts=[(x+s*thickness/2,y,z) for s in (-1,1) for y,z in coords];n=len(coords)
    faces=[tuple(range(n-1,-1,-1)),tuple(range(n,n*2))]
    faces += [(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
    mesh=bpy.data.meshes.new(name);mesh.from_pydata(verts,[],faces);mesh.update()
    o=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(o)
    b=o.modifiers.new('Yoke edge radii','BEVEL');b.width=thickness*.15;b.segments=3
    return register(o,name,mat)

def controls(w,d,z,back=False):
    y=(-1 if back else 1)*d*.505
    if not back:
        box('Recessed control bezel',(w*.43,.006,w*.14),(0,y,z),'rubber',.002)
        box('LCD window',(w*.18,.008,w*.085),(-w*.07,y+.004,z),'screen',.001)
        for i in range(4):cylinder('Navigation button',w*.012,.008,(w*(.06+.034*i),y+.004,z),'trim',vertices=16)
    else:
        for i in range(4):
            x=(i-1.5)*w*.12;cylinder('DMX power socket',w*.035,.009,(x,y,z),'rubber',vertices=24)
            ring('Socket rim',w*.034,w*.005,(x,y-.005,z),'trim')
            for a in range(3):cylinder('Socket pin',w*.003,.002,(x+w*.015*math.cos(a*math.tau/3),y-.006,z+w*.015*math.sin(a*math.tau/3)),'metal',vertices=8)

def vents(w,d,z,count=9):
    for side in (-1,1):
        for i in range(count):
            box('Housing ventilation slot',(.003,d*.08,w*.03),(side*w*.501,-d*.28+i*d*.06,z),'rubber',.0005)

def array_positions(count):
    if count==1:return [(0,0)],.82
    if count==7:return [(0,0)]+[(.62*math.cos(i*math.tau/6),.62*math.sin(i*math.tau/6)) for i in range(6)],.28
    if count==12:return [(r*math.cos(i*math.tau/n+math.pi/6),r*math.sin(i*math.tau/n+math.pi/6)) for n,r in [(3,.28),(9,.70)] for i in range(n)],.23
    if count==19:return [(0,0)]+[(r*math.cos(i*math.tau/n),r*math.sin(i*math.tau/n)) for n,r in [(6,.39),(12,.78)] for i in range(n)],.18
    if count==37:return [(0,0)]+[(r*math.cos(i*math.tau/n),r*math.sin(i*math.tau/n)) for n,r in [(6,.26),(12,.52),(18,.78)] for i in range(n)],.12
    pts=[(.82*math.sqrt((i+.5)/count)*math.cos(i*2.39996),.82*math.sqrt((i+.5)/count)*math.sin(i*2.39996)) for i in range(count)]
    return pts,.70/math.sqrt(count)

def optics(r,y,z,count=1,fresnel=False,aura=False):
    ring('Front metal retaining ring',r*.96,r*.025,(0,y,z))
    cylinder('Optic carrier',r,.012,(0,y-.008,z),'rubber')
    pts,ratio=array_positions(count)
    for i,(x,zz) in enumerate(pts):
        rr=r*ratio
        ring('Individual optic bezel',rr,rr*.055,(x*r,y+.012,z+zz*r),'trim')
        cylinder('Optical glass',rr*.93,.008,(x*r,y+.014,z+zz*r),'glass')
        if count>1:cylinder('Lens highlight',rr*.18,.002,(x*r-rr*.24,y+.02,z+zz*r+rr*.23),'highlight',vertices=24)
    if fresnel:
        for i in range(1,10):ring('Fresnel concentric step',r*.085*i,r*.006,(0,y+.020,z),'highlight')
    if aura:
        for i in range(36):
            a=i*math.tau/36;cylinder('Aura accent pixel',r*.022,.005,(r*.89*math.cos(a),y+.02,z+r*.89*math.sin(a)),'aura',vertices=12)

def moving(spec):
    global PART
    p=spec['profile'];w,h,d=spec['width_m'],spec['height_m'],spec['depth_m']
    wash=p['family']=='moving_wash';bh=h*p.get('base_height',.16 if not p.get('baseless') else .07)
    r=min(w*.33,h*.26);zc=h-r;depth=d*p.get('head_depth',.50 if wash else .85)
    PART='Base'
    if p.get('baseless'):
        cylinder('Compact pan pedestal',w*.21,bh,(0,0,bh/2),'body','Z')
        for x in (-1,1):box('Mounting outrigger',(w*.44,d*.18,h*.027),(x*w*.26,0,h*.014),'metal')
    else:
        box('Lower base',(w*.92,d*.91,bh*.80),(0,0,bh*.49),'body',.027)
        box('Base upper shoulder',(w*.84,d*.78,bh*.25),(0,0,bh*.87),'trim',.018)
        for sx in (-1,1):
            for sy in (-1,1):cylinder('Rubber foot',w*.043,bh*.17,(sx*w*.35,sy*d*.31,bh*.085),'rubber','Z',24)
            box('Carry handle',(w*.095,d*.48,bh*.26),(sx*w*.46,0,bh*.62),'rubber',.01)
        controls(w,d*.91,bh*.52);controls(w,d*.91,bh*.50,True)
        vents(w*.92,d*.80,bh*.61,6)
    cylinder('Pan bearing',w*.20,h*.046,(0,0,bh),'rubber','Z')
    PART='Yoke'
    box('Yoke cross member',(w*.82,d*.31,h*.09),(0,0,bh+h*.06),'body',.017)
    for s in (-1,1):
        cheek('Angled yoke arm',s*w*.42,w*.115,[(-d*.16,bh+h*.08),(d*.16,bh+h*.08),(d*.19,zc-h*.025),(d*.12,zc+h*.07),(-d*.12,zc+h*.07),(-d*.20,zc-h*.025)])
        cylinder('Tilt bearing',r*.30,w*.13,(s*w*.36,0,zc),'trim','X')
        cylinder('Tilt cap',r*.21,.007,(s*w*.486,0,zc),'rubber','X')
        for zz in (bh+h*.15,zc):cylinder('Yoke screw',w*.009,.005,(s*w*.483,-d*.02,zz),'metal','X',12)
    PART='Head'
    seg=64 if p.get('shell','round')=='round' else 12
    shell('Sculpted head shell',[(-depth*.49,r*.55,r*.62),(-depth*.39,r*.91,r*.92),(-depth*.12,r,r),(depth*.26,r*.88,r*.91),(depth*.44,r*(.94 if wash else .74),r*(.94 if wash else .74))],(0,0,zc),'body',seg)
    if not wash:
        for side in (-1,1):
            for i in range(8):box('Head cooling louvre',(.004,depth*.025,r*.43),(side*r*.93,-depth*.22+i*depth*.044,zc),'rubber',.0005)
        cylinder('Rear fan inlet',r*.45,.008,(0,-depth*.495,zc),'rubber')
        for i in range(4):ring('Rear fan guard',r*(.12+.09*i),r*.012,(0,-depth*.501,zc),'trim')
    else:
        for i in range(9):ring('Circular heatsink fin',r*.91,r*.017,(0,-depth*.35+i*depth*.04,zc),'trim')
    lr=r*(.94 if wash else p.get('lens_ratio',.7))
    cylinder('Front barrel',lr*1.10,depth*.13,(0,depth*.43,zc),'trim')
    PART='Head/Lens';optics(lr,depth*.501,zc,p.get('lens_count',1),p.get('fresnel',False),p.get('aura',False))
    if p.get('radial_blades'):
        for i in range(16):
            a=i*math.tau/16
            box('Radial wash vane',(lr*.09,.012,lr*.75),(lr*.48*math.sin(a),depth*.501+.034,zc+lr*.48*math.cos(a)),'trim',.001,(0,a,0))
    return {'Base':(0,0,0),'Yoke':(0,0,bh),'Head':(0,0,zc),'Head/Lens':(0,depth*.501,zc)},(0,depth*.52,zc)

def static(spec):
    global PART
    p=spec['profile'];f=p['family'];w,h,d=spec['width_m'],spec['height_m'],spec['depth_m'];r=min(w*.35,h*.28);z=h*.43
    PART='Body'
    if f=='profile':
        shell('LED engine shell',[(-d*.48,r*.73,r*.85),(-d*.4,r,r),(-d*.02,r*.87,r*.87),(d*.08,r*.70,r*.70)],(0,0,z),'body',16)
        cylinder('Focus barrel',r*.64,d*.40,(0,d*.26,z),'body')
        for y in (d*.08,d*.17,d*.38):ring('Barrel locking collar',r*.66,r*.04,(0,y,z),'trim')
        box('Gel frame holder',(r*1.65,.022,r*1.65),(0,d*.46,z),'body')
        for s in (-1,1):box('Framing shutter handle',(r*.38,.022,r*.12),(s*r*.93,d*.04,z),'metal')
        for i in range(9):ring('Engine cooling ring',r*.94,r*.016,(0,-d*.34+i*d*.032,z),'trim')
        rr=r*.59;fy=d*.47
    else:
        length=d*.65
        shell('Optical housing',[(-length*.56,r*.75,r*.75),(-length*.43,r,r),(length*.40,r,r),(length*.5,r*.92,r*.92)],(0,0,z),'body')
        for i in range(11):ring('Cooling fin',r*1.01,r*.017,(0,-length*.42+i*length*.052,z),'trim')
        box('Rear electronics housing',(r*1.47,d*.20,h*.28),(0,-d*.37,z-h*.04),'body')
        rr=r*.86;fy=length*.52
    controls(w*.68,d*.90,z-h*.10,True)
    PART='Yoke'
    for s in (-1,1):
        if p.get('floor_yoke'):
            for sy in (-1,1):
                cheek('Split floor yoke arm',s*w*.44,w*.06,[(sy*d*.045,z),(sy*d*.35,h*.05),(sy*d*.26,h*.025),(-sy*d*.045,z*.95)])
        else:box('Yoke side',(w*.06,d*.10,h*.59),(s*w*.44,0,h*.69),'body',.01)
        cylinder('Tilt locking knob',w*.063,w*.075,(s*w*.46,0,z),'rubber','X')
    if p.get('floor_yoke'):
        for side in (-1,1):box('Floor yoke bridge',(w*.94,d*.10,h*.055),(0,side*d*.30,h*.03),'body',.01)
    else:
        box('Mounting bridge',(w*.94,d*.10,h*.055),(0,0,h*.975),'body',.01)
        cylinder('Mounting bolt boss',w*.055,h*.023,(0,0,h*.987),'metal','Z')
    PART='Lens';optics(rr,fy,z,p.get('lens_count',1),f=='fresnel')
    if p.get('barn_doors'):
        box('Barn door top',(w*.69,.008,h*.22),(0,fy+.013,z+r*1.04),'body',.002,(math.radians(-12),0,0))
        box('Barn door bottom',(w*.69,.008,h*.22),(0,fy+.013,z-r*1.04),'body',.002,(math.radians(12),0,0))
        for s in (-1,1):box('Barn door side',(w*.18,.008,h*.54),(s*w*.38,fy+.012,z),'body',.002,(0,0,0))
    return {'Body':(0,0,0),'Yoke':(0,0,z),'Lens':(0,fy,z)},(0,fy+.025,z)

def linear(spec):
    global PART
    p=spec['profile'];w,h,d=spec['width_m'],spec['height_m'],spec['depth_m'];strobe=p['family']=='strobe'
    PART='Body';cy=h*.61;hh=h*(.62 if not p.get('strip') else .72)
    box('Extruded fixture housing',(w*.99,d*.68,h*.26 if p.get('multi_heads') else hh),(0,0,h*.18 if p.get('multi_heads') else cy),'body',.014)
    for i in range(8):box('Long heatsink rib',(w*.93,.013,hh*.06),(0,-d*.34-i*d*.015,cy+(i-4)*hh*.09),'trim',.001)
    if not p.get('multi_heads'):box('Optic surround',(w,d*.06,hh*.92),(0,d*.34,cy),'rubber',.009)
    for s in (-1,1):
        box('End cheek',(.015,d*.75,hh*1.02),(s*w*.493,0,cy),'trim')
        cylinder('Tilt knob',min(h,d)*.14,.024,(s*w*.505,0,cy),'rubber','X')
        box('Floor bracket',(w*.06,d*.83,h*.045),(s*w*.37,0,h*.03),'metal')
        box('Bracket arm',(w*.035,d*.12,h*.42),(s*w*.37,0,h*.20),'metal')
    if p.get('tilting'):box('Motor base',(w*.92,d*.91,h*.23),(0,0,h*.13),'body')
    if p.get('overhead_yoke'):
        for s in (-1,1):box('Overhead bracket side',(w*.025,d*.12,h*.55),(s*w*.45,0,h*.90),'body',.004)
        box('Overhead bracket bridge',(w*.93,d*.12,h*.04),(0,0,h*1.17),'body',.004)
    controls(min(w,.6),d*.7,h*.19,True)
    PART='Lens'
    if p.get('multi_heads'):
        n=p.get('lens_count',8);radius=min(w*.40/n,h*.22)
        for i in range(n):
            PART=f'Head_{i+1:02d}'
            x=-w*.44+(i+.5)*w*.88/n
            box('Independent tilting head',(w*.84/n,d*.72,hh*.78),(x,d*.10,cy+hh*.24),'body',.016)
            ring('Head optic collar',radius,radius*.08,(x,d*.49,cy+hh*.30),'trim')
            lens=cylinder('Independent beam optic',radius*.91,.012,(x,d*.50,cy+hh*.30),'glass');lens.scale.y=1.30
            for j in range(6):box('Module cooling rib',(w*.78/n,.009,hh*.018),(x,-d*.28,cy+(j-2)*hh*.08),'trim',.001)
            for side in (-1,1):
                box('Head support cheek',(w*.035/n,d*.38,hh*.91),(x+side*w*.44/n,0,cy+hh*.21),'trim',.006)
                cylinder('Head pivot cap',radius*.24,.010,(x+side*w*.445/n,0,cy+hh*.30),'rubber','X',24)
    elif p.get('pixel_grid'):
        cols=30;rows=9
        for j in range(rows):
            for i in range(cols):
                cylinder('Individual RGB pixel',min(w*.43/cols,hh*.40/rows),.004,(-w*.44+(i+.5)*w*.88/cols,d*.40,cy-hh*.42+(j+.5)*hh*.84/rows),'glass',vertices=16)
    elif p.get('reflector_cells'):
        n=p['reflector_cells'];radius=min(w*.41/n,hh*.27)
        for i in range(n):
            x=-w*.44+(i+.5)*w*.88/n
            ring('Reflector cell rim',radius,radius*.08,(x,d*.40,cy),'metal')
            cylinder('Blinder optic',radius*.90,.008,(x,d*.405,cy),'glass')
        for side in (-1,1):box('White strobe bank',(w*.92,.014,hh*.12),(0,d*.42,cy+side*hh*.36),'highlight',.002)
    elif strobe:
        n=min(p.get('cells',24),48)
        for side in (-1,1):
            for i in range(n):
                box('RGB diffuser cell',(w*.91/n*.92,d*.035,hh*.29),(-w*.455+(i+.5)*w*.91/n,d*.40,cy+side*hh*.25),'highlight',.001)
        box('Central white strobe strip',(w*.95,d*.04,hh*.08),(0,d*.41,cy),'glass',.001)
        for i in range(n):box('Strobe emitter',(w*.92/n*.72,d*.012,hh*.035),(-w*.46+(i+.5)*w*.92/n,d*.435,cy),'highlight',.0002)
    else:
        n=p.get('lens_count',12);r=min(w*.43/n,hh*.35)
        for i in range(n):
            x=-w*.45+(i+.5)*w*.90/n
            if p.get('diffuser'):box('Diffuser segment',(w*.88/n*.94,.012,hh*.66),(x,d*.37,cy),'glass',.004)
            else:
                ring('Optic rim',r,r*.06,(x,d*.37,cy),'trim')
                cylinder('Batten lens',r*.93,.009,(x,d*.38,cy),'glass')
                if p.get('pixel_clusters'):
                    pts,lr=array_positions(19)
                    for xx,zz in pts:cylinder('RGB pixel',r*lr*.7,.002,(x+xx*r,d*.38+.009,cy+zz*r),'aura',vertices=12)
    pivots={'Body':(0,0,0),'Yoke':(0,0,cy),'Lens':(0,d*.38,cy)}
    if p.get('multi_heads'):
        for i in range(n):pivots[f'Head_{i+1:02d}']=(-w*.44+(i+.5)*w*.88/n,0,cy+hh*.30)
    return pivots,(0,d*.39,cy)

def transform_geometry(spec,pivots,emitter):
    bpy.context.view_layer.update();deps=bpy.context.evaluated_depsgraph_get()
    points=[o.matrix_world@v.co for o in OBJECTS for v in o.evaluated_get(deps).data.vertices]
    lo=Vector([min(p[i] for p in points) for i in range(3)]);hi=Vector([max(p[i] for p in points) for i in range(3)])
    target=Vector((spec['width_m'],spec['depth_m'],spec['height_m']));scale=Vector([target[i]/(hi[i]-lo[i]) for i in range(3)])
    offset=Vector((-(hi.x+lo.x)/2,-(hi.y+lo.y)/2,-lo.z))
    transform=Matrix.Diagonal((*scale,1))@Matrix.Translation(offset)
    # Bake evaluated modifiers and nonuniform envelope scaling into editable meshes.
    # Assigning a nonuniform matrix to a rotated object would discard its shear.
    for o in OBJECTS:
        mesh=bpy.data.meshes.new_from_object(o.evaluated_get(deps),depsgraph=deps)
        mesh.transform(transform@o.matrix_world)
        # All modeled components are closed solids. Mirrored cheek outlines can
        # reverse winding; orient them outward before normals/runtime export.
        mesh.calc_loop_triangles()
        volume=sum(mesh.vertices[t.vertices[0]].co.dot(mesh.vertices[t.vertices[1]].co.cross(mesh.vertices[t.vertices[2]].co)) for t in mesh.loop_triangles)/6
        if volume<0:
            for face in mesh.polygons:face.flip()
            mesh.update()
        o.modifiers.clear();o.data=mesh;o.matrix_world=Matrix.Identity(4)
    bpy.context.view_layer.update()
    return {k:transform@Vector(v) for k,v in pivots.items()},transform@Vector(emitter),list(scale)

def runtime(v):return (float(v[0]),float(v[2]),float(-v[1]))

def export(spec,folder,pivots,emitter):
    stage_path=folder/'models/fixture.usdc';out=folder/'models/fixture.usdz'
    stage=Usd.Stage.CreateNew(str(stage_path));UsdGeom.SetStageMetersPerUnit(stage,1);UsdGeom.SetStageUpAxis(stage,'Y')
    root=UsdGeom.Xform.Define(stage,'/Fixture');stage.SetDefaultPrim(root.GetPrim())
    usd_mats={}
    for key,m in M.items():
        path='/Fixture/Materials/'+key;mat=UsdShade.Material.Define(stage,path);sh=UsdShade.Shader.Define(stage,path+'/Surface');sh.CreateIdAttr('UsdPreviewSurface')
        n=m.node_tree.nodes.get('Principled BSDF')
        sh.CreateInput('diffuseColor',Sdf.ValueTypeNames.Color3f).Set(Gf.Vec3f(*m.diffuse_color[:3]))
        sh.CreateInput('roughness',Sdf.ValueTypeNames.Float).Set(float(n.inputs['Roughness'].default_value))
        sh.CreateInput('metallic',Sdf.ValueTypeNames.Float).Set(float(n.inputs['Metallic'].default_value))
        strength=float(n.inputs['Emission Strength'].default_value)
        if strength:sh.CreateInput('emissiveColor',Sdf.ValueTypeNames.Color3f).Set(Gf.Vec3f(*(v*strength for v in m.diffuse_color[:3])))
        mat.CreateSurfaceOutput().ConnectToSource(sh.ConnectableAPI(),'surface');usd_mats[m.name]=mat
    for part,pivot in pivots.items():
        xf=UsdGeom.Xform.Define(stage,'/Fixture/'+part)
        parent=part.rsplit('/',1)[0] if '/' in part else None
        pos=pivot-pivots[parent] if parent else pivot
        xf.AddTranslateOp().Set(Gf.Vec3d(*runtime(pos)))
    deps=bpy.context.evaluated_depsgraph_get();triangles=0;mesh_count=0;signature=hashlib.sha256()
    for index,o in enumerate(OBJECTS):
        ev=o.evaluated_get(deps);mesh=ev.to_mesh();mesh.calc_loop_triangles();part=o['fixture_part'];pivot=pivots[part]
        path='/Fixture/'+part+'/'+re.sub('[^A-Za-z0-9_]','_',o.name)+f'_{index}'
        usd=UsdGeom.Mesh.Define(stage,path)
        points=[runtime(ev.matrix_world@v.co-pivot) for v in mesh.vertices]
        counts=[3]*len(mesh.loop_triangles);indices=[i for t in mesh.loop_triangles for i in t.vertices]
        normal_matrix=ev.matrix_world.to_3x3().inverted().transposed()
        normals=[runtime((normal_matrix@mesh.corner_normals[i].vector).normalized()) for t in mesh.loop_triangles for i in t.loops]
        usd.CreatePointsAttr(points);usd.CreateFaceVertexCountsAttr(counts);usd.CreateFaceVertexIndicesAttr(indices)
        usd.CreateNormalsAttr(normals);usd.SetNormalsInterpolation('faceVarying');usd.CreateSubdivisionSchemeAttr('none')
        UsdShade.MaterialBindingAPI.Apply(usd.GetPrim()).Bind(usd_mats[o.data.materials[0].name])
        triangles+=len(counts);mesh_count+=1;signature.update(json.dumps([points,indices]).encode());ev.to_mesh_clear()
    moving_head=spec['profile']['family'].startswith('moving_');ep='/Fixture/Head/Emitter' if moving_head else '/Fixture/Emitter'
    anchor=UsdGeom.Xform.Define(stage,ep);anchor.AddTranslateOp().Set(Gf.Vec3d(*runtime(emitter-pivots['Head'] if moving_head else emitter)))
    stage.GetRootLayer().Save()
    if out.exists():out.unlink()
    if not UsdUtils.CreateNewARKitUsdzPackage(Sdf.AssetPath(str(stage_path)),str(out)):raise RuntimeError('USDZ packaging failed')
    stage_path.unlink()
    # Reopen independently and count meshes/triangles: preview and runtime cannot silently diverge.
    reopened=Usd.Stage.Open(str(out));um=[UsdGeom.Mesh(p) for p in reopened.Traverse() if p.IsA(UsdGeom.Mesh)]
    actual_tris=sum(len(m.GetFaceVertexCountsAttr().Get()) for m in um)
    assert len(um)==mesh_count and actual_tris==triangles,'Runtime dropped detail geometry'
    return {'mesh_count':mesh_count,'triangle_count':triangles,'geometry_sha256':signature.hexdigest(),'runtime_matches_evaluated_authoring':True,'emitter':{'prim_path':ep,'position_m':runtime(emitter),'quaternion':[0,0,0,1],'optical_axis':[0,0,-1]},'parts':[{'name':p.lower().replace('/','_'),'prim_path':'/Fixture/'+p,'pivot_m':runtime(v)} for p,v in pivots.items()]}

def previews(spec,folder):
    global PART
    scene=bpy.context.scene;w,h,d=spec['width_m'],spec['height_m'],spec['depth_m'];e=max(w,h,d)
    before=set(bpy.data.objects);PART='Preview'
    box('Review floor',(e*4,e*4,.005),(0,0,-.012),'floor',0)
    # 500 mm reference bar with ten 50 mm segments, review-only.
    for i in range(10):box('Scale 50mm',(.05,.012,.012),(-.225+i*.05,d*.70,.006),'highlight' if i%2==0 else 'rubber',0)
    bpy.ops.object.camera_add();cam=bpy.context.object;scene.camera=cam;cam.data.type='ORTHO';cam.data.ortho_scale=max(w,h,d)*1.5
    target=Vector((0,0,h*.49));views={'front':(0,e*3,h*.53),'side':(e*3,0,h*.53),'rear':(0,-e*3,h*.53),'three-quarter':(e*2.2,e*2.6,h*1.6)}
    folder.joinpath('previews').mkdir(exist_ok=True)
    for name,loc in views.items():
        cam.location=loc;cam.rotation_euler=(target-Vector(loc)).to_track_quat('-Z','Y').to_euler();scene.render.filepath=str(folder/'previews'/f'{name}.png');bpy.ops.render.render(write_still=True)
    for o in set(bpy.data.objects)-before:
        if o in OBJECTS:OBJECTS.remove(o)
        bpy.data.objects.remove(o,do_unlink=True)

def build(spec,folder):
    global PART,M
    folder=Path(folder);OBJECTS.clear();bpy.ops.wm.read_factory_settings(use_empty=True)
    scene=bpy.context.scene;scene.unit_settings.system='METRIC';scene.unit_settings.scale_length=1
    scene.render.engine='BLENDER_WORKBENCH';scene.render.resolution_x=640;scene.render.resolution_y=640;scene.render.resolution_percentage=100
    sh=scene.display.shading;sh.light='STUDIO';sh.color_type='MATERIAL';sh.show_shadows=True;sh.show_cavity=True;sh.cavity_type='BOTH';sh.background_type='WORLD'
    scene.world=bpy.data.worlds.new('Review');scene.world.color=(.095,.105,.12)
    M={'body':material('Powder coated housing',(.055,.064,.078),.25,.34),'trim':material('Housing trim',(.10,.12,.15),.45,.28),'rubber':material('Rubber and recesses',(.012,.018,.024),0,.7),'metal':material('Bare metal',(.36,.40,.45),.8,.25),'glass':material('Optical lens',(.045,.26,.33),.15,.12,.12),'highlight':material('Lens highlights',(.42,.57,.64),.12,.22),'screen':material('Display glass',(.025,.19,.28),0,.18,.4),'aura':material('Accent optic',(.23,.10,.35),.1,.18,.2),'floor':material('Review floor',(.12,.13,.15),0,.6)}
    family=spec['profile']['family']
    if family.startswith('moving_'):pivots,emitter=moving(spec)
    elif family in ('batten','strobe','blinder'):pivots,emitter=linear(spec)
    else:pivots,emitter=static(spec)
    pivots,emitter,normalization=transform_geometry(spec,pivots,emitter)
    (folder/'models').mkdir(exist_ok=True);(folder/'validation').mkdir(exist_ok=True)
    report=export(spec,folder,pivots,emitter);report.update({'family':family,'detail_level':'high','representation':'procedural_approximation','normalization_scale':normalization,'approximation':'Outer envelope follows recorded dimensions; contours, local spacing, fasteners and pivots are estimated from images.','authoring_to_runtime':'(x,y,z) -> (x,z,-y), Blender optical forward +Y','reference_sources':spec.get('source_urls',[])})
    previews(spec,folder)
    # Editable group transforms with local origins at the same pivots used by USD.
    root=bpy.data.objects.new('Fixture',None);bpy.context.collection.objects.link(root)
    groups={}
    for part,pivot in pivots.items():
        parent=part.rsplit('/',1)[0] if '/' in part else None
        o=bpy.data.objects.new(part,None);bpy.context.collection.objects.link(o)
        o.parent=groups[parent] if parent else root
        o.location=pivot-pivots[parent] if parent else pivot;groups[part]=o
    bpy.context.view_layer.update()
    for o in OBJECTS:
        matrix=o.matrix_world.copy();o.parent=groups[o['fixture_part']];o.matrix_world=matrix
    anchor=bpy.data.objects.new('Emitter',None);bpy.context.collection.objects.link(anchor)
    anchor.location=emitter;anchor.parent=root;anchor.empty_display_type='ARROWS';anchor.empty_display_size=.035
    bpy.context.view_layer.update()
    bpy.context.preferences.filepaths.save_version=0
    bpy.ops.wm.save_as_mainfile(filepath=str(folder/'models/fixture.blend'),compress=True)
    (folder/'validation/detail.json').write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps({'id':spec['id'],'meshes':report['mesh_count'],'triangles':report['triangle_count']}))
