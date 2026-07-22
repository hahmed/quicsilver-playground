import "@hotwired/turbo-rails"
import "controllers"
import { connect, openMessageStream } from "quicsilver/web_transport"

function writeTo(elementId, message, { append = true } = {}) {
  const element = document.getElementById(elementId)
  if (!element) return

  element.textContent = append ? `${element.textContent}${message}\n` : message
}

function timestamp() {
  return new Date().toISOString()
}

function logTransport(message) {
  writeTo("transport-output", `${timestamp()} ${message}`)
}

function clearTransportLog() {
  const element = document.getElementById("transport-output")
  if (!element) return

  element.textContent = ""
}

function csrfToken() {
  return document.querySelector("meta[name='csrf-token']")?.content
}

async function fetchJson(url, options = {}) {
  const response = await fetch(url, {
    ...options,
    headers: {
      Accept: "application/json",
      ...(options.body ? { "Content-Type": "application/json" } : {}),
      ...(csrfToken() ? { "X-CSRF-Token": csrfToken() } : {}),
      ...(options.headers || {})
    }
  })

  const payload = await response.json()
  if (!response.ok) throw new Error(payload.error || `HTTP ${response.status}`)
  return payload
}

window.clearTransportLog = clearTransportLog

window.runEcho = async function () {
  clearTransportLog()

  try {
    if (!("WebTransport" in window)) {
      logTransport("WebTransport is not available in this browser")
      return
    }

    const url = new URL("/transports/echo", window.location.href)
    url.protocol = "https:"
    url.port = window.QUICSILVER_PORT || window.location.port || "4433"
    logTransport(`connecting to ${url}`)

    const transport = await connect(url.toString())
    logTransport("transport ready")

    transport.closed.then(
      () => logTransport("transport closed cleanly"),
      (error) => logTransport(`transport closed with error: ${error}`)
    )

    const stream = await openMessageStream(transport)
    const message = { hello: "world", at: Date.now() }

    logTransport(`sending ${JSON.stringify(message)}`)
    await stream.send(message)
    await stream.close()

    logTransport("waiting for echo")
    for await (const response of stream.responses()) {
      logTransport(`received ${JSON.stringify(response)}`)
      break
    }

    transport.close()
  } catch (error) {
    console.error(error)
    logTransport(`failed: ${error.name || "Error"}: ${error.message || error}`)
  }
}

window.runApiStatus = async function () {
  const output = document.getElementById("api-output")
  if (output) output.textContent = "Requesting /api/status ..."

  try {
    const payload = await fetchJson("/api/status")
    if (output) output.textContent = JSON.stringify(payload, null, 2)
  } catch (error) {
    if (output) output.textContent = `${error.name || "Error"}: ${error.message || error}`
  }
}

async function loadMessages() {
  const list = document.getElementById("messages-list")
  if (!list) return

  const messages = await fetchJson("/api/messages")

  if (messages.length === 0) {
    list.innerHTML = `<p class="text-sm text-slate-500">No messages yet. Post the first one over the JSON API.</p>`
    return
  }

  list.innerHTML = messages.map(() => `
    <article class="rounded-2xl border border-white/10 bg-white/[0.04] p-4">
      <div class="flex items-center justify-between gap-3">
        <p class="text-sm font-bold text-white"></p>
        <time class="text-xs text-slate-500"></time>
      </div>
      <p class="mt-2 text-sm leading-6 text-slate-300"></p>
    </article>
  `).join("")

  list.querySelectorAll("article").forEach((article, index) => {
    const message = messages[index]
    article.querySelector("p").textContent = message.author
    article.querySelector("time").textContent = new Date(message.created_at).toLocaleTimeString()
    article.querySelectorAll("p")[1].textContent = message.body
  })
}

window.loadMessages = async function () {
  try {
    await loadMessages()
  } catch (error) {
    writeTo("messages-error", `${error.name || "Error"}: ${error.message || error}`, { append: false })
  }
}

window.createMessage = async function (event) {
  event.preventDefault()

  const form = event.currentTarget
  const error = document.getElementById("messages-error")
  if (error) error.textContent = ""

  try {
    await fetchJson("/api/messages", {
      method: "POST",
      body: JSON.stringify({
        message: {
          author: form.elements.author.value,
          body: form.elements.body.value
        }
      })
    })

    form.reset()
    await loadMessages()
  } catch (errorValue) {
    if (error) error.textContent = `${errorValue.name || "Error"}: ${errorValue.message || errorValue}`
  }
}


let dropTransport = null
let dropTransportReady = false
let dropTransportConnecting = false
let dropActivityPoller = null
let latestDropEventId = null

