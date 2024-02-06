require_relative 'base'

module QueuePromise
  class Handle < BaseHandle
    attr_reader :queue

    def initialize(waiter, num)
      super
      @queue = Queue.new
    end

    def complete!
      super do
        @value = nil
      end
    end

    def ready!(value)
      super do |v|
        @value = v
        @queue << @value
      end
    end

    def ready?
      @value
    end

    def stop!
      @queue << :stop
    end
  end

  class Waiter < BaseWaiter
    Handle = QueuePromise::Handle

    def wait(handle)
      handle.complete!.queue.pop
      handle
    end

    def stop!
      super
      handles.each(&:stop!)
    end
  end
end
