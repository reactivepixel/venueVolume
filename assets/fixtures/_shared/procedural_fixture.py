"""Shared Blender/OpenUSD builder for source-backed fixture approximations."""
from pathlib import Path
import json
import math
import sys

import bpy
from mathutils import Vector
from pxr import Gf, Sdf, Usd, UsdGeom, UsdShade, UsdUtils


def _mat(name, color, metallic=0.0, roughness=0.45, emission=None):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color, 1.0)
    mat.use_nodes = True
    node = mat.node_tree.nodes.get("Principled BSDF")
    node.inputs["Base Color"].default_value = (*color, 1.0)
    node.inputs["Metallic"].default_value = metallic
    node.inputs["Roughness"].default_value = roughness
    if emission:
        node.inputs["Emission Color"].default_value = (*emission, 1.0)
        node.inputs["Emission Strength"].default_value = 2.5
    return mat


def _cube(name, size, loc, mat, bevel=0.0, rotation=(0,0,0)):
    bpy.ops.mesh.primitive_cube_add(location=loc, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel:
        mod = obj.modifiers.new("Edge softening", "BEVEL")
        mod.width = min(bevel, min(size) * 0.12)
        mod.segments = 3
    obj.data.materials.append(mat)
    return obj


def _cylinder(name, radius, depth, loc, mat, rotation=(math.pi/2, 0, 0), vertices=48):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=loc, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(mat)
    return obj


def _sphere(name, size, loc, mat):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=48, ring_count=24, location=loc)
    obj=bpy.context.object; obj.name=name; obj.scale=(size[0]/2,size[1]/2,size[2]/2)
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    obj.data.materials.append(mat)
    return obj


def _torus(name, major_radius, minor_radius, loc, mat, rotation=(math.pi/2,0,0)):
    bpy.ops.mesh.primitive_torus_add(major_radius=major_radius,minor_radius=minor_radius,major_segments=48,minor_segments=12,location=loc,rotation=rotation)
    obj=bpy.context.object;obj.name=name;obj.data.materials.append(mat);return obj


def _mesh(stage, path, lo, hi, material):
    x0,y0,z0 = lo; x1,y1,z1 = hi
    points = [(x0,y0,z0),(x1,y0,z0),(x1,y1,z0),(x0,y1,z0),(x0,y0,z1),(x1,y0,z1),(x1,y1,z1),(x0,y1,z1)]
    faces = [(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)]
    mesh = UsdGeom.Mesh.Define(stage, path)
    mesh.CreatePointsAttr(points)
    mesh.CreateFaceVertexCountsAttr([4]*6)
    mesh.CreateFaceVertexIndicesAttr([i for f in faces for i in f])
    mesh.CreateSubdivisionSchemeAttr("none")
    UsdShade.MaterialBindingAPI.Apply(mesh.GetPrim()).Bind(material)
    return mesh


def _mesh_cylinder(stage,path,center,radius,length,material,segments=32):
    """Cylinder along runtime Z (the fixture optical axis)."""
    cx,cy,cz=center; z0=cz-length/2; z1=cz+length/2
    points=[]
    for z in (z0,z1):
        points.extend((cx+radius*math.cos(2*math.pi*i/segments),cy+radius*math.sin(2*math.pi*i/segments),z) for i in range(segments))
    faces=[]
    faces.append(tuple(range(segments-1,-1,-1)))
    faces.append(tuple(range(segments,segments*2)))
    for i in range(segments):
        j=(i+1)%segments;faces.append((i,j,segments+j,segments+i))
    mesh=UsdGeom.Mesh.Define(stage,path)
    mesh.CreatePointsAttr(points);mesh.CreateFaceVertexCountsAttr([len(x) for x in faces]);mesh.CreateFaceVertexIndicesAttr([i for f in faces for i in f]);mesh.CreateSubdivisionSchemeAttr("none")
    UsdShade.MaterialBindingAPI.Apply(mesh.GetPrim()).Bind(material);return mesh


