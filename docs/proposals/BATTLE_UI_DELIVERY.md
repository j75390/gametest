# 전투 UI 12종 전달 · 2026-10-08

상태: needs_review. PNG 및 자산 검수 완료, Claude의 게임 연결·실제 화면 검증·최종 승인은 남아 있다.

## 파일
assets/ui/battle/ 아래:
- energy_orb.png — 512×512. 중앙 숫자 권장 위치 (256,256). 80~110px 표시 크기 권장.
- pile_draw.png / pile_discard.png — 각256×256. 보라/금색 뽑을 더미, 낡은 은색 버린 더미. 56~72px 권장.
- intent_attack.png / intent_defend.png / intent_buff.png / intent_debuff.png / intent_unknown.png — 각128×128. 붉은 검/파란 방패/금색 상승 표식/보라 해골/보라 물음표. 32~48px 권장. 숫자는 그림 밖에서 코드로 표시.
- block_shield.png — 128×128. 중앙 숫자 권장 위치(64,64). 32~48px 권장.
- end_turn_normal.png / end_turn_hover.png / end_turn_disabled.png — 각360×120. 동일 실루엣. 글자 영역 x54,y32,w252,h56, 중앙(180,60). 보라/금색 기본, 밝은 hover, 회색 disabled.

## 제작·검수
- 소품9개: 기존 로컬 ComfyUI SDXL base + BiRefNet, 768px 원본에서 투명 여백 정리 후 지정 크기로 축소. 콜라주·잘림·트럼프 글자 결과를 버리고 재생성했다. 한 장에 하나의 의미 단위.
- 버튼3개: 동일한 원본 형태로 직접 제작한 PNG. 생성형 버튼 세 장을 따로 뽑아 모양이 달라지는 문제를 피한다. 글자 없음.
- 모든 파일 RGBA, 모서리 투명, 알파 영역/크기 검사. docs/proposals/battle_ui_review.png에서 어두운 배경 합성 검수.
- battle_ui_manifest.json에 경로·크기·상태·생성 방식 기록. battle_ui_jobs.json 및 battle_ui_generate.py로 재현 가능. 중간 결과 ai/battle_ui_20261008_output은 Git 제외.
- scripts/, content.json, catalog.json 및 바탕화면 실행 복사본은 Codex가 변경하지 않았다. Claude 담당자가 연결하고 Godot의 실제 전투 화면에서 위치·글자 중앙·작은 크기 가독성을 확인한다.
