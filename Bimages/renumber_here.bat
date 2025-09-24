@if (@CodeSection == @Batch) @then
@echo off
REM 이 배치가 있는 폴더를 작업 폴더로
cd /d "%~dp0"
REM 내장 JScript 실행 (PowerShell 불필요)
cscript //nologo //E:JScript "%~f0"
echo.
pause
goto :eof
@end

// ===== JScript 영역 (여기 아래는 건드릴 필요 없음) =====
var fso = new ActiveXObject("Scripting.FileSystemObject");
var folder = fso.GetFolder(".");
var files = new Enumerator(folder.Files);

// 허용 확장자(소문자)
var allow = {".gif":1,".png":1,".jpg":1,".jpeg":1,".webp":1};

var arr = [];
for (; !files.atEnd(); files.moveNext()){
  var file = files.item();
  var name = fso.GetBaseName(file.Name);
  var ext = "." + fso.GetExtensionName(file.Name).toLowerCase();

  if (!allow[ext]) continue; // 이미지만
  // "숫자" 또는 "숫자-숫자" (앞자리 0 허용)
  var m = name.match(/^0*(\d+)(?:-(\d+))?$/);
  if (!m) continue;

  arr.push({
    path: file.Path,
    ext: ext,
    main: parseInt(m[1],10),
    sub: (m[2] !== undefined ? parseInt(m[2],10) : null)
  });
}

// 정렬: 본번호 → (본번호만 먼저) → -1 → -2 …
arr.sort(function(a,b){
  if (a.main !== b.main) return a.main - b.main;
  if (a.sub === null && b.sub !== null) return -1;
  if (a.sub !== null && b.sub === null) return 1;
  if (a.sub === null && b.sub === null) return 0;
  return a.sub - b.sub;
});

if (arr.length === 0){
  WScript.Echo("변경할 파일 없음.");
  WScript.Quit(0);
}

// 충돌 방지: 1차 임시이름 → 2차 최종이름
for (var i=0;i<arr.length;i++){
  var tmp = arr[i].path + ".tmp_ren";
  fso.MoveFile(arr[i].path, tmp);
  arr[i].tmp = tmp;
}

var n = 1;
for (var j=0;j<arr.length;j++){
  var target = fso.BuildPath(folder.Path, String(n) + arr[j].ext);
  // 중복 생겨도 앞 단계에서 전부 tmp로 빠졌으니 안전
  fso.MoveFile(arr[j].tmp, target);
  n++;
}

WScript.Echo("완료: " + arr.length + "개 파일 리네임.");
