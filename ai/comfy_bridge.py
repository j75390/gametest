"""Local ComfyUI bridge. Standard library only; assets are promoted separately."""
import argparse
import json
import sys
import time
import uuid
from pathlib import Path
from urllib.request import Request, urlopen
from urllib.parse import urlencode, urlparse
from urllib.error import HTTPError, URLError

ROOT = Path(__file__).resolve().parent

def read(path):
    return json.loads(Path(path).read_text(encoding="utf-8-sig"))

def request(base, route, payload=None, raw=False):
    data = None if payload is None else json.dumps(payload).encode()
    req = Request(base + route, data=data, headers={"Content-Type": "application/json"})
    try:
        with urlopen(req, timeout=30) as response:
            body = response.read()
    except HTTPError as exc:
        raise RuntimeError(f"HTTP {exc.code}: {exc.read().decode(errors='replace')}") from exc
    return body if raw else json.loads(body)

def run():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", type=Path, default=ROOT / "comfy_config.json")
    commands = parser.add_subparsers(dest="command", required=True)
    commands.add_parser("status")
    commands.add_parser("models")
    upload = commands.add_parser("upload")
    upload.add_argument("image", type=Path)
    gen = commands.add_parser("generate")
    gen.add_argument("--workflow", type=Path, default=ROOT / "workflows/sdxl_api.json")
    gen.add_argument("--prompt")
    gen.add_argument("--negative")
    gen.add_argument("--seed", type=int)
    gen.add_argument("--steps", type=int)
    gen.add_argument("--timeout", type=float, default=600)
    gen.add_argument("--set", action="append", default=[], metavar="NODE.INPUT=JSON")
    args = parser.parse_args()
    config = read(args.config)
    base = config["api_url"].rstrip("/")
    if urlparse(base).hostname not in ("127.0.0.1", "localhost", "::1"):
        raise ValueError("Only local ComfyUI endpoints are supported")
    if args.command == "status":
        print(json.dumps(request(base, "/system_stats"), ensure_ascii=False, indent=2))
        return
    if args.command == "models":
        info = request(base, "/object_info/CheckpointLoaderSimple")
        print(json.dumps(info["CheckpointLoaderSimple"]["input"]["required"]["ckpt_name"][0], ensure_ascii=False))
        return
    if args.command == "upload":
        boundary = uuid.uuid4().hex
        name = uuid.uuid4().hex + args.image.suffix.lower()
        body = (f'--{boundary}\r\nContent-Disposition: form-data; name="image"; filename="{name}"\r\nContent-Type: application/octet-stream\r\n\r\n').encode()
        body += args.image.read_bytes() + f'\r\n--{boundary}--\r\n'.encode()
        req = Request(base + "/upload/image", data=body, headers={"Content-Type": f"multipart/form-data; boundary={boundary}"})
        with urlopen(req, timeout=60) as response:
            print(response.read().decode())
        return
    workflow = read(args.workflow)
    if not isinstance(workflow, dict) or "nodes" in workflow or not all(isinstance(v, dict) and "class_type" in v for v in workflow.values()):
        raise ValueError("Workflow must be an API-format node dictionary")
    bindings = config.get("bindings", {})
    for option in ("prompt", "negative", "seed", "steps"):
        value = getattr(args, option)
        if value is not None:
            node, field = bindings[option].split(".", 1)
            workflow[node]["inputs"][field] = value
    for assignment in args.set:
        target, value = assignment.split("=", 1)
        node, field = target.split(".", 1)
        if field not in workflow[node]["inputs"]:
            raise ValueError(f"Unknown input: {target}")
        workflow[node]["inputs"][field] = json.loads(value)
    folder = ROOT / "generated" / (time.strftime("%Y%m%d-%H%M%S") + "-" + uuid.uuid4().hex[:8])
    folder.mkdir(parents=True)
    (folder / "workflow.json").write_text(json.dumps(workflow, ensure_ascii=False, indent=2), encoding="utf-8")
    reply = request(base, "/prompt", {"prompt": workflow, "client_id": str(uuid.uuid4())})
    if reply.get("node_errors"):
        raise RuntimeError(json.dumps(reply))
    prompt_id = reply["prompt_id"]
    (folder / "job.json").write_text(json.dumps(reply, indent=2), encoding="utf-8")
    print(f"Queued {prompt_id}", flush=True)
    deadline = time.monotonic() + args.timeout
    while time.monotonic() < deadline:
        history = request(base, "/history/" + prompt_id).get(prompt_id)
        if history:
            (folder / "history.json").write_text(json.dumps(history, ensure_ascii=False, indent=2), encoding="utf-8")
            status = history.get("status", {})
            if status.get("status_str") == "error":
                raise RuntimeError(f"Generation failed; see {folder / 'history.json'}")
            if status.get("completed"):
                count = 0
                for output in history.get("outputs", {}).values():
                    for item in output.get("images", []):
                        if item.get("type") != "output":
                            continue
                        content = request(base, "/view?" + urlencode({k: item[k] for k in ("filename", "subfolder", "type")}), raw=True)
                        if not content.startswith(b"\x89PNG\r\n\x1a\n"):
                            raise ValueError("Expected a PNG output")
                        count += 1
                        target = folder / f"image_{count:03d}.png"
                        target.write_bytes(content)
                        print(target, flush=True)
                if not count:
                    raise RuntimeError("No saved PNG outputs; add a SaveImage node")
                return
        time.sleep(2)
    raise TimeoutError(f"Job {prompt_id} still pending. Server job was not cancelled; metadata: {folder}")

if __name__ == "__main__":
    try:
        run()
    except (OSError, ValueError, KeyError, RuntimeError, TimeoutError, URLError) as exc:
        print(f"Comfy bridge error: {exc}", file=sys.stderr)
        sys.exit(1)
