@echo off
REM =====================================================
REM Batch Script to Generate All 20 Numbered Keycaps
REM =====================================================
REM This script uses OpenSCAD command line to generate
REM all 20 numbered keycap STL files automatically
REM =====================================================

echo Starting generation of 20 numbered keycap STL files...
echo.

set OPENSCAD="C:\Program Files\OpenSCAD\openscad.exe"
set SCRIPT=generate_numbered_keycaps.scad

REM Loop through numbers 1-20
for /L %%i in (1,1,20) do (
    echo Generating Body5_num%%i.stl...
    %OPENSCAD% -D number_to_generate=%%i -o Body5_num%%i.stl %SCRIPT%
    if errorlevel 1 (
        echo ERROR: Failed to generate Body5_num%%i.stl
        pause
        exit /b 1
    )
    echo   Completed Body5_num%%i.stl
    echo.
)

echo.
echo =====================================================
echo All 20 numbered keycap STL files generated successfully!
echo Files created: Body5_num1.stl through Body5_num20.stl
echo =====================================================
echo.
pause
