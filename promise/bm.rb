#!/bin/env ruby

require 'rubygems'
require 'bundler'
require 'bundler/setup'
Bundler.require(:default)

require 'benchmark'

require_relative 'lib/queue'
require_relative 'lib/queue_each'
require_relative 'lib/socket'
require_relative 'lib/socket_each'
require_relative 'lib/promise'
require_relative 'lib/cvsingle'
require_relative 'lib/cveach'
require_relative 'lib/thread_promise'

class Worker
  attr_reader :waiter, :num, :handle, :result

  def initialize(waiter, num)
    @waiter = waiter
    @num = num
    @handle = waiter.create_handle(num)
    @result = 0

    @thread = Thread.new(@waiter) do |w|
      while w.running?
        h = w.wait(handle)
        break if w.stop?

        @result += 1 if h.ready?
      end
    rescue StandardError => e
      puts "Critical Error: #{e}\n#{e.backtrace}"
      exit!(5)
    end
  end

  def stop!
    @thread.join
  end

  def ready!
    v = @handle.ready!(num)
    # sanity check
    return unless v != num

    puts "Sanity check failed: returned value[#{v}] != #{num}"
    exit!(42)
  end
end

class Runner
  attr_reader :klass, :concurrency, :count

  def initialize(klass:, concurrency:, count:)
    @klass = klass
    @concurrency = concurrency
    @count = count
    @cases = {}

    @waiter, @workers = prepare_bechmark
  end

  def prepare_bechmark
    waiter = klass::Waiter.new
    workers = concurrency.times.map { |i| Worker.new(waiter, i) }
    [waiter, workers]
  end

  def run
    c = 0
    while c < count

      idx = c % concurrency
      worker = @workers[idx]
      worker.ready!
      c += 1
    end
    @workers.map(&:result).sum
  end

  def stop
    @waiter.stop!
    @workers.each(&:stop!)
    @workers = nil
    @waiter = nil
  end
end

THREADS = ENV.fetch('THREADS', 10).to_i
COUNT = ENV.fetch('COUNT', 900_000).to_i
CASES = [QueuePromise, QueuePromiseEach, SocketPromise, SocketPromiseEach, ConditionVariableEachPromise,
         RubyThreadPromise, ConcurrentRubyPromise, ConditionVariableSinglePromise]
# CASES = [QueuePromise, QueuePromiseEach]

max_bm_length = CASES.map { |klass| klass.to_s.size }.max

def without_gc
  GC.start
  GC.disable
  yield
ensure
  GC.enable
  GC.start
end

def formatted(width, text)
  "#{''.ljust(width)}#{text}"
end

yjit = RubyVM::YJIT.enabled? rescue false
puts "    ===== Benchmark[RUBY=#{RUBY_VERSION} THREADS=#{THREADS} COUNT=#{COUNT}] YJIT=#{yjit}] ====="
puts formatted(max_bm_length, '      user     system      total         real')

CASES.each do |klass|
  # warmup
  if yjit
    @runner = Runner.new(klass: klass, concurrency: THREADS, count: COUNT)
    sleep 2
    @result = @runner.run
    puts "Unexpected result! #{@result.inspect} != #{COUNT}" if @result != COUNT
    without_gc do
      @runner.stop
      @runner = nil
    end
  end

  @runner = Runner.new(klass: klass, concurrency: THREADS, count: COUNT)
  sleep 2

  without_gc do
    r = Benchmark.measure(klass.to_s) do
      @result = @runner.run
    end
    ips = COUNT / r.real
    print r.label.rjust(max_bm_length)
    puts r.format(Benchmark::FORMAT.strip + "   %s ips\n", ips.round(1))
  end

  puts "Unexpected result! #{@result.inspect} != #{COUNT}" if @result != COUNT
  @runner.stop
  @runner = nil
end
