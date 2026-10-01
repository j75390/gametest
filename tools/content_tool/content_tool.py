#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
LuckyExpedition Content Tool
- Zero third-party dependencies
- Local web GUI + REST API + CLI
- Content types: cards, relics, potions, enchants, powers, monsters, events
- Optional ComfyUI API bridge
- Godot JSON export
- Handover document generation
"""

from __future__ import annotations
import argparse
import json
import os
import random
import shutil
import sys
import threading
import time
import urllib.parse
import urllib.request
import webbrowser
from datetime import datetime
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Any

APP_DIR = Path(__file__).resolve().parent
STATIC_DIR = APP_DIR / "static"
DATA_DIR = APP_DIR / "data"
DATA_FILE = DATA_DIR / "content.json"
HANDOVER_STATE_FILE = DATA_DIR / "handover.json"
EXPORT_DIR = APP_DIR / "export"
HANDOVER_FILE = APP_DIR / "HANDOVER_CURRENT.md"

TYPE_ORDER = ["cards", "relics", "potions", "enchants", "powers", "monsters", "events"]

SCHEMA: dict[str, dict[str, Any]] = {
    "cards": {
        "label": "카드",
        "required": ["id", "name", "character", "energy_cost", "rarity", "type", "description"],
        "fields": [
            {"key":"id","label":"ID","kind":"text","placeholder":"kalian_abyss_slash"},
            {"key":"name","label":"카드명","kind":"text"},
            {"key":"character","label":"캐릭터","kind":"text","placeholder":"kalian"},
            {"key":"energy_cost","label":"에너지","kind":"number","default":1},
            {"key":"rarity","label":"등급","kind":"select","options":["일반","고급","희귀","영웅","전설"],"default":"일반"},
            {"key":"type","label":"타입","kind":"select","options":["공격","스킬","파워","저주","상태"],"default":"공격"},
            {"key":"target","label":"대상","kind":"select","options":["적 1명","적 전체","자신","아군 1명","파티 전체","무작위"],"default":"적 1명"},
            {"key":"description","label":"기본 효과","kind":"textarea"},
            {"key":"upgraded_description","label":"강화 효과","kind":"textarea"},
            {"key":"keywords","label":"키워드","kind":"text","placeholder":"출혈, 연속공격"},
            {"key":"enchantable","label":"인챈트 가능","kind":"bool","default":True},
            {"key":"image","label":"이미지 경로","kind":"text","placeholder":"assets/cards/kalian/abyss_slash.png"},
            {"key":"art_prompt","label":"아트 프롬프트","kind":"textarea"},
            {"key":"art_source","label":"아트 소스","kind":"select","options":["AUTO","COMFYUI","PREMIUM","MANUAL"],"default":"AUTO"},
            {"key":"approval_state","label":"검수 상태","kind":"select","options":["draft","generated","needs_review","approved","rejected"],"default":"draft"},
        ]
    },
    "relics": {
        "label": "유물",
        "required": ["id","name","rarity","effect","flavor_text"],
        "fields": [
            {"key":"id","label":"ID","kind":"text","placeholder":"pale_road_map"},
            {"key":"name","label":"유물명","kind":"text"},
            {"key":"rarity","label":"등급","kind":"select","options":["일반","고급","희귀","영웅","전설","고대"],"default":"일반"},
            {"key":"scope","label":"효과 범위","kind":"select","options":["PERSONAL","PARTY","GLOBAL_MAP"],"default":"PERSONAL"},
            {"key":"effect","label":"효과","kind":"textarea"},
            {"key":"flavor_text","label":"기록문","kind":"textarea"},
            {"key":"tags","label":"태그","kind":"text","placeholder":"조건부,저주,파티공용"},
            {"key":"origin_event","label":"관련 이벤트","kind":"text"},
            {"key":"character_restriction","label":"캐릭터 제한","kind":"text","placeholder":"고대 유물일 때 캐릭터 ID"},
            {"key":"curse_tag","label":"저주 유물","kind":"bool","default":False},
            {"key":"stackable","label":"파티 효과 중첩","kind":"bool","default":False},
            {"key":"icon","label":"아이콘 경로","kind":"text"},
            {"key":"art_prompt","label":"아트 프롬프트","kind":"textarea"},
            {"key":"art_source","label":"아트 소스","kind":"select","options":["AUTO","COMFYUI","PREMIUM","MANUAL"],"default":"AUTO"},
            {"key":"approval_state","label":"검수 상태","kind":"select","options":["draft","generated","needs_review","approved","rejected"],"default":"draft"},
        ]
    },
    "potions": {
        "label": "포션",
        "required": ["id","name","rarity","effect"],
        "fields": [
            {"key":"id","label":"ID","kind":"text"},
            {"key":"name","label":"포션명","kind":"text"},
            {"key":"rarity","label":"등급","kind":"select","options":["일반","고급","희귀","영웅","전설"],"default":"일반"},
            {"key":"effect","label":"효과","kind":"textarea"},
            {"key":"story","label":"짧은 기록","kind":"textarea"},
            {"key":"battle_only","label":"전투 전용","kind":"bool","default":True},
            {"key":"icon","label":"아이콘 경로","kind":"text"},
            {"key":"art_prompt","label":"아트 프롬프트","kind":"textarea"},
            {"key":"art_source","label":"아트 소스","kind":"select","options":["AUTO","COMFYUI","PREMIUM","MANUAL"],"default":"COMFYUI"},
            {"key":"approval_state","label":"검수 상태","kind":"select","options":["draft","generated","needs_review","approved","rejected"],"default":"draft"},
        ]
    },
    "enchants": {
        "label": "마법부여",
        "required": ["id","name","rarity","effect"],
        "fields": [
            {"key":"id","label":"ID","kind":"text"},
            {"key":"name","label":"인챈트명","kind":"text"},
            {"key":"rarity","label":"등급","kind":"select","options":["일반","고급","희귀","영웅","전설"],"default":"일반"},
            {"key":"applicable_type","label":"적용 카드","kind":"select","options":["전체","공격","스킬","파워"],"default":"전체"},
            {"key":"effect","label":"효과","kind":"textarea"},
            {"key":"description","label":"설명","kind":"textarea"},
            {"key":"icon","label":"아이콘 경로","kind":"text"},
            {"key":"art_prompt","label":"아트 프롬프트","kind":"textarea"},
            {"key":"art_source","label":"아트 소스","kind":"select","options":["AUTO","COMFYUI","PREMIUM","MANUAL"],"default":"COMFYUI"},
            {"key":"approval_state","label":"검수 상태","kind":"select","options":["draft","generated","needs_review","approved","rejected"],"default":"draft"},
        ]
    },
    "powers": {
        "label": "파워/상태이상",
        "required": ["id","name","category","effect","tooltip"],
        "fields": [
            {"key":"id","label":"ID","kind":"text","placeholder":"poison"},
            {"key":"name","label":"이름","kind":"text","placeholder":"맹독"},
            {"key":"category","label":"분류","kind":"select","options":["BUFF","DEBUFF","POWER","CURSE","SPECIAL"],"default":"DEBUFF"},
            {"key":"stack_mode","label":"중첩 방식","kind":"select","options":["SINGLE","COUNTER","DURATION","CONDITIONAL"],"default":"COUNTER"},
            {"key":"target","label":"대상","kind":"select","options":["SELF","ALLY","ENEMY","PARTY","ALL_ENEMIES"],"default":"ENEMY"},
            {"key":"trigger","label":"발동 시점","kind":"select","options":["즉시","턴 시작","턴 종료","공격 시","피격 시","카드 사용 시","드로우 시","전투 시작","전투 종료"],"default":"즉시"},
            {"key":"duration","label":"기본 지속 턴","kind":"number","default":0},
            {"key":"max_stack","label":"최대 중첩(0=무제한)","kind":"number","default":0},
            {"key":"effect","label":"효과","kind":"textarea"},
            {"key":"remove_condition","label":"제거 조건","kind":"textarea"},
            {"key":"tooltip","label":"Hover 툴팁","kind":"textarea"},
            {"key":"icon","label":"아이콘 경로","kind":"text"},
            {"key":"art_prompt","label":"아이콘 프롬프트","kind":"textarea"},
            {"key":"art_source","label":"아트 소스","kind":"select","options":["AUTO","COMFYUI","PREMIUM","MANUAL"],"default":"COMFYUI"},
            {"key":"approval_state","label":"검수 상태","kind":"select","options":["draft","generated","needs_review","approved","rejected"],"default":"draft"},
        ]
    },
    "monsters": {
        "label": "몬스터",
        "required": ["id","name","rank","hp","description"],
        "fields": [
            {"key":"id","label":"ID","kind":"text"},
            {"key":"name","label":"이름","kind":"text"},
            {"key":"rank","label":"등급","kind":"select","options":["NORMAL","ELITE","BOSS"],"default":"NORMAL"},
            {"key":"act","label":"등장 ACT","kind":"number","default":1},
            {"key":"hp","label":"HP","kind":"number","default":50},
            {"key":"description","label":"설명","kind":"textarea"},
            {"key":"attack_pattern","label":"행동 패턴(JSON)","kind":"json","default":[]},
            {"key":"powers","label":"기본 파워 ID(JSON 배열)","kind":"json","default":[]},
            {"key":"drop_table","label":"드랍(JSON)","kind":"json","default":{}},
            {"key":"image","label":"이미지 경로","kind":"text"},
            {"key":"art_prompt","label":"아트 프롬프트","kind":"textarea"},
            {"key":"art_source","label":"아트 소스","kind":"select","options":["AUTO","COMFYUI","PREMIUM","MANUAL"],"default":"AUTO"},
            {"key":"approval_state","label":"검수 상태","kind":"select","options":["draft","generated","needs_review","approved","rejected"],"default":"draft"},
        ]
    },
    "events": {
        "label": "이벤트",
        "required": ["id","title","category","story","choices"],
        "fields": [
            {"key":"id","label":"ID","kind":"text"},
            {"key":"title","label":"제목","kind":"text"},
            {"key":"category","label":"종류","kind":"select","options":["COMMON","CHARACTER","PARTY","CHAIN"],"default":"COMMON"},
            {"key":"act","label":"ACT(0=전체)","kind":"number","default":0},
            {"key":"rarity","label":"등장 희귀도","kind":"select","options":["일반","낮음","희귀","초희귀"],"default":"일반"},
            {"key":"stage","label":"연속 이벤트 Stage","kind":"number","default":1},
            {"key":"character_restriction","label":"캐릭터 제한","kind":"text"},
            {"key":"story","label":"스토리","kind":"textarea"},
            {"key":"choices","label":"선택지(JSON 배열)","kind":"json","default":[]},
            {"key":"next_stage","label":"다음 Stage ID","kind":"text"},
            {"key":"combat","label":"특수 전투 ID","kind":"text"},
            {"key":"reward","label":"보상/결과(JSON)","kind":"json","default":{}},
            {"key":"text_effects","label":"텍스트 효과(JSON 배열)","kind":"json","default":[]},
            {"key":"image","label":"이벤트 이미지 경로","kind":"text"},
            {"key":"art_prompt","label":"이벤트 아트 프롬프트","kind":"textarea"},
            {"key":"art_source","label":"아트 소스","kind":"select","options":["AUTO","COMFYUI","PREMIUM","MANUAL"],"default":"AUTO"},
            {"key":"approval_state","label":"검수 상태","kind":"select","options":["draft","generated","needs_review","approved","rejected"],"default":"draft"},
        ]
    }
}

for _kind in TYPE_ORDER:
    SCHEMA[_kind]["fields"].append({"key":"runtime","label":"게임 효과/추가 데이터 (JSON)","kind":"json","default":{}})
SCHEMA["cards"]["fields"][5]["options"].append("방어")

def ensure_dirs() -> None:
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    EXPORT_DIR.mkdir(parents=True, exist_ok=True)
    if not DATA_FILE.exists():
        save_data({t: [] for t in TYPE_ORDER})
    if not HANDOVER_STATE_FILE.exists():
        save_json_atomic(HANDOVER_STATE_FILE, {
            "goal":"",
            "completed":"",
            "pending":"",
            "notes":""
        })

def save_json_atomic(path: Path, obj: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + ".tmp")
    tmp.write_text(json.dumps(obj, ensure_ascii=False, indent=2), encoding="utf-8")
    tmp.replace(path)

def load_data() -> dict[str, list[dict[str, Any]]]:
    ensure_dirs()
    try:
        raw = json.loads(DATA_FILE.read_text(encoding="utf-8"))
    except Exception as exc:
        raise ValueError("Content database cannot be read; original preserved") from exc
    for t in TYPE_ORDER:
        raw.setdefault(t, [])
        if not isinstance(raw[t], list):
            raw[t] = []
    return raw

def save_data(data: dict[str, list[dict[str, Any]]]) -> None:
    save_json_atomic(DATA_FILE, data)

def load_handover_state() -> dict[str, str]:
    ensure_dirs()
    try:
        obj = json.loads(HANDOVER_STATE_FILE.read_text(encoding="utf-8"))
    except Exception:
        obj = {}
    return {
        "goal": str(obj.get("goal","")),
        "completed": str(obj.get("completed","")),
        "pending": str(obj.get("pending","")),
        "notes": str(obj.get("notes",""))
    }

def validate_item(kind: str, item: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    if kind not in SCHEMA:
        return [f"알 수 없는 타입: {kind}"]
    for key in SCHEMA[kind]["required"]:
        value = item.get(key)
        if value is None or value == "" or value == []:
            errors.append(f"필수값 누락: {key}")
    if item.get("id") and any(ch.isspace() for ch in str(item["id"])):
        errors.append("id에는 공백을 사용할 수 없습니다.")
    if kind == "cards":
        try:
            if int(item.get("energy_cost", 0)) < 0:
                errors.append("energy_cost는 0 이상이어야 합니다.")
        except Exception:
            errors.append("energy_cost는 숫자여야 합니다.")
    if kind == "relics":
        if item.get("rarity") == "고대":
            if not item.get("character_restriction"):
                errors.append("고대 유물은 character_restriction이 필요합니다.")
            if not item.get("origin_event"):
                errors.append("고대 유물은 origin_event가 필요합니다.")
    if kind == "powers":
        try:
            if int(item.get("duration", 0)) < 0:
                errors.append("duration은 0 이상이어야 합니다.")
        except Exception:
            errors.append("duration은 숫자여야 합니다.")
    if kind == "events":
        choices = item.get("choices")
        if choices is not None and not isinstance(choices, list):
            errors.append("choices는 JSON 배열이어야 합니다.")
        if item.get("category") == "CHARACTER" and not item.get("character_restriction"):
            errors.append("CHARACTER 이벤트는 character_restriction이 필요합니다.")
    return errors

def upsert_item(kind: str, item: dict[str, Any]) -> tuple[bool, list[str]]:
    old = next((x for x in load_data().get(kind, []) if x.get("id") == item.get("id")), {})
    item = {**old, **item}
    if any(item.get(k) != old.get(k) for k in ("image", "icon")) and old:
        item["approval_state"] = "needs_review"
    errors = validate_item(kind, item)
    if errors:
        return False, errors
    data = load_data()
    items = data[kind]
    item_id = str(item["id"])
    for i, old in enumerate(items):
        if str(old.get("id")) == item_id:
            items[i] = item
            save_data(data)
            return True, []
    items.append(item)
    save_data(data)
    return True, []

def delete_item(kind: str, item_id: str) -> bool:
    if kind not in TYPE_ORDER:
        return False
    data = load_data()
    before = len(data[kind])
    data[kind] = [x for x in data[kind] if str(x.get("id")) != item_id]
    save_data(data)
    return len(data[kind]) != before

def validate_all(kind: str | None = None) -> dict[str, Any]:
    data = load_data()
    results: dict[str, Any] = {}
    types = [kind] if kind else TYPE_ORDER
    total = valid = 0
    for t in types:
        if t not in TYPE_ORDER:
            results[t] = {"error":"unknown type"}
            continue
        rows = []
        for item in data[t]:
            total += 1
            errs = validate_item(t, item)
            if not errs:
                valid += 1
            rows.append({"id":item.get("id"),"errors":errs})
        results[t] = rows
    return {"total":total,"valid":valid,"invalid":total-valid,"results":results}

def build_stats() -> dict[str, Any]:
    data = load_data()
    counts = {t: len(data[t]) for t in TYPE_ORDER}
    approved = {}
    for t in TYPE_ORDER:
        approved[t] = sum(1 for x in data[t] if x.get("approval_state") == "approved")
    return {"counts":counts, "approved":approved, "total":sum(counts.values())}

def export_data(godot_path: str | None = None) -> dict[str, Any]:
    import godot_bridge
    return godot_bridge.export_catalog(load_data(), Path(godot_path) if godot_path else APP_DIR.parents[1])

def generate_handover(state: dict[str, str] | None = None) -> str:
    if state is None:
        state = load_handover_state()
    save_json_atomic(HANDOVER_STATE_FILE, state)
    stats = build_stats()
    validation = validate_all()
    lines = [
        "# 운빨원정대 현재 인수인계",
        "",
        f"- 생성 시각: {datetime.now().isoformat(timespec='seconds')}",
        "",
        "## 현재 목표",
        state.get("goal","") or "- 미입력",
        "",
        "## 완료된 것",
        state.get("completed","") or "- 미입력",
        "",
        "## 남은 작업",
        state.get("pending","") or "- 미입력",
        "",
        "## 메모",
        state.get("notes","") or "- 없음",
        "",
        "## 콘텐츠 현황",
    ]
    labels = {t:SCHEMA[t]["label"] for t in TYPE_ORDER}
    for t in TYPE_ORDER:
        lines.append(f"- {labels[t]}: {stats['counts'][t]}개 (approved {stats['approved'][t]}개)")
    lines += [
        "",
        "## 검증 결과",
        f"- 전체 {validation['total']}개 / 정상 {validation['valid']}개 / 오류 {validation['invalid']}개",
        "",
        "## 다음 작업자 필수 규칙",
        "- 종합 이미지 크롭 재사용 금지",
        "- 카드에는 에너지/이름/등급/타입/효과/아트 필수",
        "- 플레이어와 몬스터는 동일한 파워/상태이상 시스템 사용",
        "- 미등록 도감은 실루엣만 표시하고 클릭 반응 없음",
        "- 고대 유물은 캐릭터 전용 특수 이벤트 체인으로만 획득",
        "- 실제 Godot 실행 확인 후 완료 처리",
    ]
    text = "\n".join(lines) + "\n"
    HANDOVER_FILE.write_text(text, encoding="utf-8")
    return text

def comfy_status(base: str = "http://127.0.0.1:8188") -> dict[str, Any]:
    try:
        with urllib.request.urlopen(base.rstrip("/") + "/system_stats", timeout=2.5) as r:
            payload = json.loads(r.read().decode("utf-8"))
        return {"ok":True,"url":base,"system_stats":payload}
    except Exception as e:
        return {"ok":False,"url":base,"error":str(e)}

def _get_json(url: str, timeout: float = 10.0) -> Any:
    with urllib.request.urlopen(url, timeout=timeout) as r:
        return json.loads(r.read().decode("utf-8"))

def _post_json(url: str, payload: Any, timeout: float = 30.0) -> Any:
    raw = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(url, data=raw, headers={"Content-Type":"application/json"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read().decode("utf-8"))

def _default_checkpoint(base: str) -> str:
    info = _get_json(base.rstrip("/") + "/object_info/CheckpointLoaderSimple")
    values = info["CheckpointLoaderSimple"]["input"]["required"]["ckpt_name"][0]
    if not values:
        raise RuntimeError("ComfyUI 체크포인트를 찾지 못했습니다.")
    return values[0]

def _basic_workflow(prompt: str, negative: str, width: int, height: int, seed: int, checkpoint: str, prefix: str) -> dict[str, Any]:
    return {
        "1":{"class_type":"CheckpointLoaderSimple","inputs":{"ckpt_name":checkpoint}},
        "2":{"class_type":"CLIPTextEncode","inputs":{"text":prompt,"clip":["1",1]}},
        "3":{"class_type":"CLIPTextEncode","inputs":{"text":negative,"clip":["1",1]}},
        "4":{"class_type":"EmptyLatentImage","inputs":{"width":width,"height":height,"batch_size":1}},
        "5":{"class_type":"KSampler","inputs":{
            "seed":seed,"steps":28,"cfg":6.5,"sampler_name":"euler","scheduler":"normal","denoise":1.0,
            "model":["1",0],"positive":["2",0],"negative":["3",0],"latent_image":["4",0]
        }},
        "6":{"class_type":"VAEDecode","inputs":{"samples":["5",0],"vae":["1",2]}},
        "7":{"class_type":"SaveImage","inputs":{"filename_prefix":prefix,"images":["6",0]}}
    }

def comfy_generate(payload: dict[str, Any]) -> dict[str, Any]:
    if payload.get("type") not in ("relics", "potions", "enchants", "powers") or not payload.get("id"):
        raise ValueError("Repeatable icon type and existing item id required")
    selected = next((x for x in load_data()[payload["type"]] if x.get("id") == payload["id"]), None)
    if not selected or selected.get("art_source") in ("PREMIUM", "MANUAL"):
        raise ValueError("Item missing or requires premium/manual art")
    if payload.get("type") in ("cards", "monsters", "events"):
        raise ValueError("Core illustration requires a separate high-quality art workflow")
    base = str(payload.get("url") or "http://127.0.0.1:8188").rstrip("/")
    prompt = str(payload.get("prompt") or "").strip()
    if not prompt:
        raise ValueError("prompt가 비어 있습니다.")
    negative = str(payload.get("negative") or "text, watermark, logo, UI, collage, low quality, blurry")
    width = int(payload.get("width") or 768)
    height = int(payload.get("height") or 768)
    seed = int(payload.get("seed") if payload.get("seed") is not None else random.randint(0, 2**63 - 1))
    prefix = str(payload.get("prefix") or "LuckyExpedition")
    output = str(payload.get("output") or f"generated/{prefix}.png")
    checkpoint = str(payload.get("checkpoint") or "").strip() or _default_checkpoint(base)

    workflow_file = str(payload.get("workflow_file") or "").strip()
    if workflow_file:
        wf_path = Path(workflow_file).expanduser()
        if not wf_path.exists():
            raise ValueError("workflow_file이 존재하지 않습니다.")
        workflow = json.loads(wf_path.read_text(encoding="utf-8"))
        # Simple placeholders usable in exported API-format JSON.
        rep = {
            "{{PROMPT}}": prompt,
            "{{NEGATIVE}}": negative,
            "{{SEED}}": seed,
            "{{WIDTH}}": width,
            "{{HEIGHT}}": height,
            "{{PREFIX}}": prefix,
            "{{CHECKPOINT}}": checkpoint,
        }
        raw = json.dumps(workflow)
        for k,v in rep.items():
            raw = raw.replace(k, str(v))
        workflow = json.loads(raw)
    else:
        workflow = _basic_workflow(prompt, negative, width, height, seed, checkpoint, prefix)

    res = _post_json(base + "/prompt", {"prompt":workflow})
    prompt_id = res["prompt_id"]
    images = []
    started = time.time()
    while time.time() - started < 600:
        hist = _get_json(base + "/history/" + prompt_id)
        if prompt_id in hist:
            for node in hist[prompt_id].get("outputs", {}).values():
                images.extend(node.get("images", []))
            if images:
                break
        time.sleep(1.0)
    if not images:
        raise TimeoutError("ComfyUI 생성 완료 대기 시간이 초과되었습니다.")

    img = images[0]
    qs = urllib.parse.urlencode({
        "filename":img["filename"],
        "subfolder":img.get("subfolder",""),
        "type":img.get("type","output")
    })
    out_path = Path(output).expanduser()
    if not out_path.is_absolute():
        out_path = APP_DIR / out_path
    out_path.parent.mkdir(parents=True, exist_ok=True)
    urllib.request.urlretrieve(base + "/view?" + qs, out_path)
    kind, item_id = payload.get("type"), payload.get("id")
    if kind and item_id:
        item = next((x for x in load_data().get(kind, []) if x.get("id") == item_id), None)
        if item is None:
            raise ValueError("Unknown content item")
        item["image" if kind in ("cards", "monsters", "events") else "icon"] = str(out_path)
        item["approval_state"] = "needs_review"
        item["generation"] = {"prompt_id":prompt_id,"seed":seed,"checkpoint":checkpoint}
        upsert_item(kind, item)
    return {"ok":True,"prompt_id":prompt_id,"output":str(out_path),"seed":seed,"checkpoint":checkpoint,"approval_state":"needs_review"}

def json_response(handler: BaseHTTPRequestHandler, status: int, payload: Any) -> None:
    raw = json.dumps(payload, ensure_ascii=False).encode("utf-8")
    handler.send_response(status)
    handler.send_header("Content-Type","application/json; charset=utf-8")
    handler.send_header("Content-Length", str(len(raw)))
    handler.send_header("Cache-Control","no-store")
    handler.end_headers()
    handler.wfile.write(raw)

class Handler(BaseHTTPRequestHandler):
    server_version = "LuckyExpeditionContentTool/1.0"

    def log_message(self, fmt: str, *args: Any) -> None:
        # Keep console readable.
        sys.stdout.write("[HTTP] " + (fmt % args) + "\n")

    def _read_json(self) -> dict[str, Any]:
        length = int(self.headers.get("Content-Length","0") or "0")
        if length <= 0:
            return {}
        raw = self.rfile.read(length)
        return json.loads(raw.decode("utf-8"))

    def _serve_file(self, path: Path, content_type: str) -> None:
        if not path.exists() or not path.is_file():
            self.send_error(404)
            return
        raw = path.read_bytes()
        self.send_response(200)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length",str(len(raw)))
        self.end_headers()
        self.wfile.write(raw)

    def do_GET(self) -> None:
        p = urllib.parse.urlparse(self.path)
        path = p.path
        q = urllib.parse.parse_qs(p.query)
        if path == "/":
            return self._serve_file(STATIC_DIR / "index.html", "text/html; charset=utf-8")
        if path == "/static/app.js":
            return self._serve_file(STATIC_DIR / "app.js", "application/javascript; charset=utf-8")
        if path == "/static/style.css":
            return self._serve_file(STATIC_DIR / "style.css", "text/css; charset=utf-8")
        if path == "/api/schema":
            return json_response(self,200,{"type_order":TYPE_ORDER,"schema":SCHEMA})
        if path == "/api/data":
            return json_response(self,200,load_data())
        if path == "/api/stats":
            return json_response(self,200,build_stats())
        if path == "/api/handover":
            return json_response(self,200,load_handover_state())
        if path == "/api/comfy/status":
            base = q.get("url",["http://127.0.0.1:8188"])[0]
            return json_response(self,200,comfy_status(base))
        if path == "/api/validate":
            kind = q.get("type",[None])[0]
            return json_response(self,200,validate_all(kind))
        self.send_error(404)

    def do_POST(self) -> None:
        p = urllib.parse.urlparse(self.path)
        path = p.path
        try:
            payload = self._read_json()
            if path == "/api/item":
                kind = str(payload.get("type") or "")
                item = payload.get("item")
                if not isinstance(item, dict):
                    return json_response(self,400,{"ok":False,"errors":["item이 객체가 아닙니다."]})
                ok, errors = upsert_item(kind, item)
                return json_response(self,200 if ok else 400,{"ok":ok,"errors":errors})
            if path == "/api/export":
                result = export_data(payload.get("godot_path"))
                return json_response(self,200,{"ok":True,**result})
            if path == "/api/handover":
                state = {
                    "goal":str(payload.get("goal","")),
                    "completed":str(payload.get("completed","")),
                    "pending":str(payload.get("pending","")),
                    "notes":str(payload.get("notes",""))
                }
                text = generate_handover(state)
                return json_response(self,200,{"ok":True,"path":str(HANDOVER_FILE),"text":text})
            if path == "/api/comfy/generate":
                result = comfy_generate(payload)
                return json_response(self,200,result)
            return self.send_error(404)
        except Exception as e:
            return json_response(self,500,{"ok":False,"error":str(e)})

    def do_DELETE(self) -> None:
        p = urllib.parse.urlparse(self.path)
        if p.path != "/api/item":
            return self.send_error(404)
        q = urllib.parse.parse_qs(p.query)
        kind = q.get("type",[""])[0]
        item_id = q.get("id",[""])[0]
        ok = delete_item(kind,item_id)
        return json_response(self,200 if ok else 404,{"ok":ok})

def run_server(host: str, port: int, open_browser: bool) -> None:
    ensure_dirs()
    server = ThreadingHTTPServer((host,port), Handler)
    actual_port = server.server_address[1]
    url = f"http://{host}:{actual_port}"
    print(f"\n운빨원정대 Content Tool 실행: {url}")
    print("종료: Ctrl+C\n")
    if open_browser:
        threading.Timer(0.6, lambda: webbrowser.open(url)).start()
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n서버 종료.")
    finally:
        server.server_close()

def cli() -> None:
    parser = argparse.ArgumentParser(description="운빨원정대 Content Tool")
    sub = parser.add_subparsers(dest="cmd", required=True)

    p = sub.add_parser("import-game")
    p.add_argument("--godot", required=True)

    p = sub.add_parser("serve")
    p.add_argument("--host", default="127.0.0.1")
    p.add_argument("--port", type=int, default=8765)
    p.add_argument("--no-browser", action="store_true")

    p = sub.add_parser("list")
    p.add_argument("type", choices=TYPE_ORDER)

    p = sub.add_parser("add")
    p.add_argument("type", choices=TYPE_ORDER)
    g = p.add_mutually_exclusive_group(required=True)
    g.add_argument("--file")
    g.add_argument("--json")

    p = sub.add_parser("delete")
    p.add_argument("type", choices=TYPE_ORDER)
    p.add_argument("id")

    p = sub.add_parser("validate")
    p.add_argument("--type", choices=TYPE_ORDER)

    p = sub.add_parser("export")
    p.add_argument("--godot")

    p = sub.add_parser("handover")
    p.add_argument("--goal", default="")
    p.add_argument("--completed", default="")
    p.add_argument("--pending", default="")
    p.add_argument("--notes", default="")

    p = sub.add_parser("comfy-status")
    p.add_argument("--url", default="http://127.0.0.1:8188")

    sub.add_parser("self-test")

    args = parser.parse_args()
    ensure_dirs()

    if args.cmd == "import-game":
        import import_game
        print(json.dumps(import_game.run(Path(args.godot), sys.modules[__name__]),ensure_ascii=False))
        return
    if args.cmd == "serve":
        return run_server(args.host,args.port,not args.no_browser)
    if args.cmd == "list":
        print(json.dumps(load_data()[args.type],ensure_ascii=False,indent=2))
        return
    if args.cmd == "add":
        raw = Path(args.file).read_text(encoding="utf-8") if args.file else args.json
        item = json.loads(raw)
        ok, errors = upsert_item(args.type,item)
        if not ok:
            print(json.dumps({"ok":False,"errors":errors},ensure_ascii=False,indent=2))
            raise SystemExit(2)
        print(json.dumps({"ok":True,"id":item["id"]},ensure_ascii=False))
        return
    if args.cmd == "delete":
        ok = delete_item(args.type,args.id)
        print(json.dumps({"ok":ok},ensure_ascii=False))
        raise SystemExit(0 if ok else 1)
    if args.cmd == "validate":
        report = validate_all(args.type)
        print(json.dumps(report,ensure_ascii=False,indent=2))
        raise SystemExit(0 if report["invalid"] == 0 else 2)
    if args.cmd == "export":
        print(json.dumps(export_data(args.godot),ensure_ascii=False,indent=2))
        return
    if args.cmd == "handover":
        state = {"goal":args.goal,"completed":args.completed,"pending":args.pending,"notes":args.notes}
        print(generate_handover(state))
        return
    if args.cmd == "comfy-status":
        result = comfy_status(args.url)
        print(json.dumps(result,ensure_ascii=False,indent=2))
        raise SystemExit(0 if result["ok"] else 1)
    if args.cmd == "self-test":
        ok = run_self_test()
        raise SystemExit(0 if ok else 3)

def run_self_test() -> bool:
    """Non-destructive smoke test using a temporary data directory."""
    global DATA_DIR, DATA_FILE, HANDOVER_STATE_FILE, EXPORT_DIR, HANDOVER_FILE
    original = (DATA_DIR,DATA_FILE,HANDOVER_STATE_FILE,EXPORT_DIR,HANDOVER_FILE)
    import tempfile
    import threading
    try:
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            DATA_DIR = tmp / "data"
            DATA_FILE = DATA_DIR / "content.json"
            HANDOVER_STATE_FILE = DATA_DIR / "handover.json"
            EXPORT_DIR = tmp / "export"
            HANDOVER_FILE = tmp / "HANDOVER_CURRENT.md"
            ensure_dirs()

            card = {
                "id":"test_card","name":"테스트 카드","character":"kalian",
                "energy_cost":1,"rarity":"일반","type":"공격",
                "target":"적 1명","description":"10 피해"
            }
            ok, errs = upsert_item("cards",card)
            assert ok and not errs
            assert load_data()["cards"][0]["id"] == "test_card"

            bad_relic = {"id":"ancient_test","name":"고대 테스트","rarity":"고대","effect":"x","flavor_text":"y"}
            errs = validate_item("relics",bad_relic)
            assert any("character_restriction" in x for x in errs)
            assert any("origin_event" in x for x in errs)

            report = validate_all()
            assert report["total"] == 1 and report["invalid"] == 0

            exp = export_data()
            assert (EXPORT_DIR / "cards.json").exists()
            assert len(exp["written"]) == len(TYPE_ORDER)

            text = generate_handover({"goal":"테스트","completed":"A","pending":"B","notes":"C"})
            assert "테스트" in text and HANDOVER_FILE.exists()

            # HTTP smoke test
            server = ThreadingHTTPServer(("127.0.0.1",0), Handler)
            port = server.server_address[1]
            th = threading.Thread(target=server.serve_forever, daemon=True)
            th.start()
            try:
                schema = _get_json(f"http://127.0.0.1:{port}/api/schema")
                assert "cards" in schema["schema"]
                data = _get_json(f"http://127.0.0.1:{port}/api/data")
                assert data["cards"][0]["id"] == "test_card"
                payload = {"type":"powers","item":{
                    "id":"poison","name":"맹독","category":"DEBUFF",
                    "effect":"턴 시작 피해","tooltip":"중첩만큼 피해"
                }}
                res = _post_json(f"http://127.0.0.1:{port}/api/item",payload)
                assert res["ok"] is True
                got = _get_json(f"http://127.0.0.1:{port}/api/data")
                assert got["powers"][0]["id"] == "poison"
            finally:
                server.shutdown()
                server.server_close()
                th.join(timeout=2)

            print("SELF-TEST PASS")
            return True
    except Exception as e:
        print("SELF-TEST FAIL:",repr(e))
        return False
    finally:
        DATA_DIR,DATA_FILE,HANDOVER_STATE_FILE,EXPORT_DIR,HANDOVER_FILE = original

if __name__ == "__main__":
    cli()
