from pathlib import Path
import json,wave
import numpy as np
root=Path(__file__).resolve().parents[1]
folder=root/'assets/audio/bgm'
records=json.loads((folder/'manifest.json').read_text(encoding='utf-8'))
assert len(records)==6
results=[]
for r in records:
    path=root/r['path']
    with wave.open(str(path),'rb') as w:
        assert (w.getnchannels(),w.getsampwidth(),w.getframerate())==(2,2,44100)
        n=w.getnframes(); raw=w.readframes(n)
        assert len(raw)==n*4
    data=np.frombuffer(raw,dtype='<i2').reshape(-1,2)/32768
    peak=float(np.max(np.abs(data)))
    rms=float(np.sqrt(np.mean(data**2)))
    seam=float(np.max(np.abs(data[0]-data[-1])))
    assert peak<.9 and rms>.005 and seam<.001
    results.append({'id':r['id'],'frames':n,'duration':round(n/44100,3),'peak':round(peak,4),'rms':round(rms,4),'boundary_difference':seam,'clipped_samples':int(np.sum(np.abs(data)>=.999))})
out=root/'docs/proposals/BGM_ASSET_QA_20261009.json'
out.write_text(json.dumps({'checks':'WAV structure, stereo, sample rate, non-silence, no clipping, boundary continuity','not_checked':'human listening quality and Godot scene integration','tracks':results},indent=2),encoding='utf-8')
print('BGM_ASSET_QA 6 tracks passed; listening review required')