def _usd_material(stage, path, color, emissive=False):
    material = UsdShade.Material.Define(stage, path)
    shader = UsdShade.Shader.Define(stage, path + "/PreviewSurface")
    shader.CreateIdAttr("UsdPreviewSurface")
    shader.CreateInput("diffuseColor", Sdf.ValueTypeNames.Color3f).Set(Gf.Vec3f(*color))
    shader.CreateInput("roughness", Sdf.ValueTypeNames.Float).Set(0.35)
    shader.CreateInput("metallic", Sdf.ValueTypeNames.Float).Set(0.15)
    if emissive:
        shader.CreateInput("emissiveColor", Sdf.ValueTypeNames.Color3f).Set(Gf.Vec3f(*color))
    material.CreateSurfaceOutput().ConnectToSource(shader.ConnectableAPI(), "surface")
    return material


def _setup_scene(spec):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.unit_settings.system = "METRIC"
    scene.unit_settings.scale_length = 1.0
    scene.render.engine = "BLENDER_WORKBENCH"
    scene.display.shading.light = "STUDIO"
    scene.display.shading.color_type = "MATERIAL"
    scene.display.shading.show_shadows = True
    scene.display.shading.show_cavity = True
    scene.render.resolution_x = 512
    scene.render.resolution_y = 512
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.film_transparent = False
    scene.world = bpy.data.worlds.new("Fixture preview world")
    scene.world.color = (0.025, 0.03, 0.04)
    dark = _mat("Powder-coated housing", (0.025,0.03,0.04), metallic=0.45, roughness=0.3)
    accent = _mat("Accent", (0.08,0.10,0.13), metallic=0.25, roughness=0.38)
    lens = _mat("Lens", (0.02,0.22,0.32), roughness=0.15, emission=(0.02,0.45,0.8))
    glass = _mat("Optical glass", (0.025,0.11,0.09), metallic=0.05, roughness=0.08, emission=(0.02,0.32,0.18))
    screen = _mat("Display", (0.03,0.12,0.2), roughness=.1, emission=(0.05,.35,.8))
    silver = _mat("Machined metal", (.22,.24,.27), metallic=.75, roughness=.24)
    warm = _mat("Warm lens", (.28,.13,.025), roughness=.12, emission=(1.0,.34,.04))
    w,h,d = spec["width_m"], spec["height_m"], spec["depth_m"]
    kind = spec["shape"]
    parts = []
    if kind == "focus_spot_4z":
        bh=h*.17
        _cube("Base",(w*.84,d,bh),(0,0,bh/2),dark,.018)
        _cube("Control panel",(w*.58,d*.025,bh*.46),(0,-d*.488,bh*.55),accent,.004)
        _cube("LCD",(w*.13,d*.012,bh*.22),(-w*.07,-d*.505,bh*.56),screen,.002)
        for x in (-w*.31,w*.31): _cylinder("Pan bearing",h*.04,w*.055,(x,0,bh*.78),silver,rotation=(0,math.pi/2,0),vertices=32)
        for side in (-1,1):
            _cube("Yoke.L" if side<0 else "Yoke.R",(w*.12,d*.54,h*.43),(side*w*.44,0,bh+h*.215),dark,.014)
        _cube("Yoke bridge",(w*.78,d*.54,h*.09),(0,0,bh+h*.055),dark,.012)
        hr=min(w*.31,h*.235); hc=h-hr
        for side in (-1,1): _cylinder("Tilt axle.L" if side<0 else "Tilt axle.R",hr*.24,w*.075,(side*w*.34,0,hc),silver,rotation=(0,math.pi/2,0),vertices=32)
        _sphere("Head capsule",(hr*2,d*.66,hr*1.9),(0,d*.03,hc),dark)
        _cylinder("Lens barrel",hr*.76,d*.18,(0,-d*.38,hc),accent)
        _torus("Lens bezel",hr*.58,hr*.09,(0,-d*.475,hc),silver)
        _cylinder("Lens",hr*.53,d*.018,(0,-d*.49,hc),glass)
        for i in range(7): _cube(f"Head vent {i}",(hr*.09,d*.03,h*.025),((-3+i)*hr*.11,d*.34,hc-hr*.62),accent,.001)
        parts=["/Fixture/Base","/Fixture/Yoke","/Fixture/Head","/Fixture/Head/Lens"]
    elif kind == "sharpy":
        bh=h*.20
        _cube("Base",(w,d,bh),(0,0,bh/2),dark,.025)
        _cube("Front console",(w*.67,d*.025,bh*.48),(0,-d*.49,bh*.52),accent,.006)
        _cube("LCD",(w*.16,d*.012,bh*.24),(-w*.15,-d*.507,bh*.53),screen,.002)
        for side in (-1,1):
            _cube("Yoke.L" if side<0 else "Yoke.R",(w*.15,d*.55,h*.48),(side*w*.425,0,bh+h*.23),dark,.018,rotation=(0,side*math.radians(4),0))
        _cube("Yoke bridge",(w*.72,d*.52,h*.10),(0,0,bh+h*.05),dark,.014)
        hr=min(w*.29,h*.23);hc=h-hr
        for side in (-1,1): _cylinder("Tilt axle.L" if side<0 else "Tilt axle.R",hr*.24,w*.08,(side*w*.34,0,hc),silver,rotation=(0,math.pi/2,0),vertices=32)
        _cylinder("Head body",hr,d*.55,(0,d*.04,hc),dark)
        _cylinder("Optical snout",hr*.78,d*.23,(0,-d*.34,hc),accent)
        _torus("Lens rim",hr*.61,hr*.10,(0,-d*.475,hc),silver)
        _cylinder("Lens",hr*.56,d*.018,(0,-d*.49,hc),glass)
        parts=["/Fixture/Base","/Fixture/Yoke","/Fixture/Head","/Fixture/Head/Lens"]
    elif kind == "forte":
        bh=h*.18
        _cube("Base",(w,d,bh),(0,0,bh/2),dark,.032)
        for x in (-w*.27,w*.27):
            for i in range(5): _cube(f"Base vent {x} {i}",(w*.045,d*.025,bh*.25),(x+(i-2)*w*.05,-d*.49,bh*.55),accent,.001)
        _cube("Display",(w*.13,d*.012,bh*.28),(0,-d*.507,bh*.55),screen,.003)
        for side in (-1,1):
            _cube("Yoke.L" if side<0 else "Yoke.R",(w*.13,d*.50,h*.49),(side*w*.43,0,bh+h*.24),dark,.022,rotation=(0,side*math.radians(5),0))
        _cube("Yoke bridge",(w*.74,d*.48,h*.10),(0,0,bh+h*.055),dark,.018)
        hr=min(w*.28,h*.22);hc=h-hr
        for side in (-1,1): _cylinder("Tilt axle.L" if side<0 else "Tilt axle.R",hr*.24,w*.08,(side*w*.34,0,hc),silver,rotation=(0,math.pi/2,0),vertices=32)
        _cylinder("Head barrel",hr,d*.64,(0,d*.04,hc),dark)
        _cylinder("Lens housing",hr*.82,d*.17,(0,-d*.39,hc),accent)
        _torus("Silver bezel",hr*.66,hr*.085,(0,-d*.485,hc),silver)
        _cylinder("Lens",hr*.61,d*.016,(0,-d*.498,hc),glass)
        for i in range(6): _cube(f"Head vent {i}",(hr*.08,d*.025,h*.022),((-2.5+i)*hr*.12,d*.355,hc-hr*.66),accent,.001)
        parts=["/Fixture/Base","/Fixture/Yoke","/Fixture/Head","/Fixture/Head/Lens"]
    elif kind == "colorado_solo_batten":
        body_h=h*.62
        _cube("Ribbed housing",(w,d*.72,body_h),(0,d*.10,h*.47),dark,.018)
        for i in range(22): _cube(f"Cooling rib {i}",(w*.006,d*.74,body_h*.72),(-w*.46+i*w*.044,d*.11,h*.43),accent,.001)
        _cube("Optic frame",(w*.91,d*.12,h*.25),(0,-d*.39,h*.70),accent,.01)
        colors=[(.22,.05,.5),(.08,.18,.9),(.05,.5,1),(.05,.75,.8),(.1,.9,.45),(.45,1,.18),(1,.9,.08),(1,.48,.06),(1,.18,.1),(1,.08,.35),(.8,.06,.65),(.35,.08,.7)]
        seg=w*.84/12
        for i,c in enumerate(colors):
            lm=_mat(f"LED segment {i+1}",c,roughness=.12,emission=c)
            _cube(f"Optic segment {i+1}",(seg*.92,d*.025,h*.17),(-w*.42+(i+.5)*seg,-d*.456,h*.70),lm,.004)
        _cube("Electronics pod",(w*.32,d*.82,h*.25),(0,d*.08,h*.16),dark,.014)
        for side in (-1,1):
            _cube("Mounting foot.L" if side<0 else "Mounting foot.R",(w*.07,d*.46,h*.09),(side*w*.40,d*.04,h*.045),silver,.006)
        parts=["/Fixture/Body","/Fixture/Lens"]
    elif kind == "kl_fresnel_8":
        cy=h*.48; radius=min(w*.39,h*.29)
        _cylinder("Main barrel",radius,d*.58,(0,d*.12,cy),dark)
        _cylinder("Rear electronics",radius*.86,d*.26,(0,d*.38,cy),dark)
        _cylinder("Lens housing",radius*1.06,d*.18,(0,-d*.32,cy),accent)
        _torus("Fresnel rim",radius*.84,radius*.10,(0,-d*.43,cy),silver)
        _cylinder("Fresnel lens",radius*.78,d*.018,(0,-d*.445,cy),warm)
        for r in (.18,.34,.50,.66): _torus(f"Fresnel ring {r}",radius*r,radius*.015,(0,-d*.458,cy),silver)
        _cube("Yoke top",(w*.92,d*.09,h*.065),(0,d*.02,h*.965),dark,.006)
        for side in (-1,1): _cube("Yoke.L" if side<0 else "Yoke.R",(w*.07,d*.10,h*.72),(side*w*.46,d*.03,h*.61),dark,.007)
        # Four recognisable barn-door leaves, folded within the documented envelope.
        _cube("Barn door top",(w*.72,d*.025,h*.24),(0,-d*.47,h*.77),dark,.004,rotation=(math.radians(-8),0,0))
        _cube("Barn door bottom",(w*.72,d*.025,h*.20),(0,-d*.47,h*.17),dark,.004,rotation=(math.radians(8),0,0))
        _cube("Barn door left",(w*.20,d*.025,h*.55),(-w*.39,-d*.47,cy),dark,.004,rotation=(0,0,math.radians(-6)))
        _cube("Barn door right",(w*.20,d*.025,h*.55),(w*.39,-d*.47,cy),dark,.004,rotation=(0,0,math.radians(6)))
        parts=["/Fixture/Body","/Fixture/Yoke","/Fixture/Lens"]
    elif kind == "moving_head":
        base_h = h * .18
        _cube("Base", (w*.76,d,base_h), (0,0,base_h/2), dark, .02)
        arm_w = w*.12
        arm_h = h*.48
        for side in (-1,1):
            _cube("Yoke.L" if side < 0 else "Yoke.R", (arm_w,d*.48,arm_h), (side*(w/2-arm_w/2),0,base_h+arm_h/2), dark, .012)
        head_h = h*.32
        _cube("Head", (w*.66,d*.62,head_h), (0,0,h-head_h/2), accent, .025)
        _cylinder("Lens", min(w*.24,head_h*.42), d*.08, (0,-d*.35,h-head_h/2), lens)
        parts = ["/Fixture/Base","/Fixture/Yoke","/Fixture/Head","/Fixture/Head/Lens"]
    elif kind == "batten":
        _cube("Body", (w,d,h), (0,0,h/2), dark, min(h,d)*.12)
        count = max(4,min(20,round(w/max(h*.8,.04))))
        for i in range(count):
            x = -w*.45 + (w*.9)*(i+.5)/count
            _cube(f"Lens.{i+1:02d}",(w*.72/count,d*.03,h*.55),(x,-d/2-d*.015,h*.55),lens,.004)
        parts = ["/Fixture/Body","/Fixture/Lens"]
    else:
        body_d = d*.82
        _cube("Body", (w,h*.72,body_d), (0,d*.09,h*.48), dark, min(w,h)*.06)
        radius = min(w*.38,h*.3)
        _cylinder("Lens", radius, d*.18, (0,-d*.41,h*.48), lens)
        _cube("Yoke", (w*.92,d*.10,h*.08), (0,d*.28,h*.88), accent, .008)
        parts = ["/Fixture/Body","/Fixture/Yoke","/Fixture/Lens"]
    return scene, parts


