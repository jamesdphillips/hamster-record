require "./config/application"
Bundler.require(:bench)
require "./config/initializers/contracts"
require "./lib/hamster/record"
require "functional/record"
require "concurrent/immutable_struct"
require "hamsterdam"
require "memory_profiler"

#
# Simple Benchmarks for Hamster::Record

# Sample Struct/Records

example = { meowmix: 123, woof: :woof }.freeze
Catnip = Struct.new(:meowmix, :woof)
Initial = Class.new(Hamster::Hash)
FRecord = Functional::Record.new(:meowmix, :woof)
HRecord = Hamster::Record.define(:meowmix, :woof).freeze
HRecordDefault = Hamster::Record.define do
  field :woof, default: :wood
  field :meowmix
end
HRecordTypes = Hamster::Record.define do
  field :woof, Symbol
  field :meowmix, Fixnum
end
FRecordTypes = Functional::Record.new(meowmix: Fixnum, woof: Symbol)
CStruct = Concurrent::ImmutableStruct.new(:meowmix, :woof)
TheWire = Hamsterdam::Struct.define(:meowmix, :woof)

class TestForward
  extend Forwardable
  def_delegators :@args, :[], :fetch, :merge
  def initialize(args)
    @args = args
  end
end

#
# Memory

def test_mem(name, &block)
  report = MemoryProfiler.report do
    100_000.times { block.call }
  end
  puts "-----------------------------------", name, "-----------------------------------"
  puts "Total allocated: #{(report.total_allocated_memsize.bytes / 1.megabyte.to_f).round(3)} MBs"
  puts "Total objects: #{report.total_allocated} objects"
end

test_mem("PORO", &-> { Initial.new(example) })
test_mem("ConcurrentRuby Struct", &-> { CStruct.new(123, :woof) })
test_mem("Hasmter Record", &-> { HRecord.new(example) })
test_mem("FunctionalRuby Record", &-> { FRecord.new(example) })
test_mem("Hamsterdam Struct", &-> { TheWire.new(example) })

#
# Benchmark instantiation

COUNT = 1_000_000

example = { meowmix: 123, woof: :woof }.freeze
default_example = { meowmix: 123 }.freeze

def bench_for(bench, name, op)
  bench.report(name) do
    COUNT.times { op.call }
  end
end

puts "-----------------------------------", "Instantiation", "-----------------------------------"

Benchmark.bm(25) do |x|
  bench_for(x, "class:", -> { TestForward.new(example) })
  bench_for(x, "struct:", -> { Catnip.new(123, :woof) })
  bench_for(x, "concurrent-ruby struct:", -> { CStruct.new(123, :woof) })
  bench_for(x, "subclassed hamster hash:", -> { Initial.new(example) })
  bench_for(x, "hamster record:", -> { HRecord.new(example) })
  bench_for(x, "hamster record w/ default:", -> { HRecordDefault.new(default_example) })
  bench_for(x, "hamster record w/ types:", -> { HRecordTypes.new(example) })
  bench_for(x, "hamster:", -> { Hamster::Hash.new(example) })
  bench_for(x, "functional-ruby record:", -> { FRecord.new(example) })
  bench_for(x, "^^ w/ types:", -> { FRecordTypes.new(example) })
  bench_for(x, "openstruct:", -> { OpenStruct.new(example) })
  bench_for(x, "hamsterdam:", -> { TheWire.new(example) })
end
