import bpy
from mathutils import Vector

BASE = r"C:\Users\tgden\Desktop\MIKO\Source\Enemies\SecurityRobot"
bpy.ops.wm.open_mainfile(filepath=BASE + r"\security_robot_rig.blend")
scene = bpy.context.scene
scene.render.engine = 'BLENDER_EEVEE'
scene.render.resolution_x = 900
scene.render.resolution_y = 900
scene.render.resolution_percentage = 100
scene.world.color = (0.16, 0.16, 0.16)
rig = bpy.data.objects['Security_Robot_Rig']

camera_data = bpy.data.cameras.new('QA Camera')
camera = bpy.data.objects.new('QA Camera', camera_data)
scene.collection.objects.link(camera)
scene.camera = camera
camera_data.type = 'ORTHO'
camera_data.ortho_scale = 1.35

for name, location, power, size in [
    ('QA Key', (2, -3, 3), 500, 3),
    ('QA Fill', (-2, 1, 1.5), 250, 3),
]:
    light_data = bpy.data.lights.new(name, 'AREA')
    light_data.energy = power
    light_data.shape = 'DISK'
    light_data.size = size
    light = bpy.data.objects.new(name, light_data)
    scene.collection.objects.link(light)
    light.location = location

for filename, action_name, frame, location in [
    ('rig_idle', 'Idle', 1, (1.5, -1.8, 0.65)),
    ('rig_weapon_raised', 'Raise_Weapon', 20, (1.5, -1.8, 0.65)),
    ('rig_pivot_mid', 'Pivot_Left', 13, (1.5, -1.8, 0.65)),
    ('rig_head_scan', 'Head_Scan', 12, (1.5, -1.8, 0.65)),
    ('rig_open_arm', 'Open_Arm_Test', 20, (1.5, -1.8, 0.65)),
]:
    rig.animation_data.action = bpy.data.actions[action_name]
    scene.frame_set(frame)
    camera.location = location
    camera.rotation_euler = (Vector((0, 0, 0)) - camera.location).to_track_quat('-Z', 'Y').to_euler()
    scene.render.filepath = BASE + '\\' + filename + '.png'
    bpy.ops.render.render(write_still=True)
