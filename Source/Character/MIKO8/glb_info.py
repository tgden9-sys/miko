import json,struct,glob,os
def read(p):
 r=open(p,'rb').read();return json.loads(r[20:20+struct.unpack_from('<I',r,12)[0]])
B=os.path.dirname(__file__)
for p in [B+'/MIKO8_source.glb']+glob.glob(B+'/Templates/**/*.glb',recursive=True):
 d=read(p);print(os.path.basename(p),'nodes',len(d.get('nodes',[])),'skins',len(d.get('skins',[])))
 print('nodes',[(n.get('name'),n.get('translation'),n.get('rotation')) for n in d.get('nodes',[])][:8])
 print('animations',[(a.get('name'),len(a['channels']),max(d['accessors'][s['input']].get('max',[0])[0] for s in a['samplers'])) for a in d.get('animations',[])])
 if 'meshes' in d:
  print('position',[(d['accessors'][p['attributes']['POSITION']].get('min'),d['accessors'][p['attributes']['POSITION']].get('max'),d['accessors'][p['attributes']['POSITION']]['count']) for m in d['meshes'] for p in m['primitives']])