def _build_usdz(spec, out_path):
    w,h,d = spec["width_m"], spec["height_m"], spec["depth_m"]
    stage_path = out_path.with_suffix(".usdc")
    stage = Usd.Stage.CreateNew(str(stage_path))
    UsdGeom.SetStageUpAxis(stage, UsdGeom.Tokens.y)
    UsdGeom.SetStageMetersPerUnit(stage, 1.0)
    root = UsdGeom.Xform.Define(stage, "/Fixture")
    stage.SetDefaultPrim(root.GetPrim())
    dark = _usd_material(stage,"/Fixture/Materials/Housing",(0.025,0.03,0.04))
    lens = _usd_material(stage,"/Fixture/Materials/Lens",(0.02,0.35,0.7),True)
    silver = _usd_material(stage,"/Fixture/Materials/Metal",(.22,.24,.27))
    warm = _usd_material(stage,"/Fixture/Materials/WarmLens",(.8,.25,.025),True)
    kind = spec["shape"]
    if kind in ("focus_spot_4z","sharpy","forte"):
        profiles={
            "focus_spot_4z":dict(bh=.17,aw=.12,ah=.43,hr=.235,body=.66,snout=.22),
            "sharpy":dict(bh=.20,aw=.15,ah=.48,hr=.23,body=.55,snout=.25),
            "forte":dict(bh=.18,aw=.13,ah=.49,hr=.22,body=.64,snout=.19),
        }[kind]
        bh=h*profiles["bh"];hr=min(w*.30,h*profiles["hr"]);hc=h-hr;aw=w*profiles["aw"]
        UsdGeom.Xform.Define(stage,"/Fixture/Base")
        _mesh(stage,"/Fixture/Base/Body",(-w/2,0,-d/2),(w/2,bh,d/2),dark)
        _mesh(stage,"/Fixture/Base/ControlPanel",(-w*.29,bh*.34,-d/2-.000001),(w*.29,bh*.78,-d*.46),silver)
        UsdGeom.Xform.Define(stage,"/Fixture/Yoke")
        _mesh(stage,"/Fixture/Yoke/Left",(-w/2,bh,-d*.27),(-w/2+aw,bh+h*profiles["ah"],d*.27),dark)
        _mesh(stage,"/Fixture/Yoke/Right",(w/2-aw,bh,-d*.27),(w/2,bh+h*profiles["ah"],d*.27),dark)
        _mesh(stage,"/Fixture/Yoke/Bridge",(-w*.37,bh,-d*.26),(w*.37,bh+h*.09,d*.26),dark)
        UsdGeom.Xform.Define(stage,"/Fixture/Head")
        _mesh_cylinder(stage,"/Fixture/Head/Barrel",(0,hc,d*.03),hr,d*profiles["body"],dark)
        snout_length=d*profiles["snout"]
        _mesh_cylinder(stage,"/Fixture/Head/Snout",(0,hc,-d/2+snout_length/2+.004),hr*.80,snout_length,silver)
        UsdGeom.Xform.Define(stage,"/Fixture/Head/Lens")
        _mesh_cylinder(stage,"/Fixture/Head/Lens/Glass",(0,hc,-d/2+.004),hr*.62,.008,lens)
        UsdGeom.Xform.Define(stage,"/Fixture/Head/Emitter")
    elif kind == "colorado_solo_batten":
        UsdGeom.Xform.Define(stage,"/Fixture/Body")
        _mesh(stage,"/Fixture/Body/Housing",(-w/2,0,-d/2),(w/2,h,d/2),dark)
        _mesh(stage,"/Fixture/Body/ElectronicsPod",(-w*.16,0,-d*.34),(w*.16,h*.28,d*.48),silver)
        UsdGeom.Xform.Define(stage,"/Fixture/Lens")
        seg=w*.84/12
        for i in range(12):
            x0=-w*.42+i*seg;x1=x0+seg*.92
            _mesh(stage,f"/Fixture/Lens/Segment_{i+1:02d}",(x0,h*.57,-d/2-.000001),(x1,h*.82,-d*.44),lens)
        UsdGeom.Xform.Define(stage,"/Fixture/Emitter")
    elif kind == "kl_fresnel_8":
        cy=h*.48;radius=min(w*.39,h*.29)
        UsdGeom.Xform.Define(stage,"/Fixture/Body")
        _mesh_cylinder(stage,"/Fixture/Body/Barrel",(0,cy,d*.10),radius,d*.74,dark)
        _mesh(stage,"/Fixture/Body/RearElectronics",(-w*.32,h*.18,d*.31),(w*.32,h*.72,d/2),dark)
        UsdGeom.Xform.Define(stage,"/Fixture/Yoke")
        _mesh(stage,"/Fixture/Yoke/Left",(-w/2,h*.24,-d*.05),(-w*.43,h,d*.05),dark)
        _mesh(stage,"/Fixture/Yoke/Right",(w*.43,h*.24,-d*.05),(w/2,h,d*.05),dark)
        _mesh(stage,"/Fixture/Yoke/Top",(-w/2,h*.93,-d*.08),(w/2,h,d*.08),dark)
        UsdGeom.Xform.Define(stage,"/Fixture/Lens")
        _mesh_cylinder(stage,"/Fixture/Lens/Glass",(0,cy,-d/2+.005),radius*.82,.01,warm)
        _mesh(stage,"/Fixture/Lens/BarnDoorTop",(-w*.36,h*.73,-d/2),(w*.36,h*.98,-d*.45),dark)
        _mesh(stage,"/Fixture/Lens/BarnDoorBottom",(-w*.36,0,-d/2),(w*.36,h*.22,-d*.45),dark)
        UsdGeom.Xform.Define(stage,"/Fixture/Emitter")
    elif kind == "moving_head":
        bh=h*.18; hh=h*.32; ah=h*.48; aw=w*.12
        UsdGeom.Xform.Define(stage,"/Fixture/Base"); _mesh(stage,"/Fixture/Base/Body",(-w*.38,0,-d/2),(w*.38,bh,d/2),dark)
        UsdGeom.Xform.Define(stage,"/Fixture/Yoke")
        _mesh(stage,"/Fixture/Yoke/Left",(-w/2,bh,-d*.24),(-w/2+aw,bh+ah,d*.24),dark)
        _mesh(stage,"/Fixture/Yoke/Right",(w/2-aw,bh,-d*.24),(w/2,bh+ah,d*.24),dark)
        UsdGeom.Xform.Define(stage,"/Fixture/Head"); _mesh(stage,"/Fixture/Head/Body",(-w*.33,h-hh,-d*.31),(w*.33,h,d*.31),dark)
        UsdGeom.Xform.Define(stage,"/Fixture/Head/Lens"); _mesh(stage,"/Fixture/Head/Lens/Glass",(-w*.24,h-hh*.82,-d/2),(w*.24,h-hh*.18,-d*.30),lens)
        UsdGeom.Xform.Define(stage,"/Fixture/Head/Emitter")
    elif kind == "batten":
        UsdGeom.Xform.Define(stage,"/Fixture/Body"); _mesh(stage,"/Fixture/Body/Housing",(-w/2,0,-d/2),(w/2,h,d/2),dark)
        UsdGeom.Xform.Define(stage,"/Fixture/Lens"); _mesh(stage,"/Fixture/Lens/Panel",(-w*.46,h*.2,-d/2-.000001),(w*.46,h*.8,-d*.46),lens)
        UsdGeom.Xform.Define(stage,"/Fixture/Emitter")
    else:
        UsdGeom.Xform.Define(stage,"/Fixture/Body"); _mesh(stage,"/Fixture/Body/Housing",(-w/2,0,-d*.32),(w/2,h*.82,d/2),dark)
        UsdGeom.Xform.Define(stage,"/Fixture/Yoke"); _mesh(stage,"/Fixture/Yoke/Bracket",(-w*.46,h*.82,-d*.2),(w*.46,h,d*.2),dark)
        UsdGeom.Xform.Define(stage,"/Fixture/Lens"); _mesh(stage,"/Fixture/Lens/Glass",(-w*.36,h*.2,-d/2),(w*.36,h*.7,-d*.32),lens)
        UsdGeom.Xform.Define(stage,"/Fixture/Emitter")
    stage.GetRootLayer().Save()
    if out_path.exists(): out_path.unlink()
    if not UsdUtils.CreateNewARKitUsdzPackage(Sdf.AssetPath(str(stage_path)), str(out_path)):
        raise RuntimeError("USDZ packaging failed")
    stage_path.unlink()


