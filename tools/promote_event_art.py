"""Attach illustrations to story events that have none.

Usage: python tools/promote_event_art.py <art_dir> [--dry-run]
Looks for <art_dir>/<event_id>.png (2:3 portrait, at least 800x1200). For every live event without art the picture is
copied to assets/events/<event_id>_v1.png, the event gets `image`, and the catalog is exported.
Afterwards run `Godot --headless --path . --import`.
"""
import json
import shutil
import struct
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools" / "content_tool"))
import content_tool as ct  # noqa: E402


def png_size(path: Path):
    head = path.read_bytes()[:32]
    if head[:8] != b"\x89PNG\r\n\x1a\n":
        return None
    return struct.unpack(">II", head[16:24])


def retry(call, *args):
    for attempt in range(6):
        try:
            return call(*args)
        except PermissionError:
            time.sleep(1.0 + attempt)
    return call(*args)


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    art_dir = Path(sys.argv[1])
    dry = "--dry-run" in sys.argv
    promoted, skipped = [], []
    for item in ct.load_data()["events"]:
        if item.get("approval_state") != "approved" or item.get("image"):
            continue
        source = art_dir / f"{item['id']}.png"
        if not source.is_file():
            continue
        size = png_size(source)
        if size is None or size[0] < 800 or abs(size[0] / size[1] - 2 / 3) > 0.03:
            skipped.append((item["id"], f"art is {size}, expected a 2:3 portrait of at least 800x1200"))
            continue
        if not dry:
            target = ROOT / "assets" / "events" / f"{item['id']}_v1.png"
            shutil.copyfile(source, target)
            ok, errors = retry(ct.upsert_item, "events", {"id": item["id"], "image": f"res://assets/events/{item['id']}_v1.png",
                                                          "art_source": "COMFYUI", "text_only": False})
            if not ok:
                skipped.append((item["id"], "; ".join(errors)))
                continue
            retry(ct.upsert_item, "events", {"id": item["id"], "approval_state": "approved"})
        promoted.append(item["id"])
    if not dry and promoted:
        retry(ct.export_data, str(ROOT))
    print(json.dumps({"promoted": promoted, "skipped": skipped}, ensure_ascii=False, indent=1))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
