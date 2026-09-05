@echo off
REM ===============================================
REM calibrate.bat – Drop your checkerboard video onto this.
REM Expects CameraCalibrator.py in the same folder.
REM ===============================================

REM Change working dir to script’s folder
cd /d "%~dp0"

REM Check that the .py script is present
if not exist "CameraCalibrator.py" (
    echo ERROR: CameraCalibrator.py not found in "%~dp0"
    echo Make sure the .bat and .py files live together.
    pause
    exit /b 1
)

REM Check you’ve supplied a video file
if "%~1"=="" (
    echo Usage: Drag and drop a checkerboard video onto this script.
    pause
    exit /b 1
)

REM Run the Python calibration
echo Running calibration on: "%~1"
python "%~dp0CameraCalibrator.py" "%~1"
if errorlevel 1 (
    echo.
    echo Calibration FAILED. See messages above.
) else (
    echo.
    echo Calibration SUCCEEDED. Check the generated *_calib.txt.
)

echo.
pause