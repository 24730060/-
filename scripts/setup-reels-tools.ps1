# 릴스 편집 도구 설치 (Windows 10/11)
# yt-dlp, ffmpeg, whisper.cpp, whisper 모델, pycapcut 가상환경
# 실행: powershell -ExecutionPolicy Bypass -File scripts\setup-reels-tools.ps1
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"   # Invoke-WebRequest 속도 개선

$ModelName = "ggml-large-v3-turbo-q5_0.bin"
$ModelUrl  = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/$ModelName"
$ModelDir  = Join-Path $HOME ".cache\whisper"
$VenvDir   = Join-Path $HOME ".pycapcut"
$WhisperDir = Join-Path $env:LOCALAPPDATA "whisper-cpp"

function Refresh-Path {
  $env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
              [Environment]::GetEnvironmentVariable("Path", "User")
}

# 1. winget 확인 (Windows 10/11 기본 포함, 없으면 Microsoft Store에서 "앱 설치 관리자" 설치)
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
  Write-Host "winget이 없습니다. Microsoft Store에서 '앱 설치 관리자(App Installer)'를 설치한 뒤 다시 실행하세요." -ForegroundColor Red
  exit 1
}

# 2. yt-dlp, ffmpeg, python (관리자 권한 창이 뜨면 '예'를 누르세요)
Write-Host "==> yt-dlp, ffmpeg, python 설치"
foreach ($id in @("yt-dlp.yt-dlp", "Gyan.FFmpeg", "Python.Python.3.12")) {
  winget install --id $id -e --accept-source-agreements --accept-package-agreements
  # 이미 설치된 경우 winget이 0이 아닌 코드를 돌려주므로 여기서 멈추지 않음
}
Refresh-Path

# 3. whisper.cpp (winget 패키지가 없어 GitHub 릴리스에서 받음)
Write-Host "==> whisper.cpp 설치: $WhisperDir"
$release = Invoke-RestMethod "https://api.github.com/repos/ggml-org/whisper.cpp/releases/latest"
$asset = $release.assets | Where-Object { $_.name -eq "whisper-bin-x64.zip" } | Select-Object -First 1
if (-not $asset) { throw "whisper-bin-x64.zip 을 릴리스 $($release.tag_name) 에서 찾지 못했습니다." }
$zip = Join-Path $env:TEMP $asset.name
Invoke-WebRequest $asset.browser_download_url -OutFile $zip
if (Test-Path $WhisperDir) { Remove-Item $WhisperDir -Recurse -Force }
Expand-Archive $zip -DestinationPath $WhisperDir
Remove-Item $zip
$cli = Get-ChildItem $WhisperDir -Recurse -Filter "whisper-cli.exe" | Select-Object -First 1
$binDir = $cli.DirectoryName
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*$binDir*") {
  [Environment]::SetEnvironmentVariable("Path", "$userPath;$binDir", "User")
}
Refresh-Path

# 4. whisper 모델
Write-Host "==> whisper 모델 다운로드: $ModelDir\$ModelName"
New-Item -ItemType Directory -Force -Path $ModelDir | Out-Null
curl.exe -fL --retry 3 -C - -o (Join-Path $ModelDir $ModelName) $ModelUrl

# 5. pycapcut 가상환경
Write-Host "==> $VenvDir 가상환경 생성 및 pycapcut 설치"
$py = Get-Command py -ErrorAction SilentlyContinue
if ($py) { & $py.Source -3.12 -m venv $VenvDir } else { python -m venv $VenvDir }
& "$VenvDir\Scripts\python.exe" -m pip install --upgrade pip
& "$VenvDir\Scripts\python.exe" -m pip install pycapcut

# 6. 버전 확인
Write-Host ""
Write-Host "==> 설치된 버전"
Write-Host "yt-dlp:      $(yt-dlp --version)"
Write-Host "ffmpeg:      $((ffmpeg -version)[0])"
Write-Host "whisper.cpp: $($release.tag_name) ($($cli.FullName))"
Write-Host "모델:        $([math]::Round((Get-Item (Join-Path $ModelDir $ModelName)).Length / 1MB)) MB"
Write-Host "python:      $(& "$VenvDir\Scripts\python.exe" --version)"
$pcv = (& "$VenvDir\Scripts\python.exe" -m pip show pycapcut | Select-String "^Version:").ToString().Split(" ")[1]
Write-Host "pycapcut:    $pcv"
Write-Host ""
Write-Host "설치 끝!" -ForegroundColor Green
