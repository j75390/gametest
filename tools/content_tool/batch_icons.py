"""Resumable local ComfyUI icon jobs through the Content Tool API functions.
Generation stages assets for review; never auto-enables unimplemented effects.
"""
import argparse
import json
from pathlib import Path
import time
import content_tool as ct

def run(manifest_path):
    manifest_path = Path(manifest_path).resolve()
    jobs = json.loads(manifest_path.read_text(encoding='utf-8-sig'))
    output = manifest_path.parent / (manifest_path.stem + '_output')
    output.mkdir(parents=True, exist_ok=True)
    journal = output / 'results.json'
    results = json.loads(journal.read_text(encoding='utf-8')) if journal.exists() else {}
    for i, job in enumerate(jobs):
        key = job['type'] + '/' + job['id']
        if results.get(key, {}).get('ok') and Path(results[key]['output']).is_file():
            print('SKIP ' + key, flush=True)
            continue
        item = next(x for x in ct.load_data()[job['type']] if x['id'] == job['id'])
        if (item.get('image') or item.get('icon')) and not (job.get('retry_generated') and item.get('art_source') == 'COMFYUI' and item.get('approval_state') == 'needs_review'):
            raise ValueError('Refusing existing art: ' + key)
        print(f'START {i+1}/{len(jobs)} {key}', flush=True)
        # Each explicitly listed job opts into the user-requested ComfyUI lane.
        previous = item.copy()
        ct.save_json_atomic(output / (job['id'] + '.before.json'), previous)
        ok, errors = ct.upsert_item(job['type'], {'id': job['id'], 'art_source': 'COMFYUI'})
        if not ok: raise ValueError(errors)
        wf = ct._basic_workflow(job['prompt'], job.get('negative', 'text, letters, watermark, photo, background scene, multiple objects, grid, collage, border, frame, cropped, blurry'), job.get('size', 576), job.get('size', 576), job['seed'], 'sd_xl_base_1.0.safetensors', 'codex_icons/' + job['id'])
        wf['5']['inputs'].update(steps=job.get('steps',18), cfg=6.0, sampler_name='euler', scheduler='normal')
        wf['8'] = {'class_type':'LoadBackgroundRemovalModel','inputs':{'bg_removal_name':'birefnet.safetensors'}}
        wf['9'] = {'class_type':'RemoveBackground','inputs':{'bg_removal_model':['8',0],'image':['6',0]}}
        wf['10'] = {'class_type':'InvertMask','inputs':{'mask':['9',0]}}
        wf['11'] = {'class_type':'JoinImageWithAlpha','inputs':{'image':['6',0],'alpha':['10',0]}}
        wf['7']['inputs']['images'] = ['11',0]
        workflow = output / (job['id'] + '.workflow.json')
        ct.save_json_atomic(workflow, wf)
        started = time.time()
        try:
            result = ct.comfy_generate({**job, 'workflow_file': str(workflow), 'output': str(output / (job['id'] + '.png'))})
            result['previous_approval_state'] = previous.get('approval_state', 'draft')
            result['seconds'] = round(time.time() - started, 1)
            results[key] = result
            print('DONE ' + key + ' ' + str(result['seconds']) + 's', flush=True)
        except Exception as exc:
            results[key] = {'ok': False, 'error': str(exc)}
            print('FAILED ' + key + ': ' + str(exc), flush=True)
        ct.save_json_atomic(journal, results)
    print('BATCH COMPLETE ' + str(sum(bool(x.get('ok')) for x in results.values())) + '/' + str(len(jobs)), flush=True)

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('manifest')
    args = parser.parse_args()
    run(args.manifest)
