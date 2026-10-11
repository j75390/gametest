# 유물 형태 검수 — 2026-10-09

담당 Codex. 기존 18종 보존, 미보유 136종을 로컬 ComfyUI SDXL + BiRefNet으로 제작한다. 실제 유물명·설정에 대응한 물건 형태를 ai/relic_objects_20261009.json에 명시했다. 내장 이미지 생성 도구를 사용하지 않는다.

이 폴더는 생성/검수 단계다. results.json의 needs_review는 승인 의미가 아니다. Claude는 검수 합격 목록을 받은 후에만 공용 catalog에 반영한다. 효과 수치와 해금 조건은 변경하지 않는다.

## 첫 묶음 검수와 수정

- 007 초기 보석 콜라주 불합격. 이후 귀마개에 다른 코르크 물건이 섞여 다시 불합격.
- 008 초기 장치/복수 실패 불합격. 두 원판 사이 붉은 실을 감은 단순 나무 실패로 재생성.
- 009 초기 방패 같은 장식 및 과다 구멍 불합격. 네 구멍의 갈색 단추로 재생성.
- 010 현대 수도꼭지가 달린 대야 불합격. 중세의 독립된 얕은 금속 그릇으로 재생성.
- 014 눈이 붙은 천 불합격. 직사각형 접힌 천으로 재생성.
- 015 마개에 문자가 붙은 결과 불합격. 무표기 원뿔 코르크로 재생성.
- 016 이미지 밖 큰 글자 불합격. 무표기 밀랍 조각으로 재생성.
- 017 두 물건과 둥근 목재 모양 불합격. 길고 뾰족한 단일 철못으로 재생성.
- 018 분필 대신 천 묶음 불합격. 원통 분필과 가는 파란 끈으로 재생성.
- 019 돛천에 배 그림이 생긴 결과 불합격. 단순 캔버스 천 묶음으로 재생성.
- 020 통행표에 가짜 문자와 바코드가 붙어 불합격. 빈 종이와 구멍으로 재생성.
- 023 로프 양 끝 화면 잘림 불합격. 전체가 들어오도록 재생성.
- 024 바늘 대신 저울 본체 불합격. 분리된 가느다란 금속 바늘로 재생성.
- 025 호루라기 대신 배관 불합격. 짧은 취구와 소리통이 있는 호루라기로 재생성.
- 026 가위 복수/상자 배경 불합격. 가위 한 쌍으로 재생성.

## 검수 기준

물건 종류와 재질, 의도한 구성, 작은 아이콘에서 읽히는 실루엣, 온전한 외곽, 투명 배경, 불필요한 글자/얼굴/눈/프레임 없음. 수치 검사만 통과한 결과를 완성품으로 취급하지 않는다. 실패한 원본은 ai/relics_20261009_output에 남기며 ComfyUI에서 다시 생성한다.

## 10:24 진행과 후속 검수

전체 배치 실행 중(session 67662, ComfyUI8188). 63번째 작업까지 생성 로그 확인. 완료 수가 아니라 생성 진행 위치다. 016 밀랍은 배경 제거 후 빈 알파로 실패했으며 기존 잘못된 파일이 남아 있을 수 있으므로 적용 금지. 결과 장부와 육안 검수를 기준으로 합격을 결정한다.

추가 재검수/재생성 대상: common007(끈 잘림),020(종이 형태 불명확),024(바늘 대신 시계 본체),031(받침 대신 찻잔),033(압착판 대신 잎 장식),034(배경 남음),037(장갑 손가락 확인),042(칼 복수),045(끈 대신 책 포함),046(반쪽 대신 온전한 안경),049(종이 묶음 대신 리본),051(손잡이 대신 등불),055(열쇠 복수),056(돌 조각 대신 계단). 031/033/034/042/045/046/049/051/055/056 물건 설명은 다음 재생성을 위해 이미 개선했다.

요청한 오늘12시까지 10분 간격 이 대화 후속 작업을 앱 heartbeat comfyui-12로 설정했다. 배치 중복 실행 금지. 의미없는 상태 알림은 하지 않는다. 아직 최종 합격 목록과 게임 연결은 완료되지 않았다.

