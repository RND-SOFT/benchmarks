#!/bin/env ruby

# rubocop:disable Style/RescueModifier

require 'rubygems'
require 'bundler'
require 'bundler/setup'
Bundler.require(:default)

require 'benchmark'

require_relative 'lib/utils'
require_relative 'lib/promises'

STDOUT.sync = true

YJIT = RubyVM::YJIT.enabled? rescue false
THREADS = ENV.fetch('THREADS', 10).to_i
COUNT = ENV.fetch('COUNT', 900_000).to_i
CASES = [Promises::Queue, Promises::ConditionVariable, Promises::Thread, Promises::Socket,
         Promises::ConcurrentRuby].freeze

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

puts "    ===== [#{Process.pid}] Benchmark[RUBY=#{RUBY_VERSION} THREADS=#{THREADS} COUNT=#{COUNT}] YJIT=#{YJIT}] ====="
puts formatted(max_bm_length, '      user     system      total         real')

CASES.each do |klass|
  # warmup
  begin
    @runner = Runner.new(klass: klass, concurrency: THREADS, count: COUNT)
    sleep 2
    @runner.run
    @result = @runner.result
    puts "Unexpected result! #{@result.inspect} != #{COUNT}" if (@result - COUNT).abs > 10
    without_gc do
      @runner.shutdown!
      @runner = nil
    end
  end

  @runner = Runner.new(klass: klass, concurrency: THREADS, count: COUNT)
  sleep 2

  without_gc do
    r = Benchmark.measure(klass.to_s) do
      @runner.run
    end
    sleep 2
    @result = @runner.result
    ips = COUNT / r.real
    print r.label.rjust(max_bm_length)
    puts r.format(Benchmark::FORMAT.strip + "   %s ips\n", ips.round(1))
  end

  puts "Unexpected result! #{@result.inspect} != #{COUNT}" if (@result - COUNT).abs > 10
  @runner.shutdown!
  @runner = nil
end
