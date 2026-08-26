@echo off
setlocal EnableExtensions
chcp 65001 >nul
cd /d "%~dp0"

echo ============================================
echo   GameShelf - Subir proyecto a GitHub
echo ============================================
echo.

where git >nul 2>&1
if errorlevel 1 goto :git_missing

if not exist ".git" (
  git init
  if errorlevel 1 goto :error
)

git add .
git diff --cached --quiet
if errorlevel 1 goto :commit_changes

echo No hay cambios nuevos que confirmar.
goto :after_commit

:commit_changes
git commit -m "GameShelf 1.0 - iPhone app"
if errorlevel 1 goto :error

:after_commit
git branch -M main
if errorlevel 1 goto :error

rem Comprobar directamente si ya existe el remote origin.
git remote get-url origin >nul 2>&1
if errorlevel 1 goto :ask_repo_url

goto :remote_ready

:ask_repo_url
echo.
set "REPO_URL="
set /p "REPO_URL=Introduce la URL HTTPS del repositorio GitHub: "
if not defined REPO_URL goto :missing_url

git remote add origin "%REPO_URL%"
if errorlevel 1 goto :error

:remote_ready
for /f "delims=" %%R in ('git remote get-url origin 2^>nul') do set "CURRENT_REMOTE=%%R"
echo.
echo Repositorio: %CURRENT_REMOTE%
echo Subiendo rama main...
git push -u origin main
if errorlevel 1 goto :error

echo.
echo [OK] Proyecto subido correctamente.
echo GitHub Actions iniciara automaticamente el build del IPA por el push a main.
echo Abre el repositorio ^> Actions ^> Build GameShelf iPhone IPA.
pause
exit /b 0

:missing_url
echo [ERROR] No se ha indicado ninguna URL.
pause
exit /b 1

:git_missing
echo [ERROR] Git no esta instalado o no esta en PATH.
echo Instala Git for Windows y vuelve a ejecutar este archivo.
pause
exit /b 1

:error
echo.
echo [ERROR] La operacion no se completo correctamente.
pause
exit /b 1
