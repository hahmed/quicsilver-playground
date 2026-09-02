# frozen_string_literal: true

class DropTransport < Quicsilver::WebTransport::Channel
  command "snapshot", to: Drop::Commands::Snapshot
  command "reaction", to: Drop::Commands::Reaction
  command "comment", to: Drop::Commands::Comment
  command "claim", to: Drop::Commands::Claim

  stream "subscribe", to: Drop::Streams::Activity

  datagram do |packet|
    DropRoom.broadcast_datagram(packet, except: session)
  end

  def connect
    DropRoom.join(session)
  end

  def disconnect
    DropRoom.leave(session)
  end
end