function setDropTransportStatus(label, mode = "fallback") {
  const status = document.getElementById("drop-transport-status")
  if (!status) return

  status.textContent = `Room transport: ${label}`
  status.className = {
    webtransport: "rounded-full bg-fuchsia-400/10 px-3 py-1 text-xs font-bold text-fuchsia-300",
    connecting: "rounded-full bg-cyan-400/10 px-3 py-1 text-xs font-bold text-cyan-300",
    fallback: "rounded-full bg-slate-400/10 px-3 py-1 text-xs font-bold text-slate-300"
  }[mode]
}

async function connectDropTransport() {
  if (!document.getElementById("drop-activity")) return false
  if (!("WebTransport" in window)) {
    setDropTransportStatus("Rails API fallback", "fallback")
    return false
  }
  if (dropTransportReady) return true
  if (dropTransportConnecting) return false

  dropTransportConnecting = true
  setDropTransportStatus("connecting", "connecting")

  try {
    const url = new URL("/transports/drop", window.location.href)
    url.protocol = "https:"
    url.port = window.QUICSILVER_PORT || window.location.port || "4433"

    dropTransport = await connect(url.toString())
    dropTransportReady = true
    setDropTransportStatus("WebTransport", "webtransport")

    dropTransport.closed.then(
      () => {
        dropTransportReady = false
        dropTransport = null
        setDropTransportStatus("Rails API fallback", "fallback")
      },
      () => {
        dropTransportReady = false
        dropTransport = null
        setDropTransportStatus("Rails API fallback", "fallback")
      }
    )

    return true
  } catch (error) {
    console.error(error)
    dropTransportReady = false
    dropTransport = null
    setDropTransportStatus("Rails API fallback", "fallback")
    return false
  } finally {
    dropTransportConnecting = false
  }
}

async function sendDropCommand(command) {
  const connected = dropTransportReady || await connectDropTransport()
  if (!connected || !dropTransport) throw new Error("WebTransport unavailable")

  const stream = await openMessageStream(dropTransport)
  await stream.send(command)
  await stream.close()

  for await (const response of stream.responses()) {
    if (response.type === "error") throw new Error(response.error)
    setDropTransportStatus("WebTransport · live", "webtransport")
    return response
  }

  throw new Error("No WebTransport response")
}

function applyDropPayload(payload) {
  if (payload.product) renderDropStats(payload.product)
  if (payload.events) renderDropActivity(payload.events)
}

function startDropActivityPolling() {
  if (dropActivityPoller || !document.getElementById("drop-activity")) return

  dropActivityPoller = setInterval(() => {
    if (document.hidden) return

    window.loadDrop().catch(console.error)
    window.loadDropActivity().catch(console.error)
  }, 2000)
}

function stopDropActivityPolling() {
  if (!dropActivityPoller) return

  clearInterval(dropActivityPoller)
  dropActivityPoller = null
}

function renderDropStats(product) {
  const watching = document.getElementById("drop-watching")
  const claimed = document.getElementById("drop-claimed")
  const nextMilestone = document.getElementById("drop-next-milestone")

  if (watching) watching.textContent = Number(product.watching_count).toLocaleString()
  if (claimed) claimed.textContent = product.claimed_count
  if (nextMilestone) nextMilestone.textContent = product.next_milestone

  product.variants.forEach((variant) => {
    const card = document.querySelector(`[data-drop-variant-id="${variant.id}"]`)
    if (!card) return

    const stock = card.querySelector("[data-variant-stock]")
    const variantClaimed = card.querySelector("[data-variant-claimed]")
    if (stock) stock.textContent = variant.stock
    if (variantClaimed) variantClaimed.textContent = variant.claimed_count
  })
}

function animateNewDropEvents(events) {
  if (!events.length) return

  const newestId = Math.max(...events.map((event) => event.id))

  if (latestDropEventId) {
    events
      .filter((event) => event.id > latestDropEventId)
      .forEach((event) => {
        if (event.kind === "milestone") {
          sparkDropMilestone()
        } else if (event.emoji) {
          burstDropEmoji(event.emoji)
        } else if (event.kind === "comment") {
          burstDropEmoji("💬")
        } else if (event.kind === "claim") {
          burstDropEmoji("💎")
        }
      })
  }

  latestDropEventId = newestId
}

function renderDropActivity(events) {
  const list = document.getElementById("drop-activity")
  if (!list) return

  animateNewDropEvents(events)

  list.innerHTML = events.map((event) => `
    <article class="rounded-2xl border border-white/10 bg-black/20 p-4">
      <p class="text-sm text-slate-300"><span class="mr-2"></span><span data-actor></span> <span data-body></span></p>
      <p class="mt-2 text-xs text-slate-600" data-time></p>
    </article>
  `).join("")

  list.querySelectorAll("article").forEach((article, index) => {
    const event = events[index]
    article.querySelector("span").textContent = event.emoji || "•"
    article.querySelector("[data-actor]").textContent = event.actor || "system"
    article.querySelector("[data-body]").textContent = event.body
    article.querySelector("[data-time]").textContent = new Date(event.created_at).toLocaleTimeString()
  })
}

