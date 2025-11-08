# frozen_string_literal: true
require_relative "lcg"
require_relative "period_finder"

# Пример: линейный конгруэнтный генератор
lcg = LCG.new(seed: 1, a: 5, c: 3, m: 16)

result = PeriodFinder.find_period(lcg)

puts "=== Определение периода ==="
if result[:period]
  puts "Период последовательности: #{result[:period]}"
  puts "Повторившееся значение: #{result[:repeat_value]}"
else
  puts "Период не найден в заданных пределах."
end
