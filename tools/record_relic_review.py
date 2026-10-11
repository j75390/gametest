"""Record explicit visual decisions, tied to generated seed; never edits catalog."""
import json
from pathlib import Path
P=Path(__file__).resolve().parents[1]/'docs/proposals/relics_20261009'
r=json.loads((P/'results.json').read_text(encoding='utf-8'))
out=json.loads((P/'manual_review.json').read_text(encoding='utf-8')) if (P/'manual_review.json').exists() else {}
reject={
'common':{7:'끈 외곽 잘림',16:'빈 알파/정상 자산 없음',20:'종이 형태 흐림',24:'바늘 대신 시계',31:'받침에 찻잔 포함',33:'압착판 대신 장식 원판',34:'천 배경 미제거',37:'장갑 손가락 누락 의심',38:'이름표 대신 잎 조각',42:'칼 복수',45:'끈에 책 포함',46:'반쪽 대신 온전한 안경',49:'종이 대신 리본 테두리',51:'손잡이 대신 등불',55:'열쇠 복수',56:'조각 대신 계단 전체',59:'돔 덮개 대신 평평한 격자'},
'uncommon':{4:'가짜 글자',6:'흐린 잔여물',11:'축 복수',12:'책 대신 배',16:'가짜 글자',17:'두 잔 대신 한 잔',19:'종이 대신 원형 봉인',20:'실패 없는 금속 막대 복수',24:'뿌리 대신 꽃 식물',25:'바늘보다 실 실패가 주체',26:'이중 거울 대신 단일 거울',29:'흐리고 잘린 색인',30:'종이 대신 풍경',31:'처방전 없이 깃털만',33:'두 구획 대신 네 구획',34:'가짜 글자',36:'손잡이 대신 배관 전체',37:'한도표 대신 투명 나선',40:'두 심지 대신 여러 심지'},
'rare':{1:'문서 대신 타원 액자',2:'맥박계 복수 및 글자',3:'열쇠 복수/잘림',4:'완장 대신 방패',6:'선적표 대신 금속 토큰',7:'해도 대신 나침반 심볼',8:'자물쇠 누락',10:'화물증 대신 봉인만'}
}
reject['rare'].update({12:'병 외부 부속 콜라주',13:'폐 형태 없이 일반 잎',14:'접목도 대신 꽃',16:'검은 홀더 누락',17:'도장 대신 원형 고리',18:'봉투 없이 봉인만',19:'흐린 색인 형태',24:'배경 남고 글자 생성'})
reject['epic']={1:'금색 봉인 누락',2:'여섯 홈 누락',4:'황동 고리 누락',6:'종이 없는 심볼',7:'중앙 종이가 제거됨',8:'끈 누락',9:'장부 없이 리본만',10:'쉼표 대신 음표',11:'세 구획 없이 단일 병',12:'대기표 복수/글자'}
reject['legend']={4:'세 면의 빛 대신 단일 등불'}
reject['ancient']={2:'글자 및 봉인 대신 칼 전체',5:'문양이 문 형태 아님',8:'탄창 없이 총알만',9:'문서 없이 봉인/글자',10:'기계 부품과 정지 레버 누락'}
limits={'common':59,'uncommon':40,'rare':24,'epic':12,'legend':4,'ancient':12}
for ident,item in r.items():
    _,group,number=ident.split('_');num=int(number)
    if group not in limits or num>limits[group]:continue
    reason=reject[group].get(num)
    if item.get('state')=='failed':reason=item.get('error','생성 실패')
    if item.get('qa',{}).get('flags') and not reason:reason='수치 검수 경고: '+','.join(item['qa']['flags'])
    out[ident]={'id':ident,'name':item.get('name'),'seed':item.get('seed'),'attempt':item.get('attempt'),'verdict':'reject' if reason else 'pass','reason':reason or '육안 검수: 물건 종류, 외곽, 투명 배경 확인','reviewed_at':'2026-10-09T10:35:00+09:00','path':item.get('path')}
(P/'manual_review.json').write_text(json.dumps(out,ensure_ascii=False,indent=2),encoding='utf-8')
print('REVIEW',len(out),'PASS',sum(v['verdict']=='pass' for v in out.values()),'REJECT',sum(v['verdict']=='reject' for v in out.values()))