## 10:35 육안검수 기록
첫 96종을 manual_review.json에 seed/사유별로 기록했다. 현재 51종 합격, 45종 불합격. 생성 완료와 구분한다. 불합격 34종의 물건 설명을 tools/refine_relic_objects.py로 보강했고 나머지 설명은 앞선 수정에서 보강했다. 전체 배치는 계속 진행 중이다. 배치 완료 후 manual_review의 reject ID만 재생성하고 새로운 seed는 반드시 다시 육안검수한다. 기존 pass는 보존한다. content.json/catalog/scripts/실행본은 수정하지 않았다.

## 10:45 전체 첫 검수 완료 및 재생성
첫136종 모두 육안검수:67합격/69불합격. manual_review.json은 검수 당시 seed에 묶여 있다. 원본 배치 종료, ComfyUI 큐 비어 있음 확인 후 불합격69종만 session98697로 재생성 시작. 합격67종 보존. CLAUDE_ART_MAPPING.json에는 동일 seed의 합격 경로만 포함하고 512RGBA/투명도 검사 통과. 재생성본은 seed가 바뀌면 미검수로 취급한다. tools/record_relic_review.py는 최초 검수 기록용이며 다음 검수에서 그대로 재실행하면 이전 사유로 새 seed를 판정하므로 재실행하지 말 것. export_reviewed_relics.py는 매번 실행 가능.
첫 재생성 common007은 전기 커넥터 형태로 불합격,016은 콜라주/배경 잔여로 불합격,020은 가장자리 가짜 문자로 불합격. 다음 재생성 설명을 더 단순하게 보강해야 한다.

## 10:55 재생성 일부 재검수
review01~03의 재생성29종을 decisions_1052.json으로 판정/seed 기록. 13종 추가 합격하여 동일 seed 합격80종. CLAUDE_ART_MAPPING 갱신. session98697은 계속 실행 중이므로 중복 재생성 금지. 이후 재생성16종의 설명은 refine_relic_objects_third.py로 개선했고 실행 완료했다. tools/relic_review_update.py는 결정을 현재seed에 묶고 결정파일에도 expected_seed를 남긴다. 같은 결정파일을 다른 seed에 재사용할 수 없다. common007 전기커넥터,016/024 반복텍스처에 대한 제외 조건도 다음 배치를 위해 추가했다. 첫 검수 도구 record_relic_review.py는 재실행 금지.

## 11:05 재생성69종 재검수 완료
두 번째 생성본 전체검수 완료. decisions_1102.json 40종 재판정/seed 기록으로13종 추가 합격, 누적93합격/43불합격/미검수0(재생성 직전 기준). CLAUDE_ART_MAPPING 갱신. ComfyUI 큐 비어 있음 확인 후 불합격43종만 session57451 재생성 실행. refine_relic_objects_third.py 및 fourth.py의 보강 설명 적용. 기존93합격은 유지. 다음 wake에서 session57451 확인하고 완료 후 새 seed만 재검수할 것. record_relic_review.py 재실행 금지.

## 2026-10-09 11:27 Codex 새 seed 검수
- session57451 재생성 배치가 계속 실행 중이며 ComfyUI 큐 실행1/대기0 확인. 중복 배치 없음.
- review_01~04를 --review-only로 현재 PNG 기준 갱신 후 재생성25종 육안검수. decisions_1125.json에 seed 고정 판정 기록. 8종 추가 합격하여 동일seed 합격101종, 현재 reject35종. 배치 후반은 아직 이전 reject seed이므로 미검수0이라는 export 숫자가 재생성 완료를 의미하지 않는다.
- CLAUDE_ART_MAPPING.json의 passed만 적용 가능. 기존18종 보존. content/catalog/scripts/실행본 변경 및 push 없음.
- 재생성 sheet는 건너뛴 인덱스 때문에 자동 갱신이 늦을 수 있음. 검수 직전 --review-only 실행 필수. 다음 작업은 session57451 완료 확인 및 후반 새seed 검수. 12시 이후 새 생성 금지.

