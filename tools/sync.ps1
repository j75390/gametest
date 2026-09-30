param(
    [ValidateSet('start', 'finish', 'status')][string]$Action = 'status',
    [string]$Message = ''
)
$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)
function Run-Git {
    & git @args
    if ($LASTEXITCODE -ne 0) { throw 'Git failed. Resolve the reported problem before continuing.' }
}
if ($Action -eq 'status') {
    Run-Git status --short --branch
    exit
}
$branch = & git branch --show-current
if ($LASTEXITCODE -ne 0 -or $branch -ne 'main') { throw 'Use main, or manage your feature branch manually.' }
$changes = & git status --porcelain
if ($LASTEXITCODE -ne 0) { throw 'Cannot inspect working tree.' }
if ($Action -eq 'start') {
    if ($changes) { throw 'Local changes exist. Preserve and commit them before pulling. No files were overwritten.' }
    Run-Git pull --ff-only origin main
    exit
}
if ($changes) {
    if ([string]::IsNullOrWhiteSpace($Message)) { throw 'Provide -Message with a description of the work.' }
    $handoff = & git status --porcelain -- HANDOFF.md
    if (-not $handoff) { throw 'Update HANDOFF.md with changes, tests and remaining work before finishing.' }
    Run-Git add --all
    Run-Git diff --cached --stat
    Run-Git commit -m $Message
}
Run-Git pull --ff-only origin main
Run-Git push origin main
