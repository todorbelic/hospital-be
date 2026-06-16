@echo off
setlocal enabledelayedexpansion

:: ============================================================
::  CHM to Markdown Converter (Windows)
::  Requirements: 7-Zip and Pandoc must be installed
::  Usage: chm_to_markdown.bat yourfile.chm
:: ============================================================

:: --- Check argument ---
if "%~1"=="" (
    echo Usage: chm_to_markdown.bat yourfile.chm
    exit /b 1
)

set "CHM=%~1"
set "EXTRACT=%~dp1extracted"
set "OUTPUT=%~dp1output"

:: --- Check CHM file exists ---
if not exist "%CHM%" (
    echo ERROR: File not found: %CHM%
    exit /b 1
)

:: --- Detect 7-Zip ---
set "SEVENZIP="
if exist "C:\Program Files\7-Zip\7z.exe"       set "SEVENZIP=C:\Program Files\7-Zip\7z.exe"
if exist "C:\Program Files (x86)\7-Zip\7z.exe" set "SEVENZIP=C:\Program Files (x86)\7-Zip\7z.exe"
where 7z >nul 2>&1 && set "SEVENZIP=7z"

if "%SEVENZIP%"=="" (
    echo ERROR: 7-Zip not found. Download from https://www.7-zip.org/
    exit /b 1
)

:: --- Detect Pandoc ---
where pandoc >nul 2>&1
if errorlevel 1 (
    echo ERROR: Pandoc not found. Download from https://pandoc.org/installing.html
    exit /b 1
)

echo.
echo ============================================================
echo  CHM to Markdown Converter
echo ============================================================
echo  Input : %CHM%
echo  Output: %OUTPUT%
echo ============================================================
echo.

:: --- Step 1: Extract CHM ---
echo [1/3] Extracting %CHM% ...
if exist "%EXTRACT%" rmdir /s /q "%EXTRACT%"
mkdir "%EXTRACT%"
"%SEVENZIP%" x "%CHM%" -o"%EXTRACT%" -y >nul 2>&1
if errorlevel 1 (
    echo ERROR: Extraction failed. Is the file a valid CHM?
    exit /b 1
)
echo       Done.

:: --- Step 2: Convert HTML to Markdown ---
echo [2/3] Converting HTML to Markdown ...
if exist "%OUTPUT%" rmdir /s /q "%OUTPUT%"
mkdir "%OUTPUT%"

set "COUNT=0"
set "ERRORS=0"

for /r "%EXTRACT%" %%F in (*.html *.htm) do (
    :: Get path relative to EXTRACT folder
    set "FULLPATH=%%F"
    set "RELPATH=!FULLPATH:%EXTRACT%\=!"

    :: Get directory and base name
    set "RELDIR=%%~dpF"
    set "RELDIR=!RELDIR:%EXTRACT%\=!"
    set "RELDIR=!RELDIR:~0,-1!"
    set "BASENAME=%%~nF"

    :: Create output subdirectory
    if not "!RELDIR!"=="" (
        if not exist "%OUTPUT%\!RELDIR!" mkdir "%OUTPUT%\!RELDIR!"
        set "OUTFILE=%OUTPUT%\!RELDIR!\!BASENAME!.md"
        set "IMGDIR=%OUTPUT%\!RELDIR!\images"
    ) else (
        set "OUTFILE=%OUTPUT%\!BASENAME!.md"
        set "IMGDIR=%OUTPUT%\images"
    )

    :: Run Pandoc
    pandoc "%%F" --from html --to markdown --extract-media="!IMGDIR!" -o "!OUTFILE!" 2>nul
    if errorlevel 1 (
        set /a ERRORS+=1
    ) else (
        set /a COUNT+=1
    )
)

echo       Converted: %COUNT% files  ^|  Errors: %ERRORS%

:: --- Step 3: Fix internal .html links -> .md ---
echo [3/3] Rewriting internal links ^(.html ^-^> .md^) ...
for /r "%OUTPUT%" %%F in (*.md) do (
    powershell -NoProfile -Command ^
        "(Get-Content '%%F' -Raw) -replace '\.html\)', '.md)' | Set-Content '%%F' -NoNewline"
)
echo       Done.

echo.
echo ============================================================
echo  Conversion complete!
echo  Markdown files : %OUTPUT%\
echo  Images folder  : %OUTPUT%\images\  (and subfolders)
echo ============================================================
echo.

:: --- Open output folder ---
set /p OPEN="Open output folder? (Y/N): "
if /i "%OPEN%"=="Y" explorer "%OUTPUT%"

endlocal
