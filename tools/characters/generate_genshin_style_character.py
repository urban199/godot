import bpy, math, os
from mathutils import Vector
from math import radians

# Neko Nightfall stylized anime character generator for Blender 4.x.
# Creates actual mesh geometry, an armature, skinned meshes, materials, and animation actions.
OUT = os.environ.get("NEKO_OUTPUT", os.path.abspath("build/neko_nightfall_genshin_style.glb"))
os.makedirs(os.path.dirname(OUT), exist_ok=True)
bpy.ops.object.select_all(action="SELECT"); bpy.ops.object.delete(use_global=False)
for datablocks in (bpy.data.meshes, bpy.data.curves, bpy.data.armatures, bpy.data.materials, bpy.data.actions):
    pass

def mat(name, color, metallic=0.0, rough=0.55):
    m=bpy.data.materials.new(name); m.diffuse_color=(*color,1); m.use_nodes=True
    bs=m.node_tree.nodes.get("Principled BSDF"); bs.inputs["Base Color"].default_value=(*color,1)
    bs.inputs["Metallic"].default_value=metallic; bs.inputs["Roughness"].default_value=rough
    return m
skin=mat("Skin_Porcelain",(0.96,0.73,0.67),0,0.48)
hair=mat("Hair_Warm_Blonde",(0.95,0.66,0.34),0.12,0.3)
hair_hi=mat("Hair_Highlights",(1.0,0.82,0.51),0.05,0.28)
cloth=mat("Outfit_Midnight_Black",(0.025,0.018,0.045),0.18,0.36)
cloth2=mat("Outfit_Charcoal",(0.12,0.09,0.15),0.12,0.42)
red=mat("Eye_Ruby_Red",(0.85,0.012,0.045),0.1,0.22)
white=mat("Eye_White",(1.0,0.94,0.88),0,0.25)
gold=mat("Trim_Antique_Gold",(0.78,0.42,0.12),0.72,0.28)
bootmat=mat("Boots_Leather",(0.035,0.025,0.04),0.22,0.3)

# Create armature in standard upright Z-up space, character faces -Y.
bpy.ops.object.armature_add(enter_editmode=True, location=(0,0,0))
rig=bpy.context.object; rig.name="Neko_Rig"; rig.data.name="Neko_Humanoid_Skeleton"
eb=rig.data.edit_bones; eb.remove(eb[0])
bones={
"root":((0,0,0),(0,0,0.15),None),
"hips":((0,0,0.88),(0,0,1.12),"root"),
"spine":((0,0,1.12),(0,0,1.48),"hips"),
"chest":((0,0,1.48),(0,0,1.68),"spine"),
"neck":((0,0,1.68),(0,0,1.82),"chest"),
"head":((0,0,1.82),(0,0,2.12),"neck"),
"upper_arm.L":((0.16,0,1.60),(0.42,0,1.48),"chest"),
"lower_arm.L":((0.42,0,1.48),(0.57,-0.01,1.25),"upper_arm.L"),
"hand.L":((0.57,-0.01,1.25),(0.61,-0.05,1.15),"lower_arm.L"),
"upper_arm.R":((-0.16,0,1.60),(-0.42,0,1.48),"chest"),
"lower_arm.R":((-0.42,0,1.48),(-0.57,-0.01,1.25),"upper_arm.R"),
"hand.R":((-0.57,-0.01,1.25),(-0.61,-0.05,1.15),"lower_arm.R"),
"upper_leg.L":((0.105,0,0.95),(0.13,0,0.55),"hips"),
"lower_leg.L":((0.13,0,0.55),(0.13,-0.04,0.16),"upper_leg.L"),
"foot.L":((0.13,-0.04,0.16),(0.13,-0.20,0.10),"lower_leg.L"),
"upper_leg.R":((-0.105,0,0.95),(-0.13,0,0.55),"hips"),
"lower_leg.R":((-0.13,0,0.55),(-0.13,-0.04,0.16),"upper_leg.R"),
"foot.R":((-0.13,-0.04,0.16),(-0.13,-0.20,0.10),"lower_leg.R")}
for n,(h,t,p) in bones.items():
 b=eb.new(n); b.head=h; b.tail=t
 if p: b.parent=eb[p]