## 2026-10-09 11:36 CUDA 오류 복구 및 재개
- session57451은 rare006에서 CUDA out of memory로 서버 실행 스레드가 멈췄고 900초 timeout. rare007 큐 대기 상태에서 배치 PID31688 및 오류 서버 PID28580/30272 종료. 생성 중인 작업은 검수 합격으로 취급하지 않았다.
- 기존 ComfyUI .venv 환경으로 --lowvram 서버 재시작(PID21892). 큐0/0 및 배경 제거 노드 확인 후 reject/failed35종만 session19477로 재개. 합격101종 보존.
- tools/relic_art_batch.py에 UTC 2026-10-09 03:00(한국12:00) 이후 새로운 prompt 및 다음 작업 시작을 막는 guard 추가. 진행 중 생성은 완료될 수 있으며 새 seed는 별도 검수 필요.
- common016/024/034 실제 물건 설명 단순화. export 현재101합격/34reject/1미검수실패/1missing(rare006, 이전 PNG가 남아도 적용금지). 후속 heartbeat에서19477 확인; 중복배치 금지. 자동push없음.

## 2026-10-09 11:45 복구 배치 재검수
- session19477 정상 진행, 큐 실행1/대기0. review-only로 최신 그림 갱신 후 decisions_1141.json(21종), decisions_1144.json(8종)에 육안검수/seed 기록.
- 여과천common034 및 붉은 색인uncommon029 추가 합격: 동일seed 합격103종. export 시점 불합격30/새seed 미검수3/누락0; 후반 생성 중이므로 숫자 변동 가능.
- 실패한 형태 common007/016/024/038/046, uncommon033/034/037, rare017, epic009 설명 보강. 현재 배치에는 착수 당시 프롬프트가 적용되므로 다음 reject retry에 반영된다. 합격그림 유지, content/catalog/scripts/실행본 미수정. 자동push없음.
- 다음 heartbeat는19477 완료/새seed 확인 후 후반검수. epic011은3칸중 가운데만 내용물이 있어 불합격 대상(아직 결정파일 미기록). 12시 신규prompt 차단 유지.

## 2026-10-09 11:52 마지막 정오 전 재생성
- session19477 완료 및 ComfyUI 큐0/0, 배치 프로세스 없음 확인. 새seed136종 검수 상태 정리 완료: 신규105합격/31불합격/미검수0/누락0. 기존18보존. 마지막 대기표epic012 및 반납된 탄창ancient008 추가합격(decisions_1151.json).
- CLAUDE_ART_MAPPING.json의 동일seed passed105경로 갱신. 실제 게임 적용은 Claude 담당이며 content/catalog/scripts/실행본은 변경하지 않음.
- 불합격31종만 session91547 마지막 재생성 착수. 이전105합격 보존. 도구가12:00KST 이후 새prompt와 다음 작업 시작을 차단한다. 12시 heartbeat에서91547 상태/새seed를 확인하고 미완성 목록 및 합격경로 인계 후 자동화 PAUSED 처리할 것.
- needs_review와 이전seed판정은 적용금지. review-only로 sheet 최신화 후 새seed 육안검수. 자동push없음.