def _render_previews(scene, fixture_dir, spec):
    w,h,d = spec["width_m"], spec["height_m"], spec["depth_m"]
    extent=max(w,h,d)
    floor=_cube("Preview floor",(extent*4,extent*4,.015),(0,0,-.012),_mat("Floor",(.11,.12,.14),roughness=.7))
    floor.hide_render=False
    # One-meter segmented scale bar, kept preview-only.
    for i in range(10):
        bar=_cube(f"Scale {i}",(.1,.018,.018),(-.5+.05+i*.1,-d*.72,.025),_mat(f"ScaleMat{i}",(.9,.9,.9) if i%2==0 else (.05,.05,.05)))
        bar.hide_render=False
    bpy.ops.object.light_add(type="AREA", location=(extent*1.6,-extent*1.5,extent*2.2)); bpy.context.object.data.energy=950; bpy.context.object.data.shape="DISK"; bpy.context.object.data.size=extent*2
    bpy.ops.object.light_add(type="AREA", location=(-extent*1.6,extent*.8,extent*1.1)); bpy.context.object.data.energy=650; bpy.context.object.data.size=extent*1.5
    bpy.ops.object.camera_add(); cam=bpy.context.object; scene.camera=cam; cam.data.type="ORTHO"; cam.data.ortho_scale=max(w,h)*1.45
    target=Vector((0,0,h*.48))
    views={"front":(0,-extent*3,h*.55),"side":(extent*3,0,h*.55),"rear":(0,extent*3,h*.55),"three-quarter":(extent*2.2,-extent*2.2,h*1.35)}
    previews=fixture_dir/"previews"; previews.mkdir(parents=True,exist_ok=True)
    for name,loc in views.items():
        cam.location=loc; cam.rotation_euler=(target-Vector(loc)).to_track_quat("-Z","Y").to_euler()
        scene.render.filepath=str(previews/f"{name}.png")
        bpy.ops.render.render(write_still=True)


def build(spec, fixture_dir):
    fixture_dir=Path(fixture_dir).resolve()
    scene,parts=_setup_scene(spec)
    _render_previews(scene,fixture_dir,spec)
    (fixture_dir/"models").mkdir(parents=True,exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(fixture_dir/"models/fixture.blend"),compress=True)
    backup=fixture_dir/"models/fixture.blend1"
    if backup.exists(): backup.unlink()
    _build_usdz(spec,fixture_dir/"models/fixture.usdz")
    print(json.dumps({"fixture":spec["id"],"parts":parts}))
