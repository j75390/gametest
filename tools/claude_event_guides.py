"""Structural composition inputs, never delivered as finished images."""
from PIL import Image,ImageDraw
from pathlib import Path
import numpy as np
out=Path(__file__).resolve().parents[1]/'ai/claude_events_20261011'
for key in ['05','26','28']:
 im=Image.new('RGB',(768,1152),'#39323e');d=ImageDraw.Draw(im)
 d.rectangle((0,870,768,1152),fill='#5d4733')
 if key=='05':
  d.line([(385,280),(385,880)],fill='#b59247',width=20);d.ellipse((275,850,495,910),fill='#b59247');d.line([(160,380),(600,380)],fill='#b59247',width=20)
  for x in [160,600]:
   d.line([(x,385),(x-75,645)],fill='#9a743c',width=6);d.line([(x,385),(x+75,645)],fill='#9a743c',width=6)
   d.pieslice((x-80,575,x+80,700),0,180,fill='#b59247');d.line([(x-80,637),(x+80,637)],fill='#cfa960',width=10)
  d.ellipse((100,865,270,940),fill='#a87843');d.ellipse((530,865,585,895),fill='#887862')
 elif key=='26':
  for x,y in [(200,750),(590,970)]:
   d.ellipse((x-120,y-120,x+120,y+120),outline='#91704d',width=22)
   for dx,dy in [(110,0),(0,110),(75,75),(75,-75)]:d.line([(x-dx,y-dy),(x+dx,y+dy)],fill='#91704d',width=12)
  for points in [[(160,590),(540,800)],[(200,550),(590,760)],[(220,900),(580,690)],[(300,990),(430,740)]]:d.line(points,fill='#816040',width=26)
  for b in [(75,990,190,1080),(420,1020,540,1100),(510,540,630,650)]:d.rounded_rectangle(b,25,fill='#a19a83')
 else:
  d.rectangle((160,465,360,900),fill='#c5b99c');d.ellipse((160,425,360,495),fill='#c5b99c');d.line([(260,442),(255,405)],fill='#151114',width=14)
  d.ellipse((100,870,420,930),fill='#997542');d.rectangle((238,926,280,1020),fill='#997542');d.ellipse((140,1000,380,1040),fill='#997542')
  d.ellipse((560,510,625,575),fill='#211b29');d.polygon([(555,565),(630,565),(695,810),(520,810)],fill='#31233c')
 a=np.asarray(im).astype(float);y,x=np.mgrid[:1152,:768];a=np.clip(a*(.8+.15*np.sin(x/80)+.1*np.cos(y/100))[:,:,None]+np.random.default_rng(int(key)).normal(0,2,a.shape),0,255)
 Image.fromarray(a.astype('uint8')).save(out/f'common_act1_{key}_guide.png')
