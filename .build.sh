#!/bin/bash
# Usage: ./.build.sh [--dark|--light] [--watch] [--lualatex] <path/to/file.tex>

MODE="dark"
WATCH=0
ENGINE="pdflatex"
INPUT=""

for arg in "$@"; do
  case $arg in
    --dark)     MODE="dark" ;;
    --light)    MODE="light" ;;
    --watch)    WATCH=1 ;;
    --lualatex) ENGINE="lualatex" ;;
    --invert)
      echo "❌ Option removed: --invert is no longer supported"
      echo "Usage: $0 [--dark|--light] [--watch] [--lualatex] <path/to/file.tex>"
      exit 1
      ;;
    --*)
      echo "❌ Unknown option: $arg"
      echo "Usage: $0 [--dark|--light] [--watch] [--lualatex] <path/to/file.tex>"
      exit 1
      ;;
    *)          INPUT="$arg" ;;
  esac
done

if [ -z "$INPUT" ]; then
    echo "Usage: $0 [--dark|--light] [--watch] [--lualatex] <path/to/file.tex>"
    exit 1
fi

if [ ! -f "$INPUT" ]; then
    echo "❌ File not found: $INPUT"
    exit 1
fi

SRC="$INPUT"
REL="${INPUT#figures/}"
OUT_DIR="out/$(dirname "$REL")"
NAME=$(basename "$REL" .tex)
PROJECT_ROOT="${HOST_PROJECT_ROOT:-$(pwd)}"
PROJECT_ROOT="${PROJECT_ROOT%/}"

mkdir -p "$OUT_DIR"

# HTML theme
if [ "$MODE" = "dark" ]; then
    BG_COLOR="#1e1e2e"
    TEXT_COLOR="#cdd6f4"
else
    BG_COLOR="#f8f8f8"
    TEXT_COLOR="#333333"
fi

do_build() {
    # Compile PDF
    if ! $ENGINE -interaction=nonstopmode -output-directory="$OUT_DIR" "$SRC" > /tmp/build.log 2>&1; then
        echo "❌ $ENGINE failed:"
        tail -20 /tmp/build.log
        return 1
    fi

    # Convert to SVG
    if ! dvisvgm --pdf "$OUT_DIR/$NAME.pdf" -o "$OUT_DIR/$NAME.svg" > /dev/null 2>&1; then
        echo "❌ dvisvgm failed"
        return 1
    fi

    # Clean up intermediate files in out/ and source directory
    rm -f "$OUT_DIR/$NAME.pdf" \
           "$OUT_DIR/$NAME.aux" \
           "$OUT_DIR/$NAME.log" \
           "$OUT_DIR/$NAME.out"
    rm -f "$(dirname "$SRC")/$NAME.aux" \
           "$(dirname "$SRC")/$NAME.log" \
           "$(dirname "$SRC")/$NAME.pdf" \
           "$(dirname "$SRC")/$NAME.fls" \
           "$(dirname "$SRC")/$NAME.fdb_latexmk" \
           "$(dirname "$SRC")/$NAME.synctex.gz"

    echo "✅ $OUT_DIR/$NAME.svg"
    SVG_REL="${OUT_DIR#out/}/$NAME.svg"

    cat > "out/preview.html" << EOF
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>$NAME</title>
  <style>
    body {
      margin: 0;
      background: $BG_COLOR;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      font-family: monospace;
      color: $TEXT_COLOR;
      gap: 0.75rem;
    }
    .label { opacity: 0.5; font-size: 0.75rem; }
    button {
      background: none;
      border: 1px solid currentColor;
      color: $TEXT_COLOR;
      border-radius: 4px;
      padding: 2px 8px;
      font-family: monospace;
      font-size: 0.7rem;
      cursor: pointer;
      opacity: 0.4;
    }
    button:hover { opacity: 0.8; }
    img {
      display: block;
      width: 95vw;
      height: calc(100vh - 5rem);
      max-height: 95vh;
      object-fit: contain;
      outline: 1px solid rgba(128,128,128,0.4);
    }
  </style>
</head>
<body>
  <div style="display:flex; align-items:center; gap:0.5rem;">
    <span class="label">$NAME.svg</span>
    <button onclick="navigator.clipboard.writeText('$PROJECT_ROOT/out/$SVG_REL')">copy path</button>
  </div>
  <img src="$SVG_REL" />
</body>
</html>
EOF
}

# First build
do_build

# Open preview on first build
if [ "${OPEN_PREVIEW:-1}" = "1" ]; then
    code "out/preview.html"
fi

# Watch mode
if [ "$WATCH" -eq 1 ]; then
    if ! command -v inotifywait &> /dev/null; then
        echo "❌ --watch requires inotify-tools: sudo apt install inotify-tools"
        exit 1
    fi
    echo "👁  Watching $INPUT..."
    while inotifywait -q -e close_write "$INPUT"; do
        echo "🔄 $(date +%H:%M:%S) rebuilding..."
        do_build || true
    done
fi
