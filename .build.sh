#!/bin/bash
# Usage: ./.build.sh [--watch] [--lualatex] <path/to/file.tex>

WATCH=0
ENGINE="pdflatex"
INPUT=""

for arg in "$@"; do
  case $arg in
    --watch)    WATCH=1 ;;
    --lualatex) ENGINE="lualatex" ;;
    --invert)
      echo "❌ Option removed: --invert is no longer supported"
      echo "Usage: $0 [--watch] [--lualatex] <path/to/file.tex>"
      exit 1
      ;;
    --*)
      echo "❌ Unknown option: $arg"
      echo "Usage: $0 [--watch] [--lualatex] <path/to/file.tex>"
      exit 1
      ;;
    *)          INPUT="$arg" ;;
  esac
done

if [ -z "$INPUT" ]; then
    echo "Usage: $0 [--watch] [--lualatex] <path/to/file.tex>"
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
BASE_NAME="${NAME%-light}"
BASE_NAME="${BASE_NAME%-dark}"
PROJECT_ROOT="${HOST_PROJECT_ROOT:-$(pwd)}"
PROJECT_ROOT="${PROJECT_ROOT%/}"
DARK_OUT_NAME="$BASE_NAME"
LIGHT_OUT_NAME="$BASE_NAME-light"

mkdir -p "$OUT_DIR"

cleanup_build_artifacts() {
    local out_name="$1"

    rm -f "$OUT_DIR/$out_name.pdf" \
           "$OUT_DIR/$out_name.aux" \
           "$OUT_DIR/$out_name.log" \
           "$OUT_DIR/$out_name.out"
}

build_variant() {
    local variant="$1"
    local out_name="$2"
    local tmp_src
    local toggle
    local engine_status=0

    tmp_src="/tmp/${out_name}.tex"

    if [ "$variant" = "dark" ]; then
        toggle='\darkbgtrue'
    else
        toggle='\darkbgfalse'
    fi

    if ! awk -v toggle="$toggle" '
        /^[ \t]*\\darkbg(true|false)[ \t]*$/ { print toggle; next }
        { print }
    ' "$SRC" > "$tmp_src"; then
        echo "❌ Failed to prepare $variant variant"
        rm -f "$tmp_src"
        return 1
    fi

    if ! $ENGINE -interaction=nonstopmode -output-directory="$OUT_DIR" "$tmp_src" > /tmp/build.log 2>&1; then
        engine_status=$?
    fi

    rm -f "$tmp_src"

    if [ "$engine_status" -ne 0 ] && [ ! -f "$OUT_DIR/$out_name.pdf" ]; then
        echo "❌ $ENGINE failed for $variant variant:"
        tail -20 /tmp/build.log
        cleanup_build_artifacts "$out_name"
        return 1
    fi

    if [ "$engine_status" -ne 0 ]; then
        echo "⚠️  $ENGINE reported issues for $variant variant, continuing with generated PDF"
        tail -10 /tmp/build.log
    fi

    # Convert to SVG
    if ! dvisvgm --pdf "$OUT_DIR/$out_name.pdf" -o "$OUT_DIR/$out_name.svg" > /dev/null 2>&1; then
        echo "❌ dvisvgm failed for $variant variant"
        cleanup_build_artifacts "$out_name"
        return 1
    fi

    # Normalize root <svg> dimensions for responsive <img> usage (viewBox-only sizing)
    if ! perl -0777 -i -pe "s{(<svg\b[^>]*?)\s+width=(['\"]).*?\2([^>]*?>)}{\$1\$3}s; s{(<svg\b[^>]*?)\s+height=(['\"]).*?\2([^>]*?>)}{\$1\$3}s" "$OUT_DIR/$out_name.svg"; then
      echo "❌ Failed to normalize SVG root dimensions"
      cleanup_build_artifacts "$out_name"
      return 1
    fi

    cleanup_build_artifacts "$out_name"

    echo "✅ $OUT_DIR/$out_name.svg"
}

