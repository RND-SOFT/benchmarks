# rubocop:disable Style/RescueModifier

$mx = Mutex.new

# debug helper
module Logable
  def log(msg)
    $mx.synchronize { puts "#{self}(#{num})[#{Thread.current.object_id}]: #{msg}" }
  end
end

class Worker
  include Logable
  attr_reader :manager, :num, :result, :thread, :cnt

  def initialize(manager, num)
    @manager = manager
    @num = num
    @result = 0

    @thread = Thread.new(@manager) do |m|
      while running?
        expected = num * 100_000 + @result
        promise = m.do_job_with_promise(expected)
        actual = promise.wait

        break @result unless running?

        if expected != actual
          puts "Worker Sanity check failed: #{expected} != #{actual}"
          exit!(42)
        end

        @result += 1
      end

      @result
    rescue StandardError => e
      log "Critical Error: #{e}\n#{e.backtrace}"
      exit!(5)
    end
  end

  def running?
    !@shutdown && @manager.running?
  end

  def shutdown!
    @shutdown = true
  end
end

class Manager
  include Logable
  attr_reader :num

  def initialize(klass, num, queue)
    @klass = klass
    @num = num
    @queue = queue
    @running = true
  end

  def do_job_with_promise(prepared)
    @promise&.close!

    @promise = @klass.new(prepared)
    @queue << @promise
    @promise
  end

  def shutdown!
    @running = false
    @promise&.fulfill(-1) rescue nil
    Thread.pass
    sleep 0.05
    @promise&.close! rescue nil
    Thread.pass
    sleep 0.05
    @promise&.shutdown! rescue nil
    @promise = nil
  end

  def running?
    @running
  end
end

class Runner
  attr_reader :klass, :concurrency, :count

  def initialize(klass:, concurrency:, count:)
    @klass = klass
    @concurrency = concurrency
    @count = count

    prepare_bechmark
  end

  def prepare_bechmark
    @managers = []
    @workers = []
    @promises = Queue.new

    concurrency.times.map do |i|
      manager = Manager.new(klass, i, @promises)
      @managers << manager
      @workers << Worker.new(manager, i)
    end
  end

  def run
    c = 0
    while c < count

      promise = @promises.pop
      promise.fulfill(promise.prepared)

      c += 1
    end
  end

  def result
    @workers&.each(&:shutdown!)
    @managers&.each(&:shutdown!)
    @workers&.map(&:thread)&.each(&:kill)
    Thread.pass
    @workers&.map(&:result)&.sum
  end

  def shutdown!
    result
    @workers = nil
    @managers = nil
  end
end
