# 로컬 아이콘 일괄 제작

1. Content Tool (127.0.0.1:8765), ComfyUI (127.0.0.1:8188)를 실행한다.
2. ai/icon_batch_20261006_v2.json 형식으로 type/id/prompt/seed를 작성한다. 기존 콘텐츠 ID만 허용.
3. `python tools/content_tool/batch_icons.py ai/icon_batch_20261006_v2.json`
4. 결과는 manifest이름_output/results.json 및 개별 PNG/실행 workflow.json에 저장된다. 같은 명령 재실행 시 성공 항목은 건너뛴다.
5. 그림 검수 후 assets에 복사하고 Content Tool의 image/icon을 res:// 경로로 연결한다. 기존 구현 항목만 승인 복구 후 export_catalog한다. proposal은 draft 유지.

그림: SDXL base 1.0, 768px, 22 steps, BiRefNet 배경 제거. 모델 추가 설치 없음. 결과 크기/투명도와 실제 게임 렌더를 검수해야 한다. `retry_generated`는 이번 배치가 생성한 needs_review 아이콘에만 사용한다. 승인된 기존 원화는 덮어쓰지 않는다.

최초 576px 프롬프트에는 장식 테두리가 과도하게 생겨 v2에서 물체 우선 프롬프트와 프레임 제외 조건을 사용했다. PNG의 RGB 미리보기에는 흰 배경이 보일 수 있으므로 실제 알파와 Godot 렌더로 판단한다.
