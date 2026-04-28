Write-Host "Attempting to fix icon generation..."

# 1. Force clean
Remove-Item -Recurse -Force .dart_tool -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force build -ErrorAction SilentlyContinue

# 2. Pub get
flutter pub get

# 3. Run launcher icons
flutter pub run flutter_launcher_icons

if ($LASTEXITCODE -eq 0) {
    Write-Host "Icon generation SUCCESS!"
} else {
    Write-Host "Icon generation FAILED!"
}
