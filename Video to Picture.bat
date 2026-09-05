@echo off
REM -----------------------------------
REM Check if file was dragged or dropped
REM -----------------------------------
if "%~1"=="" (
    echo Please drag and drop a video file onto this batch file.
    pause
    exit /b
)

REM -----------------------------------
REM Basic setup
REM -----------------------------------
set "INPUT=%~1"
set "videoName=%~n1"
set "outputDir=%~dp1%videoName%"

REM Overwrite existing folder if it exists
if exist "%outputDir%" (
    rmdir /s /q "%outputDir%"
)

mkdir "%outputDir%"

echo Input file: "%INPUT%"
echo Output directory: "%outputDir%"

REM -----------------------------------
REM Use ffprobe console output, then parse "Duration: HH:MM:SS.xx"
REM -----------------------------------
set "durationFull="
for /f "delims=" %%L in ('ffprobe -i "%INPUT%" 2^>^&1 ^| findstr /i "Duration:"') do (
    set "durationFull=%%L"
)

REM If we did not find any line containing "Duration:", error out
if "%durationFull%"=="" (
    echo Error: Unable to retrieve duration from ffprobe output.
    pause
    exit /b
)

echo Raw line with duration: %durationFull%

REM -----------------------------------
REM 1) Remove everything up through "Duration: "
REM    This leaves something like "00:01:23.45, start..."
REM -----------------------------------
setlocal enabledelayedexpansion

REM Make sure we handle possible leading spaces
set "cleanLine=%durationFull%"
set "cleanLine=!cleanLine:*Duration: =!"

echo After removing "Duration: ": !cleanLine!

REM -----------------------------------
REM 2) Split at the comma so we just get "00:01:23.45" part
REM -----------------------------------
for /f "tokens=1 delims=," %%A in ("!cleanLine!") do (
    set "timeVal=%%A"
)

echo Extracted time string: !timeVal!

REM -----------------------------------
REM 3) Split that time string by : and . to get hh, mm, and ss
REM    e.g.: "00:01:23.45" -> hh=00, mm=01, ss=23 (the .45 fraction is ignored)
REM -----------------------------------
set "hh=0"
set "mm=0"
set "sx=0"

for /f "tokens=1,2,3 delims=:." %%a in ("!timeVal!") do (
    set "hh=%%a"
    set "mm=%%b"
    set "sx=%%c"
)

REM -----------------------------------
REM 4) Convert to total seconds (integer only)
REM -----------------------------------
set /a totalSec=(1 * hh * 3600) + (1 * mm * 60) + (1 * sx)

endlocal & set /a duration=%totalSec%
echo Computed duration (whole seconds): %duration%

REM -----------------------------------
REM If totalSec is zero, something likely went wrong
REM -----------------------------------
if %duration%==0 (
    echo Error: Computed zero duration. Check if your file is valid or very short.
    pause
    exit /b
)

REM -----------------------------------
REM Prompt for total number of frames
REM -----------------------------------
set /p "totalFrames=Enter the total number of frames you want: "

if "%totalFrames%"=="" (
    echo You must enter a value for total frames.
    pause
    exit /b
)

REM Ensure user entered numeric
for /f "delims=0123456789" %%x in ("%totalFrames%") do (
    echo Invalid input. Please enter a valid number.
    pause
    exit /b
)

REM -----------------------------------
REM Calculate frame extraction interval
REM duration is in seconds; convert to milliseconds
REM -----------------------------------
set /a durationMs=%duration%*1000
set /a interval=%durationMs%/%totalFrames%

echo Extracting 1 frame per %interval% milliseconds...

REM -----------------------------------
REM Now run ffmpeg to extract frames
REM -----------------------------------
ffmpeg -i "%INPUT%" -vf "fps=fps=1000/%interval%" -vsync vfr "%outputDir%\%videoName%_%%04d.png"

echo Frame extraction completed! Frames are saved to: %outputDir%
pause