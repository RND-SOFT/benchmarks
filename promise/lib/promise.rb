require_relative 'base'

require 'concurrent/promise'

module ConcurrentRubyPromise
  class Handle < BaseHandle
    attr_reader :promise

    def initialize(waiter, num)
      super
      # первичная инициализация
      @promise = Concurrent::Promises.fulfilled_future(nil)
    end

    def complete!
      super do
        @promise = Concurrent::Promises.resolvable_future
      end
    end

    def ready!(value)
      super do |v|
        @promise.fulfill(v)
      end
    end

    def ready?
      @promise.fulfilled? && @promise.value
    end

    def stop!
      @promise.fulfill(nil)
    end
  end

  class Waiter < BaseWaiter
    Handle = ConcurrentRubyPromise::Handle

    def wait(handle)
      handle.complete!.promise.wait
      handle
    end

    def stop!
      super
      handles.each(&:stop!)
    end
  end
end