## 2026-10-09 12:00 최종 Claude 인계 — 신규 생성 종료
- 마지막 session91547 종료, ComfyUI 큐0/0, 배치 프로세스 없음 확인. 정오 이후 신규 생성 없음.
- 신규136종 최종 육안검수: **110합격 / 26불합격 / 미검수0 / 누락0**. 기존18종 보존: 전체154종 중128종 아트 확보,26종 미완성. 게임 적용 완료 수가 아니라 아트 검수 수다.
- 합격 경로: docs/proposals/relics_20261009/CLAUDE_ART_MAPPING.json의 passed110종(res://assets/relics/comfy_batch_20261009/...). 동일seed만 export. decisions_1200.json에 마지막31종 seed/판정 기록, manual_review.json에 사유 보관. 최초검수도구 및 final_relic_review_1200.py를 새seed에 재실행하지 말 것.
- Claude는 passed만 통합하고 아래26종 파일은 적용하지 말 것. needs_review라는 생성 상태 자체는 합격이 아니다. content/catalog/scripts/실행본 미수정, 자동push 없음.
- 후속 개선: 종이 배경이 제거되는 문서류, 분리벽/잠금/안경 다리 등 부품 누락, 단일 물건 콜라주 해결 필요. 서버는 기존 .venv 저메모리 모드로 복구됨. 생성 도구의12시deadline guard가 남아 있으므로 향후 재개는 새 사용자 승인 일정으로 변경 필요.

| 미완성 ID | 이름 | 마지막 불합격 이유 |
|---|---|---|
| relic_common_024 | 저울 바늘 | 저울 바늘 축 구멍 누락, 봉 형태 |
| relic_common_038 | 식물 이름표 | 하나의 이름표 대신 분리된 목판과 말뚝 |
| relic_common_046 | 반쪽 독서경 | 반쪽 대신 완전한 두 렌즈 안경 |
| relic_uncommon_019 | 거꾸로 쓴 처방전 | 종이 외곽이 네모로 잘림 |
| relic_uncommon_024 | 봉인된 뿌리 | 뿌리관과 별도 빈 관 두 개 |
| relic_uncommon_025 | 이름을 남기는 바늘 | 실구멍 없는 핀과 붓같은 실 뭉치 |
| relic_uncommon_033 | 재 분리접시 | 분리벽 없는 접시 |
| relic_uncommon_034 | 배급 한도표 | 한도 목판 대신 세로 막대 배열 |
| relic_uncommon_036 | 분배관 손잡이 | T형 손잡이 누락 |
| relic_uncommon_037 | 손으로 적은 한도 | 종이 없이 프레임만 남음 |
| relic_uncommon_040 | 서로 다른 심지 | 두 심지 대신 세 개 촛대 |
| relic_rare_006 | 돌아오는 선적표 | 선적표 종이 없이 닻만 있음 |
| relic_rare_007 | 수심 없는 해도 | 해도 종이 외곽 잘림 |
| relic_rare_008 | 잠긴 구조정 | 잠금 장치와 사슬 누락 |
| relic_rare_010 | 살아 있는 화물증 | 화물 문서 없이 하트만 있음 |
| relic_rare_014 | 원장의 접목도 | 접목 도식 종이 없이 희미한 가지 |
| relic_rare_016 | 삭제관의 백묵 | 분필과 홀더 대신 빈 금속관 두 개 |
| relic_rare_017 | 원본 대조인 | 도장 본체와 도장 면 분리, 버섯 그림 |
| relic_epic_001 | 서명 없는 면죄부 | 면죄부 두루마리가 두 관으로 분리 |
| relic_epic_002 | 여섯 사람의 종 | 여섯 표시 홈 누락 |
| relic_epic_006 | 반증된 제조식 | 제조식 종이 없이 얇은 파편만 남음 |
| relic_epic_010 | 성가대의 쉼표 | 음악 쉼표 문양 누락, 사각 패널 |
| relic_epic_011 | 분산된 불씨 | 세 불씨 칸 대신 두 열과 여섯 용기 |
| relic_ancient_002 | 풀어 쓴 맹세 | 맹세 두루마리 없이 검만 있음 |
| relic_ancient_005 | 문밖의 방패 | 문 형상 없는 방패 |
| relic_ancient_009 | 자필 헌혈증 | 헌혈증 종이가 제거되어 빈 프레임 |

## 2026-10-10 미완성 유물 26종 재제작 완료 — Claude 통합 인계
- 사용자 재제작 요청에 따라 로컬 ComfyUI만 사용. 기존 18종과 이전 합격 110종 보존. 오늘 미완성 26종을 재생성·개별/시트 육안검수했고 모두 합격.
- 최종 신규 136 합격 / 불합격 0 / 새 seed 미검수 0 / 누락 0. 기존 18종 포함 전체 154종 아트 확보. 게임 통합 완료 수는 아님.
- 적용 목록: docs/proposals/relics_20261009/CLAUDE_ART_MAPPING.json. exporter가 현재 results seed와 manual_review seed의 일치를 확인한 136종만 내보냄. 파일은 res://assets/relics/comfy_batch_20261009/.
- 오늘 판정·검수 seed는 decisions_20261010_a~f.json 및 manual_review.json에 기록. 마지막 6종은 e/f. needs_review 생성 상태만으로 판정하지 않음.
- 구조 누락 재발 방지를 위해 ai/relic_structure_guides와 tools/relic_structure_guides.py에 ComfyUI 입력용 구조 가이드를 추가. 이 가이드는 최종 게임 이미지가 아님. 모든 최종 PNG는 ComfyUI 렌더 결과.
- Claude 담당 content.json/catalog.json/scripts/실행복사본 미수정. Claude는 mapping 기반으로 통합하고 Godot 실제 크기에서 가독성을 최종 확인할 것. push 없음. 기존 자동화 PAUSED 유지.
- 2026-10-09 12:00의 110/26 현황은 아래의 과거 기록이며 이번 136/0 현황으로 대체됨. 지난 날짜 deadline guard는 이번 사용자 재개 요청에 맞춰 제거됨.