bpy.ops.object.mode_set(mode="OBJECT")
rig.show_in_front=True

def uv(name, loc, scale, material, bone=None, seg=24, rings=16):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=seg, ring_count=rings, location=loc)
    o=bpy.context.object; o.name=name; o.scale=scale; bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    o.data.materials.append(material)
    if bone:
        # rigid skinning for each piece; model is modular but truly attached to the armature
        vg=o.vertex_groups.new(name=bone); vg.add(list(range(len(o.data.vertices))),1.0,"REPLACE")
        mod=o.modifiers.new("Neko_Armature","ARMATURE"); mod.object=rig
        o.parent=rig
    bevel=o.modifiers.new("Smooth_Surface","SUBSURF"); bevel.levels=1; bevel.render_levels=1
    o.modifiers.new("Weighted_Normals","WEIGHTED_NORMAL")
    return o

def cone_between(name, a, b, radius1, radius2, material, bone=None, verts=16):
    mid=(Vector(a)+Vector(b))/2; d=Vector(b)-Vector(a)
    bpy.ops.mesh.primitive_cone_add(vertices=verts, radius1=radius1, radius2=radius2, depth=d.length, location=mid)
    o=bpy.context.object; o.name=name; o.rotation_mode="QUATERNION"; o.rotation_quaternion=d.to_track_quat('Z','Y')
    o.data.materials.append(material)
    if bone:
        vg=o.vertex_groups.new(name=bone); vg.add(list(range(len(o.data.vertices))),1.0,"REPLACE")
        mod=o.modifiers.new("Neko_Armature","ARMATURE"); mod.object=rig; o.parent=rig
    bevel=o.modifiers.new("Soft_Edges","BEVEL"); bevel.width=.025; bevel.segments=2
    o.modifiers.new("Weighted_Normals","WEIGHTED_NORMAL")
    return o

# Body silhouette
uv("Torso_Dress",(0,0,1.42),(.28,.16,.37),cloth,"spine")
uv("Chest_Bodice",(0,-.012,1.57),(.255,.145,.20),cloth2,"chest")
uv("Waist_Belt",(0,-.005,1.20),(.255,.17,.065),gold,"hips")
uv("Skirt_Main",(0,0,1.12),(.34,.23,.20),cloth,"hips")
for i in range(7):
    a=2*math.pi*i/7
    p=(.25*math.sin(a),.16*math.cos(a),1.10)
    panel=uv("Skirt_Panel_%02d"%i,p,(.09,.07,.22),cloth2,"hips",16,12)
    panel.rotation_euler[1]=math.sin(a)*.18
# Neck, head and face
uv("Neck",(0,0,1.77),(.085,.08,.13),skin,"neck")
uv("Anime_Head",(0,-.012,1.96),(.19,.17,.245),skin,"head",32,24)
# eyes on front (-Y), both large and red
for side in [-1,1]:
    x=side*.083
    uv("Eye_White",(x,-.166,1.99),(.061,.022,.045),white,"head",20,12)
    uv("Ruby_Anime_Iris",(x,-.187,1.991),(.035,.012,.036),red,"head",20,12)
    uv("Eye_Glint",(x-.009,-.198,2.008),(.009,.006,.011),white,"head",12,8)
    # brows
    uv("Brow",(x,-.171,2.052),(.046,.008,.009),hair,"head",12,8)
uv("Mouth",(0,-.177,1.91),(.018,.006,.006),red,"head",12,8)
# bob hair cap and layered locks
uv("Hair_Cap",(0,.005,2.105),(.205,.185,.15),hair,"head",28,18)
for i in range(11):
    x=-.18+i*.036
    z=2.055 + .012*math.cos(i*.8)
    lock=uv("Bob_Lock_%02d"%i,(x,-.075,z),(.034,.11,.13+0.025*(i%3)),hair_hi if i%3==0 else hair,"head",16,12)
