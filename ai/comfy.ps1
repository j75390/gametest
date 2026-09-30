param(
    [ValidateSet('check','generate')][string]$Action = 'check',
    [ValidateSet('character','background','card')][string]$Preset = 'character',
    [string]$Prompt,
    [long]$Seed = 9357
)
$ErrorActionPreference = 'Stop'
$comfyPython = 'D:\Comfy-Desktop\ComfyUI-Installs\ComfyUI\standalone-env\python.exe'
if (-not (Test-Path -LiteralPath $comfyPython)) { throw "Missing ComfyUI Python: $comfyPython" }
if ($Action -eq 'check') {
    & $comfyPython (Join-Path $PSScriptRoot 'check_comfy.py')
} else {
    if ([string]::IsNullOrWhiteSpace($Prompt)) { throw 'Use -Prompt to describe the requested image.' }
    & $comfyPython (Join-Path $PSScriptRoot 'comfy_bridge.py') generate --workflow (Join-Path $PSScriptRoot "workflows\${Preset}_api.json") --prompt $Prompt --seed $Seed
}
exit $LASTEXITCODE
