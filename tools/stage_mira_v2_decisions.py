import json, runpy, sys
from pathlib import Path
root=Path(__file__).resolve().parents[1]
rows=json.loads(Path(sys.argv[1]).read_text(encoding='utf-8-sig'))
for row in rows:
    src=root/'ai/claude_mira_cards_v2_20261011'/(row['id']+'_raw.png')
    sys.argv=['stage_mira_card_v2.py',row['id'],str(src),'--verdict',row.get('verdict','pass'),'--reason',row['reason']]
    runpy.run_path(str(root/'tools/stage_mira_card_v2.py'),run_name='__main__')
