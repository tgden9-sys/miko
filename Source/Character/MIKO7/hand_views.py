exec(compile(open(r'C:\Users\tgden\Desktop\MIKO\Source\Character\MIKO7\inspect_mesh.py').read().split('for name,vec in ')[0], 'inspect_setup', 'exec'))
scene.cycles.samples=12
for name,vec in [('hand_front',(0,-1,0)),('hand_side',(1,-.15,0)),('hand_back',(0,1,0))]:
    center=Vector((.23,.0,-.17));cam.data.ortho_scale=.21
    cam.location=center+Vector(vec);aim(cam,center)
    scene.render.filepath=os.path.join(r'C:\Users\tgden\Desktop\MIKO\Builds\Validation\MIKO7',name+'.png')
    bpy.ops.render.render(write_still=True)
