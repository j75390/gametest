
import argparse, json, random, time, urllib.request, urllib.parse, uuid
from pathlib import Path

BASE="http://127.0.0.1:8188"

def getj(url):
    with urllib.request.urlopen(url, timeout=10) as r:
        return json.loads(r.read().decode())

def postj(url, payload):
    data=json.dumps(payload).encode()
    req=urllib.request.Request(url,data=data,headers={"Content-Type":"application/json"})
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.loads(r.read().decode())

def checkpoint(base):
    info=getj(base+"/object_info/CheckpointLoaderSimple")
    vals=info["CheckpointLoaderSimple"]["input"]["required"]["ckpt_name"][0]
    if not vals:
        raise RuntimeError("No checkpoint found")
    return vals[0]

def wf(prompt,negative,w,h,steps,cfg,seed,ckpt,prefix):
    return {
      "1":{"class_type":"CheckpointLoaderSimple","inputs":{"ckpt_name":ckpt}},
      "2":{"class_type":"CLIPTextEncode","inputs":{"text":prompt,"clip":["1",1]}},
      "3":{"class_type":"CLIPTextEncode","inputs":{"text":negative,"clip":["1",1]}},
      "4":{"class_type":"EmptyLatentImage","inputs":{"width":w,"height":h,"batch_size":1}},
      "5":{"class_type":"KSampler","inputs":{"seed":seed,"steps":steps,"cfg":cfg,"sampler_name":"euler","scheduler":"normal","denoise":1.0,"model":["1",0],"positive":["2",0],"negative":["3",0],"latent_image":["4",0]}},
      "6":{"class_type":"VAEDecode","inputs":{"samples":["5",0],"vae":["1",2]}},
      "7":{"class_type":"SaveImage","inputs":{"filename_prefix":prefix,"images":["6",0]}}
    }

def wait(base,pid):
    for _ in range(600):
        h=getj(base+"/history/"+pid)
        if pid in h:
            if h[pid].get("status", {}).get("status_str") == "error":
                raise RuntimeError(json.dumps(h[pid]["status"], ensure_ascii=False))
            imgs=[]
            for node in h[pid].get("outputs",{}).values():
                imgs += node.get("images",[])
            if imgs: return imgs
        time.sleep(1)
    raise TimeoutError("ComfyUI timeout")

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--url",default=BASE)
    ap.add_argument("--prompt")
    ap.add_argument("--workflow", type=Path)
    ap.add_argument("--reference", type=Path)
    ap.add_argument("--negative",default="text, watermark, logo, UI, collage, multiple characters, low quality, blurry")
    ap.add_argument("--width",type=int,default=832)
    ap.add_argument("--height",type=int,default=1216)
    ap.add_argument("--steps",type=int,default=28)
    ap.add_argument("--cfg",type=float,default=6.5)
    ap.add_argument("--seed",type=int,default=-1)
    ap.add_argument("--checkpoint",default="")
    ap.add_argument("--prefix",default="LuckyExpedition")
    ap.add_argument("--output",required=True)
    ap.add_argument("--transparent", action="store_true")
    a=ap.parse_args()

    base=a.url.rstrip("/")
    getj(base+"/system_stats")
    seed=a.seed if a.seed>=0 else random.randint(0,2**63-1)
    ck=a.checkpoint or checkpoint(base)
    if a.workflow:
        workflow=json.loads(a.workflow.read_text(encoding="utf-8-sig"))
        if a.seed >= 0: workflow["5"]["inputs"]["seed"] = a.seed
    else:
        if not a.prompt: ap.error("--prompt or --workflow is required")
        workflow=wf(a.prompt,a.negative,a.width,a.height,a.steps,a.cfg,seed,ck,a.prefix)
    if a.reference:
        boundary=uuid.uuid4().hex
        name=uuid.uuid4().hex+a.reference.suffix
        body=(f'--{boundary}\r\nContent-Disposition: form-data; name="image"; filename="{name}"\r\nContent-Type: application/octet-stream\r\n\r\n').encode()
        body+=a.reference.read_bytes()+f'\r\n--{boundary}--\r\n'.encode()
        request=urllib.request.Request(base+"/upload/image",data=body,headers={"Content-Type":f"multipart/form-data; boundary={boundary}"})
        with urllib.request.urlopen(request,timeout=60) as response: uploaded=json.load(response)
        workflow["20"]["inputs"]["image"]=uploaded["name"]
    workflow["5"]["inputs"].update(sampler_name="dpmpp_2m", scheduler="karras")
    if a.transparent:
        workflow["8"]={"class_type":"LoadBackgroundRemovalModel","inputs":{"bg_removal_name":"birefnet.safetensors"}}
        workflow["9"]={"class_type":"RemoveBackground","inputs":{"bg_removal_model":["8",0],"image":["6",0]}}
        workflow["10"]={"class_type":"InvertMask","inputs":{"mask":["9",0]}}
        workflow["11"]={"class_type":"JoinImageWithAlpha","inputs":{"image":["6",0],"alpha":["10",0]}}
        workflow["7"]["inputs"]["images"]=["11",0]
    out=Path(a.output)
    out.parent.mkdir(parents=True,exist_ok=True)
    if out.exists():
        raise FileExistsError(f"Refusing to overwrite {out}; choose a new output filename")
    out.with_suffix('.workflow.json').write_text(json.dumps(workflow,ensure_ascii=False,indent=2),encoding='utf-8')
    res=postj(base+"/prompt",{"prompt":workflow})
    out.with_suffix('.job.json').write_text(json.dumps(res,indent=2),encoding='utf-8')
    print('Queued '+res['prompt_id'],flush=True)
    imgs=wait(base,res["prompt_id"])
    img=imgs[0]
    q=urllib.parse.urlencode({"filename":img["filename"],"subfolder":img.get("subfolder",""),"type":img.get("type","output")})
    out=Path(a.output)
    out.parent.mkdir(parents=True,exist_ok=True)
    urllib.request.urlretrieve(base+"/view?"+q,out)
    print(out.resolve())

if __name__=="__main__":
    main()
