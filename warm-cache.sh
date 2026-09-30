#!/usr/bin/env bash
# warm-cache.sh - re-fill a website's page/CDN cache after a purge.
# Works on Linux and macOS (bash 3.2+, curl, grep, sed). No xargs needed.
#
# Usage:
#   ./warm-cache.sh https://example.com                      # auto-discovers /wp-sitemap.xml
#   ./warm-cache.sh https://example.com /sitemap_index.xml   # custom sitemap (index or urlset)
#   PAGE_JOBS=4 ASSET_JOBS=8 ./warm-cache.sh https://example.com
#
# Walks the sitemap (following one level of sitemap index), requests every page,
# then every same-domain CSS/JS/image/font file referenced in those pages.
# Prints every request as it happens and a summary of non-200s at the end.
# Lists and logs are saved in ./warm-cache-<host>/.

set -eo pipefail

SITE="${1:?Usage: $0 https://your-domain [sitemap-path]}"
SITE="${SITE%/}"                                  # strip trailing slash
SITEMAP="${2:-}"                                  # empty = auto-discover
PAGE_JOBS="${PAGE_JOBS:-2}"                       # keep low to go easy on the origin
ASSET_JOBS="${ASSET_JOBS:-4}"
UA="${UA:-cache-warmer/1.0}"

HOST="${SITE#*://}"
HOST_RE="$(printf '%s' "$HOST" | sed 's/\./\\./g')"   # escape dots for regex
OUT="warm-cache-${HOST}"
HTML_DIR="$OUT/html"
rm -rf "$HTML_DIR"; mkdir -p "$HTML_DIR"
: > "$OUT/page-status.txt"; : > "$OUT/asset-status.txt"

NNBSP="$(printf '\342\200\257')"                  # macOS screenshot narrow no-break space
fetch()  { curl -sL --compressed -A "$UA" "$@"; }
# Fetch a sitemap, transparently un-gzipping *.xml.gz files
fetch_xml() { case "$1" in *.gz) fetch "$1" | gunzip -c 2>/dev/null ;; *) fetch "$1" ;; esac; }
# Extract <loc> values; tolerates newlines/whitespace and CDATA inside <loc>
locs()   { tr -d '\r' | tr '\n' ' ' | grep -oE '<loc>[^<]*(<!\[CDATA\[[^]]*\]\]>)?[^<]*</loc>' \
             | sed -E 's#</?loc>##g; s#<!\[CDATA\[##; s#\]\]>##; s/^[[:space:]]+//; s/[[:space:]]+$//; s/&amp;/\&/g'; }
encode() { sed "s/ /%20/g; s/$NNBSP/%E2%80%AF/g"; }

# Wait until fewer than $1 background jobs are running (bash 3.2-safe)
throttle() { while [ "$(jobs -pr | wc -l)" -ge "$1" ]; do sleep 0.1; done; }

# 1. Find the sitemap: argument > robots.txt "Sitemap:" lines > common locations
if [ -n "$SITEMAP" ]; then
  case "$SITEMAP" in http*) CANDIDATES="$SITEMAP" ;; *) CANDIDATES="$SITE/${SITEMAP#/}" ;; esac
else
  CANDIDATES="$(fetch "$SITE/robots.txt" | tr -d '\r' | grep -i '^sitemap:' | sed -E 's/^[Ss]itemap:[[:space:]]*//')
$SITE/sitemap_index.xml
$SITE/wp-sitemap.xml
$SITE/sitemap.xml"
fi
ROOT=""
for c in $CANDIDATES; do
  if fetch_xml "$c" | grep -qE '<(urlset|sitemapindex)'; then ROOT="$c"; break; fi
done
[ -n "$ROOT" ] || { echo "No sitemap found. Pass one explicitly: $0 $SITE /path/to/sitemap.xml"; exit 1; }
echo "Sitemap: $ROOT"

# Walk it, following nested sitemap indexes (up to 3 levels)
: > "$OUT/pages.txt"
queue="$ROOT"
for level in 1 2 3; do
  next=""
  for sm in $queue; do
    xml="$(fetch_xml "$sm")"
    if printf '%s' "$xml" | grep -q '<sitemapindex'; then
      next="$next $(printf '%s' "$xml" | locs | tr '\n' ' ')"
    else
      printf '%s' "$xml" | locs >> "$OUT/pages.txt"
    fi
  done
  [ -n "${next// /}" ] || break
  queue="$next"
done
sort -u -o "$OUT/pages.txt" "$OUT/pages.txt"
echo "Pages:  $(wc -l < "$OUT/pages.txt" | tr -d ' ')"

# 2. Warm pages (each saved to its own file, so parallel output never interleaves)
warm_page() {
  local url=$1 n=$2 meta code secs
  meta=$(curl -s -A "$UA" -o "$HTML_DIR/$n.html" -w '%{http_code} %{time_total}' "$url")
  code=${meta%% *}; secs=${meta#* }
  printf 'PAGE  %s %ss %s\n' "$code" "$secs" "$url"
  [ "$code" = 200 ] || echo "$code $url" >> "$OUT/page-status.txt"
}
n=0
while IFS= read -r url; do
  [ -n "$url" ] || continue
  n=$((n + 1)); throttle "$PAGE_JOBS"
  warm_page "$url" "$n" &
done < "$OUT/pages.txt"
wait

# Collect same-domain asset URLs from the saved HTML
cat "$HTML_DIR"/*.html 2>/dev/null \
 | grep -oE "(href|src)=[\"']https?://${HOST_RE}/[^\"']+\.(css|js|png|jpe?g|webp|avif|svg|gif|woff2?)(\?[^\"']*)?[\"']" \
 | sed -E "s/^(href|src)=[\"']//; s/[\"']$//; s/&#038;/\&/g; s/&amp;/\&/g" \
 | encode | sort -u > "$OUT/assets.txt" || true
echo "Assets: $(wc -l < "$OUT/assets.txt" | tr -d ' ')"

# 3. Warm assets
warm_asset() {
  curl -s -A "$UA" -o /dev/null -w 'ASSET %{http_code} %{time_total}s %{url_effective}\n' "$1" \
    | tee -a "$OUT/asset-status.txt"
}
while IFS= read -r url; do
  [ -n "$url" ] || continue
  throttle "$ASSET_JOBS"
  warm_asset "$url" &
done < "$OUT/assets.txt"
wait

# Summary
echo
echo "Done: $(wc -l < "$OUT/pages.txt" | tr -d ' ') pages, $(wc -l < "$OUT/assets.txt" | tr -d ' ') assets."
grep -v '^ASSET 200 ' "$OUT/asset-status.txt" > "$OUT/asset-failures.txt" || true
if [ -s "$OUT/page-status.txt" ] || [ -s "$OUT/asset-failures.txt" ]; then
  echo "Non-200 responses (403 on pages usually = challenged by a security rule):"
  sed 's/^/PAGE  /' "$OUT/page-status.txt"
  cat "$OUT/asset-failures.txt"
else
  echo "Everything returned 200."
fi
