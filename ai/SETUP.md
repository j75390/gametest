# ComfyUI → Godot 연결 및 집 PC 병합

## 실제 연결
- 로컬 API: `http://127.0.0.1:8188`.
- 기본 모델: `sd_xl_base_1.0.safetensors`.
- 배경 제거: ComfyUI 기본 `LoadBackgroundRemovalModel` / `RemoveBackground` / `InvertMask` / `JoinImageWithAlpha` 노드와 `birefnet.safetensors`.
- BiRefNet은 이 PC의 `D:/Comfy-Desktop/ComfyUI-Shared/models/background_removal/`에 설치했다. 모델 자체는 Git에 업로드하지 않는다.
- 모델 출처: https://huggingface.co/Comfy-Org/BiRefNet (revision 35767b272f2846752a3aee1259abdd4586f735c8).
- SHA256: `9ab37426bf4de0567af6b5d21b16151357149139362e6e8992021b8ce356a154`.
- 서버 실행 Python은 `ComfyUI/.venv/Scripts/python.exe`다. `standalone-env/python.exe`는 HTTP 호출 도구를 실행할 수 있지만 이 PC에서는 torch가 없어 서버 실행용이 아니다.

## 사용
1. ComfyUI Desktop을 켜고 `ai/comfy.ps1 check`로 실제 API/모델 상태를 검사한다.
2. `generate_character_select.bat` 또는 `python tools/generate_characters.py --characters mira`를 실행한다.
3. `ai/generated/selection-날짜시간/`에 PNG와 작업 ID, API 워크플로가 기록된다. 기존 게임 이미지는 덮어쓰지 않는다.
4. 이미지를 검수한 뒤 `assets/characters/<id>/illustration/<id>_character_select.png`에 반영한다. `data/character_assets.json`의 illustration/selection을 사용한다. 도감 full/gallery와 전투 motions는 별도다.

`ai/workflows/selection/*.json`이 재실행 기준 워크플로다. 미라는 제공받은 `full_02.png`를 ComfyUI에 새로 upload하고 img2img denoise 0.4로 생성한 후 배경을 제거한다. 기존 원화를 잘라 붙이는 경로가 아니다. 다른 PC에서도 서버에 남아 있는 임시 파일명에 의존하지 않게 upload를 수행한다.

`character_prompts.json`은 프롬프트 요약이며 실제 샘플러/크기/시드/노드는 워크플로에 기록한다. 루시안은 기존 남성 성직자 설정을 유지했다. 초기 배경 잔상/잘린 구도 결과는 `ai/generated/first-pass`에 보존하고 완성 원화로 취급하지 않는다.

IPAdapter와 전용 LoRA는 설치하지 않았다. SD 모션, 카드 그림, 모든 캐릭터 화풍의 최종 통일이 완료됐다는 의미는 아니다. 이미지 생성 실패는 오류로 반환하며 임시 이미지로 완료 처리하지 않는다.