# side/back locks
for side in [-1,1]:
    for j in range(3):
        uv("Side_Hair_%s_%d"%(side,j),(side*(.17+.012*j),.015,1.98-j*.07),(.055,.09,.105),hair if j%2 else hair_hi,"head",16,12)
# Arms and gloves
for side,label in [(1,"L"),(-1,"R")]:
    uv("Shoulder_"+label,(side*.22,0,1.59),(.13,.14,.13),cloth2,"upper_arm."+label,20,12)
    cone_between("UpperArm_"+label,(side*.22,0,1.59),(side*.42,0,1.48),.075,.06,skin,"upper_arm."+label)
    cone_between("Sleeve_"+label,(side*.24,0,1.58),(side*.42,0,1.48),.095,.075,cloth,"upper_arm."+label)
    cone_between("Forearm_"+label,(side*.42,0,1.48),(side*.57,-.01,1.25),.06,.045,skin,"lower_arm."+label)
    cone_between("Glove_"+label,(side*.43,-.005,1.46),(side*.57,-.015,1.27),.072,.052,bootmat,"lower_arm."+label)
    uv("Hand_"+label,(side*.60,-.04,1.20),(.055,.045,.075),skin,"hand."+label)
# legs, stockings, boots
for side,label in [(1,"L"),(-1,"R")]:
    cone_between("Thigh_"+label,(side*.11,0,.96),(side*.13,0,.56),.105,.075,skin,"upper_leg."+label)
    cone_between("Stocking_"+label,(side*.11,-.005,.95),(side*.13,-.005,.56),.11,.078,cloth,"upper_leg."+label)
    cone_between("Shin_"+label,(side*.13,0,.56),(side*.13,-.035,.17),.071,.045,skin,"lower_leg."+label)
    cone_between("Boot_"+label,(side*.13,-.025,.45),(side*.13,-.12,.13),.09,.07,bootmat,"lower_leg."+label)
    uv("Boot_Sole_"+label,(side*.13,-.13,.095),(.09,.17,.035),gold,"foot."+label,16,8)
# decorative buttons / ribbons
for z in [1.48,1.40,1.32]:
    uv("Bodice_Button",(0,-.151,z),(.018,.01,.018),gold,"chest",12,8)
uv("Hair_Ornament",(0.13,-.153,2.10),(.045,.012,.06),gold,"head",16,12)

# Actions with bone rotation keys; export them as individual glTF clips via NLA.
def make_action(name, poses, end=24, loop=False):
    bpy.ops.object.select_all(action="DESELECT")
    rig.select_set(True)
    bpy.context.view_layer.objects.active=rig
    if rig.animation_data:
        rig.animation_data.action = None
    bpy.ops.object.mode_set(mode="POSE")
    for pb in rig.pose.bones: pb.rotation_mode='XYZ'
    for frame, mapping in poses:
        for bone, rot in mapping.items():
            pb=rig.pose.bones.get(bone)
            if pb:
                pb.rotation_euler=tuple(radians(v) for v in rot)
                pb.keyframe_insert(data_path="rotation_euler",frame=frame,group=bone)
    bpy.ops.object.mode_set(mode="OBJECT")
    act=rig.animation_data.action
    act.name=name
    act.use_fake_user=True
    for fc in act.fcurves:
        for kp in fc.keyframe_points: kp.interpolation='BEZIER'
    scene=bpy.context.scene; scene.frame_start=1; scene.frame_end=end
    return act
