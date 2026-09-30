#!/usr/bin/env bash
# 릴스 편집 도구 설치 (macOS)
# yt-dlp, ffmpeg, whisper-cpp, whisper 모델, pycapcut 가상환경
set -euo pipefail

MODEL_NAME="ggml-large-v3-turbo-q5_0.bin"
MODEL_URL="https://huggingface.co/ggerganov/whisper.cpp/resolve/main/${MODEL_NAME}"
MODEL_DIR="$HOME/.cache/whisper"
VENV_DIR="$HOME/.pycapcut"

if [[ "$(uname)" != "Darwin" ]]; then
  echo "이 스크립트는 macOS 전용입니다." >&2
  exit 1
fi

# brew 경로를 현재 셸에 등록 (Apple Silicon: /opt/homebrew, Intel: /usr/local)
load_brew() {
  for p in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [[ -x "$p" ]]; then
      eval "$("$p" shellenv)"
      return 0
    fi
  done
  return 1
}

# 1. Homebrew
if ! command -v brew >/dev/null 2>&1 && ! load_brew; then
  echo "==> Homebrew가 없습니다. 먼저 아래 명령어를 터미널에 붙여넣어 설치하세요 (맥 비밀번호 필요):"
  echo
  echo '  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
  echo
  echo "설치가 끝나면 이 스크립트를 다시 실행하세요."
  exit 1
fi

# 2. brew 패키지
echo "==> yt-dlp, ffmpeg, whisper-cpp 설치"
brew install yt-dlp ffmpeg whisper-cpp

# 3. whisper 모델
echo "==> whisper 모델 다운로드: $MODEL_DIR/$MODEL_NAME"
mkdir -p "$MODEL_DIR"
curl -fL --retry 3 -C - -o "$MODEL_DIR/$MODEL_NAME" "$MODEL_URL"

# 4. pycapcut 가상환경
if ! command -v python3 >/dev/null 2>&1; then
  brew install python
fi
echo "==> $VENV_DIR 가상환경 생성 및 pycapcut 설치"
python3 -m venv "$VENV_DIR"
"$VENV_DIR/bin/pip" install --upgrade pip
"$VENV_DIR/bin/pip" install pycapcut

# 5. 버전 확인
echo
echo "==> 설치된 버전"
echo "brew:        $(brew --version | head -1)"
echo "yt-dlp:      $(yt-dlp --version)"
echo "ffmpeg:      $(ffmpeg -version | head -1)"
echo "whisper-cpp: $(brew list --versions whisper-cpp)"
echo "모델:        $(ls -lh "$MODEL_DIR/$MODEL_NAME" | awk '{print $5, $9}')"
echo "python:      $("$VENV_DIR/bin/python" --version)"
echo "pycapcut:    $("$VENV_DIR/bin/pip" show pycapcut | awk '/^Version:/{print $2}')"
echo
echo "설치 끝!"
