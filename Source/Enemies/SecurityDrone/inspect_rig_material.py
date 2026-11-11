import bpy
from pathlib import Path
root = Path(__file__).resolve().parent
bpy.ops.wm.open_mainfile(filepath=str(root / 'security_drone_rig.blend'))
for name in ('Drone_Body', 'Visor_Alert_Lens'):
    obj = bpy.data.objects[name]
    print('OBJECT', name, len(obj.data.vertices), [m.name for m in obj.data.materials])
    for mat in obj.data.materials:
        print('MATERIAL', mat.name)
        for node in mat.node_tree.nodes:
            print('NODE', node.name, node.type)
        for link in mat.node_tree.links:
            print('LINK', link.from_node.name, link.from_socket.name, '->', link.to_node.name, link.to_socket.name)
