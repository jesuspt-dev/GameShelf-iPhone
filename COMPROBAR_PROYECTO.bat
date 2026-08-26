@echo off
setlocal EnableExtensions
chcp 65001 >nul
cd /d "%~dp0"

echo ============================================
echo   GameShelf - Comprobacion local
echo ============================================
echo.

set FAIL=0

for %%F in (
  "GameShelf\GameShelfApp.swift"
  "GameShelf\Models.swift"
  "GameShelf\Services.swift"
  "GameShelf\RootView.swift"
  "GameShelf\Info.plist"
  "GameShelf.xcodeproj\project.pbxproj"
  ".github\workflows\build-ipa.yml"
) do (
  if not exist %%F (
    echo [FALTA] %%F
    set FAIL=1
  ) else (
    echo [OK] %%F
  )
)

if "%FAIL%"=="1" (
  echo.
  echo [ERROR] Faltan archivos esenciales.
  pause
  exit /b 1
)

echo.
echo [OK] Estructura esencial presente.
echo La compilacion iOS real se valida en GitHub Actions con Xcode 26.
pause
