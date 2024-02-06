require_relative 'base'

module SocketPromise
  class Handle < BaseHandle
    attr_reader :read_io, :write_io

    def initialize(waiter, num)
      super
      @read_io, @write_io = IO.pipe
    end

    def complete!
      super do
        @value = nil
      end
    end

    def ready!(value)
      super do |v|
        @value = v
        @write_io.puts(v)
      end
    end

    def ready?
      @value
    end

    def stop!
      @write_io.puts('stop')
      @write_io.close
      sleep 0.02
      @read_io.close
    end
  end

  class Waiter < BaseWaiter
    Handle = SocketPromise::Handle

    def wait(handle)
      handle.complete!.read_io.gets
      handle
    end

    def stop!
      super
      handles.each(&:stop!)
    end
  end
end
