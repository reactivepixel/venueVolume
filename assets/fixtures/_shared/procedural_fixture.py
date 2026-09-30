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


def _cube(name, size, loc, mat, bevel=0.0):
    bpy.ops.mesh.primitive_cube_add(location=loc)
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
    w,h,d = spec["width_m"], spec["height_m"], spec["depth_m"]
    kind = spec["shape"]
    parts = []
    if kind == "moving_head":
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
    kind = spec["shape"]
    if kind == "moving_head":
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
    _build_usdz(spec,fixture_dir/"models/fixture.usdz")
    print(json.dumps({"fixture":spec["id"],"parts":parts}))
