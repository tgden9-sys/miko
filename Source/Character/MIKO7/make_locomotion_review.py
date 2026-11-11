from PIL import Image,ImageDraw
from pathlib import Path
import json
BASE=Path(__file__).resolve().parent;qa=BASE.parents[2]/'Builds'/'Validation'/'MIKO7'/'v3'
meta=json.loads((BASE/'MIKO7_Locomotion_v3.json').read_text())
sheet=Image.new('RGB',(2000,440*len(meta['clips'])),(36,41,49));d=ImageDraw.Draw(sheet)
for row,clip in enumerate(meta['clips']):
    for i in range(5):
        path=qa/f'{clip}_{i}.png'
        if not path.exists():continue
        im=Image.open(path).convert('RGBA');bg=Image.new('RGBA',im.size,(36,41,49,255));bg.alpha_composite(im)
        x=i*400;y=row*440;sheet.paste(bg.convert('RGB'),(x,y));d.text((x+10,y+408),f'{clip} / {i*25}%',fill='white')
sheet.save(qa/'locomotion_contact_sheet.jpg',quality=90)
for group in [('Idle','Walk','Sprint'),('JumpStart','JumpAir','JumpLand'),('Turn180Left','Turn180Right'),('Turn90Left','Turn90Right')]:
    out=Image.new('RGB',(2000,440*len(group)),(36,41,49))
    for row,clip in enumerate(group):
        source=list(meta['clips']).index(clip);out.paste(sheet.crop((0,source*440,2000,(source+1)*440)),(0,row*440))
    out.save(qa/('review_'+group[0]+'.jpg'),quality=92)
