# Quicsilver Playground

A Rails playground for Quicsilver: ordinary Rails pages, assets, APIs, and browser realtime running over HTTP/3.

The app is intentionally split into three surfaces:

- `/` — protocol lab with a JSON API check and WebTransport echo.
- `/docs` — normal Rails docs: resourceful routes, controllers, ERB, Turbo navigation, and Turbo votes.
- `/drop` — **QuicDrop**, an ET90 live drop room with campaign images, colorways, claims, reactions, comments, and activity.

The point is to prove that Rails can stay Rails while the transport underneath becomes QUIC/HTTP/3.

## Local setup

Install and trust a local mkcert root once:

```bash
mkcert -install
```

Add the development hostname once:

```bash
sudo sh -c 'printf "\n127.0.0.1 quicsilver.test\n::1 quicsilver.test\n" >> /etc/hosts'
```

Install gems:

```bash
bundle install
```

## Run the playground

Start Rails over TCP HTTPS, Quicsilver over UDP HTTP/3, and Tailwind:

```bash
bin/dev
```

In another terminal, launch a fresh Chrome profile forced onto HTTP/3 for the local origin:

```bash
bin/chrome-h3
```

Open:

```text
https://quicsilver.test:3443/
```

Chrome DevTools → Network → Protocol should show `h3` for the document, Rails assets, API calls, docs navigation, and QuicDrop campaign images when launched with `bin/chrome-h3`.

## Demo surfaces

### `/` Protocol lab

The homepage is the quick verification surface:

- `GET /api/status` through a normal Rails controller.
- WebTransport echo through `/transports/echo`.
- Links into `/docs` and `/drop`.

Click **Run** on the WebTransport echo. You should see:

```text
transport ready
sending { ... }
received { ... }
transport closed cleanly
```

### `/docs` Rails over HTTP/3

The docs section is deliberately boring Rails:

- `resources :docs, param: :slug`
- `DocsController`
- ERB views
- Turbo navigation
- nested Turbo vote resource

Use this page to prove that normal Rails pages and Turbo fetches work over HTTP/3 without turning the app into a custom protocol demo.

### `/drop` QuicDrop

QuicDrop is the richer storefront demo.

It is a fictional ET90 football boot drop: one hero product, multiple colorways, campaign images, stock/claim counters, reactions, comments, and a live activity feed.

Current implementation:

- Rails renders the page.
- PNG campaign images are served through the Rails asset pipeline.
- QuicDrop opens a browser WebTransport session to `/transports/drop`.
- Reactions, comments, claims, and snapshots use reliable WebTransport message streams when available.
- Rails JSON APIs remain as fallback and for direct inspection:
  - `GET /api/drop`
  - `GET /api/drop_events`
  - `POST /api/drop_events`
  - `POST /api/drop_claims`
- Browser JavaScript animates local reaction bursts and swaps campaign images into the hero frame.

In DevTools, the `/drop` document and ET90 PNGs should show `h3`. The live room should show a long-lived pending `webtransport` request for `/transports/drop`. After a successful command, the page shows `Room transport: WebTransport · live`.

## QuicDrop WebTransport shape

QuicDrop now uses WebTransport for its command path. The current route is:

```ruby
webtransport "/transports/drop", to: DropTransport
```

The goal is not just to replace `fetch()` with a socket. The page should use multiple WebTransport capabilities where they make sense.

### Reliable command stream

The current implementation uses reliable bidirectional message streams for actions that must be processed exactly enough to matter:

```json
{ "type": "reaction", "emoji": "🔥" }
{ "type": "comment", "body": "need the Inferno pair" }
{ "type": "claim", "variant_id": 12 }
{ "type": "snapshot" }
```

The server responds with events and updated product state:

```json
{
  "type": "event",
  "event": { "kind": "claim", "body": "claimed Volt" },
  "product": { "claimed_count": 118 }
}
```

### Next: server activity stream

Use server-initiated stream data for the room feed:

```json
{ "type": "activity", "event": { ... } }
{ "type": "stats", "product": { ... } }
{ "type": "milestone", "body": "150 claims unlocked Final Whistle" }
```

The first version can stream periodic snapshots. A later version can add per-process pub/sub and broadcast every new event to connected sessions.

### Next: datagrams for hype

Use unreliable datagrams for disposable, high-volume room energy:

```json
{ "type": "hype", "emoji": "🔥", "x": 0.42, "y": 0.71 }
```

A dropped emoji burst is fine. Claims and comments stay on reliable streams; fast reaction noise can use datagrams. This is the clearest “WebTransport is more than WebSockets” part of the demo.

### Fallback

The JSON API path remains as a fallback. If WebTransport is unavailable, QuicDrop still works through normal Rails requests.

## Later

QuicDrop is intentionally focused on Rails over HTTP/3 and browser WebTransport. Future versions may add a small diagnostics panel for Quicsilver-native protocol features such as connection metadata, backpressure signals, and QPACK stats.

## Why `bin/chrome-h3`?

Chrome does not naturally promote local/private-root origins to HTTP/3 through `Alt-Svc` in the same way it does for public production certificates. The playground uses a trusted short-lived ECDSA development certificate so TLS and WebTransport work locally, but full local page/assets-over-H3 still needs Chrome's local development override:

```bash
--origin-to-force-quic-on=quicsilver.test:3443
```

`bin/chrome-h3` hides that in a dedicated throwaway Chrome profile so normal browsing is untouched.

Production does not need this flag when using a publicly trusted certificate and normal `Alt-Svc`.

## Ports

The dev stack uses the same numeric port for TCP and UDP, like production:

```text
Puma TCP HTTPS:        quicsilver.test:3443
Quicsilver UDP HTTP/3: quicsilver.test:3443
```

TCP and UDP can share the same port.

## Useful checks

Check Alt-Svc on the TCP response:

```bash
curl -I https://quicsilver.test:3443/ | grep -i alt-svc
```

Expected:

```text
alt-svc: h3=":3443"; ma=3600
```

Check direct HTTP/3:

```bash
curl --http3 -I https://quicsilver.test:3443/
```

Expected:

```text
HTTP/3 200
```

Inspect the generated development certificate:

```bash
openssl x509 -in tmp/quicsilver/webtransport/localhost.pem -noout -issuer -subject -dates -text | grep -E "Issuer:|Subject:|Not Before|Not After|Public Key Algorithm"
```

It should be an ECDSA certificate signed by the mkcert development CA and valid for about 13 days.

If you change certificate generation, clear the cached cert:

```bash
rm -rf tmp/quicsilver/webtransport
```

## Debug H3 requests

Set `H3_DEBUG=1` to log requests handled by Quicsilver:

```bash
H3_DEBUG=1 bin/dev
```
