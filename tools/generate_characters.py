"""Reproduce reviewed ComfyUI workflows into a fresh review folder; never overwrite live art."""
import argparse, datetime, subprocess, sys
from pathlib import Path
root=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser()
p.add_argument('--characters',nargs='+',choices=['mira','kalian','sera','lucian'],default=['mira','kalian','sera','lucian'])
p.add_argument('--output-dir',type=Path)
p.add_argument('--seed',type=int)
a=p.parse_args()
folder=a.output_dir or root/'ai/generated'/datetime.datetime.now().strftime('selection-%Y%m%d-%H%M%S')
for name in a.characters:
 command=[sys.executable,str(root/'tools/comfy_bridge.py'),'--workflow',str(root/'ai/workflows/selection'/(name+'.json')),'--output',str(folder/(name+'_character_select.png'))]
 if name=='mira':command+=['--reference',str(root/'assets/characters/mira/full_02.png')]
 if a.seed is not None:command+=['--seed',str(a.seed)]
 subprocess.run(command,cwd=root,check=True)
print('Generated for review; live assets and character data were not overwritten.')