function burstDropEmoji(emoji) {
  const layer = document.getElementById("drop-effects")
  if (!layer) return

  for (let index = 0; index < 10; index += 1) {
    const node = document.createElement("div")
    node.textContent = emoji
    node.style.position = "absolute"
    node.style.left = `${20 + Math.random() * 60}%`
    node.style.bottom = `${5 + Math.random() * 25}%`
    node.style.fontSize = `${24 + Math.random() * 34}px`
    node.style.opacity = "0"
    node.style.transform = "translateY(40px) scale(0.8)"
    node.style.transition = "transform 1200ms ease-out, opacity 1200ms ease-out"
    layer.appendChild(node)

    requestAnimationFrame(() => {
      node.style.opacity = "1"
      node.style.transform = `translate(${(Math.random() - 0.5) * 180}px, -${180 + Math.random() * 240}px) scale(${1 + Math.random()}) rotate(${(Math.random() - 0.5) * 50}deg)`
    })

    setTimeout(() => node.remove(), 1300)
  }
}

function sparkDropMilestone() {
  burstDropEmoji("✨")
  setTimeout(() => burstDropEmoji("⚡"), 120)
}

window.swapDropHero = function (src) {
  const image = document.getElementById("drop-hero-image")
  if (!image) return

  image.style.opacity = "0.35"
  image.style.transform = "scale(0.985)"

  setTimeout(() => {
    image.src = src
    image.onload = () => {
      image.style.opacity = "1"
      image.style.transform = "scale(1)"
    }
  }, 120)
}

window.loadDrop = async function () {
  if (!document.getElementById("drop-activity")) return

  try {
    const payload = await sendDropCommand({ type: "snapshot" })
    applyDropPayload(payload)
  } catch (_error) {
    const product = await fetchJson("/api/drop")
    renderDropStats(product)
  }
}

window.loadDropActivity = async function () {
  if (!document.getElementById("drop-activity")) return

  const events = await fetchJson("/api/drop_events")
  renderDropActivity(events)
}

window.claimDropVariant = async function (variantId) {
  try {
    const before = Number(document.getElementById("drop-claimed")?.textContent || 0)
    let payload

    try {
      payload = await sendDropCommand({ type: "claim", variant_id: variantId })
    } catch (_error) {
      payload = await fetchJson("/api/drop_claims", {
        method: "POST",
        body: JSON.stringify({ variant_id: variantId })
      })
      await loadDropActivity()
    }

    applyDropPayload(payload)
    burstDropEmoji(payload.claimed ? "💎" : "👀")

    const after = Number(payload.product.claimed_count)
    if (after > before && [25, 50, 100, 250, 500, 1000].includes(after)) sparkDropMilestone()
  } catch (error) {
    burstDropEmoji("🫠")
    console.error(error)
  }
}

window.sendDropReaction = async function (emoji) {
  try {
    let payload

    try {
      payload = await sendDropCommand({ type: "reaction", emoji })
    } catch (_error) {
      payload = await fetchJson("/api/drop_events", {
        method: "POST",
        body: JSON.stringify({ kind: "reaction", emoji })
      })
      await loadDropActivity()
    }

    applyDropPayload(payload)
    burstDropEmoji(emoji)
  } catch (error) {
    console.error(error)
  }
}

window.sendDropComment = async function (event) {
  event.preventDefault()
  const form = event.currentTarget
  const body = form.elements.body.value

  try {
    let payload

    try {
      payload = await sendDropCommand({ type: "comment", actor: "you", body })
    } catch (_error) {
      payload = await fetchJson("/api/drop_events", {
        method: "POST",
        body: JSON.stringify({ kind: "comment", actor: "you", body })
      })
      await loadDropActivity()
    }

    applyDropPayload(payload)
    form.reset()
    burstDropEmoji("💬")
  } catch (error) {
    console.error(error)
  }
}

document.addEventListener("turbo:load", () => {
  const status = document.getElementById("webtransport-status")
  if (status) status.textContent = "WebTransport" in window ? "available" : "not available"

  loadMessages().catch((error) => {
    writeTo("messages-error", `${error.name || "Error"}: ${error.message || error}`, { append: false })
  })

  if (document.getElementById("drop-activity")) {
    connectDropTransport().then(() => window.loadDrop()).catch(console.error)
    window.loadDropActivity().catch(console.error)
    startDropActivityPolling()
  }
})

document.addEventListener("turbo:before-cache", () => {
  stopDropActivityPolling()
})
