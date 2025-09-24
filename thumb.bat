@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul
pushd "%~dp0"

REM ===== 설정 =====
set "THUMB_H=250"        REM 썸네일 세로 크기(px)
REM =================

where ffmpeg >nul 2>&1 || (echo [에러] ffmpeg를 찾을 수 없음.&goto :finish)

for %%D in ("A-1images" "A-2images" "Bimages") do (
  if exist "%%~D\*.gif" (
    echo [%%~D] 썸네일 생성 중...
    for %%F in ("%%~D\*.gif") do (
      call :thumb "%%~fF"
    )
  ) else (
    echo [알림] %%~D 폴더가 없거나 GIF가 없음 → 스킵
  )
)

:finish
echo.
echo === 작업 종료 ===
echo.
pause
popd
goto :eof


:thumb
REM %1 = 원본 GIF 경로
set "SRC=%~1"
set "SRCDIR=%~dp1"
set "TDIR=!SRCDIR:images\=thumbs\!"
set "TPNG=%TDIR%%~n1.png"

if not exist "%TDIR%" mkdir "%TDIR%" >nul 2>&1

REM 항상 새로 덮어쓰기 (-y 옵션)
ffmpeg -hide_banner -loglevel error -y -i "%SRC%" ^
  -frames:v 1 -update 1 ^
  -filter_complex "[0:v]scale=-1:%THUMB_H%:flags=lanczos[fg];color=white:s=16x16[bg];[bg][fg]scale2ref[bg][fg2];[bg][fg2]overlay=shortest=1:format=auto,format=rgb24" ^
  "%TPNG%"

if exist "%TPNG%" (
  echo    - %~nx1 → 갱신됨
) else (
  echo    - %~nx1 → [에러] 생성 실패
)
goto :eof
