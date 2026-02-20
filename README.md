# tikz-studio

A structured workspace for creating high-quality mathematical and scientific figures using TikZ/LaTeX, exported as SVG for integration into web applications.

---

## Philosophy

Mathematical figures deserve publication-quality rendering. This studio uses **TikZ** — the gold standard for scientific illustration in the LaTeX ecosystem — to produce clean, vectorial SVG files that integrate seamlessly into modern web frontends.

The workflow: **edit → watch → preview → deploy**.

---

## Project Structure

```
tikz-studio/
├── figures/                  # TikZ source files (.tex), organized by discipline
│   ├── geometry/
│   ├── vectors/
│   ├── chemistry/
│   └── algebra/
│
├── out/                      # Generated SVG output — mirrors figures/ structure
│   ├── geometry/             #   (no figures/ prefix)
│   ├── vectors/
│   ├── chemistry/
│   └── algebra/
│
├── templates/                # Reusable LaTeX templates per discipline
│   ├── base.tex
│   ├── geometry.tex
│   └── chemistry.tex
│
├── .build.sh                 # Build script
└── .vscode/
    └── settings.json
```

> `out/` mirrors `figures/` without the `figures/` prefix.
> `figures/geometry/triangle.tex` → `out/geometry/triangle.svg`

---

## Prerequisites

### TeX Live (Ubuntu)

```bash
sudo apt install texlive-latex-extra texlive-science texlive-fonts-recommended
```

> Do **not** install `texlive-full` — it pulls in ConTeXt, whose post-install format generation takes an unreasonable amount of time.

### inotify-tools (for `--watch` mode)

```bash
sudo apt install inotify-tools
```

### VSCode Extensions

| Extension | Purpose |
|-----------|---------|
| Live Server | Auto-refresh HTML preview in browser |
| LaTeX language support | Syntax highlighting |

> LaTeX Workshop auto-build is **disabled** (`.vscode/settings.json`) — `.build.sh` handles all compilation.

---

## Build Script

```
./.build.sh [--dark|--light] [--invert] [--watch] [--lualatex] <path/to/file.tex>
```

### Arguments

| Argument | Default | Description |
|----------|---------|-------------|
| `<path>` | — | Path to the `.tex` source file, relative to project root |
| `--dark` | ✅ | Dark background in the HTML preview |
| `--light` | | Light background in the HTML preview |
| `--invert` | | Embed CSS inversion filter in the SVG. Output named `<name>-invert.svg` |
| `--watch` | | Watch the source file and rebuild automatically on every save |
| `--lualatex` | | Use LuaLaTeX instead of pdflatex (required for `fontspec`/`unicode-math`) |

### What it does

1. Compiles `.tex` → PDF via `pdflatex` (or `lualatex` with `--lualatex`)
2. Converts PDF → SVG via `dvisvgm`
3. Cleans up all intermediate files (`.aux`, `.log`, `.pdf`, `.fls`, `.synctex.gz`) from both `out/` and `figures/`
4. If `--invert`: embeds a CSS inversion filter in the SVG, outputs as `<name>-invert.svg`
5. Overwrites `out/preview.html` with the latest figure
6. Opens `out/preview.html` in VSCode on first build

### Examples

```bash
# Basic build
./.build.sh figures/geometry/triangle.tex

# Light background preview
./.build.sh --light figures/geometry/triangle.tex

# Dark mode SVG (inverted colors, for dark-mode web use)
./.build.sh --invert figures/geometry/triangle.tex
# → out/geometry/triangle-invert.svg

# Watch mode — rebuilds on every save
./.build.sh --watch figures/geometry/triangle.tex

# LuaLaTeX with modern font
./.build.sh --lualatex --dark figures/algebra/sinusoid.tex

# All combined
./.build.sh --lualatex --dark --watch figures/algebra/sinusoid.tex
```

---

## Live Preview

The build script generates `out/preview.html` on every build.