write_preview() {
    local dark_svg_rel="${OUT_DIR#out/}/$DARK_OUT_NAME.svg"
    local light_svg_rel="${OUT_DIR#out/}/$LIGHT_OUT_NAME.svg"
    local dark_svg_abs="$PROJECT_ROOT/out/$dark_svg_rel"
    local light_svg_abs="$PROJECT_ROOT/out/$light_svg_rel"
    local copy_cmd="cp &quot;$dark_svg_abs&quot; &quot;$light_svg_abs&quot; ./"

    cat > "out/preview.html" << EOF
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>$BASE_NAME</title>
  <style>
    :root {
      --page-bg: #1e1e2e;
      --page-text: #cdd6f4;
      --card-border: rgba(128, 128, 128, 0.32);
      --card-shadow: 0 18px 50px rgba(0, 0, 0, 0.18);
      --dark-bg: #1e1e2e;
      --dark-text: #cdd6f4;
      --light-bg: #ffffff;
      --light-text: #222222;
      --button-bg: rgba(255, 255, 255, 0.08);
      --button-border: rgba(255, 255, 255, 0.18);
      --button-light-bg: rgba(0, 0, 0, 0.04);
      --button-light-border: rgba(0, 0, 0, 0.12);
    }
    body {
      margin: 0;
      min-height: 100vh;
      background: var(--page-bg);
      color: var(--page-text);
      font-family: monospace;
      padding: 24px;
      box-sizing: border-box;
    }
    .page {
      width: min(1400px, 100%);
      margin: 0 auto;
      display: grid;
      gap: 20px;
    }
    .page-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 16px;
    }
    .page-actions {
      display: flex;
      align-items: center;
      gap: 10px;
      flex-wrap: wrap;
    }
    .title {
      opacity: 0.75;
      font-size: 0.85rem;
      letter-spacing: 0.08em;
      text-transform: uppercase;
    }
    .cards {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(320px, 1fr));
      gap: 20px;
      align-items: start;
    }
    .card {
      border-radius: 4px;
      border: 1px solid var(--card-border);
      box-shadow: var(--card-shadow);
      overflow: hidden;
    }
    .card.dark {
      background: var(--dark-bg);
      color: var(--dark-text);
    }
    .card.light {
      background: var(--light-bg);
      color: var(--light-text);
    }
    .card-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 12px;
      padding: 14px 16px;
      border-bottom: 1px solid var(--card-border);
    }
    .meta {
      display: grid;
      gap: 4px;
    }
    .variant {
      font-size: 0.72rem;
      opacity: 0.65;
      text-transform: uppercase;
      letter-spacing: 0.08em;
    }
    .label {
      opacity: 0.9;
      font-size: 0.8rem;
      word-break: break-all;
    }
    button {
      border-radius: 999px;
      padding: 6px 12px;
      font-family: monospace;
      font-size: 0.75rem;
      cursor: pointer;
      transition: opacity 120ms ease, transform 120ms ease;
    }
    .page-actions button {
      background: var(--button-bg);
      border: 1px solid var(--button-border);
      color: var(--page-text);
    }
    .card.dark button {
      background: var(--button-bg);
      border: 1px solid var(--button-border);
      color: var(--dark-text);
    }
    .card.light button {
      background: var(--button-light-bg);
      border: 1px solid var(--button-light-border);
      color: var(--light-text);
    }
    button:hover {
      opacity: 0.9;
      transform: translateY(-1px);
    }
    .figure-wrap {
      padding: 18px;
    }
    .figure-surface {
      display: block;
      width: 100%;
      min-height: 300px;
      border-radius: 6px;
      outline: 1px solid rgba(128,128,128,0.4);
      box-sizing: border-box;
    }
    .card.dark .figure-surface {
      background: var(--dark-bg);
    }
    .card.light .figure-surface {
      background: var(--light-bg);
    }
    img {
      display: block;
      width: 100%;
      height: auto;
      max-height: 72vh;
      object-fit: contain;
    }
    @media (max-width: 720px) {
      body {
        padding: 14px;
      }
      .page-header {
        align-items: start;
        flex-direction: column;
      }
      .card-header {
        align-items: start;
        flex-direction: column;
      }
    }
  </style>
</head>
<body>
  <div class="page">
    <div class="page-header">
      <div class="title">$BASE_NAME</div>
      <div class="page-actions">
        <button onclick="navigator.clipboard.writeText('$copy_cmd')">copy cp ./</button>
      </div>
    </div>
    <div class="cards">
      <section class="card dark">
        <div class="card-header">
          <div class="meta">
            <span class="variant">dark</span>
            <span class="label">$DARK_OUT_NAME.svg</span>
          </div>
          <button onclick="navigator.clipboard.writeText('$dark_svg_abs')">copy path</button>
        </div>
        <div class="figure-wrap">
          <div class="figure-surface">
            <img src="$dark_svg_rel" alt="$DARK_OUT_NAME.svg" />
          </div>
        </div>
      </section>
      <section class="card light">
        <div class="card-header">
          <div class="meta">
            <span class="variant">light</span>
            <span class="label">$LIGHT_OUT_NAME.svg</span>
          </div>
          <button onclick="navigator.clipboard.writeText('$light_svg_abs')">copy path</button>
        </div>
        <div class="figure-wrap">
          <div class="figure-surface">
            <img src="$light_svg_rel" alt="$LIGHT_OUT_NAME.svg" />
          </div>
        </div>
      </section>
    </div>
  </div>
</body>
</html>
EOF
}

do_build() {
    build_variant "dark" "$DARK_OUT_NAME" || return 1
    build_variant "light" "$LIGHT_OUT_NAME" || return 1
    write_preview
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
