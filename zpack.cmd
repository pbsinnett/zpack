@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Zoom WAV Processor

:: -----------------------------
:: CONFIG
:: -----------------------------
set "CONCAT_LIST=concat_list.txt"
set "TS_LIST=timestamp_list.txt"
set "OUTDIR=Converted"

:: -----------------------------
:: TOOL CHECKS
:: -----------------------------
(where ffmpeg >nul 2>&1 && where wavpack >nul 2>&1 && where wvgain >nul 2>&1) || (
    echo Missing required tools ^(FFmpeg, WavPack, or wvgain^).
    pause & exit /b
)

:: -----------------------------
:: DISCOVERY & PREP
:: -----------------------------
set "ZOOMDRIVE="
for %%D in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
    if exist %%D:\ZOOM_*.SYS set "ZOOMDRIVE=%%D" & goto :FOUND_DRIVE
)
:FOUND_DRIVE
if defined ZOOMDRIVE (echo Zoom detected: %ZOOMDRIVE%:) else (echo Local mode.)

del files.txt processed.log Results.log "%TS_LIST%" 2>nul
if not exist "%OUTDIR%" md "%OUTDIR%"

<nul set /p prompt=Scanning...
if defined ZOOMDRIVE if exist "%ZOOMDRIVE%:\" (
    dir /s /b "%ZOOMDRIVE%:\*.wav" 2>nul | findstr /i /v "\\TRASH\\" >> files.txt
)
dir /b /s "*.wav" 2>nul | findstr /v /c:"%OUTDIR%" >> files.txt

echo.
if not exist files.txt (echo No files found. & pause & exit /b)
for /f %%A in ('find /c /v "" ^< files.txt') do set TOTAL=%%A
echo Found %TOTAL% WAV files.

:: -----------------------------
:: MAIN LOOP
:: -----------------------------
set COUNT=0
for /f "usebackq delims=" %%F in ("files.txt") do (
    set /a COUNT+=1
    call :ANALYZE "%%F"
)

:: -----------------------------
:: USER REVIEW
:: -----------------------------
title Zoom WAV Processor - Done
echo.
echo Done.

:: 1. Ask about deletion (Waits indefinitely)
set "DEL_ORIG=N"
choice /m "Delete processed originals?"
if errorlevel 1 if not errorlevel 2 set "DEL_ORIG=Y"

:: 2. Final Review Pause (Window stays static here)
echo.
echo Ready to sync timestamps and cleanup.
<nul set /p prompt=Press a key to exit...
pause >nul

:: -----------------------------
:: CLEANUP & EXIT (Runs after you close)
:: -----------------------------

:: 3. Timestamp Sync (Must run BEFORE deletion)
if exist "%TS_LIST%" (
    echo.
    echo Syncing timestamps...
    powershell -NoProfile -WindowStyle Hidden -Command "$c=Get-Content '%TS_LIST%'; foreach($L in $c){ $p=$L -split '\|'; if(Test-Path $p[1]){ try{ $s=Get-Item $p[0]; $d=Get-Item $p[1]; $d.LastWriteTime=$s.LastWriteTime; $d.CreationTime=$s.CreationTime }catch{} } }"
)

:: 4. Delete Originals (If requested)
if "%DEL_ORIG%"=="Y" (
    echo Deleting originals...
    if exist processed.log for /f "usebackq delims=" %%K in ("processed.log") do (
        set "TGT=%%~K"
        if defined ZOOMDRIVE echo "%%~K" | find /i "%ZOOMDRIVE%:" >nul && (
             if /i not "%%~dpK"=="%ZOOMDRIVE%:\" (if exist "%%~dpK" rd /s /q "%%~dpK" 2>nul) else (del /q "%%~K")
        ) || (del /q "%%~K")
    )
    if defined ZOOMDRIVE if exist "%ZOOMDRIVE%:\TRASH\" rd /s /q "%ZOOMDRIVE%:\TRASH" & md "%ZOOMDRIVE%:\TRASH"
)

del files.txt processed.log Results.log "%TS_LIST%" 2>nul
exit /b

:: ==================================================
:: LOGIC CORE
:: ==================================================
:ANALYZE
set "FULL=%~1" & set "NAME=%~nx1" & set "DIR=%~dp1" & set "BASE=%~n1" & set "EXT=%~x1"

:: Skip logic
if exist processed.log findstr /x /c:"%FULL%" processed.log >nul 2>&1 && exit /b
echo "%NAME%" | findstr /r "_[0-9][0-9][0-9][^0-9]" >nul && exit /b

