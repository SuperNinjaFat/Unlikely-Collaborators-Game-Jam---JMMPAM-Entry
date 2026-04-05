# Deletes the Caterpillar Climb save file to reset game state.
# Usage: .\clear-save.ps1 [-SaveFile <path>]
param(
    [string]$SaveFile = "$env:APPDATA\Godot\app_userdata\Caterpillar Climb\global_state.tres"
)

if (Test-Path $SaveFile) {
    Remove-Item $SaveFile
    Write-Host "Deleted save file: $SaveFile"
} else {
    Write-Host "No save file found at: $SaveFile"
}
