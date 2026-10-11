"""Rig the authored static anime-model.glb without replacing its geometry.

The source GLB is intentionally kept as the only character source. Blender
imports its separate face, hair, clothing, and body meshes, builds a humanoid
armature, assigns vertex weights, adds distinct actions, and exports a rigged
GLB for GitHub Actions to validate before replacing the source asset.
"""

import math
import os

import bpy
from mathutils import Vector


ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "../.."))
INPUT = os.environ.get(
    "NEKO_INPUT", os.path.join(ROOT, "assets/characters/player/anime-model.glb")
)
OUTPUT = os.environ.get(
    "NEKO_OUTPUT", os.path.join(ROOT, "build/anime-model-rigged.glb")
)


def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for datablocks in (bpy.data.actions, bpy.data.armatures, bpy.data.meshes):
        for datablock in list(datablocks):
            if datablock.users == 0:
                datablocks.remove(datablock)


def world_bounds(meshes):
    points = [obj.matrix_world @ Vector(corner) for obj in meshes for corner in obj.bound_box]
    if not points:
        raise RuntimeError("anime-model.glb contains no mesh geometry")
    minimum = Vector((min(p.x for p in points), min(p.y for p in points), min(p.z for p in points)))
    maximum = Vector((max(p.x for p in points), max(p.y for p in points), max(p.z for p in points)))
    return minimum, maximum


def build_rig(minimum, maximum):
    center = (minimum + maximum) * 0.5
    height = maximum.z - minimum.z
    width = maximum.x - minimum.x
    if height <= 0.2 or width <= 0.1:
        raise RuntimeError("anime-model.glb has implausible character bounds")

    z = minimum.z
    # Bone positions are derived from the authored model bounds, not a new mesh.
    positions = {
        "root": ((center.x, center.y, z), (center.x, center.y, z + height * 0.08), None),
        "Hips": ((center.x, center.y, z + height * 0.46), (center.x, center.y, z + height * 0.56), "root"),
        "Spine": ((center.x, center.y, z + height * 0.56), (center.x, center.y, z + height * 0.70), "Hips"),
        "Chest": ((center.x, center.y, z + height * 0.70), (center.x, center.y, z + height * 0.80), "Spine"),
        "Neck": ((center.x, center.y, z + height * 0.80), (center.x, center.y, z + height * 0.86), "Chest"),
        "Head": ((center.x, center.y, z + height * 0.86), (center.x, center.y, maximum.z), "Neck"),
    }
    for side, label in ((-1, "L"), (1, "R")):
        shoulder = center.x + side * width * 0.16
        elbow = center.x + side * width * 0.31
        wrist = center.x + side * width * 0.43
        hip = center.x + side * width * 0.10
        knee = center.x + side * width * 0.11
        positions[f"UpperArm_{label}"] = (
            (shoulder, center.y, z + height * 0.76),
            (elbow, center.y, z + height * 0.67),
            "Chest",
        )
        positions[f"LowerArm_{label}"] = (
            (elbow, center.y, z + height * 0.67),
            (wrist, center.y, z + height * 0.57),
            f"UpperArm_{label}",
        )
        positions[f"Hand_{label}"] = (
            (wrist, center.y, z + height * 0.57),
            (center.x + side * width * 0.47, center.y, z + height * 0.54),
            f"LowerArm_{label}",
        )
        positions[f"UpperLeg_{label}"] = (
            (hip, center.y, z + height * 0.48),
            (knee, center.y, z + height * 0.28),
            "Hips",
        )
        positions[f"LowerLeg_{label}"] = (
            (knee, center.y, z + height * 0.28),
            (knee, center.y, z + height * 0.08),
            f"UpperLeg_{label}",
        )
        positions[f"Foot_{label}"] = (
            (knee, center.y, z + height * 0.08),
            (knee, minimum.y, z + height * 0.04),
            f"LowerLeg_{label}",
        )

    armature_data = bpy.data.armatures.new("Neko_Humanoid_Skeleton")
    rig = bpy.data.objects.new("Neko_Humanoid_Rig", armature_data)
    bpy.context.collection.objects.link(rig)
    bpy.context.view_layer.objects.active = rig
    rig.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    edit_bones = armature_data.edit_bones
    for name, (head, tail, parent_name) in positions.items():
        bone = edit_bones.new(name)
        bone.head = head
        bone.tail = tail if (Vector(tail) - Vector(head)).length > 0.015 else Vector(head) + Vector((0, 0, 0.02))
        if parent_name:
            bone.parent = edit_bones[parent_name]
    bpy.ops.object.mode_set(mode="OBJECT")
    rig.show_in_front = True
    return rig, positions, center


