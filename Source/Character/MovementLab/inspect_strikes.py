"""Print world-space sword-tip travel from converted tracks for timing review."""
import pathlib,json,struct,numpy as np
root=pathlib.Path(__file__).resolve().parents[3]
raw=(root/'MovementLab/models/Miko.glb').read_bytes()
j=json.loads(raw[20:20+struct.unpack_from('<I',raw,12)[0]])
nodes={n.get('name'):n for n in j['nodes']}
parents={j['nodes'][c].get('name'):n.get('name') for n in j['nodes'] for c in n.get('children',[])}
def matrix(q,p):
 x,y,z,w=q
 m=np.eye(4)
 m[:3,:3]=[[1-2*y*y-2*z*z,2*x*y-2*w*z,2*x*z+2*w*y],[2*x*y+2*w*z,1-2*x*x-2*z*z,2*y*z-2*w*x],[2*x*z-2*w*y,2*y*z+2*w*x,1-2*x*x-2*y*y]]
 m[:3,3]=p
 return m
index=np.array(nodes['DEF-f_index.01.R']['translation'])
pinky=np.array(nodes['DEF-f_pinky.01.R']['translation'])
tip=(index+pinky)*.43+(index-pinky)/np.linalg.norm(index-pinky)*1.04
for file in ['LabActions','MIKO8_Combat']:
 for name,c in json.loads((root/f'MovementLab/models/{file}.json').read_text())['clips'].items():
  if name not in ['Uppercut','AirA','AirCombo','GroundPound','SwordBlock','SwordA','SwordB','SwordC']:continue
  print(name,'frames',len(c['frames']))
  coords=[]
  for i,f in enumerate(c['frames']):
   cache={}
   def world(n):
    if n in cache:return cache[n]
    m=matrix(f[n]['q'],f[n]['p'])
    if parents.get(n) in f:m=world(parents[n])@m
    cache[n]=m
    return m
   v=world('DEF-hand.R')@np.append(tip,1)
   coords.append(v[:3])
  print('frame, tip forward, tip height, tip sideways')
  for i,v in enumerate(coords):
   if i%2==0: print(i,*(round(x,2) for x in [v[2],v[1],v[0]]))
