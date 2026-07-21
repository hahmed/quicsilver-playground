import "@hotwired/turbo-rails"
import "controllers"
import { connect, openMessageStream } from "quicsilver_web_transport"

function output() {
  return document.getElementById("transport-output")
}

function log(message) {
  const element = output()
  if (!element) return

  element.textContent += `${new Date().toISOString()} ${message}\n`
}

function clearLog() {
  const element = output()
  if (!element) return

  element.textContent = ""
}

window.clearTransportLog = clearLog

window.runEcho = async function () {
  clearLog()

  try {
    if (!("WebTransport" in window)) {
      log("WebTransport is not available in this browser")
      return
    }

    const url = new URL("/transports/echo", window.location.href)
    log(`connecting to ${url}`)

    const transport = await connect(url.toString())
    log("transport ready")

    transport.closed.then(
      () => log("transport closed cleanly"),
      (error) => log(`transport closed with error: ${error}`)
    )

    const stream = await openMessageStream(transport)
    const message = { hello: "world", at: Date.now() }

    log(`sending ${JSON.stringify(message)}`)
    await stream.send(message)
    await stream.close()

    log("waiting for echo")
    for await (const response of stream.responses()) {
      log(`received ${JSON.stringify(response)}`)
      break
    }

    transport.close()
  } catch (error) {
    console.error(error)
    log(`failed: ${error.name || "Error"}: ${error.message || error}`)
  }
}

document.addEventListener("turbo:load", () => {
  const status = document.getElementById("webtransport-status")
  if (status) status.textContent = "WebTransport" in window ? "available" : "not available"
})
