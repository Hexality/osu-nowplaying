# Run this script with powershell. Not Powershell 7 aka pwsh.exe
# This script is used to build the project.

# Install ps2exe

# check if ps2exe is installed
if(!(Get-Module ps2exe -ListAvailable)) {
	Write-Host "ps2exe is not installed. Installing it."
	Install-Module ps2exe -Scope AllUsers
}

# make build folder
mkdir .\build

# Build the projects

# Import ps2exe
Import-Module ps2exe -UseWindowsPowerShell

Invoke-ps2exe .\app.ps1 .\build\osu-np.exe -x64 -icon .\icon.ico -version 2.0.0 -description "osu!NP for osu!lazer" -product "osu!NP" -copyright "Hexality"

Write-Host "Build complete!"	
