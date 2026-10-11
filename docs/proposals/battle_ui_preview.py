from PIL import Image,ImageDraw,ImageFont
from pathlib import Path
p=Path(__file__).resolve().parents[2];a=p/'assets/ui/battle'
font=ImageFont.truetype('C:/Windows/Fonts/malgun.ttf',20)
small=ImageFont.truetype('C:/Windows/Fonts/malgun.ttf',14)
items=[('energy_orb','에너지'),('pile_draw','뽑을 더미'),('pile_discard','버린 더미'),('intent_attack','공격 의도'),('intent_defend','방어 의도'),('intent_buff','강화 의도'),('intent_debuff','약화 의도'),('intent_unknown','미확인 의도'),('block_shield','방어도')]
canvas=Image.new('RGBA',(1080,940),(18,15,23,255));d=ImageDraw.Draw(canvas)
d.text((30,20),'전투 UI 자산 · 연결 전 검수',font=font,fill='#d2c4a4')
for n,(name,label) in enumerate(items):
 im=Image.open(a/(name+'.png')).convert('RGBA');assert im.getchannel('A').getextrema()[0]==0
 im.thumbnail((150,150));x=30+(n%5)*210;y=75+(n//5)*230
 canvas.alpha_composite(im,(x+(170-im.width)//2,y+(150-im.height)//2))
 d.text((x,y+160),label,font=font,fill='#e4ddcd');d.text((x,y+191),name,font=small,fill='#a99a80')
for n,state in enumerate(['normal','hover','disabled']):
 im=Image.open(a/('end_turn_'+state+'.png')).convert('RGBA');assert im.size==(360,120)
 canvas.alpha_composite(im,(30,570+n*120));d.text((420,607+n*120),state,font=font,fill='#e4ddcd')
canvas.convert('RGB').save(p/'docs/proposals/battle_ui_review.png')
print('12 PNG size/alpha checks passed; preview saved')
