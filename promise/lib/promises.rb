require 'thread/promise'
require 'concurrent/promise'

# rubocop:disable Style/RescueModifier

module Promises
  class Base
    attr_accessor :prepared

    def initialize(prepared, *_args)
      self.prepared = prepared
    end

    def reset
      @value = nil
    end

    def shutdown!
      fulfill(-1) rescue nil
    end
  end

  class Queue < Base
    def initialize(*args)
      super
      @queue = ::Queue.new
    end

    def wait
      @queue.pop
    end

    def fulfill(value)
      @queue.push(value)
    end

    def close!; end
  end

  class Socket < Base
    def initialize(*args)
      super
      @read_io, @write_io = IO.pipe
    end

    def wait
      @read_io.gets rescue nil
      @value
    end

    def fulfill(value)
      @value = value
      @write_io.puts(value) rescue nil
    end

    def close!
      @write_io.close rescue nil
      @read_io.close rescue nil
    end
  end

  class Thread < Base
    def initialize(*args)
      super
      @promise = ::Thread.promise
    end

    def wait
      @promise.value
    end

    def fulfill(value)
      @promise.deliver(value)
    end

    def close!; end
  end

  class ConcurrentRuby < Base
    def initialize(*args)
      super
      @promise = Concurrent::Promises.resolvable_future
    end

    def wait
      @promise.value
    end

    def fulfill(value)
      @promise.fulfill(value)
    end

    def close!; end
  end

  class ConditionVariable < Base
    def initialize(*args)
      super
      @cv = ::ConditionVariable.new
      @mutex = Mutex.new
      @closed = false
    end

    def wait
      @mutex.synchronize do
        @value = nil
        @cv.wait(@mutex) while @value.nil?
        @value
      end
    end

    def fulfill(value)
      @mutex.synchronize do
        @value = value
      end
      @cv.signal
    end

    def close!; end
    # def close!
    #   @closed = true
    #   @cv.signal
    # end
  end
end
