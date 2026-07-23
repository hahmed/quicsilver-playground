# frozen_string_literal: true

class DropTransport < Quicsilver::WebTransport::Endpoint
  COMMANDS = {
    "snapshot" => Drop::Commands::Snapshot,
    "reaction" => Drop::Commands::Reaction,
    "comment" => Drop::Commands::Comment,
    "claim" => Drop::Commands::Claim
  }

  private
    def run
      session.on_stream do |raw_stream|
        spawn { handle_stream(raw_stream) }
      end

      wait_for_session_close
    end

    def handle_stream(raw_stream)
      stream = Quicsilver::WebTransport::FramedStream.new(raw_stream)
      message = decode(stream.read_message)
      return unless message

      puts "[DropTransport] #{message.inspect}"
      Rails.logger.info("[DropTransport] #{message.inspect}")

      if message.fetch("type") == "subscribe"
        Drop::Streams::Activity.call(stream: stream, codec: codec)
      else
        stream.write_message encode(dispatch(message))
        stream.close
      end
    rescue KeyError, ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound => error
      stream&.write_message encode(Drop::Payload.error(error.message))
      stream&.close
    rescue => error
      Rails.logger.error("[DropTransport] #{error.class}: #{error.message}")
      stream&.write_message encode(Drop::Payload.error(error.message))
      stream&.close
    end

    def dispatch(message)
      command = COMMANDS.fetch(message.fetch("type"))
      command.call(message)
    rescue KeyError
      Drop::Payload.error("Unknown drop command: #{message['type']}")
    end

    def decode(payload)
      return unless payload

      codec.decode(payload)
    end

    def encode(payload)
      codec.encode(payload)
    end

    def codec
      @codec ||= Quicsilver::WebTransport::Codec.resolve(:json)
    end
end
