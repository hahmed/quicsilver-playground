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
      DropRoom.join(session)

      session.on_datagram do |packet|
        spawn { DropRoom.broadcast_datagram(packet, except: session) }
      end

      session.on_stream do |raw_stream|
        spawn { handle_stream(raw_stream) }
      end

      wait_for_session_close
    ensure
      DropRoom.leave(session)
    end

    def handle_stream(raw_stream)
      debug "stream open raw=#{raw_stream.class}"
      stream = Quicsilver::WebTransport::FramedStream.new(raw_stream)
      debug "waiting for first message"
      message = decode(stream.read_message)
      return debug("stream ended before first message") unless message

      debug "message #{message.inspect}"
      Rails.logger.info("[DropTransport] #{message.inspect}")

      if message.fetch("type") == "subscribe"
        debug "enter activity stream"
        Drop::Streams::Activity.call(stream: stream, codec: codec, session: session)
        debug "activity stream returned"
      else
        debug "dispatch command type=#{message['type']}"
        stream.write_message encode(dispatch(message))
        debug "command response written type=#{message['type']}"
        stream.close
        debug "command stream closed type=#{message['type']}"
      end
    rescue KeyError, ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound => error
      debug "handled error #{error.class}: #{error.message}"
      stream&.write_message encode(Drop::Payload.error(error.message))
      stream&.close
    rescue => error
      debug "unhandled error #{error.class}: #{error.message}\n#{error.backtrace&.first(5)&.join("\n")}" 
      Rails.logger.error("[DropTransport] #{error.class}: #{error.message}")
      stream&.write_message encode(Drop::Payload.error(error.message))
      stream&.close
    ensure
      debug "stream ensure"
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

    def debug(message)
      warn "[DropTransport] #{message}" if ENV["DROP_DEBUG"]
    end
end
