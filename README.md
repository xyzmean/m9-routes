# m9-routes

Policy-routing lists for the M9 WireGuard entry points (m9-14 / m9-16). Each entry
point splits wg0 client traffic three ways via an nft set (`table ip wgpbr`):

| dest in            | action                                            |
|--------------------|---------------------------------------------------|
| `@force_m13`       | **always** mark `0x1` → table 100 → **m9-13** exit |
| `@direct4`         | DIRECT local egress (fast, local IP)              |
| everything else    | mark `0x1` → m9-13 (foreign exit)                 |

`@force_m13` is checked **first**, so Google + Meta/WhatsApp always take the
foreign exit even though some of their IPs sit inside RU-present ranges (Google
Global Cache, Meta edge) that would otherwise leak to the direct path.

- **force-m13.lst** — Google (`goog.json`) + Meta/WhatsApp/Instagram (AS32934).
  Regenerate: `./gen-force-m13.sh`.
- **update-routes.sh** — run on each entry point (via `wg-pbr-update.timer`):
  pulls the fresh ru/cn list (radb-tools) + this force list, rebuilds the nft set.

Part of the M9 stack — see `xyzmean/wgmon-agent`, `xyzmean/wg-dashboard-vue`.
