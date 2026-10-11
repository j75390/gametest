from pathlib import Path
from PIL import Image, ImageDraw
root=Path(__file__).resolve().parents[1]
work=root/'ai/claude_mira_cards_20261011'
files=sorted((work/'withdrawn_portrait_v1').glob('*.png'))
for offset in range(0,len(files),8):
    sheet=Image.new('RGB',(1200,660),'#211a28'); d=ImageDraw.Draw(sheet)
    for i,p in enumerate(files[offset:offset+8]):
        x,y=(i%4)*300,(i//4)*330
        sheet.paste(Image.open(p).convert('RGB').resize((290,290)),(x,y))
        d.text((x+2,y+295),p.stem,fill='white')
    sheet.save(work/f'archive_preview_{offset//8+1:02}.jpg',quality=94)
