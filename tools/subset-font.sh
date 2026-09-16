#!/usr/bin/env bash
# Regenerates the inlined Inter subset in index.html.
# Run it whenever the visible text on the page changes.
#
#   pip install fonttools brotli
#   bash tools/subset-font.sh
#
# TEXT must list every character the page renders. Note that .hint is
# uppercased by CSS, so its glyphs are needed in UPPERCASE here.
set -euo pipefail
cd "$(dirname "$0")/.."

TEXT='helowrd, MOVEARUNDCLIKTHG·'
CSS_URL='https://fonts.googleapis.com/css2?family=Inter:wght@100..900&display=swap'
UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36'

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# the last @font-face in the CSS is the "latin" subset
url="$(curl -s -H "User-Agent: $UA" "$CSS_URL" | grep -o 'https://[^)]*\.woff2' | tail -1)"
curl -s -o "$tmp/inter.woff2" "$url"

pyftsubset "$tmp/inter.woff2" \
  --output-file="$tmp/subset.woff2" \
  --flavor=woff2 \
  --layout-features='kern' \
  --text="$TEXT"

python - "$tmp/subset.woff2" <<'PY'
import base64, re, sys
b64 = base64.b64encode(open(sys.argv[1], "rb").read()).decode()
html = open("index.html", encoding="utf-8").read()
html, n = re.subn(r"(url\(data:font/woff2;base64,)[^)]*(\))", r"\g<1>" + b64 + r"\g<2>", html, count=1)
assert n == 1, "inline @font-face not found in index.html"
open("index.html", "w", encoding="utf-8", newline="\n").write(html)
print("index.html updated:", len(b64), "base64 chars of font")
PY
