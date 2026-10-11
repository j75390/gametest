import json,runpy,sys
from pathlib import Path
root=Path(__file__).resolve().parents[1]
decisions=json.loads(Path(sys.argv[1]).read_text(encoding='utf-8-sig'))
for row in decisions:
 source=row.get('source',str(root/'ai/claude_mira_cards_20261011'/(row['id']+'_raw.png')))
 sys.argv=['stage_mira_card_art.py',row['id'],source,'--verdict',row['verdict'],'--reason',row['reason']]
 runpy.run_path(str(root/'tools/stage_mira_card_art.py'),run_name='__main__')
