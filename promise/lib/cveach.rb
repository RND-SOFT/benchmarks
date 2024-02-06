require_relative 'base'

module ConditionVariableEachPromise
  class Handle < BaseHandle
    attr_reader :value, :cv

    def initialize(waiter, num)
      super
      @cv = ConditionVariable.new
    end

    def complete!
      super do
        @cv = ConditionVariable.new
        @value = nil
      end
    end

    def ready!(value)
      super do |v|
        @value = v
        waiter.mutex.synchronize do
          @cv.signal
        end
      end
    end

    def ready?
      @value
    end

    def stop!
      @cv.signal
    end
  end

  class Waiter < BaseWaiter
    Handle = ConditionVariableEachPromise::Handle
    attr_reader :mutex

    def initialize
      super
      @mutex = Mutex.new
    end

    def wait(handle)
      @mutex = Mutex.new
      @mutex.synchronize do
        handle.complete!
        handle.cv.wait(@mutex) while running? && !handle.ready?
        handle
      end
    end

    def stop!
      @mutex.synchronize do
        super
        handles.each(&:stop!)
      end
    end
  end
end