**Setup (once):**
1. Open `out/preview.html` in VSCode
2. Click **Go Live** in the status bar (Live Server extension)
3. The browser opens and auto-refreshes on every rebuild

**Preview features:**
- Configurable background (`--dark` / `--light`)
- Displays the figure filename
- **Copy path** button — copies the absolute path to clipboard (e.g. `/home/paul/tikz-studio/out/geometry/triangle.svg`)

**With `--watch`:** every `Ctrl+S` on the `.tex` file triggers a rebuild → preview updates automatically in the browser. Zero manual steps.

---

## Color Inversion

The `--invert` flag is designed for figures intended for dark-mode web pages.

It embeds `filter: invert(1) hue-rotate(180deg)` directly in the SVG:

- **Black lines** → white lines
- **White background** → transparent / dark
- **Colored elements**: hue is approximately preserved (`hue-rotate(180deg)` compensates for the hue shift introduced by `invert`)
- **Pure saturated colors** (e.g. full red) remain unchanged

The filter is self-contained in the SVG file — no CSS needed in the consuming page.

---

## Output Naming

| Command | Output file |
|---------|-------------|
| `./.build.sh figures/geometry/triangle.tex` | `out/geometry/triangle.svg` |
| `./.build.sh --invert figures/geometry/triangle.tex` | `out/geometry/triangle-invert.svg` |

---

## Integration with React

```jsx
// Static asset
import triangleSrc from './out/geometry/triangle.svg';
<img src={triangleSrc} alt="triangle" />

// Dark mode variant
<picture>
  <source srcset={triangleInvertSrc} media="(prefers-color-scheme: dark)" />
  <img src={triangleSrc} alt="triangle" />
</picture>
```

---

## Math Fonts

### With pdflatex (default)

| Package | Style |
|---------|-------|
| `newpxmath` | Palatino-based, elegant, round — **recommended default** |
| `newtxmath` | Times-based, sharp, professional |
| `fourier` | Utopia-based, distinctive |
| `kpfonts` | Balanced, modern |

```latex
\usepackage{newpxmath}
```

### With `--lualatex` (via `unicode-math`)

Unlock OpenType math fonts — noticeably more refined rendering.

```latex
\usepackage{iftex}
\ifluatex
  \usepackage{fontspec}
  \usepackage{unicode-math}
  \setmathfont{TeX Gyre Pagella Math}  % change font name here
\else
  \usepackage{newpxmath}               % fallback for pdflatex
\fi
```

#### Available fonts (already in texlive)

| Font name | Style |
|-----------|-------|
| `TeX Gyre Pagella Math` | Palatino — elegant, round ✅ |
| `TeX Gyre Termes Math` | Times — sharp, professional |
| `TeX Gyre DejaVu Math` | Humanist — very readable on screen |
| `TeX Gyre Bonum Math` | Bookman — classic |
| `TeX Gyre Schola Math` | Century Schoolbook |
| `Latin Modern Math` | Refined Computer Modern |

#### Additional fonts (require install)

| Font name | Style | Install |
|-----------|-------|---------|
| `Fira Math` | Sans-serif, very modern | `sudo apt install fonts-firamath` |
| `STIX Two Math` | Serif, complete, professional | `sudo apt install fonts-stix` |
| `Libertinus Math` | Elegant, open | `sudo apt install fonts-libertinus` |

> **Trade-off**: LuaLaTeX is slower than pdflatex. In `--watch` mode, saves take longer to rebuild. Use `--lualatex` for final-quality builds or when the font difference matters.

---

## Key Packages

| Package | Purpose |
|---------|---------|
| `tikz` | Core drawing engine |
| `tkz-euclide` | High-level Euclidean geometry (points, angles, segments) |
| `chemfig` | Molecular and chemical structure diagrams |
| `pgfplots` | Function graphs and data plots |
| `unicode-math` | OpenType math fonts (LuaLaTeX only) |
| `dvisvgm` | PDF → SVG conversion |

---

## License

MIT
