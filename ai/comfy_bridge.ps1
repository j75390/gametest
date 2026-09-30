$ErrorActionPreference = 'Stop'
$comfyPython = 'D:\Comfy-Desktop\ComfyUI-Installs\ComfyUI\standalone-env\python.exe'
if (-not (Test-Path -LiteralPath $comfyPython)) { throw "ComfyUI Python not found: $comfyPython" }
& $comfyPython (Join-Path $PSScriptRoot 'comfy_bridge.py') @args
exit $LASTEXITCODE
