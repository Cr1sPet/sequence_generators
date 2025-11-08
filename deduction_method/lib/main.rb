# frozen_string_literal: true
require_relative "lcg"
require_relative "serial_test"
require_relative "poker_test"
require_relative "correlation_test"
require_relative "gap_test"

rng = LCG.new(seed: 123456, a: 1103515245, c: 12345, m: 2**31)
samples = rng.generate(10_000)

puts "=== Serial test ==="
res = serial_test(samples, d: 2, bins: 20)
puts "chi2=#{res[:chi2].round(4)}, p=#{res[:p_value].round(6)}"

puts "\n=== Poker test ==="
poker = poker_test(samples)
puts "chi2=#{poker[:chi2].round(4)}, p=#{poker[:p_value].round(6)}"

puts "\n=== Correlation test ==="
corr = correlation_test(samples)
corr[:results].each { |lag, r| puts "lag=#{lag}: rho=#{r[:rho].round(5)}, p=#{r[:p_value].round(5)}" }

puts "\n=== Gap test ==="
gap = gap_test(samples)
puts "chi2=#{gap[:chi2].round(4)}, p=#{gap[:p_value].round(6)}"
