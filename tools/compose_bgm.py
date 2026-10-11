"""Original procedural compositions, not sample-library orchestral recordings.
Circular scheduling/reverb preserves musical loops. Uses numpy and stdlib only.
"""
from pathlib import Path
import json, wave
import numpy as np

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/audio/bgm'
OUT.mkdir(parents=True,exist_ok=True)
SR=44100
RNG=np.random.default_rng(9102026)

SCORES=[
 dict(id='title_embers',title='재 속의 이름',scene='시작 화면',bpm=66,kind='title',chords=[50,46,53,45,50,48,46,45],melody=[74,77,76,69,72,70,69,65],pad=.20,bell=.18,drums=.0),
 dict(id='map_fog',title='등불 사이의 길',scene='원정 지도',bpm=76,kind='map',chords=[50,48,46,45,50,53,48,45],melody=[62,65,69,67,65,62,60,61],pad=.17,bell=.13,drums=.07),
 dict(id='battle_ledger',title='끝나지 않은 회진',scene='일반 전투',bpm=112,kind='battle',chords=[50,50,46,45,50,48,46,45],melody=[74,69,77,76,74,72,70,73],pad=.12,bell=.12,drums=.31),
 dict(id='boss_receiver',title='다음 수령인',scene='보스 전투',bpm=96,kind='boss',chords=[38,39,46,45,38,41,39,45],melody=[62,63,69,68,65,62,63,61],pad=.24,bell=.14,drums=.38),
 dict(id='shop_candle',title='촛불 아래 흥정',scene='상점',bpm=82,kind='shop',chords=[50,53,46,48,50,55,46,45],melody=[74,77,81,79,77,74,72,73],pad=.10,bell=.17,drums=.02),
 dict(id='story_margin',title='지워지지 않은 여백',scene='스토리·연대표',bpm=60,kind='story',chords=[50,46,48,45,50,53,46,45],melody=[74,69,70,72,65,69,67,61],pad=.18,bell=.13,drums=.0),
]

def freq(note): return 440*2**((note-69)/12)

def tone(note,seconds,kind):
    t=np.arange(max(1,int(seconds*SR)))/SR
    f=freq(note)
    if kind=='pad':
        y=np.zeros(len(t))
        for detune in [-.0017,.0014]:
            phase=2*np.pi*f*(1+detune)*t+.008*f*np.sin(2*np.pi*.19*t)
            for k in range(1,8): y+=np.sin(k*phase+ k*.21)/(k*k*2)
        attack=np.minimum(t/.65,1); release=np.minimum((seconds-t)/1.1,1)
        y*=attack*np.maximum(release,0)
    elif kind=='bell':
        y=sum(np.sin(2*np.pi*f*r*t)*a*np.exp(-t/d) for r,a,d in [(1,1,2.8),(2,.30,1.2),(2.76,.12,.7),(4.03,.05,.4)])
        y*=np.minimum(t/.006,1)*np.minimum((seconds-t)/.2,1)
    elif kind=='pluck':
        y=sum(np.sin(2*np.pi*f*k*t+.01*k*np.sin(2*np.pi*4*t))*np.exp(-t*(2+k*.4))/k**1.5 for k in range(1,9))
        y*=np.minimum(t/.004,1)*np.minimum((seconds-t)/.10,1)
    elif kind=='organ':
        y=sum(np.sin(2*np.pi*f*r*t)*a for r,a in [(1,.65),(2,.25),(3,.08),(.5,.12)])
        y*=np.minimum(t/.09,1)*np.minimum((seconds-t)/.3,1)
    else:
        y=np.sin(2*np.pi*f*t+.03*np.sin(2*np.pi*4.8*t))+.25*np.sin(2*np.pi*2*f*t)
        y*=np.minimum(t/.15,1)*np.minimum((seconds-t)/.3,1)
    return y.astype(np.float32)

def drum(kind):
    sec=.85 if kind=='low' else .27
    t=np.arange(int(sec*SR))/SR
    noise=RNG.normal(0,1,len(t))
    if kind=='low':
        phase=2*np.pi*(48*t+32*.05*(1-np.exp(-t/.05)))
        y=np.sin(phase)*np.exp(-t*7)+.10*noise*np.exp(-t*65)
    else:
        noise=np.convolve(noise,np.ones(8)/8,mode='same')
        y=noise*np.exp(-t*24)+.15*np.sin(2*np.pi*155*t)*np.exp(-t*30)
    return y.astype(np.float32)

def add(buf,y,beat,spb,amp,pan=0):
    start=int(beat*spb*SR)
    ix=(np.arange(len(y))+start)%len(buf)
    buf[ix,0]+=y*amp*np.sqrt((1-pan)/2)
    buf[ix,1]+=y*amp*np.sqrt((1+pan)/2)

