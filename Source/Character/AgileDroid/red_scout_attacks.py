"""Author scout attack poses in metres, with -Y forward and +Z up."""
from math import radians

import bpy
from mathutils import Euler, Vector


def smoothstep(value):
    t = max(0.0, min(1.0, value))
    return t * t * (3.0 - 2.0 * t)


def sample(keys, frame):
    for (start, a), (end, b) in zip(keys, keys[1:]):
        if frame <= end:
            t = smoothstep((frame - start) / (end - start))
            return tuple(x + (y - x) * t for x, y in zip(a, b))
    return keys[-1][1]


def world_rotation(pose, rotation):
    rest = pose.bone.matrix_local.to_quaternion()
    if pose.parent:
        parent_rest = pose.parent.bone.matrix_local.to_quaternion()
        local_rest = parent_rest.inverted() @ rest
        rotation = local_rest.inverted() @ pose.parent.matrix.to_quaternion().inverted() @ rotation
    else:
        rotation = rest.inverted() @ rotation
    pose.rotation_quaternion = rotation
    bpy.context.view_layer.update()


def turn(pose, pitch, twist):
    rotate = Euler((radians(pitch), 0, radians(twist)), 'XYZ').to_quaternion()
    world_rotation(pose, rotate @ pose.bone.matrix_local.to_quaternion())


def aim(pose, direction):
    rest = pose.bone.matrix_local.to_quaternion()
    normal = rest @ Vector((0, 1, 0))
    world_rotation(pose, normal.rotation_difference(direction.normalized()) @ rest)


def bend(bones, upper, lower, end, target, pole):
    """Solve the knee/elbow from a hand or ankle target and a bend direction."""
    origin = bones[upper].head.copy()
    delta = target - origin
    direction = delta.normalized()
    a = (bones[lower].bone.head_local - bones[upper].bone.head_local).length
    b = (bones[end].bone.head_local - bones[lower].bone.head_local).length
    reach = max(abs(a - b) + .002, min(delta.length, a + b - .002))
    along = (a*a + reach*reach - b*b) / (2 * reach)
    lateral = (pole - pole.dot(direction) * direction).normalized()
    joint = origin + direction * along + lateral * max(0, a*a - along*along)**.5
    aim(bones[upper], joint - origin)
    aim(bones[lower], origin + direction * reach - bones[lower].head)


