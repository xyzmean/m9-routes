#!/usr/bin/env bash
# Regenerate force-m13.lst — IPv4 prefixes that MUST egress via m9-13 (foreign
# exit) even when they fall inside the ru/cn direct whitelist. Google + Meta/
# WhatsApp publish IPs that overlap RU-present ranges (GGC, Meta edge), so without
# this override they leak to the local/direct path and get blocked/throttled.
set -euo pipefail
OUT="${1:-force-m13.lst}"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

# Google — authoritative goog.json (all Google service ranges)
curl -fsSL -m25 https://www.gstatic.com/ipranges/goog.json \
  | python3 -c "import sys,json;[print(p['ipv4Prefix']) for p in json.load(sys.stdin)['prefixes'] if 'ipv4Prefix' in p]" \
  > "$TMP/google.lst"

# Meta / WhatsApp / Instagram — AS32934 announced prefixes (RIPEstat)
curl -fsSL -m30 "https://stat.ripe.net/data/announced-prefixes/data.json?resource=AS32934" \
  | python3 -c "import sys,json;[print(p['prefix']) for p in json.load(sys.stdin)['data']['prefixes'] if ':' not in p['prefix']]" \
  > "$TMP/meta.lst"

cat "$TMP/google.lst" "$TMP/meta.lst" \
  | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/[0-9]+$' | sort -u > "$OUT"
echo "force-m13: $(wc -l < "$OUT") prefixes (google + meta/whatsapp)"
