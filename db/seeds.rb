doc_pages = [
  {
    title: "HTTP/3 basics",
    slug: "http3-basics",
    category: "Protocol",
    position: 1,
    summary: "QUIC, HTTP/3, streams, and why this is more than a faster TCP socket.",
    body: <<~BODY
      HTTP/3 is HTTP semantics over QUIC. Rails still sees a request, headers, a path, and a response body. The transport below that request is different.

      QUIC runs over UDP and gives HTTP/3 independent streams inside one connection. A slow image or API response does not have to block every other response behind it in the same way TCP-level head-of-line blocking can.

      In this playground, the ordinary Rails page, Tailwind assets, JavaScript, JSON API responses, and WebTransport handshakes all ride the same HTTP/3-capable local setup.

      Open Chrome DevTools, enable the Protocol column, and launch with bin/chrome-h3. You should see h3 for the document and assets.
    BODY
  },
  {
    title: "Rails over HTTP/3",
    slug: "rails-over-http3",
    category: "Rails",
    position: 2,
    summary: "Quicsilver serves the same Rails Rack app; controllers and views stay boring.",
    body: <<~BODY
      Quicsilver does not ask Rails to become a new framework. It serves the Rails Rack application over HTTP/3.

      That means normal controllers, routes, middleware, ERB views, cookies, CSRF protection, Turbo, Stimulus, and the asset pipeline can keep doing normal Rails things.

      The docs section is deliberately boring Rails: resources :docs, a DocsController, ERB templates, and Turbo-powered vote buttons.

      The interesting bit is below Rack: the same app can be reached over QUIC and HTTP/3.
    BODY
  },
  {
    title: "Assets and Alt-Svc",
    slug: "assets-and-alt-svc",
    category: "Browser",
    position: 3,
    summary: "How browsers discover HTTP/3 and why asset-heavy pages are a good demo.",
    body: <<~BODY
      Browsers do not upgrade HTTP/1.1 to HTTP/3 with an Upgrade header. They discover HTTP/3 with Alt-Svc.

      The TCP HTTPS response advertises something like Alt-Svc: h3=\":3443\"; ma=3600. The browser can then use HTTP/3 for later requests to that origin.

      Product grids are a useful demo because they load many independent assets: one HTML document, CSS, JavaScript, and lots of product images. In DevTools, those requests should show h3 when the local H3 workflow is active.

      Local Chrome has stricter behavior around private roots and Alt-Svc, so this playground includes bin/chrome-h3 for a repeatable local full-H3 browser session.
    BODY
  },
  {
    title: "WebTransport",
    slug: "webtransport",
    category: "Realtime",
    position: 4,
    summary: "Where browser-native streams fit beside normal Rails request/response.",
    body: <<~BODY
      WebTransport is for long-lived browser sessions over HTTP/3. It is not a controller action and not an HTTP/1.1 WebSocket upgrade.

      A browser opens an HTTP/3 Extended CONNECT request with :protocol = webtransport. Once accepted, the client and server can exchange reliable streams and unreliable datagrams.

      In Rails terms, this is useful for the parts of an app that want realtime behavior: reactions, comments, stock updates, collaboration cursors, activity feeds, and live operational status.

      The protocol lab includes a small echo endpoint. QuicDrop will use the same idea for flash-sale reactions and activity.
    BODY
  },
  {
    title: "Queue saturation",
    slug: "queue-saturation",
    category: "Operations",
    position: 5,
    summary: "Flash sales are a natural place to show backpressure, jobs, and live visibility.",
    body: <<~BODY
      A flash sale is not just a fast web page. It is a pressure test for the whole app: product images, API calls, reservations, stock updates, background jobs, and user feedback.

      Queue saturation happens when work arrives faster than workers drain it. The user-facing app still needs to be understandable while the queue is under pressure.

      QuicDrop is intended to make that visible: reserve buttons create work, activity events show progress, and live status can move over WebTransport.

      The first version focuses on Rails and HTTP/3 surfaces. Queue-backed reservations and saturation controls are a natural next iteration.
    BODY
  },
  {
    title: "Deployment shape",
    slug: "deployment-shape",
    category: "Production",
    position: 6,
    summary: "The production shape is TCP HTTPS plus UDP HTTP/3, usually on the same host and port.",
    body: <<~BODY
      A production HTTP/3 deployment needs UDP open end to end.

      The common shape is TCP HTTPS on :443 for normal web discovery, plus UDP QUIC/HTTP/3 on :443 for H3 traffic and WebTransport. Both listeners should present a publicly trusted certificate for the same origin.

      Alt-Svc advertises the HTTP/3 endpoint: h3=\":443\"; ma=86400.

      Many managed L7 load balancers do not pass UDP through by default, so deployment is part of the demo story. For a clean public proof, a small VPS with TCP/443 and UDP/443 open is often simpler than fighting a platform that terminates QUIC elsewhere.
    BODY
  }
]

doc_pages.each do |attributes|
  page = DocPage.find_or_initialize_by(slug: attributes.fetch(:slug))
  page.update!(attributes)
end