def save(path,data):
    pcm=(np.clip(data,-.999,.999)*32767).astype('<i2')
    with wave.open(str(path),'wb') as f:
        f.setnchannels(2); f.setsampwidth(2); f.setframerate(SR); f.writeframes(pcm.tobytes())

def compose(score):
    spb=60/score['bpm']; bars=16
    n=int(round(bars*4*spb*SR)); mix=np.zeros((n,2),np.float32)
    for bar in range(bars):
        root=score['chords'][bar%8]; b=bar*4
        intervals=[0,3,7] if bar%8 not in [3,7] else [0,4,7]
        for i,k in enumerate(intervals):
            add(mix,tone(root+12+k,spb*5.8,'pad'),b,spb,score['pad']/3,[-.55,0,.55][i])
        add(mix,tone(root-12,spb*3.8,'organ'),b,spb,.13,0)
        if score['kind'] in ['battle','boss']:
            for step in range(8):
                note=root+12+[0,7,12,7,3,7,12,7][step]
                add(mix,tone(note,spb*.48,'pluck'),b+step*.5,spb,.085,(-1)**step*.35)
            for step in [0,2]: add(mix,drum('low'),b+step,spb,score['drums'])
            for step in [1,3]: add(mix,drum('tap'),b+step,spb,score['drums']*.38,.18)
            if bar%4==3:
                for step in [3,3.5,3.75]: add(mix,drum('low'),b+step,spb,score['drums']*.55,-.15)
        elif score['kind'] in ['shop','map']:
            for step,k in enumerate([0,7,12,3]):
                add(mix,tone(root+12+k,spb*1.7,'pluck'),b+step,spb,.095 if score['kind']=='shop' else .055,(-1)**step*.35)
            add(mix,drum('tap'),b+2,spb,score['drums'],.1)
        m=score['melody'][bar%8]
        # Shared rising minor-third motif, independently varied across scenes.
        if bar%2==0:
            add(mix,tone(m,spb*3.4,'bell'),b+.5,spb,score['bell'],-.12)
            add(mix,tone(m+3 if bar%8==0 else m-2,spb*2,'bell'),b+2.5,spb,score['bell']*.6,.3)
        elif score['kind'] not in ['story','title'] or bar%4==3:
            add(mix,tone(m,spb*3,'bell'),b+1,spb,score['bell']*.65,.25)
        if score['kind']=='boss':
            add(mix,tone(root+12,spb*3.8,'organ'),b,spb,.15,-.2)
            if bar%4==3: add(mix,tone(root+25,spb*2.2,'pad'),b+2,spb,.075,.4)
    # Circular late reflections retain tails at the beginning of the next loop.
    dry=mix.copy()
    for delay,gain in [(.083,.12),(.149,.10),(.281,.08),(.443,.065),(.719,.045),(1.117,.03)]:
        mix+=np.roll(dry[:,::-1],int(delay*SR),axis=0)*gain
    mix-=mix.mean(axis=0)
    peak=float(np.max(np.abs(mix)))
    mix*=.62/max(peak,.001)
    # Very short boundary taper prevents residual waveform discontinuity.
    fade=int(.006*SR)
    mix[:fade]*=np.linspace(0,1,fade)[:,None]
    mix[-fade:]*=np.linspace(1,0,fade)[:,None]
    path=OUT/(score['id']+'.wav');save(path,mix)
    rms=float(np.sqrt(np.mean(mix**2)))
    record={**score,'path':path.relative_to(ROOT).as_posix(),'duration_seconds':round(n/SR,3),'sample_rate':SR,'channels':2,'bars':bars,'beats_per_bar':4,'peak_dbfs':round(20*np.log10(np.max(np.abs(mix))),2),'rms_dbfs':round(20*np.log10(rms),2),'loop':True,'status':'needs_listening_review','production':'original procedural composition and synthesis; no external samples'}
    print(score['id'],record['duration_seconds'],'seconds',flush=True)
    return record,mix

if __name__=='__main__':
    records=[]; previews=[]
    for s in SCORES:
        record,mix=compose(s);records.append(record)
        clip=mix[:SR*12].copy();fade=SR//2
        clip[:fade]*=np.linspace(0,1,fade)[:,None];clip[-fade:]*=np.linspace(1,0,fade)[:,None]
        previews.extend([clip,np.zeros((SR,2),np.float32)])
    save(OUT/'bgm_preview_6tracks.wav',np.concatenate(previews))
    (OUT/'manifest.json').write_text(json.dumps(records,ensure_ascii=False,indent=2,default=float),encoding='utf-8')
