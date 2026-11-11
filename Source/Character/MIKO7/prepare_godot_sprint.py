"""Copy the approved clip into Godot, shifting its frame-1 time origin to zero."""
import json,struct,pathlib
BASE=pathlib.Path(__file__).resolve().parent
source=BASE/'MIKO7_Sprint_Check.glb'
dest=BASE.parents[2]/'Game'/'models'/'miko7'/'MIKO7_Sprint_Check.glb'
raw=source.read_bytes();magic,version,total=struct.unpack_from('<III',raw)
chunks=[];cursor=12
while cursor<len(raw):
    size,kind=struct.unpack_from('<II',raw,cursor);cursor+=8
    chunks.append([kind,bytearray(raw[cursor:cursor+size])]);cursor+=size
doc=json.loads(chunks[0][1]);binary=next(data for kind,data in chunks if kind==0x004e4942)
inputs={s['input'] for a in doc['animations'] for s in a['samplers']}
offset=min(doc['accessors'][i]['min'][0] for i in inputs)
for i in inputs:
    a=doc['accessors'][i];assert a['componentType']==5126 and a['type']=='SCALAR'
    view=doc['bufferViews'][a['bufferView']];start=view.get('byteOffset',0)+a.get('byteOffset',0);stride=view.get('byteStride',4)
    values=[]
    for k in range(a['count']):
        p=start+k*stride;t=max(0.,struct.unpack_from('<f',binary,p)[0]-offset)
        struct.pack_into('<f',binary,p,t);values.append(t)
    a['min']=[min(values)];a['max']=[max(values)]
text=json.dumps(doc,separators=(',',':')).encode();text+=b' '*((-len(text))%4);chunks[0][1]=text
size=12+sum(8+len(data) for kind,data in chunks)
result=struct.pack('<III',magic,version,size)
for kind,data in chunks:result+=struct.pack('<II',len(data),kind)+data
dest.write_bytes(result)
report={'source':str(source),'godot_export':str(dest),'removed_leading_hold_seconds':offset,'clip_count':len(doc['animations']),'duration':max(doc['accessors'][i]['max'][0] for i in inputs)}
qa=BASE.parents[2]/'Builds'/'Validation'/'MIKO7'/'godot'
(qa/'export_timing.json').write_text(json.dumps(report,indent=2))
print(json.dumps(report))
