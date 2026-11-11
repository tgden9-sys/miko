"""Run in Blender's Text Editor, or use Open MIKO7.cmd, to show the MIKO sidebar."""
import bpy
from mathutils import Matrix,Vector

def rig():return bpy.data.objects.get('MIKO7_RIG')

def reset():
    r=rig()
    if not r:return
    r.animation_data.action=None
    for p in r.pose.bones:
        p.matrix_basis=Matrix.Identity(4)
        for k in ['Grip','Thumb','Index','Middle','Ring','Pinky','IK']:
            if k in p:p[k]=0.0
    r.update_tag();bpy.context.view_layer.update()

class MIKO_OT_Rest(bpy.types.Operator):
    bl_idname='miko.rest';bl_label='Rest pose';bl_options={'REGISTER','UNDO'}
    def execute(self,context):reset();return {'FINISHED'}

class MIKO_OT_Preview(bpy.types.Operator):
    bl_idname='miko.preview';bl_label='Load animation';bl_options={'REGISTER','UNDO'}
    def execute(self,context):
        reset();r=rig();a=bpy.data.actions.get(context.scene.miko_clip)
        if a:
            r.animation_data.action=a
            context.scene.frame_start=int(a.frame_range[0]);context.scene.frame_end=int(a.frame_range[1])-(1 if a.name.endswith('_Loop') else 0);context.scene.frame_set(context.scene.frame_start)
        return {'FINISHED'}

class MIKO_OT_Grab(bpy.types.Operator):
    bl_idname='miko.grab';bl_label='Move limb with IK';bl_options={'REGISTER','UNDO'}
    control:bpy.props.StringProperty()
    def execute(self,context):
        r=rig();s=self.control[-1];part='hand' if 'hand' in self.control else 'foot'
        end='forearm' if part=='hand' else 'shin';start='upper_arm' if part=='hand' else 'thigh';pole='elbow' if part=='hand' else 'knee'
        ctrl=r.pose.bones[self.control];joint=r.pose.bones['DEF-'+end+'.'+s];upper=r.pose.bones['DEF-'+start+'.'+s]
        wrist=joint.tail.copy();elbow=joint.head.copy();shoulder=upper.head.copy()
        line=wrist-shoulder;t=(elbow-shoulder).dot(line)/max(line.length_squared,1e-9)
        away=elbow-(shoulder+t*line)
        if away.length<.001:away=Vector((0,-1,0))
        m=ctrl.matrix.copy();m.translation=wrist;ctrl.matrix=m
        pc=r.pose.bones[f'CTRL-{pole}_pole.{s}'];m=pc.matrix.copy();m.translation=elbow+away.normalized()*.15;pc.matrix=m
        ctrl['IK']=1.0;r.update_tag()
        if context.object and context.object.mode!='OBJECT':bpy.ops.object.mode_set(mode='OBJECT')
        for o in context.selected_objects:o.select_set(False)
        r.select_set(True);context.view_layer.objects.active=r
        bpy.ops.object.mode_set(mode='POSE')
        for b in r.data.bones:b.select=False
        r.data.bones[self.control].select=True;r.data.bones.active=r.data.bones[self.control]
        return {'FINISHED'}

class MIKO_PT_Controls(bpy.types.Panel):
    bl_label='MIKO7 • Character controls';bl_idname='MIKO_PT_controls';bl_space_type='VIEW_3D';bl_region_type='UI';bl_category='MIKO'
    def draw(self,context):
        l=self.layout;r=rig()
        if not r:l.label(text='Open the MIKO7 rig first');return
        l.prop(context.scene,'miko_clip',text='Clip')
        row=l.row(align=True);row.operator('miko.preview',text='Load clip');row.operator('screen.animation_play',text='Play / pause')
        l.operator('miko.rest',text='Reset to original pose')
        l.label(text='Hands: 0 = original curl')
        l.label(text='Negative opens; positive closes')
        for s,label in [('L','Left hand'),('R','Right hand')]:
            box=l.box();box.label(text=label);p=r.pose.bones['CTRL-hand.'+s]
            for k in ['Grip','Thumb','Index','Middle','Ring','Pinky']:box.prop(p,f'["{k}"]',text=k,slider=True)
            box.operator('miko.grab',text='Pose wrist (IK)').control='CTRL-hand.'+s
            box.prop(p,'["IK"]',text='IK influence',slider=True)
        row=l.row(align=True)
        for s in ['L','R']:row.operator('miko.grab',text='Pose foot '+s).control='CTRL-foot.'+s
        l.label(text='FK: select a bone and press R')
        l.label(text='IK: select a control and press G')

classes=[MIKO_OT_Rest,MIKO_OT_Preview,MIKO_OT_Grab,MIKO_PT_Controls]
for cls in classes:
    identifier=cls.bl_idname if issubclass(cls,bpy.types.Panel) else cls.bl_idname.split('.')[0].upper()+'_OT_'+cls.bl_idname.split('.')[1]
    old=getattr(bpy.types,identifier,None)
    if old:
        try:bpy.utils.unregister_class(old)
        except RuntimeError:pass
    bpy.utils.register_class(cls)
items=[(a.name,a.name.replace('MIKO7_','').replace('_',' '),'Retargeted Quaternius animation') for a in bpy.data.actions if a.name.startswith('MIKO7_')]
bpy.types.Scene.miko_clip=bpy.props.EnumProperty(name='Animation',items=items)
for window in bpy.context.window_manager.windows:
    for area in window.screen.areas:
        if area.type=='VIEW_3D':area.spaces.active.show_region_ui=True
print('MIKO controls ready: press N in the 3D viewport and choose the MIKO tab.')