def build_attacks(rig, scene, animated_bones):
    # Hip offsets (forward, height), then torso pitch and shoulder twist.
    lunge_body = [(0, (0, -.035, 5, 7)), (6, (-.07, -.13, 7, 34)),
                  (9, (-.055, -.145, 14, 37)), (13, (.04, -.09, 26, 12)),
                  (16, (.064, -.09, 30, -29)), (20, (.018, -.135, 20, -21)),
                  (26, (.0, -.065, 9, -5)), (32, (0, -.035, 5, 7))]
    # Ankle paths in world space. The rear foot stays down for the load, and
    # the front foot holds its landing while the chassis catches up to it.
    lunge_front = [(0, (.19, 0, 0)), (5, (.19, 0, 0)), (9, (.45, .095, -9)),
                   (13, (1.00, .14, -12)), (17, (1.48, 0, 0)), (24, (1.48, 0, 0)),
                   (28, (1.63, .045, -4)), (32, (1.67, 0, 0))]
    lunge_back = [(0, (-.15, 0, 0)), (10, (-.15, 0, 0)), (13, (.04, .07, 22)),
                  (17, (.78, .13, 18)), (22, (1.23, 0, 0)), (32, (1.23, 0, 0))]
    # Hands use lateral, forward and height targets. The right forearm leads.
    lunge_strike = [(0, (-.39, .29, 1.15)), (6, (-.51, -.29, 1.39)),
                    (9, (-.51, -.32, 1.43)), (12, (-.51, .28, 1.41)),
                    (15, (-.33, .77, 1.32)), (18, (.16, .62, 1.16)),
                    (22, (.24, .38, 1.11)), (27, (-.18, .37, 1.12)), (32, (-.39, .29, 1.15))]
    lunge_guard = [(0, (.35, .36, 1.29)), (8, (.33, .49, 1.38)), (13, (.39, .26, 1.29)),
                   (17, (.45, -.18, 1.18)), (22, (.46, -.18, 1.15)), (32, (.35, .36, 1.29))]

    specs = {
        'Lunge': (32, lunge_body, lunge_front, lunge_back, lunge_strike, lunge_guard),
        'Dive': (11,
                 [(0, (0, -.11, 10, 22)), (4, (.018, -.09, 27, 5)), (11, (.045, -.05, 39, -26))],
                 [(0, (.39, .29, 9)), (5, (.43, .24, 3)), (11, (.30, .10, 0))],
                 [(0, (-.32, .32, 32)), (5, (-.34, .28, 22)), (11, (-.27, .14, 8))],
                 [(0, (-.47, -.16, 1.48)), (4, (-.53, .23, 1.53)),
                  (7, (-.40, .70, 1.13)), (11, (-.24, .66, .92))],
                 [(0, (.38, .40, 1.38)), (5, (.39, .24, 1.38)), (11, (.44, -.16, 1.18))]),
        'Recoil': (10,
                   [(0, (-.09, -.09, -19, -22)), (3, (-.09, -.14, -11, -16)), (10, (0, -.035, 5, 7))],
                   [(0, (.19, 0, 0)), (10, (.19, 0, 0))],
                   [(0, (-.25, 0, 0)), (10, (-.15, 0, 0))],
                   [(0, (-.58, -.06, 1.40)), (5, (-.49, .13, 1.20)), (10, (-.39, .29, 1.15))],
                   [(0, (.50, -.13, 1.31)), (10, (.35, .36, 1.29))]),
    }
    actions = []
    bones = rig.pose.bones
    for name, (last, body, front, back, strike, guard) in specs.items():
        action = bpy.data.actions.new('Scout_' + name)
        action.use_fake_user = True
        rig.animation_data.action = action
        previous = {}
        for frame in range(last + 1):
            scene.frame_set(frame)
            for pose in bones:
                pose.rotation_mode = 'QUATERNION'
                pose.matrix_basis.identity()
            forward, height, pitch, twist = sample(body, frame)
            root = bones['root']
            root.location = root.bone.matrix_local.to_3x3().inverted() @ Vector((0, -forward, height))
            bpy.context.view_layer.update()
            turn(bones['DEF-hips'], pitch * .20, twist * .20)
            turn(bones['DEF-spine.001'], pitch * .44, twist * .43)
            turn(bones['DEF-spine.002'], pitch * .73, twist * .70)
            turn(bones['DEF-spine.003'], pitch, twist)
            turn(bones['DEF-neck'], pitch * .44, twist * .37)
            turn(bones['DEF-head'], pitch * .24, twist * .12)
            # Match the game's physical slide curve (0.86 is the model scale).
            travel = 1.48 * smoothstep((frame - 8) / 14) if name == 'Lunge' else 0
            for side, sign, foot_keys, hand_keys in [('L', 1, front, guard), ('R', -1, back, strike)]:
                foot_forward, lift, foot_pitch = sample(foot_keys, frame)
                ankle = Vector((sign * .235, travel - foot_forward, .188 + lift))
                bend(bones, f'DEF-thigh.{side}', f'DEF-shin.{side}', f'DEF-foot.{side}',
                     ankle, Vector((sign * .17, -1, 0)))
                turn(bones[f'DEF-foot.{side}'], foot_pitch, sign * 5)
                x, y, z = sample(hand_keys, frame)
                bend(bones, f'DEF-upper_arm.{side}', f'DEF-forearm.{side}', f'DEF-hand.{side}',
                     Vector((x, -y, z + height * .34)), Vector((sign * .54, .14, -.86)))
            root.keyframe_insert('location', frame=frame, group='root')
            for bone_name in animated_bones:
                pose = bones[bone_name]
                rotation = pose.rotation_quaternion.copy()
                if bone_name in previous:
                    rotation.make_compatible(previous[bone_name])
                previous[bone_name] = rotation.copy()
                pose.rotation_quaternion = rotation
                pose.keyframe_insert('rotation_quaternion', frame=frame, group=bone_name)
        actions.append(action)
        rig.animation_data.action = None
    return actions
