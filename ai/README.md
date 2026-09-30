# ComfyUI 연결

ComfyUI Desktop을 실행한 상태에서 게임 프로젝트 루트의 PowerShell에서 사용한다.

```powershell
.\ai\comfy_bridge.ps1 status
.\ai\comfy_bridge.ps1 models
.\ai\comfy_bridge.ps1 generate --prompt 'dark gothic fantasy, purple alchemy potion, detailed game item illustration' --seed 9357
```

- 설치: `D:\Comfy-Desktop`
- 로컬 API: `http://127.0.0.1:8188`
- Python: ComfyUI의 `standalone-env/python.exe` 사용. 추가 패키지 설치 불필요.
- 기본 워크플로: `workflows/sdxl_api.json` (API 형식), SDXL 1.0 base, 1024×1024.
- 결과: `generated/<실행별 폴더>/image_001.png`. 요청 워크플로, prompt_id, 실행 이력을 함께 보존한다.
- `generated/.gdignore`로 테스트 이미지의 Godot 자동 임포트를 방지한다.
- 서버가 꺼져 있으면 ComfyUI Desktop을 먼저 실행한다. 브리지는 서버 설정을 변경하거나 중복 서버를 실행하지 않는다.

## 기존 그림체와 연결

`reference/style/manifest.json`은 현재 미라 기준 이미지의 프로젝트 상대 경로를 기록한다. 실제 원화는 기존 assets 경로를 유지한다. 이 목록 자체가 모델에 자동 적용되는 것은 아니다.

현재 기본 워크플로는 텍스트 생성만 지원한다. GameStyle LoRA, IPAdapter/reference conditioning, 배경 제거는 아직 설치·구성이 확인되지 않았으며 이 워크플로에 포함하지 않았다. SDXL의 PNG 출력은 투명 배경을 보장하지 않는다.

참조 입력이 필요한 API 워크플로를 준비하면 아래 명령으로 이미지를 업로드하고 응답의 name을 LoadImage 노드에 지정할 수 있다.

```powershell
.\ai\comfy_bridge.ps1 upload '.\assets\characters\mira\full_01.png'
.\ai\comfy_bridge.ps1 generate --workflow '.\ai\workflows\custom_api.json' --set '10.image="업로드된파일명.png"'
```

`--set NODE.INPUT=JSON`으로 명시적인 노드 입력을 바꿀 수 있다. `--prompt/--negative/--seed/--steps` 단축 옵션은 comfy_config.json의 bindings에 지정된 노드에 적용되므로 사용자 워크플로에서는 bindings를 맞추거나 --set을 사용한다.

## 게임 자산 반영

생성 → 그림체/알파/크기 확인 → assets로 복사 → 기존 JSON 구조에 등록 → Godot 실행 검증 순서로 진행한다. 연결 테스트 결과를 자동으로 캐릭터나 카드 데이터에 등록하지 않는다. 독립 모션은 시트를 자르지 않고 전체 프레임 경로와 duration을 character_assets.json에 등록한다.

시간 초과는 서버 작업을 취소하지 않는다. job.json의 prompt_id로 /history/{prompt_id}를 확인한다. 실패 이력은 history.json에 보존하며 기존 결과를 덮어쓰지 않는다.

## 연결 검증 (2026-09-29)
로컬 API 상태 확인, 설치된 모델 목록 조회, 실제 SDXL 1024×1024 생성 및 PNG 다운로드 성공. prompt_id: f9f7a2e4-fd41-47c9-995f-7effa8b0b70a. 결과: generated/20260929-233825-4c134f34/image_001.png. 게임 데이터 변경 없음. 참조 업로드 명령은 구현됐으나 참조 기반 생성은 아직 검증하지 않음.

## 최신 기본 설정
용도별 프리셋과 연결 점검 명령은 SETUP.md 참고. .\ai\comfy.ps1 check는 생성 없이 상태를 확인한다.

## 최신 선택 아트 연결
선택용 재생성은 `tools/generate_characters.py`와 `ai/workflows/selection/`을 사용한다. 위의 기본 텍스트 생성 프리셋과 별개로, 미라 참조 입력 및 BiRefNet 투명화가 실제 연결되었다. 현재 상태와 재생성 절차는 [SETUP.md](SETUP.md)가 우선한다.
