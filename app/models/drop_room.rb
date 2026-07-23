class DropRoom
  @subscribers = []
  @mutex = Mutex.new

  class << self
    def subscribe
      queue = Queue.new
      count = mutex.synchronize do
        subscribers << queue
        subscribers.size
      end
      puts "[DropRoom] subscribe count=#{count}"
      queue
    end

    def unsubscribe(queue)
      count = mutex.synchronize do
        subscribers.delete(queue)
        subscribers.size
      end
      puts "[DropRoom] unsubscribe count=#{count}"
      queue.close unless queue.closed?
    end

    def broadcast(payload)
      current_subscribers = mutex.synchronize { subscribers.dup }
      puts "[DropRoom] broadcast type=#{payload[:type] || payload['type']} subscribers=#{current_subscribers.size}"

      current_subscribers.each do |subscriber|
        subscriber << payload unless subscriber.closed?
      rescue ClosedQueueError
        unsubscribe(subscriber)
      end
    end

    private
      attr_reader :subscribers, :mutex
  end
end
