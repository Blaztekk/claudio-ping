# claude-notif installer - Windows
# Merges audio hooks into ~/.claude/settings.json

$settingsPath = "$env:USERPROFILE\.claude\settings.json"
$snippetPath = "$PSScriptRoot\snippets\windows.json"

# Load or create settings
if (Test-Path $settingsPath) {
    $backup = "$settingsPath.bak-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Copy-Item $settingsPath $backup
    Write-Host "Backup: $backup"
    $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json

    # Retention: keep only the 5 most recent backups
    Get-ChildItem -Path (Split-Path $settingsPath) -Filter "settings.json.bak-*" |
        Sort-Object LastWriteTime -Descending |
        Select-Object -Skip 5 |
        Remove-Item -Force -ErrorAction SilentlyContinue
} else {
    New-Item -ItemType Directory -Force -Path (Split-Path $settingsPath) | Out-Null
    $settings = [PSCustomObject]@{}
}

# Load snippet
$snippet = Get-Content $snippetPath -Raw | ConvertFrom-Json

# Merge hooks
if (-not $settings.PSObject.Properties['hooks']) {
    $settings | Add-Member -NotePropertyName 'hooks' -NotePropertyValue ([PSCustomObject]@{})
}

foreach ($evt in $snippet.hooks.PSObject.Properties.Name) {
    if (-not $settings.hooks.PSObject.Properties[$evt]) {
        $settings.hooks | Add-Member -NotePropertyName $evt -NotePropertyValue $snippet.hooks.$evt
        Write-Host "Added hook: $evt"
    } else {
        Write-Host "Hook '$evt' already exists in settings.json - skipped."
        Write-Host "  To merge or replace, edit manually using: $snippetPath"
    }
}

$json = $settings | ConvertTo-Json -Depth 20
[IO.File]::WriteAllText($settingsPath, $json, (New-Object Text.UTF8Encoding $false))
Write-Host "`nDone. Restart Claude Code to activate."