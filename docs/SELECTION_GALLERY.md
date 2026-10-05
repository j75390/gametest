# 2026-10-04 캐릭터 선택 화면 갤러리형 개편
- 첨부된 원정 준비 화면을 승인된 캐릭터 도감 시안 방향으로 변경. 큰 미라 원화+짧은 소개, 얇은 구분선, 하단 초상 선택. 수치/기본 덱 변경 없음.
- 내장 image_gen 편집 사용. 원본 exec-d50c9d9e-1b0b-47cc-8a9e-233f20d89765.png에서 UI/문자/버튼을 제거하고 미라/성당 구도를 유지. 출력 exec-e649b398-15e7-47d4-907f-d3e6bbf0e1fb.png → assets/backgrounds/mira_selection_gallery_v1.png.
- 생성 프롬프트: Preserve approved adult Mira identity, raven mask, pose, outfit and cathedral composition. Remove ALL text, UI, buttons, medallions, lines; reconstruct background. Right 45% dark quiet space for real engine text. Bottom subtly dark. No baked UI.
- 글자/선택/원정 시작은 실제 Godot UI. 다른 캐릭터는 기존 자산 유지. 도감 전체 개편과 별개로 현재 원정 선택 화면에 적용.
- SELECTION_GALLERY_QA 1440x900 및1280x720 통과. 캐릭터 4명 전환 및 원정 시작 신호 확인. 미라 렌더 직접 검수. 요청 전 push 금지.