base={"spine":(0,0,0),"head":(0,0,0),"upper_arm.L":(0,0,0),"upper_arm.R":(0,0,0),"upper_leg.L":(0,0,0),"upper_leg.R":(0,0,0)}
make_action("Idle",[(1,base),(12,{"spine":(1,0,0),"head":(-1,0,1)}),(24,base)],24,True)
make_action("Walk",[(1,{"upper_leg.L":(25,0,0),"upper_leg.R":(-25,0,0),"upper_arm.L":(-18,0,0),"upper_arm.R":(18,0,0)}),(7,base),(13,{"upper_leg.L":(-25,0,0),"upper_leg.R":(25,0,0),"upper_arm.L":(18,0,0),"upper_arm.R":(-18,0,0)}),(19,base),(25,{"upper_leg.L":(25,0,0),"upper_leg.R":(-25,0,0),"upper_arm.L":(-18,0,0),"upper_arm.R":(18,0,0)})],25,True)
make_action("Run",[(1,{"upper_leg.L":(42,0,0),"upper_leg.R":(-42,0,0),"upper_arm.L":(-35,0,0),"upper_arm.R":(35,0,0)}),(7,{"upper_leg.L":(-42,0,0),"upper_leg.R":(42,0,0),"upper_arm.L":(35,0,0),"upper_arm.R":(-35,0,0)}),(13,{"upper_leg.L":(42,0,0),"upper_leg.R":(-42,0,0),"upper_arm.L":(-35,0,0),"upper_arm.R":(35,0,0)})],13,True)
make_action("Aim",[(1,{"upper_arm.L":(-35,0,-20),"upper_arm.R":(-45,0,20),"spine":(-5,0,0)}),(24,{"upper_arm.L":(-35,0,-20),"upper_arm.R":(-45,0,20),"spine":(-5,0,0)})],24,True)
make_action("Shoot",[(1,{"upper_arm.L":(-35,0,-20),"upper_arm.R":(-45,0,20)}),(3,{"upper_arm.L":(-30,0,-20),"upper_arm.R":(-55,0,20)}),(8,{"upper_arm.L":(-35,0,-20),"upper_arm.R":(-45,0,20)})],8,False)
make_action("Reload",[(1,{"upper_arm.L":(-20,0,-15),"upper_arm.R":(-25,0,15)}),(12,{"upper_arm.L":(-55,0,-15),"upper_arm.R":(-20,0,15)}),(24,{"upper_arm.L":(-20,0,-15),"upper_arm.R":(-25,0,15)})],24,False)
make_action("Hit",[(1,{"spine":(0,0,-10),"head":(0,0,-8)}),(8,{"spine":(12,0,12),"head":(-8,0,5)}),(18,base)],18,False)
make_action("Death",[(1,base),(18,{"spine":(35,0,15),"head":(20,0,20),"upper_leg.L":(45,0,0),"upper_leg.R":(-30,0,0)}),(36,{"spine":(75,0,25),"head":(35,0,25),"upper_leg.L":(75,0,0),"upper_leg.R":(-60,0,0)})],36,False)

# Blender's glTF exporter does not reliably emit every fake-user action as a
# separate clip. Give every action its own NLA track so the exported GLB
# contains the complete, correctly named animation set.
required_actions=("Idle","Walk","Run","Aim","Shoot","Reload","Hit","Death")
rig.animation_data_create()
rig.animation_data.action=None
for action_name in required_actions:
    action=bpy.data.actions.get(action_name)
    if action is None:
        raise RuntimeError("Required animation action was not generated: "+action_name)
    track=rig.animation_data.nla_tracks.new()
    track.name=action_name
    strip=track.strips.new(action_name,int(action.frame_range[0]),action)
    strip.blend_type='REPLACE'
    strip.extrapolation='NOTHING'

# Export selected armature and all character meshes.
bpy.ops.object.select_all(action="DESELECT")
rig.select_set(True)
for o in bpy.context.scene.objects:
    if o.type=="MESH": o.select_set(True)
bpy.context.view_layer.objects.active=rig
bpy.ops.export_scene.gltf(filepath=OUT, export_format='GLB', use_selection=True,
    export_animations=True, export_nla_strips=True, export_skins=True, export_materials='EXPORT',
    export_apply=True, export_yup=True)
print("EXPORTED_CHARACTER:", OUT)
