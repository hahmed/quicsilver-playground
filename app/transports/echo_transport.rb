# frozen_string_literal: true

class EchoTransport < Quicsilver::WebTransport::MessageStreamEndpoint
  codec :json

  def receive(message)
    Rails.logger.info("[EchoTransport] #{message.inspect}")

    {
      echo: message,
      ruby: RUBY_VERSION,
      rails: Rails.version,
      at: Time.current.iso8601
    }
  end
end
