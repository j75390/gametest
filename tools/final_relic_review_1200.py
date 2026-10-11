import json
from pathlib import Path
p=Path(__file__).resolve().parents[1]/'docs/proposals/relics_20261009'
groups={
'common':{7:('pass','두 펠트 귀마개와 연결 끈 외곽 온전'),16:('pass','심지 없는 단일 붉은 밀랍 덩어리'),24:('reject','저울 바늘 축 구멍 누락, 봉 형태'),38:('reject','하나의 이름표 대신 분리된 목판과 말뚝'),46:('reject','반쪽 대신 완전한 두 렌즈 안경')},
'uncommon':{16:('pass','단일 목제 손잡이와 황동 검표 도장 면'),19:('reject','종이 외곽이 네모로 잘림'),24:('reject','뿌리관과 별도 빈 관 두 개'),25:('reject','실구멍 없는 핀과 붓같은 실 뭉치'),30:('pass','온전한 접힌 종이 복사본과 검은 봉인 점'),33:('reject','분리벽 없는 접시'),34:('reject','한도 목판 대신 세로 막대 배열'),36:('reject','T형 손잡이 누락'),37:('reject','종이 없이 프레임만 남음'),40:('reject','두 심지 대신 세 개 촛대')},
'rare':{6:('reject','선적표 종이 없이 닻만 있음'),7:('reject','해도 종이 외곽 잘림'),8:('reject','잠금 장치와 사슬 누락'),10:('reject','화물 문서 없이 하트만 있음'),14:('reject','접목 도식 종이 없이 희미한 가지'),16:('reject','분필과 홀더 대신 빈 금속관 두 개'),17:('reject','도장 본체와 도장 면 분리, 버섯 그림')},
'epic':{1:('reject','면죄부 두루마리가 두 관으로 분리'),2:('reject','여섯 표시 홈 누락'),6:('reject','제조식 종이 없이 얇은 파편만 남음'),9:('pass','단일 열린 장부와 붉은 리본, 글자 없음'),10:('reject','음악 쉼표 문양 누락, 사각 패널'),11:('reject','세 불씨 칸 대신 두 열과 여섯 용기')},
'ancient':{2:('reject','맹세 두루마리 없이 검만 있음'),5:('reject','문 형상 없는 방패'),9:('reject','헌혈증 종이가 제거되어 빈 프레임')}
}
d={f'relic_{g}_{n:03}':{'verdict':v,'reason':r} for g,items in groups.items() for n,(v,r) in items.items()}
(p/'decisions_1200.json').write_text(json.dumps(d,ensure_ascii=False,indent=2),encoding='utf-8')
print(len(d))
