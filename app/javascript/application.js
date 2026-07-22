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
    const response = await fetch("/api/status", {
      headers: { Accept: "application/json" }
    })
    const payload = await response.json()
    if (output) output.textContent = JSON.stringify(payload, null, 2)
  } catch (error) {
    if (output) output.textContent = `${error.name || "Error"}: ${error.message || error}`
  }
}

async function loadMessages() {
  const list = document.getElementById("messages-list")
  if (!list) return

  const response = await fetch("/api/messages", {
    headers: { Accept: "application/json" }
  })
  const messages = await response.json()

  if (messages.length === 0) {
    list.innerHTML = `<p class="text-sm text-slate-500">No messages yet. Post the first one over the JSON API.</p>`
    return
  }

  list.innerHTML = messages.map((message) => `
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

  const body = {
    message: {
      author: form.elements.author.value,
      body: form.elements.body.value
    }
  }

  try {
    const response = await fetch("/api/messages", {
      method: "POST",
      headers: {
        Accept: "application/json",
        "Content-Type": "application/json",
        "X-CSRF-Token": csrfToken()
      },
      body: JSON.stringify(body)
    })

    if (!response.ok) {
      const payload = await response.json()
      throw new Error(payload.error || `HTTP ${response.status}`)
    }

    form.reset()
    await loadMessages()
  } catch (errorValue) {
    if (error) error.textContent = `${errorValue.name || "Error"}: ${errorValue.message || errorValue}`
  }
}

document.addEventListener("turbo:load", () => {
  const status = document.getElementById("webtransport-status")
  if (status) status.textContent = "WebTransport" in window ? "available" : "not available"

  loadMessages().catch((error) => {
    writeTo("messages-error", `${error.name || "Error"}: ${error.message || error}`, { append: false })
  })
})
