"""Procedural composition guides only; final art is rendered by local ComfyUI."""
from PIL import Image, ImageDraw
from pathlib import Path
import math
import numpy as np
root=Path(__file__).resolve().parents[1]
out=root/'ai/relic_structure_guides';out.mkdir(exist_ok=True)
ids=['common_024','common_038','common_046','uncommon_019','uncommon_024','uncommon_025','uncommon_033','uncommon_034','uncommon_036','uncommon_037','uncommon_040','rare_006','rare_007','rare_008','rare_010','rare_014','rare_016','rare_017','epic_001','epic_002','epic_006','epic_010','epic_011','ancient_002','ancient_005','ancient_009']
for ident in ids:
 im=Image.new('RGB',(768,768),'white');d=ImageDraw.Draw(im)
 def box(b,c,outline='#30241d',w=5):d.rounded_rectangle(b,10,fill=c,outline=outline,width=w)
 def poly(p,c):d.polygon(p,fill=c,outline='#30241d',width=5)
 def line(p,c='#30241d',w=8):d.line(p,fill=c,width=w)
 def oval(b,c,outline='#30241d',w=5):d.ellipse(b,fill=c,outline=outline,width=w)
 gold='#a17c38';brown='#8c633b';paper='#a57742';dark='#35302e';red='#913831'
 if ident=='common_024':
  poly([(240,450),(255,270),(640,355)],gold);oval((210,300,320,410),gold);oval((239,329,291,381),'white')
 elif ident=='common_038':poly([(280,150),(480,150),(480,460),(385,620),(280,460)],brown)
 elif ident=='common_046':
  oval((220,230,490,500),gold);oval((240,250,470,480),'#b8c2cb');line([(480,360),(590,340),(625,430)],gold,15)
 elif ident=='uncommon_024':
  box((285,195,480,595),'#c3c6b9');box((310,165,455,215),brown)
  line([(382,255),(374,420),(345,525)],brown,15)
  for x,y in [(310,360),(440,335),(425,450),(310,480)]:line([(376,400),(x,y)],brown,9)
 elif ident=='uncommon_025':
  poly([(255,580),(355,200),(378,200)],'#b0bbc6');oval((347,178,385,260),'#b0bbc6');oval((356,193,374,244),'white');line([(362,220),(530,330),(540,490),(480,540)],'#743b99',5)
 elif ident=='uncommon_033':
  oval((175,205,595,575),'#ada896');oval((197,225,573,555),'#d9d3bd');line([(384,225),(384,555)],'#433c32',38);line([(373,230),(373,550)],'#e0d8c3',10)
 elif ident=='uncommon_034':
  box((230,180,540,590),brown)
  for y in [260,320]:
   for x in range(270,500,45):line([(x,y),(x+8,y+30)],'#332318',7)
 elif ident=='uncommon_036':
  box((355,300,410,540),gold);box((220,250,550,320),gold)
 elif ident=='uncommon_040':
  box((360,350,405,570),gold);box((290,565,480,600),gold)
  line([(250,300),(250,400),(515,400),(515,300)],gold,20)
  box((227,180,273,325),red);box((492,180,538,325),'#39639d')
  for x in [250,515]:poly([(x,130),(x-13,165),(x,180),(x+13,165)],'#e9b540')
 elif ident=='rare_008':
  poly([(170,350),(590,280),(560,485),(240,540)],brown);poly([(210,350),(540,310),(515,430),(245,470)],'#5e4026')
  line([(270,350),(480,440)],gold,12);box((343,320,420,415),gold);d.arc((355,280,408,355),180,360,fill=gold,width=12)
 elif ident=='rare_016':
  box((255,280,510,470),dark);box((490,310,635,440),'#dddccf')
 elif ident=='rare_017':
  box((340,260,430,440),brown);oval((305,190,465,300),brown);box((245,440,525,520),dark)
 elif ident=='epic_002':
  box((355,140,410,295),brown);poly([(330,295),(435,295),(525,510),(245,510)],gold)
  for x in range(275,515,40):line([(x,410),(x,479)],dark,16)
  oval((235,485,535,535),gold)
 elif ident=='epic_010':
  oval((180,180,588,588),gold);oval((212,212,556,556),'#be9959');line([(260,360),(510,360)],dark,8);d.rectangle((300,360,470,430),fill=dark)
 elif ident=='epic_011':
  box((170,240,598,550),'#b0b5b0');box((330,160,438,235),brown)
  for x in [312,455]:line([(x,250),(x,535)],dark,8)
  for x in [240,385,525]:oval((x-28,355,x+28,445),'#e77922');oval((x-14,375,x+14,420),'#ffd247')
 elif ident=='ancient_005':
  poly([(220,195),(545,195),(520,450),(383,605),(245,450)],dark)
  box((310,310,455,465),gold);d.pieslice((310,245,455,390),180,360,fill=gold);box((330,315,435,450),dark)
 else:
  poly([(210,185),(550,175),(562,555),(525,580),(208,565),(195,535)],paper)
  if ident=='epic_001':
   box((180,160,225,585),paper);box((540,160,585,585),paper);oval((465,480,510,525),gold)
  elif ident=='rare_007':line([(270,235),(325,265),(290,320),(400,350),(365,450),(490,510)],'#3f6481',8)
  elif ident in ['rare_014','epic_006']:
   line([(380,460),(380,320),(300,260)],dark,7);line([(380,320),(470,265)],dark,7);oval((350,430,405,480),red)
  elif ident=='rare_006':
   line([(465,440),(465,525)],dark,8);d.arc((425,465,505,540),0,180,fill=dark,width=8);line([(440,466),(490,466)],dark,7);oval((455,420,475,440),paper)
  elif ident=='rare_010':
   oval((438,440,478,480),red);oval((474,440,514,480),red);poly([(438,462),(514,462),(476,510)],red)
  elif ident=='ancient_002':
   oval((415,430,540,555),gold);line([(478,448),(478,535)],dark,12);line([(447,477),(508,477)],dark,12)
  elif ident=='ancient_009':poly([(465,445),(440,490),(465,520),(490,490)],red)
  elif ident=='uncommon_019':oval((420,425,510,515),'#794593');oval((435,440,495,500),'#aa68b5')
  elif ident=='uncommon_037':
   for y in [275,340,405]:line([(260,y),(475,y+5)],dark,15)
 a=np.array(im).astype(float);y,x=np.mgrid[:768,:768];mask=np.any(a<245,axis=2)
 rng=np.random.default_rng(sum(map(ord,ident)))
 shade=.75+.32*np.sin(x/95)+.15*np.cos(y/110)
 grain=rng.normal(0,3,(768,768))
 if ident in ['common_038','uncommon_034','rare_017']:
  grain+=6*np.sin(x*.11+np.sin(y*.015)*4)+3*np.sin(x*.7+y*.008)
 shaded=np.clip(a*shade[:,:,None]+grain[:,:,None],0,255)
 a[mask]=shaded[mask]
 Image.fromarray(a.astype('uint8')).save(out/('relic_'+ident+'.png'))
print('STRUCTURE GUIDES',len(ids))