def mesh_bone_name(obj, center):
    name = obj.name.lower().replace(".", "_")
    side = "L" if any(token in name for token in ("_l", "left", "-1")) else "R" if any(
        token in name for token in ("_r", "right", "_1")
    ) else ""
    if any(token in name for token in ("face", "eye", "iris", "pupil", "brow", "nose", "mouth", "ear", "hair", "bang", "bob", "pin")):
        return "Head"
    if "neck" in name:
        return "Neck"
    if any(token in name for token in ("hand", "cuff")) and side:
        return f"Hand_{side}"
    if any(token in name for token in ("forearm", "lower_arm", "sleeve")) and side:
        return f"LowerArm_{side}"
    if any(token in name for token in ("arm", "shoulder")) and side:
        return f"UpperArm_{side}"
    if any(token in name for token in ("shoe", "boot", "toe", "foot")) and side:
        return f"Foot_{side}"
    if any(token in name for token in ("calf", "stocking", "shin", "lower_leg")) and side:
        return f"LowerLeg_{side}"
    if any(token in name for token in ("thigh", "upper_leg", "leg")) and side:
        return f"UpperLeg_{side}"
    if any(token in name for token in ("skirt", "pleat", "waist", "belt")):
        return "Hips"
    if any(token in name for token in ("bodice", "chest", "torso", "lace")):
        return "Chest"
    position = obj.matrix_world.translation
    if position.z > center.z:
        return "Head"
    return "Spine"


def add_skinning(meshes, rig, center):
    for obj in meshes:
        # Make reruns deterministic when Actions imports the already-rigged
        # output from a previous successful push.
        world_transform = obj.matrix_world.copy()
        obj.parent = None
        obj.matrix_world = world_transform
        for modifier in list(obj.modifiers):
            if modifier.type == "ARMATURE":
                obj.modifiers.remove(modifier)
        for group in list(obj.vertex_groups):
            obj.vertex_groups.remove(group)
        bone_name = mesh_bone_name(obj, center)
        group = obj.vertex_groups.get(bone_name) or obj.vertex_groups.new(name=bone_name)
        group.add(list(range(len(obj.data.vertices))), 1.0, "REPLACE")
        modifier = obj.modifiers.new("Neko_Armature_Deform", "ARMATURE")
        modifier.object = rig
        obj.parent = rig


def ensure_uvs(meshes):
    for obj in meshes:
        if obj.data.uv_layers:
            continue
        bpy.ops.object.select_all(action="DESELECT")
        obj.select_set(True)
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.mode_set(mode="EDIT")
        bpy.ops.mesh.select_all(action="SELECT")
        bpy.ops.uv.smart_project(island_margin=0.02)
        bpy.ops.object.mode_set(mode="OBJECT")
        if not obj.data.uv_layers:
            raise RuntimeError("Could not generate UVs for mesh: " + obj.name)


def add_action(rig, name, frames, poses):
    bpy.context.view_layer.objects.active = rig
    bpy.ops.object.select_all(action="DESELECT")
    rig.select_set(True)
    rig.animation_data_create()
    rig.animation_data.action = None
    bpy.ops.object.mode_set(mode="POSE")
    for pose_bone in rig.pose.bones:
        pose_bone.rotation_mode = "XYZ"
    for frame, mapping in zip(frames, poses):
        for bone_name, degrees in mapping.items():
            pose_bone = rig.pose.bones.get(bone_name)
            if pose_bone:
                pose_bone.rotation_euler = tuple(math.radians(value) for value in degrees)
                pose_bone.keyframe_insert(data_path="rotation_euler", frame=frame, group=bone_name)
    bpy.ops.object.mode_set(mode="OBJECT")
    action = rig.animation_data.action
    action.name = name
    action.use_fake_user = True
    for curve in action.fcurves:
        for point in curve.keyframe_points:
            point.interpolation = "BEZIER"
    return action


