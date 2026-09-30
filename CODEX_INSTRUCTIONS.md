# Codex 지시: 앞으로 게임 이미지는 ComfyUI를 실제로 사용

1. ChatGPT 이미지 생성기를 사용하지 않는다.
2. 로컬 ComfyUI API: http://127.0.0.1:8188
3. 먼저 `python tools/comfy_bridge.py --prompt "test" --output "assets/test_comfy.png"` 로 실제 연결을 확인한다.
4. 성공하면 캐릭터 선택용 이미지를 아래 경로에 생성한다.
   - assets/characters/mira/illustration/mira_character_select.png
   - assets/characters/kalian/illustration/kalian_character_select.png
   - assets/characters/sera/illustration/sera_character_select.png
   - assets/characters/lucian/illustration/lucian_character_select.png
5. 배경 포함 기존 그림을 잘라서 대체하지 않는다.
6. 한 이미지에는 캐릭터 한 명만. UI/텍스트/카드/콜라주 금지.
7. 생성 후 Godot 데이터 경로에 연결하고 Godot AI MCP로 실제 실행한다.
8. ComfyUI 연결/생성 실패 시 완료 처리하지 말고 실패 이유를 보고한다.