:: --- CALCULATE PERCENTAGE ---
set /a "PCT=(COUNT*100)/TOTAL"
title [%PCT%%%] Processing %COUNT%/%TOTAL% - %NAME%
echo [%PCT%%%] %NAME%

:: --- ROBUST FOLDER PATHING ---
:: Strip trailing slash from DIR
set "TRIM_DIR=%DIR:~0,-1%"

set "G_PRE=%BASE%"
set "G_SUF=%EXT%"
set "IS_GROUP="

:: Check 1: Standard Append (_001.wav)
if exist "%DIR%%BASE%_001%EXT%" set "IS_GROUP=1" & goto :EXECUTE
if exist "%TRIM_DIR%_001\%BASE%_001%EXT%" set "IS_GROUP=1" & goto :EXECUTE

:: Check 2: Generic Suffix (_001_TAG.wav)
set "STRIPPED=%BASE:_= %"
for %%W in (%STRIPPED%) do set "TOKEN=%%W"
if "%TOKEN%"=="%BASE%" goto :EXECUTE
echo %TOKEN%| findstr /r "^[a-zA-Z]*$" >nul || goto :EXECUTE

call set "GUESS_PRE=%%BASE:_%TOKEN%=%%"
set "TEST_FILE=%GUESS_PRE%_001_%TOKEN%%EXT%"

if exist "%DIR%%TEST_FILE%" set "G_PRE=%GUESS_PRE%" & set "G_SUF=_%TOKEN%%EXT%" & set "IS_GROUP=1" & goto :EXECUTE
if exist "%TRIM_DIR%_001\%TEST_FILE%" (
    set "G_PRE=%GUESS_PRE%"
    set "G_SUF=_%TOKEN%%EXT%"
    set "IS_GROUP=1"
    goto :EXECUTE
)

:EXECUTE
if defined IS_GROUP (call :PROCESS_GROUP) else (call :PROCESS_SINGLE)
exit /b

:: ==================================================
:: PROCESSING ROUTINES
:: ==================================================
:PROCESS_SINGLE
set "OUTNAME=%NAME:.WAV=.wv%"
set "OUTNAME=%OUTNAME:.wav=.wv%"
<nul set /p prompt=Compressing to %OUTNAME%...
wavpack -q -hh -m -v -x3 -i --no-overwrite "%FULL%" "%OUTDIR%\%OUTNAME%"
echo.
if not errorlevel 1 (
    <nul set /p prompt=Normalizing %OUTNAME%...
    wvgain -n -q "%OUTDIR%\%OUTNAME%"
    echo.
    echo %FULL%^|%OUTDIR%\%OUTNAME%>> "%TS_LIST%"
    echo "%FULL%">> processed.log
)
exit /b

:PROCESS_GROUP
if exist "%CONCAT_LIST%" del "%CONCAT_LIST%"
set "FINAL_NAME=%G_PRE%%G_SUF%"
set "FINAL_NAME=%FINAL_NAME:.WAV=.wv%"
set "FINAL_NAME=%FINAL_NAME:.wav=.wv%"

:: Build List
set "IDX=0"
:LOOP_BUILD
set /a IDX+=1
set NUM=00%IDX%
set "PART_NAME=%G_PRE%_%NUM:~-3%%G_SUF%"
set "FOUND="

if exist "%DIR%%PART_NAME%" set "FOUND=%DIR%%PART_NAME%"
if not defined FOUND (
    if exist "%TRIM_DIR%_%NUM:~-3%\%PART_NAME%" (
        set "FOUND=%TRIM_DIR%_%NUM:~-3%\%PART_NAME%"
    )
)

if defined FOUND (
    set "SAFE=%FOUND:\=/%"
    if %IDX%==1 (echo file '%FULL:\=/%'>> "%CONCAT_LIST%" & echo "%FULL%">> processed.log)
    echo file '!SAFE!'>> "%CONCAT_LIST%"
    echo "%FOUND%">> processed.log
    goto :LOOP_BUILD
)

<nul set /p prompt=   - Joining %IDX% parts to %FINAL_NAME%...
ffmpeg -v error -f concat -safe 0 -i "%CONCAT_LIST%" -c copy -f wav - | wavpack -q -hh -m -v -x3 -i --no-overwrite - -o "%OUTDIR%\%FINAL_NAME%"
echo.

if not errorlevel 1 (
    <nul set /p prompt=Normalizing %FINAL_NAME%...
    wvgain -n -q "%OUTDIR%\%FINAL_NAME%"
    echo.
    echo %FULL%^|%OUTDIR%\%FINAL_NAME%>> "%TS_LIST%"
)
del "%CONCAT_LIST%" 2>nul
exit /b