#!/bin/bash
# Usage: ./.build.sh [--dark|--light] [--invert] [--watch] [--lualatex] <path/to/file.tex>

MODE="dark"
INVERT=0
WATCH=0
ENGINE="pdflatex"
INPUT=""

for arg in "$@"; do
  case $arg in
    --dark)     MODE="dark" ;;
    --light)    MODE="light" ;;
    --invert)   INVERT=1 ;;
    --watch)    WATCH=1 ;;
    --lualatex) ENGINE="lualatex" ;;
    *)          INPUT="$arg" ;;
  esac
done

if [ -z "$INPUT" ]; then
    echo "Usage: $0 [--dark|--light] [--invert] [--watch] [--lualatex] <path/to/file.tex>"
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

    # Generate inverted SVG and remove the original
    if [ "$INVERT" -eq 1 ]; then
        python3 -c "
import re
content = open('$OUT_DIR/$NAME.svg').read()
style = '<style>svg{filter:invert(1) hue-rotate(180deg)}</style>'
result = re.sub(r'(<svg[^>]*>)', r'\1' + style, content, count=1)
open('$OUT_DIR/${NAME}-invert.svg', 'w').write(result)
"
        rm -f "$OUT_DIR/$NAME.svg"
        echo "✅ $OUT_DIR/${NAME}-invert.svg"
        SVG_REL="${OUT_DIR#out/}/${NAME}-invert.svg"
    else
        echo "✅ $OUT_DIR/$NAME.svg"
        SVG_REL="${OUT_DIR#out/}/$NAME.svg"
    fi

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
      gap: 2rem;
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
    img { display: block; max-width: 90vw; max-height: 80vh; outline: 1px solid rgba(128,128,128,0.4); }
  </style>
</head>
<body>
  <div style="display:flex; align-items:center; gap:0.5rem;">
    <span class="label">$NAME.svg</span>
    <button onclick="navigator.clipboard.writeText('$(pwd)/out/$SVG_REL')">copy path</button>
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
