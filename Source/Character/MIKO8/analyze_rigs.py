import json,struct,os,numpy as np
from glb_info import read
B=os.path.dirname(__file__);Q=os.path.abspath(B+'/../../../Builds/Validation/MIKO8')
d=read(B+'/Templates/sprint-loop-1.0.7/public/humanoid-animation/quaternius-ual1-sprint-loop.glb');nodes=d['nodes'];parents={c:i for i,n in enumerate(nodes) for c in n.get('children',[])}
def mat(n):
 x,y,z,w=n.get('rotation',[0,0,0,1]);r=np.array([[1-2*y*y-2*z*z,2*x*y-2*z*w,2*x*z+2*y*w],[2*x*y+2*z*w,1-2*x*x-2*z*z,2*y*z-2*x*w],[2*x*z-2*y*w,2*y*z+2*x*w,1-2*x*x-2*y*y]]);m=np.eye(4);m[:3,:3]=r@np.diag(n.get('scale',[1,1,1]));m[:3,3]=n.get('translation',[0,0,0]);return m
cache={}
def world(i):
 if i not in cache:cache[i]=(world(parents[i]) if i in parents else np.eye(4))@mat(nodes[i])
 return cache[i]
print('NORMALIZED REST')
for i,n in enumerate(nodes):
 if any(k in n['name'] for k in ['Proximal','Intermediate','Distal']):continue
 print(n['name'],np.round(world(i)[:3,3],4).tolist())
print('OLD RIG REST')
for b in json.load(open(Q+'/source_skeleton.json'))['bones']:
 if 'f_' not in b['name'] and 'thumb' not in b['name']:print(b['name'],np.round(b['head'],4).tolist())
