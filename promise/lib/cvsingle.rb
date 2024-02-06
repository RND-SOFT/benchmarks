require_relative 'base'

module ConditionVariableSinglePromise
  class Handle < BaseHandle
    attr_reader :value

    def initialize(waiter, num)
      super
    end

    def complete!
      super do
        @value = nil
      end
    end

    def ready!(value)
      super do |v|
        @value = v
        waiter.wake_all
      end
    end

    def ready?
      @value
    end
  end

  class Waiter < BaseWaiter
    Handle = ConditionVariableSinglePromise::Handle

    attr_reader :cv, :mutex

    def initialize
      super
      @mutex = Mutex.new
      @cv = ConditionVariable.new
    end

    def wait(handle)
      @mutex.synchronize do
        handle.complete!
        @cv.wait(@mutex) while running? && !handle.ready?
        handle
      end
    end

    def wake_all
      @mutex.synchronize do
        @cv.broadcast
      end
    end

    def stop!
      @mutex.synchronize do
        super
        @cv.broadcast
      end
    end
  end
end
