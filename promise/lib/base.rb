require 'rubygems'
require 'bundler'
require 'bundler/setup'
Bundler.require(:default)

$mx = Mutex.new

# debug helper
module Logable
  def log(msg)
    $mx.synchronize { puts "#{self}: #{msg}" }
  end
end

# base Waiter class
class BaseWaiter
  include Logable

  attr_reader :handles

  def initialize *_args, **_kwargs
    super()
    @stop = false
    @handles = []
  end

  def running?
    !stop?
  end

  def stop?
    @stop
  end

  def stop!
    @stop = true
  end

  def create_handle(num)
    self.class::Handle.new(self, num).tap do |h|
      @handles << h
    end
  end

  def to_s
    "#{self.class}(#{stop?.inspect})"
  end
end

# base handle class
class BaseHandle
  include Logable

  attr_reader :waiter, :num

  def initialize(waiter, num)
    super()
    @waiter = waiter
    @num = num
    @blocker = Queue.new
  end

  def complete!
    need_release_value = ready?
    yield
    @blocker << need_release_value if need_release_value
    self
  end

  def ready!(value)
    yield(value)
    @blocker.pop
  end

  def ready?
    raise 'Unimplemented ready?'
  end

  def stop!; end

  def to_s
    "#{self.class}[#{num}](#{ready?.inspect})"
  end
end
