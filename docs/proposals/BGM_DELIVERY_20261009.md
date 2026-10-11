# 상황별 오리지널 BGM 시안6곡

2026-10-09 사용자 요청으로 직접 작곡/합성. 음악 생성 AI 모델·외부 샘플·기성곡을 사용하지 않았다. tools/compose_bgm.py 악보/합성기 재현 가능. 고품질 녹음 오케스트라로 설명하지 않는다. 합성 악기의 음색과 음악적 완성도는 청취 검수 대상이다.

| 파일 (assets/audio/bgm/) | 장면 | 곡명 | BPM | 길이 |
|---|---|---|---|---|
| title_embers.wav | 시작/메뉴 | 재 속의 이름 |66|58.182초|
| map_fog.wav | 원정 지도 | 등불 사이의 길 |76|50.526초|
| battle_ledger.wav | 일반 전투 | 끝나지 않은 회진 |112|34.286초|
| boss_receiver.wav | 보스전 | 다음 수령인 |96|40초|
| shop_candle.wav | 상점 | 촛불 아래 흥정 |82|46.829초|
| story_margin.wav | 스토리/연대표 | 지워지지 않은 여백 |60|64초|

공통 D단조 중심. 작은 상승 단3도 모티프를 장면별로 변주. 시작은 긴 패드/종, 지도는 낮은 박과 움직이는 현, 일반 전투는 빠른 플럭/타악, 보스는 반음 긴장/낮은 오르간/북, 상점은 따뜻한 플럭과 종, 스토리는 여백 많은 선율. 실제 합성음이며 사용자가 기대하는 음색과 다르면 조정할 시안이다.

## 미리듣기
bgm_preview_6tracks.wav: 위 표 순서, 곡당12초+간격1초. 본 루프와 별도이며 게임에 연결하지 않는다.

## 검증
44.1kHz, 16bit stereo PCM WAV. 6곡 구조/표본수/비무음/피크/클리핑/양 끝 연속성 검사 통과. 피크 약-4.15dBFS. 리버브 꼬리를 루프 시작으로 순환, 경계6ms 짧은 taper. 수치 검사로 음악적 청취 품질을 합격 처리하지 않음. OGG 인코더가 확인되지 않아 이번에는 WAV만 제공했다.

## Claude 연결
- AudioStreamPlayer와 Music 버스에 연결. WAV import의 loop_mode=forward, loop_begin=0, loop_end=전체 sample frame(정확한값 BGM_ASSET_QA_20261009.json). manifest의 loop=true만으로 Godot 반복 재생이 켜지는 것은 아님.
- 시작/상점 등 장면 전환에 0.8~1.5초 크로스페이드 권장. 같은 트랙이면 재시작하지 않기. 전투 배속을 바꿔도 BGM pitch/tempo는 그대로 유지.
- 첫 볼륨은 Music 버스 -10~-14dB 범위에서 효과음과 비교 조정. 모든 곡을 피크만 같다고 동일 체감 음량으로 간주하지 않는다.
- 실제 반복2회/메뉴↔지도↔전투↔상점 전환/음악음량·음소거·중복재생/효과음 마스킹 검수. 화면 연결과 버스 코드는 Claude 담당, Codex는 미수정.

status needs_listening_review. 수치 QA docs/proposals/BGM_ASSET_QA_20261009.json. 기존 자산 덮어쓰기/실행본 복사/commit/push 없음.
