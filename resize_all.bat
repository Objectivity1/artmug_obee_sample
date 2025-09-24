@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul
pushd "%~dp0"

rem ===== 설정 =====
set "TARGET_H=450"
rem =================

rem ffmpeg/ffprobe 확인
where ffmpeg  >nul 2>&1 || (echo [에러] ffmpeg 없음.&goto :finish)
where ffprobe >nul 2>&1 || (echo [에러] ffprobe 없음.&goto :finish)

call :scan_dir "A-1images" whitebg
call :scan_dir "A-2images" whitebg
call :scan_dir "Bimages"   resize

:finish
echo.
echo === 완료 ===
echo.
pause
popd
goto :eof


:scan_dir
rem %1=폴더, %2=mode(whitebg|resize)
if not exist "%~1\*.gif" (
  echo [알림] %~1 폴더가 없거나 GIF가 없음. 스킵.
  goto :eof
)
echo [%~1] 처리 중...
for %%F in ("%~1\*.gif") do (
  call :process "%~2" "%%~fF"
)
goto :eof


:process
rem %1=mode  %2=gif fullpath
set "MODE=%~1"
set "IN=%~2"
set "TMP=%~dpn2.tmp.gif"

rem 현재 세로 높이 얻기
for /f "usebackq delims=" %%H in (`ffprobe -v error -select_streams v:0 -show_entries stream^=height -of csv^=p^=0 "%IN%"`) do set "H=%%H"

if not defined H (
  echo    - %~nx2 : 높이 판독 실패 → 스킵
  goto :eof
)

if "!H!"=="%TARGET_H%" (
  echo    - %~nx2 : 이미 %TARGET_H%px → 스킵
  goto :eof
)

echo    - %~nx2 : !H! -> %TARGET_H% 처리 중...

attrib -r "%IN%" >nul 2>&1
if /i "%MODE%"=="whitebg" (
  call :whitebg "%IN%" "%TMP%"
) else (
  call :resize_only "%IN%" "%TMP%"
)

if exist "%TMP%" (
  move /y "%TMP%" "%IN%" >nul
) else (
  echo      -> [에러] 임시 파일 생성 실패: "%TMP%"
)
goto :eof


rem ── B타입용: 리사이즈만 ──
:resize_only
ffmpeg -hide_banner -loglevel error -y -i "%~1" ^
  -filter_complex "[0:v]scale=-1:%TARGET_H%:flags=lanczos,split[s0][s1];[s0]palettegen=stats_mode=single[p];[s1][p]paletteuse=new=1" ^
  -loop 0 "%~2"
goto :eof

rem ── A-1/A-2용: 리사이즈 후 빈/투명 부분 흰색 채움 ──
:whitebg
ffmpeg -hide_banner -loglevel error -y -i "%~1" ^
  -filter_complex "[0:v]scale=-1:%TARGET_H%:flags=lanczos[fg];color=white:s=16x16[bg];[bg][fg]scale2ref[bg][fg2];[bg][fg2]overlay=shortest=1:format=auto,split[s0][s1];[s0]palettegen=stats_mode=single[p];[s1][p]paletteuse=new=1" ^
  -loop 0 "%~2"
goto :eof
