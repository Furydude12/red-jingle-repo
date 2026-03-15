@@echo off
setlocal disabledelayedexpansion

:: --- CONFIGURATION ---
set "TOOL_3DS=3DS Tool\3dstool.exe"
set "VGM=vgmstream\vgmstream-cli.exe"

echo -------------------------------------------------------
echo 3DS Banner Jingle Extractor (Batch Mode)
echo -------------------------------------------------------

if not exist "%~dp0_sanitize.py" (
    echo [Error] _sanitize.py not found. Place it in the same folder as this script.
    pause
    exit /b 1
)

for %%f in (*.3ds *.cci) do (
    echo [Processing] %%f...

    "%TOOL_3DS%" -xvtf cci "%%f" -0 partition0.cxi >nul 2>&1
    "%TOOL_3DS%" -xvtf cxi partition0.cxi --exefs exefs.bin --exefs-auto-key >nul 2>&1
    "%TOOL_3DS%" -xvtfu exefs exefs.bin --exefs-dir exefs_dir >nul 2>&1

    if exist exefs_dir\banner.bnr (
        copy exefs_dir\banner.bnr banner.bin >nul
        "%TOOL_3DS%" -xvtf banner banner.bin --banner-dir banner_dir >nul 2>&1

        python -c "import struct;d=open('banner_dir/banner.bcwav','rb').read();s=struct.unpack('<I',d[12:16])[0];open('banner_dir/banner.bcwav','wb').write(d[:s])"

        echo %%~nf> _name.txt

        :: Enable delayed expansion only for the section that needs it
        setlocal enabledelayedexpansion
        for /f "delims=" %%s in ('python "%~dp0_sanitize.py"') do set "FINAL=%%s"
        "%VGM%" banner_dir\banner.bcwav -o "!FINAL!" >nul 2>&1
        echo [Success] Saved as: !FINAL!
        endlocal

    ) else (
        echo [Error] No banner found in %%f
    )

    if exist exefs_dir rd /s /q exefs_dir
    if exist banner_dir rd /s /q banner_dir
    if exist partition0.cxi del partition0.cxi
    if exist exefs.bin del exefs.bin
    if exist banner.bin del banner.bin

    echo -------------------------------------------------------
)

if exist _name.txt del _name.txt

echo Extraction Complete!
pauseecho off
