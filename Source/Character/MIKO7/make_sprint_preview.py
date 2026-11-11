from PIL import Image,ImageDraw
from pathlib import Path
base=Path(__file__).resolve().parents[3]/'Builds'/'Validation'/'MIKO7'/'v2'
frames=[]
for i in range(1,22):
    p=base/f'sprint_{i:02d}.png';im=Image.open(p).convert('RGBA')
    bg=Image.new('RGBA',im.size,(42,47,55,255));bg.alpha_composite(im);frames.append(bg.convert('RGB'))
sheet=Image.new('RGB',(480*7,510*3),(42,47,55));draw=ImageDraw.Draw(sheet)
for i,im in enumerate(frames):
    x=(i%7)*480;y=(i//7)*510;sheet.paste(im,(x,y));draw.text((x+15,y+485),f'Frame {i+1}',fill='white')
sheet.save(base/'Sprint_all_frames.jpg',quality=90)
frames[0].save(base/'MIKO7_Sprint_v2.gif',save_all=True,append_images=frames[1:20],duration=[30,40,30]*6+[30,40],loop=0,optimize=False)
