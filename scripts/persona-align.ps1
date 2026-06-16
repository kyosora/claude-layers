# Auto-align ~/.claude/CLAUDE.md to the persona for the current directory (Windows).
# The de-personalized PowerShell mirror of persona-align.sh. Opt-in: call it from
# your PowerShell profile, or prefer the cross-platform SessionStart hook.
#
# Selection precedence (first match wins; no match = no-op):
#   1. .\.claude\persona           a file containing a mode name (per-project)
#   2. cwd inside <marker>\<persona>\   marker defaults to "ws"
#                                       (override: $env:CLAUDE_LAYERS_WS_MARKER)
#   3. no-op                       leaves CLAUDE.md untouched
#
# Mirrors deploy.sh's safety: backs up the current CLAUDE.md and only copies when
# the target differs (silent no-op when already aligned). Never copies on a
# speculative default — only on an explicit selection signal.

$ErrorActionPreference = 'Stop'

$claudeDir = Join-Path $env:USERPROFILE '.claude'
$target    = Join-Path $claudeDir 'CLAUDE.md'

# Resolve PERSONAS_DIR the same way the /switch skill does.
$configFile = Join-Path $claudeDir 'persona-config'
if (Test-Path $configFile) {
    $personasDir = (Get-Content $configFile -Raw).Trim()
} else {
    $personasDir = Join-Path $claudeDir 'personas'
}

$mode = $null
# (1) per-project selection file
$selFile = Join-Path (Get-Location) '.claude\persona'
if (Test-Path $selFile) { $mode = (Get-Content $selFile -Raw).Trim() }
# (2) cwd marker dir
if (-not $mode) {
    $marker = if ($env:CLAUDE_LAYERS_WS_MARKER) { $env:CLAUDE_LAYERS_WS_MARKER } else { 'ws' }
    if ((Get-Location).Path -match "[\\/]$marker[\\/]([^\\/]+)") { $mode = $Matches[1] }
}
# (3) no explicit selection -> do nothing
if (-not $mode) { return }

$compiled = Join-Path $personasDir "compiled\$mode.md"
if (-not (Test-Path $compiled)) {
    Write-Host "persona-align: no compiled persona '$mode' in $personasDir\compiled\ (skipped)"
    return
}

# Silent no-op when already aligned; otherwise back up the current CLAUDE.md.
if (Test-Path $target) {
    if ((Get-FileHash $compiled).Hash -eq (Get-FileHash $target).Hash) { return }
    $backupDir = Join-Path $claudeDir '.claude-layers'
    if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir | Out-Null }
    Copy-Item $target (Join-Path $backupDir 'CLAUDE.md.bak') -Force
}
if (-not (Test-Path $claudeDir)) { New-Item -ItemType Directory -Path $claudeDir | Out-Null }
Copy-Item $compiled $target -Force
Write-Host "Aligned CLAUDE.md -> $mode"
