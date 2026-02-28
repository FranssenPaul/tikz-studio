# tikz-studio

Docker-first workspace for creating TikZ/LaTeX figures and exporting SVG files.

This project is designed to run through Docker. You do not need a local TeX Live installation.

## What you get

- Reproducible TeX environment across machines
- `.tex` source in `figures/`
- Generated SVG output in `out/`
- Optional watch mode for rebuild on save
- `pdflatex` and `lualatex` support

## Project layout

```text
tikz-studio/
├── figures/                  # TikZ source files (.tex)
├── out/                      # Generated SVG output
├── templates/                # Reusable templates
├── .build.sh                 # Core build script
├── Dockerfile                # TeX/Docker environment
├── docker-compose.yml        # Runtime config + volume mount
└── Makefile                  # Command shortcuts
```

`out/` mirrors `figures/` without the `figures/` prefix.
Example:
`figures/geometry/triangle-rectangle.tex` -> `out/geometry/triangle-rectangle.svg`

## Prerequisites (Docker only)

### Linux

- Docker Engine
- Docker Compose plugin (`docker compose`)

### macOS

- Docker Desktop

### Windows

- Docker Desktop (WSL2 backend recommended)

## Quick start

From project root:

```bash
docker compose build tikz
```

Then build one figure:

```bash
HOST_PROJECT_ROOT="$(pwd)" docker compose run --rm tikz ./.build.sh figures/geometry/triangle-rectangle.tex
```

Output file:
`out/geometry/triangle-rectangle.svg`

## Recommended usage (Makefile)

Use the provided shortcuts:

```bash
make image
make build FILE=figures/geometry/triangle-rectangle.tex
make build FILE=figures/geometry/triangle-rectangle.tex THEME=light
make watch FILE=figures/geometry/triangle-rectangle.tex
make lualatex FILE=figures/algebra/sinusoid-2sinx.tex
make watch-lualatex FILE=figures/algebra/sinusoid-2sinx.tex
```

Theme note:
- Default theme is dark.
- Set `THEME=light` for light preview mode.

## Direct Docker usage

### Linux / macOS

Use your host UID/GID so generated files are owned by your user:

```bash
HOST_PROJECT_ROOT="$(pwd)" LOCAL_UID=$(id -u) LOCAL_GID=$(id -g) \
docker compose run --rm tikz ./.build.sh figures/geometry/triangle-rectangle.tex
```

Watch mode:

```bash
HOST_PROJECT_ROOT="$(pwd)" LOCAL_UID=$(id -u) LOCAL_GID=$(id -g) \
docker compose run --rm tikz ./.build.sh --watch figures/geometry/triangle-rectangle.tex
```

LuaLaTeX:

```bash
HOST_PROJECT_ROOT="$(pwd)" LOCAL_UID=$(id -u) LOCAL_GID=$(id -g) \
docker compose run --rm tikz ./.build.sh --lualatex figures/algebra/sinusoid-2sinx.tex
```

### Windows (PowerShell)

Basic build:

```powershell
$env:HOST_PROJECT_ROOT = (Get-Location).Path
docker compose run --rm tikz ./.build.sh figures/geometry/triangle-rectangle.tex
```

Watch mode:

```powershell
$env:HOST_PROJECT_ROOT = (Get-Location).Path
docker compose run --rm tikz ./.build.sh --watch figures/geometry/triangle-rectangle.tex
```

LuaLaTeX:

```powershell
$env:HOST_PROJECT_ROOT = (Get-Location).Path
docker compose run --rm tikz ./.build.sh --lualatex figures/algebra/sinusoid-2sinx.tex
```

Notes for Windows:

- `LOCAL_UID/LOCAL_GID` are usually not needed.
- WSL2 filesystem paths generally perform better than mounted `C:` paths for watch workflows.
- Set `HOST_PROJECT_ROOT` so the preview "copy path" button returns a host path instead of `/workspace/...`.

## Build options

The underlying script supports:

```bash
./.build.sh [--dark|--light] [--watch] [--lualatex] <path/to/file.tex>
```

Examples:

```bash
# Light preview theme
make build FILE=figures/geometry/triangle-rectangle.tex THEME=light

# LuaLaTeX + watch
make watch-lualatex FILE=figures/algebra/sinusoid-2sinx.tex
```

## French language support

The image includes `texlive-lang-french`. To enable French typographic rules (non-breaking spaces before `:` `!` `?` `;`, `«»` quotes, French hyphenation), add the language package to your figure.

**pdflatex path** — use `babel`:

```tex
\usepackage[french]{babel}
```

**lualatex path** — use `polyglossia`:

```tex
\usepackage{polyglossia}
\setmainlanguage{french}
```

Combined with the `\ifluatex` guard already used in this project:

```tex
\usepackage{iftex}
\ifluatex
  \usepackage{fontspec}
  \usepackage{unicode-math}
  \setmainfont{Fira Sans}
  \setmonofont{Fira Mono}
  \setmathfont{Fira Math}
  \usepackage{polyglossia}
  \setmainlanguage{french}
\else
  \usepackage[T1]{fontenc}
  \usepackage{newtxtext}
  \usepackage{newtxmath}
  \usepackage[french]{babel}
\fi
```

French quotes in source: use `\og texte \fg{}` or `\enquote{texte}` (with `csquotes` package).

## How Docker is wired

- Volume mount: `.:/workspace`
- Build runs inside container, files stay on host through the mounted volume
- `OPEN_PREVIEW=0` prevents trying to open VSCode from inside container
- `HOME`, `XDG_CACHE_HOME`, `TEXMFVAR`, `TEXMFCACHE` are set to writable `/tmp` paths so `lualatex/fontspec` cache works
- `HOST_PROJECT_ROOT` is used by the preview copy button to produce a host-usable absolute path
- `--rm` removes temporary containers after each run

## Troubleshooting

- `permission denied` on Docker socket (Linux):
  - Ensure Docker daemon is running
  - Ensure your user can access Docker (`docker` group)
- First `docker compose build tikz` is slow:
  - Normal (large TeX packages)
- Watch mode appears blocked:
  - Normal, it stays attached and waits for file changes
  - Stop with `Ctrl+C`

## Typical workflow

1. Edit/create `.tex` files in `figures/...`
2. Run `make build FILE=...` or `make watch FILE=...` (`THEME=light` optional)
3. Use generated SVG from `out/...`
