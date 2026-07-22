# Quicsilver Playground

A small Rails app for trying Quicsilver, HTTP/3, and browser WebTransport.

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

Open page:

```text
https://quicsilver.test:3443/
```

Click **Run echo demo**. You should see:

```text
transport ready
sending { ... }
received { ... }
transport closed cleanly
```

Chrome DevTools Network should show the document and assets using `h3` when launched with `bin/chrome-h3`.

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
