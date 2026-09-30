# 학원 / 집 PC 작업 이어가기

공유 저장소: https://github.com/j75390/gametest.git

프로젝트 코드·이미지·제작 규칙·HANDOFF.md를 Git으로 공유한다. 상시 자동 업로드가 아니라 작업 시작/종료 시 동기화한다. PC가 꺼진 동안에는 스크립트가 실행되지 않는다. 채팅 원문이나 PC별 로그인/MCP 연결 설정은 이 저장소에 넣지 않는다.

## 집에서 최초 설정

Git과 Godot를 설치하고 GitHub 계정으로 인증한다. 기존 집 프로젝트는 그대로 둔 채 새 폴더로 받는다.

```powershell
git clone https://github.com/j75390/gametest.git gametest
cd gametest
```

이 폴더를 Codex에서 열고 HOME_PC_START.txt의 요청을 보낸다. 기존 집 프로젝트와 비교해 양쪽 변경을 보존한 다음 병합한다. project.godot를 Godot에서 가져오면 캐시가 재생성된다. 학원 검증 버전은 4.7.2다. Git 작성자 설정이 없다면 본인의 이름과 이메일을 이 저장소에 설정한다.

```powershell
git config user.name "본인 이름"
git config user.email "본인 GitHub 이메일"
```

## 매번 시작 / 종료

시작 전에:
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/sync.ps1 start
```

작업이 끝나면 HANDOFF.md에 변경 내용, 실제 검증 결과, 남은 작업을 기록하고 변경 파일에 개인 정보나 인증 정보가 없는지 확인한다.
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/sync.ps1 finish -Message "지도 작업 및 인수인계 갱신"
```

finish는 무시 목록을 제외한 변경 파일을 커밋하고 업로드한다. 새 파일도 포함하므로 실행 전에 확인한다. 인증이 필요하면 본인의 GitHub 로그인을 진행한다. 암호나 토큰을 문서에 붙여넣지 않는다.

두 PC에서 동시에 수정해 이력이 갈라졌다면 스크립트는 멈춘다. 강제 push/reset/덮어쓰기를 하지 말고 양쪽 변경을 비교하고 병합한 뒤 테스트한다. 업로드 성공을 확인한 후 다른 PC로 이동한다.

## 다음 Codex에게 요청할 문장

“AGENTS.md와 HANDOFF.md, docs/PC_SYNC.md를 읽어. 작업 시작 전에 저장소를 동기화하고, 요청한 작업이 끝나면 검증 결과와 남은 일을 HANDOFF.md에 기록한 뒤 GitHub에 커밋·업로드해. 집에 있던 별도 프로젝트의 수정은 비교해서 보존해.”
