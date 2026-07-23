class DropRoom
  @subscribers = []
  @sessions = []
  @mutex = Mutex.new

  class << self
    def join(session)
      count = mutex.synchronize do
        sessions << session unless sessions.include?(session)
        sessions.size
      end
      puts "[DropRoom] join sessions=#{count}" if ENV["DROP_DEBUG"]
    end

    def leave(session)
      sessions_count = nil
      subscribers_count = nil
      closed = []

      mutex.synchronize do
        sessions.delete(session)
        closed = subscribers.select { |subscriber| subscriber[:session] == session }
        subscribers.delete_if { |subscriber| subscriber[:session] == session }
        sessions_count = sessions.size
        subscribers_count = subscribers.size
      end

      closed.each { |subscriber| close_queue(subscriber[:queue]) }
      puts "[DropRoom] leave sessions=#{sessions_count} subscribers=#{subscribers_count}" if ENV["DROP_DEBUG"]
    end

    def broadcast_datagram(data, except: nil)
      current_sessions = mutex.synchronize { sessions.dup }
      puts "[DropRoom] datagram sessions=#{current_sessions.size} except=#{except&.object_id}" if ENV["DROP_DEBUG"]

      current_sessions.each do |session|
        next if session == except

        session.send_datagram(data) if session.open?
      rescue => error
        puts "[DropRoom] datagram failed #{error.class}: #{error.message}" if ENV["DROP_DEBUG"]
        leave(session)
      end
    end

    def subscribe(session: nil)
      queue = Queue.new
      count = mutex.synchronize do
        subscribers << { queue: queue, session: session }
        subscribers.size
      end
      puts "[DropRoom] subscribe count=#{count}" if ENV["DROP_DEBUG"]
      queue
    end

    def unsubscribe(queue)
      count = mutex.synchronize do
        subscribers.delete_if { |subscriber| subscriber[:queue] == queue }
        subscribers.size
      end
      puts "[DropRoom] unsubscribe count=#{count}" if ENV["DROP_DEBUG"]
      close_queue(queue)
    end

    def broadcast(payload)
      current_subscribers = mutex.synchronize { subscribers.dup }
      puts "[DropRoom] broadcast type=#{payload[:type] || payload['type']} subscribers=#{current_subscribers.size}" if ENV["DROP_DEBUG"]

      current_subscribers.each do |subscriber|
        queue = subscriber[:queue]
        queue << payload unless queue.closed?
      rescue ClosedQueueError
        unsubscribe(queue)
      end
    end

    private
      attr_reader :subscribers, :sessions, :mutex

      def close_queue(queue)
        queue.close unless queue.closed?
      end
  end
end
