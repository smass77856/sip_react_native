$ErrorActionPreference = "Stop"

Write-Host "Starting Build Process for OneCX (Windows)..."

# 1. Clean Build
Write-Host "Cleaning previous builds..."
flutter clean

# 2. Get Dependencies
Write-Host "Getting dependencies..."
flutter pub get

# 3. Generate Icons (Attempt)
Write-Host "Generating icons..."
flutter pub run flutter_launcher_icons
if ($LASTEXITCODE -ne 0) {
    Write-Warning "Icon generation failed. Proceeding with default icons."
}

# 4. Build Release
Write-Host "Building Windows Release..."
flutter build windows --release

# 5. Prepare Output Directories
$DistDir = "dist"
$PortableDir = "$DistDir\OneCX_Portable"
$SetupDir = "$DistDir\OneCX_Setup"

if (Test-Path $DistDir) { Remove-Item -Recurse -Force $DistDir }
New-Item -ItemType Directory -Path $PortableDir | Out-Null
New-Item -ItemType Directory -Path $SetupDir | Out-Null

# 6. Create Portable Version
Write-Host "Creating Portable Version..."
$BuildDir = "build\windows\x64\runner\Release"

# Copy all files from Release folder to Portable folder
Copy-Item -Path "$BuildDir\*" -Destination $PortableDir -Recurse

# 7. Create Setup Script (Inno Setup)
Write-Host "Creating Inno Setup Script..."

$IssContent = @"
[Setup]
AppName=OneCX
AppVersion=1.0
DefaultDirName={autopf}\OneCX
DefaultGroupName=OneCX
OutputDir=.
OutputBaseFilename=OneCX_Setup
Compression=lzma
SolidCompression=yes
ArchitecturesInstallIn64BitMode=x64

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "..\OneCX_Portable\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\OneCX"; Filename: "{app}\OneCX.exe"
Name: "{autodesktop}\OneCX"; Filename: "{app}\OneCX.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\OneCX.exe"; Description: "{cm:LaunchProgram,OneCX}"; Flags: nowait postinstall skipifsilent
"@

$IssPath = "$SetupDir\setup_script.iss"
Set-Content -Path $IssPath -Value $IssContent

# 8. Compile Setup EXE (Auto-run)
$IsccPath = "C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
if (Test-Path $IsccPath) {
    Write-Host "Compiling Setup EXE with Inno Setup..."
    & $IsccPath $IssPath
    if ($LASTEXITCODE -eq 0) {
       Write-Host "Setup EXE created successfully!"
       Write-Host "Installer is located in: $SetupDir\OneCX_Setup.exe"
    } else {
       Write-Error "Inno Setup compilation failed."
    }
} else {
    Write-Warning "Inno Setup compiler (ISCC.exe) not found at default location."
    Write-Host "Please compile manually or install Inno Setup to C:\Program Files (x86)\Inno Setup 6"
}

Write-Host "Build Complete!"
Write-Host "Portable version is in: $PortableDir"
Write-Host "Setup files are in: $SetupDir"
