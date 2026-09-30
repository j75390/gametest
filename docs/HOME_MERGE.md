# 집 / 학원 프로젝트 병합 기록

기준 원격 커밋: 1ad07a886502d646e35b957a8095e4ee5d0f2102.

기존 집 폴더는 수정하지 않고 별도 gametest 폴더에서 병합했다. 집 원본의 엔진 캐시/개인 설정을 제외한 ZIP 백업도 로컬 작업 폴더에 보존했다.

- 원격 유지: expedition_map.gd, map_view.gd, map_node.gd, 지도 PNG/아이콘/안개/선택하지 않은 공개 분기 유지, PC 동기화 문서/스크립트.
- 집 유지: character_select.gd, 독립 성당 배경, ComfyUI 도구와 프롬프트, 생성 이력, 과거 작업 문서.
- main.gd: 원격의 그래프 기반 지도 진행을 유지하고 show_character_select 진입 함수만 집의 선택 UI로 병합.
- codex.gd: 선택용 프로필을 모션팩으로 오인하지 않도록 motions 키 존재 확인 5곳 병합. 나머지 차이는 들여쓰기였다.
- data JSON: character_assets를 제외하면 양쪽 내용이 동일했다. 캐릭터 수치/카드 효과 변경 없음.
- 플러그인 업데이트 캐시와 개인 설정은 복사하지 않았다. 원격 플러그인 유지.
- 아트 원본/SD/도감 갤러리는 유지. 새 선택용 원화는 별도 illustration 경로를 사용한다.

실제 테스트 결과는 HANDOFF.md의 최신 기록을 참조한다.
