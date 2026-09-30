#!/usr/bin/env bash
# warm-cache.sh - re-fill a website's page/CDN cache after a purge.
#
# Usage:
#   ./warm-cache.sh https://example.com                      # auto-discovers /wp-sitemap.xml
#   ./warm-cache.sh https://example.com /sitemap_index.xml   # custom sitemap (index or urlset)
#   PAGE_JOBS=4 ASSET_JOBS=8 ./warm-cache.sh https://example.com
#
# Walks the sitemap (following one level of sitemap index), requests every page,
# then requests every same-domain CSS/JS/image/font file referenced in those pages.
# Prints only non-200 responses. Output lists are saved in ./warm-cache-<host>/.

set -euo pipefail

SITE="${1:?Usage: $0 https://your-domain [sitemap-path]}"
SITE="${SITE%/}"                                  # strip trailing slash
SITEMAP="${2:-/wp-sitemap.xml}"
PAGE_JOBS="${PAGE_JOBS:-2}"                       # keep low to go easy on the origin
ASSET_JOBS="${ASSET_JOBS:-4}"
UA="${UA:-cache-warmer/1.0}"

HOST="${SITE#*://}"
HOST_RE="${HOST//./\\.}"                          # escape dots for regex
OUT="warm-cache-${HOST}"
mkdir -p "$OUT"

fetch() { curl -s -A "$UA" "$@"; }
locs()  { grep -o '<loc>[^<]*' | sed 's/<loc>//; s/&amp;/\&/g'; }
encode(){ sed 's/ /%20/g; s/\xe2\x80\xaf/%E2%80%AF/g'; }   # spaces incl. macOS narrow no-break space

# 1. Page URLs from the sitemap (follow sub-sitemaps if it's an index)
ROOT_XML="$(fetch "$SITE$SITEMAP")"
if grep -q '<sitemapindex' <<<"$ROOT_XML"; then
  locs <<<"$ROOT_XML" | while read -r sm; do fetch "$sm" | locs; done
else
  locs <<<"$ROOT_XML"
fi | sort -u > "$OUT/pages.txt"
echo "Pages:  $(wc -l < "$OUT/pages.txt")"

# 2. Warm pages, report non-200s, and collect same-domain asset URLs from their HTML
: > "$OUT/page-status.txt"
export -f fetch; export UA OUT
xargs -P "$PAGE_JOBS" -I{} bash -c '
  html=$(curl -s -A "$UA" -w "\n__STATUS__%{http_code}" "{}")
  code=${html##*__STATUS__}
  [ "$code" = 200 ] || echo "$code {}" >> "$OUT/page-status.txt"
  printf "%s\n" "${html%__STATUS__*}"
' < "$OUT/pages.txt" \
 | grep -oE "(href|src)=[\"']https?://${HOST_RE}/[^\"']+\.(css|js|png|jpe?g|webp|avif|svg|gif|woff2?)(\?[^\"']*)?[\"']" \
 | sed -E "s/^(href|src)=[\"']//; s/[\"']$//; s/&#038;/\&/g; s/&amp;/\&/g" \
 | encode | sort -u > "$OUT/assets.txt"
echo "Assets: $(wc -l < "$OUT/assets.txt")"
if [ -s "$OUT/page-status.txt" ]; then
  echo "Pages that did not return 200 (403 = challenged by a security rule):"
  sort "$OUT/page-status.txt"
fi

# 3. Warm assets, print only failures
xargs -P "$ASSET_JOBS" -I{} curl -s -A "$UA" -o /dev/null -w '%{http_code} %{time_total}s {}\n' "{}" \
  < "$OUT/assets.txt" | grep -v '^200 ' || echo "All assets returned 200"
