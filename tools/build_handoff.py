"""Create and verify a self-contained project handoff, excluding machine caches."""
from pathlib import Path
from hashlib import sha256
from zipfile import ZipFile, ZIP_DEFLATED
import json

root = Path(__file__).resolve().parents[1]
output = root / 'handoff_packages'
output.mkdir(exist_ok=True)
package = output / '잿빛원정대_집PC인계_2026-09-30.zip'
index = 2
while package.exists():
    package = output / f'잿빛원정대_집PC인계_2026-09-30_{index}.zip'
    index += 1
files = [root / name for name in ('project.godot', 'AGENTS.md', 'HANDOFF.md', 'HOME_PC_START.txt', 'README.md')]
for folder in ('assets', 'data', 'docs', 'scenes', 'scripts', 'tools', 'references', 'addons/godot_ai'):
    for path in (root / folder).rglob('*'):
        if path.is_file() and not path.is_symlink() and not any(part in {'.git', '.godot', '__pycache__', '.aws', '.codex'} for part in path.parts) and path.name != '.env':
            files.append(path)
prefix = '잿빛원정대_학원인계/'
manifest = []
with ZipFile(package, 'w', ZIP_DEFLATED, compresslevel=6) as archive:
    for path in sorted(set(files)):
        relative = path.relative_to(root).as_posix()
        contents = path.read_bytes()
        manifest.append({'path': relative, 'bytes': len(contents), 'sha256': sha256(contents).hexdigest()})
        archive.writestr(prefix + relative, contents)
    archive.writestr(prefix + 'TRANSFER_MANIFEST.json', json.dumps(manifest, ensure_ascii=False, indent=2))
with ZipFile(package) as archive:
    assert archive.testzip() is None, 'ZIP CRC validation failed'
    for entry in manifest:
        assert sha256(archive.read(prefix + entry['path'])).hexdigest() == entry['sha256'], entry['path']
    for required in ('HANDOFF.md', 'HOME_PC_START.txt', 'AGENTS.md', 'project.godot', 'scripts/expedition_map.gd', 'assets/map/expedition-parchment-v2.png'):
        assert prefix + required in archive.namelist(), required
    for icon in ('battle', 'elite', 'boss', 'shop', 'rest', 'treasure', 'event', 'camp'):
        assert prefix + f'assets/map/icons/{icon}.png' in archive.namelist(), icon
report = {'package': package.name, 'files': len(manifest), 'bytes': package.stat().st_size, 'sha256': sha256(package.read_bytes()).hexdigest(), 'verification': 'ZIP CRC and every file SHA-256 passed'}
package.with_suffix('.verification.json').write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding='utf-8')
print(json.dumps(report, ensure_ascii=False, indent=2))
