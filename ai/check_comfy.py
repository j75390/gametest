"""Read-only local ComfyUI readiness check; never queues generation."""
import json
import sys
from pathlib import Path
from urllib.request import urlopen

root = Path(__file__).resolve().parent
config = json.loads((root / 'comfy_config.json').read_text(encoding='utf-8-sig'))
base = config['api_url'].rstrip('/')

def get(route):
    with urlopen(base + route, timeout=10) as response:
        return json.load(response)

try:
    stats = get('/system_stats')
    info = get('/object_info')
    queue = get('/queue')
    checkpoints = info['CheckpointLoaderSimple']['input']['required']['ckpt_name'][0]
    bg = info.get('LoadBackgroundRemovalModel', {}).get('input', {}).get('required', {}).get('bg_removal_name', [])
    bg_models = bg[1].get('options', []) if len(bg) > 1 and isinstance(bg[1], dict) else []
    required = ['CheckpointLoaderSimple', 'CLIPTextEncode', 'EmptyLatentImage', 'KSampler', 'VAEDecode', 'SaveImage']
    report = {
        'api': base, 'connected': True,
        'device': [d['name'] for d in stats.get('devices', [])],
        'checkpoints': checkpoints,
        'basic_generation_ready': bool(checkpoints) and all(n in info for n in required),
        'background_removal_models': bg_models,
        'background_removal_ready': bool(bg_models) and 'RemoveBackground' in info,
        'ipadapter_nodes': [n for n in info if 'ipadapter' in n.lower()],
        'queue_running': len(queue.get('queue_running', [])),
        'queue_pending': len(queue.get('queue_pending', [])),
        'generation_queued_by_check': False,
    }
    print(json.dumps(report, ensure_ascii=False, indent=2))
except Exception as exc:
    print('ComfyUI check failed: ' + str(exc), file=sys.stderr)
    sys.exit(1)