def create_animations(rig):
    rest = {name: (0, 0, 0) for name in (
        "Spine", "Head", "UpperArm_L", "LowerArm_L", "UpperArm_R", "LowerArm_R",
        "UpperLeg_L", "LowerLeg_L", "UpperLeg_R", "LowerLeg_R",
    )}
    actions = []
    actions.append(add_action(rig, "Idle", [1, 13, 25], [rest, {**rest, "Spine": (1, 0, 0), "Head": (-1, 0, 1)}, rest]))
    for name, leg, arm, frames in (("Walk", 24, 14, [1, 7, 13, 19, 25]), ("Run", 40, 28, [1, 7, 13])):
        poses = []
        for index, sign in enumerate((1, -1, 1, -1, 1) if name == "Walk" else (1, -1, 1)):
            poses.append({**rest, "UpperLeg_L": (leg * sign, 0, 0), "UpperLeg_R": (-leg * sign, 0, 0),
                          "UpperArm_L": (-arm * sign, 0, 0), "UpperArm_R": (arm * sign, 0, 0)})
        actions.append(add_action(rig, name, frames, poses))
    actions.append(add_action(rig, "Aim", [1, 25], [
        {**rest, "UpperArm_L": (-34, 0, -18), "UpperArm_R": (-42, 0, 18), "Spine": (-4, 0, 0)},
        {**rest, "UpperArm_L": (-34, 0, -18), "UpperArm_R": (-42, 0, 18), "Spine": (-4, 0, 0)},
    ]))
    actions.append(add_action(rig, "Shoot", [1, 3, 8], [
        {**rest, "UpperArm_L": (-34, 0, -18), "UpperArm_R": (-42, 0, 18)},
        {**rest, "UpperArm_L": (-29, 0, -18), "UpperArm_R": (-51, 0, 18)}, rest,
    ]))
    actions.append(add_action(rig, "Reload", [1, 12, 24], [
        {**rest, "UpperArm_L": (-20, 0, -14), "UpperArm_R": (-24, 0, 14)},
        {**rest, "UpperArm_L": (-52, 0, -14), "UpperArm_R": (-18, 0, 14)},
        {**rest, "UpperArm_L": (-20, 0, -14), "UpperArm_R": (-24, 0, 14)},
    ]))
    actions.append(add_action(rig, "Hit", [1, 8, 18], [
        rest, {**rest, "Spine": (12, 0, 12), "Head": (-8, 0, 5)}, rest,
    ]))
    actions.append(add_action(rig, "Death", [1, 18, 36], [
        rest, {**rest, "Spine": (35, 0, 15), "Head": (20, 0, 20)},
        {**rest, "Spine": (75, 0, 25), "Head": (35, 0, 25), "UpperLeg_L": (55, 0, 0)},
    ]))
    rig.animation_data_create()
    rig.animation_data.action = None
    for action in actions:
        track = rig.animation_data.nla_tracks.new()
        track.name = action.name
        strip = track.strips.new(action.name, int(action.frame_range[0]), action)
        strip.blend_type = "REPLACE"
    return actions


def main():
    if not os.path.isfile(INPUT):
        raise FileNotFoundError("Character source GLB not found: " + INPUT)
    os.makedirs(os.path.dirname(OUTPUT), exist_ok=True)
    clear_scene()
    bpy.ops.import_scene.gltf(filepath=INPUT)
    meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    if not meshes:
        raise RuntimeError("anime-model.glb import produced no mesh objects")
    minimum, maximum = world_bounds(meshes)
    # Remove any prior exported rig, but keep the imported authored geometry.
    for obj in list(bpy.context.scene.objects):
        if obj.type == "ARMATURE":
            bpy.data.objects.remove(obj, do_unlink=True)
    ensure_uvs(meshes)
    rig, _positions, center = build_rig(minimum, maximum)
    add_skinning(meshes, rig, center)
    actions = create_animations(rig)
    bpy.ops.object.select_all(action="DESELECT")
    rig.select_set(True)
    for obj in meshes:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = rig
    bpy.ops.export_scene.gltf(
        filepath=OUTPUT,
        export_format="GLB",
        use_selection=True,
        export_animations=True,
        export_nla_strips=True,
        export_skins=True,
        export_materials="EXPORT",
        export_apply=True,
    )
    if not os.path.isfile(OUTPUT) or os.path.getsize(OUTPUT) < 1024:
        raise RuntimeError("Blender did not produce a valid-sized GLB")
    print("SOURCE_MESHES:", len(meshes))
    print("HUMANOID_BONES:", len(rig.data.bones))
    print("ANIMATION_CLIPS:", ",".join(action.name for action in actions))
    print("EXPORTED_RIGGED_CHARACTER:", OUTPUT)


main()
