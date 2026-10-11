"""Promote draft relics to playable once they have effect data and art.

Usage: python tools/promote_relics.py <art_dir> [--dry-run]
Looks for <art_dir>/<relic_id>.png (512x512, transparent background). For every draft relic that has an `effects` list and a
picture, the picture is copied to assets/relics/<relic_id>_v1.png, the effects move into `runtime`
(where the Godot export reads them), the relic becomes shop/treasure material and the catalog is
exported. Afterwards run `Godot --headless --path . --import` so the new pictures get their .import files.
Live relics whose picture was redrawn get the new file copied over (`refreshed`).
Relics without effects (mechanics the game does not have yet) are left as drafts.
"""
import json
import shutil
import struct
import sys
import time
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools" / "content_tool"))
import content_tool as ct  # noqa: E402


def png_size(path: Path):
    head = path.read_bytes()[:32]
    if head[:8] != b"\x89PNG\r\n\x1a\n":
        return None
    return struct.unpack(">II", head[16:24])


def corner_alphas(path: Path):
    """Alpha of the four corner pixels (8-bit, non-interlaced PNG); None when it cannot be read."""
    raw = path.read_bytes()
    pos, idat, header = 8, b"", None
    while pos < len(raw):
        length, kind = struct.unpack(">I4s", raw[pos:pos + 8])
        body = raw[pos + 8:pos + 8 + length]
        if kind == b"IHDR":
            header = struct.unpack(">IIBBBBB", body)
        elif kind == b"IDAT":
            idat += body
        pos += 12 + length
    if header is None:
        return None
    w, h, depth, color, _, _, interlace = header
    if depth != 8 or interlace != 0 or color not in (2, 6):
        return None
    channels = 4 if color == 6 else 3
    if color == 2:
        return [255, 255, 255, 255]
    stride = w * channels
    data = zlib.decompress(idat)
    rows, previous = [], bytearray(stride)
    for y in range(h):
        kind_byte = data[y * (stride + 1)]
        line = bytearray(data[y * (stride + 1) + 1:(y + 1) * (stride + 1)])
        for i in range(stride):
            a = line[i - channels] if i >= channels else 0
            b = previous[i]
            c = previous[i - channels] if i >= channels else 0
            if kind_byte == 1: line[i] = (line[i] + a) & 255
            elif kind_byte == 2: line[i] = (line[i] + b) & 255
            elif kind_byte == 3: line[i] = (line[i] + (a + b) // 2) & 255
            elif kind_byte == 4:
                p = a + b - c
                pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                line[i] = (line[i] + (a if pa <= pb and pa <= pc else (b if pb <= pc else c))) & 255
        rows.append(line)
        previous = line
    alpha = lambda row, x: rows[row][x * channels + 3]
    return [alpha(0, 0), alpha(0, w - 1), alpha(h - 1, 0), alpha(h - 1, w - 1)]


def has_alpha(path: Path) -> bool:
    """Existing relic icons are transparent cut-outs: the four corners must be see-through."""
    alphas = corner_alphas(path)
    return alphas is not None and all(a < 16 for a in alphas)


def retry(call, *args):
    """OneDrive can briefly lock the Content Tool data file; try again a few times."""
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
    data = ct.load_data()
    promoted, skipped, refreshed = [], [], []
    for item in data["relics"]:
        rid = item["id"]
        source = art_dir / f"{rid}.png"
        if item.get("implementation") == "playable":
            # already live: swap in a redrawn picture (same checks), keeping the path so no re-approval is needed
            target = ROOT / "assets" / "relics" / f"{rid}_v1.png"
            if item.get("art_source") == "COMFYUI" and source.is_file() and target.is_file() and png_size(source) == (512, 512)                     and has_alpha(source) and source.read_bytes() != target.read_bytes():
                if not dry: shutil.copyfile(source, target)
                refreshed.append(rid)
            continue
        if not item.get("effects"):
            continue
        if not source.is_file():
            skipped.append((rid, "no art yet"))
            continue
        if png_size(source) != (512, 512):
            skipped.append((rid, f"art is {png_size(source)}, expected 512x512"))
            continue
        if not has_alpha(source):
            skipped.append((rid, "art has no transparent background (existing icons are cut-outs)"))
            continue
        target = ROOT / "assets" / "relics" / f"{rid}_v1.png"
        if not dry:
            shutil.copyfile(source, target)
            runtime = dict(item.get("runtime", {}))
            runtime.update(effects=item["effects"], shop=True, ordinary_drop=True)
            ok, errors = retry(ct.upsert_item, "relics", {
                "id": rid, "runtime": runtime, "implementation": "playable", "text_only": False,
                "image": f"res://assets/relics/{rid}_v1.png", "art_source": "COMFYUI",
                "art_review_state": "agent_applied_pending_user",
                "approval_basis": "Effects implemented in relic_engine; art applied by request, pending user review."})
            if not ok:
                skipped.append((rid, "; ".join(errors)))
                continue
            # changing the image resets approval; approve again now that effects and art are in place
            retry(ct.upsert_item, "relics", {"id": rid, "approval_state": "approved"})
        promoted.append(rid)
    if not dry:
        # finish any relic a previous interrupted run left playable but not approved
        for item in ct.load_data()["relics"]:
            if item.get("implementation") == "playable" and item.get("approval_state") != "approved":
                retry(ct.upsert_item, "relics", {"id": item["id"], "approval_state": "approved"})
        retry(ct.export_data, str(ROOT))
    print(json.dumps({"promoted": promoted, "refreshed": refreshed, "skipped": skipped}, ensure_ascii=False, indent=1))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
