# frozen_string_literal: true
require_relative "lfsr"
require_relative "frequency_test"
require_relative "serial_test"
require_relative "poker_test"
require_relative "correlation_test"
require_relative "gap_test"

# создаем генератор М-последовательности
lfsr = LFSR.new(seed: 1, taps: [5,3], n_bits: 5)
samples = Array.new(5000) { lfsr.next_float(bits: 32) }

puts "=== Frequency test ==="
p frequency_test(samples)

puts "=== Serial test ==="
p serial_test(samples, d:2, bins:10)

puts "=== Poker test ==="
p poker_test(samples, digits:5)

puts "=== Correlation test ==="
p correlation_test(samples, lags: [1,2,5,10])

puts "=== Gap test ==="
p gap_test(samples, a:0.2, b:0.3)
