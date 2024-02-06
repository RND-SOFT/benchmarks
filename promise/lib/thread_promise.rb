require_relative 'base'

require 'thread/promise'

module RubyThreadPromise
  class Handle < BaseHandle
    attr_reader :promise

    def initialize(waiter, num)
      super
      # первичная инициализация
      @promise = Thread.promise.deliver(nil)
    end

    def complete!
      super do
        @promise = Thread.promise
      end
    end

    def ready!(value)
      super do |v|
        @promise.deliver(v)
      end
    end

    def ready?
      @promise.delivered? && @promise.value
    end

    def stop!
      @promise.deliver(nil)
    end
  end

  class Waiter < BaseWaiter
    Handle = RubyThreadPromise::Handle

    def wait(handle)
      handle.complete!.promise.value
      handle
    end

    def stop!
      super
      handles.each(&:stop!)
    end
  end
end
