"""Create readable-size inspection sheets; never approve by generation alone."""
from pathlib import Path
from PIL import Image, ImageDraw

root = Path(__file__).resolve().parents[1]
work = root / 'ai/claude_mira_cards_v2_20261011'
files = sorted((root / 'assets/delivery/claude_20261011/cards').glob('*_v2.png'))
for offset in range(0, len(files), 6):
    group = files[offset:offset+6]
    sheet = Image.new('RGB', (900, 680), '#211a28')
    draw = ImageDraw.Draw(sheet)
    for n, path in enumerate(group):
        im = Image.open(path).convert('RGB')
        x, y = (n % 3)*300, (n//3)*340
        sheet.paste(im.resize((290,290), Image.Resampling.LANCZOS), (x,y))
        draw.text((x+5,y+295), path.stem, fill='white')
    sheet.save(work / f'preview_{offset//6+1:02}.jpg', quality=94)
print(len(files), 'approved delivery images, current versions only')
