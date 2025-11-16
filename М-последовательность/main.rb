# frozen_string_literal: true
# LFSR генератор и тесты
# Запуск: ruby lfsr_analysis.rb

require 'set'

# -----------------------
# LFSR (Linear Feedback Shift Register) генератор
# -----------------------
class LFSR
  attr_reader :state, :taps, :size
  
  def initialize(initial_state, taps, size)
    @state = initial_state
    @taps = taps  # индексы отводов (с 0, где 0 - младший бит)
    @size = size
    # Проверка, что начальное состояние не нулевое
    raise "Initial state cannot be zero" if @state == 0
  end
  
  def next_bit
    # Вычисляем обратную связь (XOR всех отводов)
    feedback = 0
    @taps.each { |tap| feedback ^= (@state >> tap) & 1 }
    
    # Сдвигаем влево и добавляем обратную связь в младший бит
    output = (@state >> (@size - 1)) & 1
    @state = ((@state << 1) | feedback) & ((1 << @size) - 1)
    output
  end
  
  def next_number(bits = 32)
    # Генерируем число из нескольких битов
    num = 0
    bits.times { num = (num << 1) | next_bit }
    num.to_f / (1 << bits)  # Нормализуем к [0,1)
  end
end

# -----------------------
# Анализ периода LFSR
# -----------------------
def lfsr_period(initial_state, taps, size)
  lfsr = LFSR.new(initial_state, taps, size)
  states = {}
  current_state = initial_state
  steps = 0
  
  while !states.key?(current_state)
    states[current_state] = steps
    lfsr.next_bit
    current_state = lfsr.state
    steps += 1
    
    # Защита от бесконечного цикла
    break if steps > (1 << size) * 2
  end
  
  period = steps - states[current_state]
  { period: period, steps_to_repeat: steps, initial_state: initial_state }
end

# -----------------------
# Вспомогательные функции для статистики
# -----------------------
def norm_inv(p)
  raise ArgumentError, "p must be in (0,1)" if p <= 0.0 || p >= 1.0
  
  a1 = -3.969683028665376e+01
  a2 =  2.209460984245205e+02
  a3 = -2.759285104469687e+02
  a4 =  1.383577518672690e+02
  a5 = -3.066479806614716e+01
  a6 =  2.506628277459239e+00

  b1 = -5.447609879822406e+01
  b2 =  1.615858368580409e+02
  b3 = -1.556989798598866e+02
  b4 =  6.680131188771972e+01
  b5 = -1.328068155288572e+01

  c1 = -7.784894002430293e-03
  c2 = -3.223964580411365e-01
  c3 = -2.400758277161838e+00
  c4 = -2.549732539343734e+00
  c5 =  4.374664141464968e+00
  c6 =  2.938163982698783e+00

  d1 = 7.784695709041462e-03
  d2 = 3.224671290700398e-01
  d3 = 2.445134137142996e+00
  d4 = 3.754408661907416e+00

  plow = 0.02425
  phigh = 1 - plow

  if p < plow
    q = Math.sqrt(-2 * Math.log(p))
    (((((c1 * q + c2) * q + c3) * q + c4) * q + c5) * q + c6) /
      ((((d1 * q + d2) * q + d3) * q + d4) * q + 1.0)
  elsif p <= phigh
    q = p - 0.5
    r = q * q
    (((((a1 * r + a2) * r + a3) * r + a4) * r + a5) * r + a6) * q /
      (((((b1 * r + b2) * r + b3) * r + b4) * r + b5) * r + 1.0)
  else
    q = Math.sqrt(-2 * Math.log(1 - p))
    -(((((c1 * q + c2) * q + c3) * q + c4) * q + c5) * q + c6) /
      ((((d1 * q + d2) * q + d3) * q + d4) * q + 1.0)
  end
end

def chi2_quantile(p, v)
  z = norm_inv(p)
  t = 1.0 - 2.0 / (9.0 * v) + z * Math.sqrt(2.0 / (9.0 * v))
  v * (t ** 3)
end

# -----------------------
# Тестовые функции (адаптированные для LFSR)
# -----------------------
def frequency_test_lfsr(lfsr, n = 1000, k = 10, alpha_lo = 0.1, alpha_hi = 0.9)
  counts = Array.new(k, 0)
  
  n.times do
    r = lfsr.next_number
    idx = [(r * k).to_i, k - 1].min
    counts[idx] += 1
  end

  expected = n.to_f / k.to_f
  chi2 = counts.reduce(0.0) { |s, obs| s + ((obs - expected) ** 2) / expected }
  df = k - 1

  left = chi2_quantile(alpha_lo, df)
  right = chi2_quantile(alpha_hi, df)

  pass = (chi2 > left) && (chi2 < right)

  {
    chi2: chi2,
    df: df,
    counts: counts,
    expected: expected,
    left_crit: left,
    right_crit: right,
    pass: pass
  }
end

def serial_test_lfsr(lfsr, n = 100000, d = 8, alpha_lo = 0.05, alpha_hi = 0.95)
  u_sequence = []
  
  n.times do
    r = lfsr.next_number
    u_i = (d * r).to_i
    u_sequence << u_i
  end

  pairs_count = Hash.new(0)
  total_pairs = 0
  
  (0...u_sequence.length - 1).each do |i|
    two_digit_number = u_sequence[i] * d + u_sequence[i + 1]
    pairs_count[two_digit_number] += 1
    total_pairs += 1
  end

  expected = total_pairs.to_f / (d * d)
  chi2 = 0.0
  
  (0...d*d).each do |pair_value|
    observed = pairs_count[pair_value] || 0
    chi2 += ((observed - expected) ** 2) / expected
  end

  df = d * d - 1

  left = chi2_quantile(alpha_lo, df)
  right = chi2_quantile(alpha_hi, df)

  pass = (chi2 > left) && (chi2 < right)

  {
    chi2: chi2,
    df: df,
    total_pairs: total_pairs,
    expected_per_pair: expected,
    pass: pass
  }
end

def poker_test_lfsr(lfsr, n = 10000, d = 10)
  u_sequence = []
  
  n.times do
    r = lfsr.next_number
    u_i = (d * r).to_i
    u_sequence << u_i
  end

  groups = []
  (0...u_sequence.length).step(5) do |i|
    group = u_sequence[i, 5]
    groups << group if group.length == 5
  end

  class_counts = Array.new(7, 0)
  
  groups.each do |group|
    freq = Hash.new(0)
    group.each { |digit| freq[digit] += 1 }
    
    case freq.values.sort.reverse
    when [5]           # a,a,a,a,a
      class_counts[6] += 1
    when [4, 1]        # a,a,a,a,b  
      class_counts[5] += 1
    when [3, 2]        # a,a,a,b,b
      class_counts[4] += 1
    when [3, 1, 1]     # a,a,a,b,c
      class_counts[3] += 1
    when [2, 2, 1]     # a,a,b,b,c
      class_counts[2] += 1
    when [2, 1, 1, 1]  # a,a,b,c,d
      class_counts[1] += 1
    when [1, 1, 1, 1, 1] # a,b,c,d,e
      class_counts[0] += 1
    end
  end

  total_groups = groups.length
  
  theoretical_probs = [
    (d-1)*(d-2)*(d-3)*(d-4).to_f / (d**4),  # P1
    10 * (d-1)*(d-2)*(d-3).to_f / (d**4),   # P2  
    15 * (d-1)*(d-2).to_f / (d**4),         # P3
    10 * (d-1)*(d-2).to_f / (d**4),         # P4
    10 * (d-1).to_f / (d**4),               # P5
    5 * (d-1).to_f / (d**4),                # P6
    1.0 / (d**4)                            # P7
  ]

  chi2 = 0.0
  7.times do |i|
    expected = total_groups * theoretical_probs[i]
    observed = class_counts[i]
    chi2 += ((observed - expected) ** 2) / expected if expected > 0
  end

  df = 6
  
  left = chi2_quantile(0.1, df)
  right = chi2_quantile(0.9, df)
  
  pass = (chi2 > left) && (chi2 < right)

  {
    chi2: chi2,
    df: df,
    class_counts: class_counts,
    total_groups: total_groups,
    pass: pass
  }
end

def correlation_test_lfsr(lfsr, n = 10000)
  sequence = []
  
  n.times do
    sequence << lfsr.next_number
  end

  sum_x = 0.0
  sum_y = 0.0
  sum_xy = 0.0
  sum_x2 = 0.0
  sum_y2 = 0.0

  (0...n-1).each do |i|
    x_i = sequence[i]
    y_i = sequence[i + 1]
    
    sum_x += x_i
    sum_y += y_i
    sum_xy += x_i * y_i
    sum_x2 += x_i * x_i
    sum_y2 += y_i * y_i
  end

  numerator = n * sum_xy - sum_x * sum_y
  denominator = Math.sqrt((n * sum_x2 - sum_x * sum_x) * (n * sum_y2 - sum_y * sum_y))
  
  r = denominator.zero? ? 0.0 : numerator / denominator

  term = (2.0 / (n - 1)) * Math.sqrt(n * (n - 3).to_f / (n + 1))
  lower_bound = (1.0 / (n - 1)) - term
  upper_bound = (1.0 / (n - 1)) + term

  pass = (r >= lower_bound) && (r <= upper_bound)

  {
    correlation: r,
    lower_bound: lower_bound,
    upper_bound: upper_bound,
    pass: pass
  }
end

def runs_test_lfsr(lfsr, n = 10000)
  sequence = []
  
  n.times do
    sequence << (lfsr.next_number > 0.5 ? 1 : 0)
  end

  runs = 1
  (1...n).each do |i|
    runs += 1 if sequence[i] != sequence[i-1]
  end

  n1 = sequence.count(1)
  n0 = sequence.count(0)
  
  expected_runs = (2 * n0 * n1).to_f / n + 1
  variance_runs = (2 * n0 * n1 * (2 * n0 * n1 - n)).to_f / (n * n * (n - 1))
  
  z = (runs - expected_runs) / Math.sqrt(variance_runs)
  
  pass = z.abs < 1.96

  {
    runs: runs,
    expected_runs: expected_runs,
    z_score: z,
    pass: pass
  }
end

# -----------------------
# Известные примитивные полиномы для LFSR
# -----------------------
lfsr_examples = [
  { 
    name: "x⁵ + x² + 1 (пример из методички)",
    size: 5,
    taps: [4, 1],  # Отводы: 5-й и 2-й биты
    initial_state: 0b00001
  },
  { 
    name: "x⁷ + x⁶ + 1",
    size: 7,
    taps: [6, 5],
    initial_state: 0b0000001
  },
  { 
    name: "x⁸ + x⁶ + x⁵ + x⁴ + 1",
    size: 8,
    taps: [7, 5, 4, 3],
    initial_state: 0b00000001
  },
  { 
    name: "x¹⁶ + x¹⁴ + x¹³ + x¹¹ + 1",
    size: 16,
    taps: [15, 13, 12, 10],
    initial_state: 0b0000000000000001
  },
  { 
    name: "x²⁰ + x¹⁹ + x¹⁶ + x¹⁴ + 1 (быстрый тест)",
    size: 20,
    taps: [19, 18, 15, 13],  # Отводы: 20, 19, 16, 14
    initial_state: 0b00000000000000000001
  },
  { 
    name: "x²⁴ + x²³ + x²² + x¹⁷ + 1 (оптимальный)",
    size: 24,
    taps: [23, 22, 21, 16],  # Отводы: 24, 23, 22, 17
    initial_state: 0b000000000000000000000001
  }
]

# -----------------------
# Основной анализ
# -----------------------
puts "=== АНАЛИЗ LFSR ГЕНЕРАТОРОВ ==="
puts

summary = []

lfsr_examples.each do |example|
  puts "=" * 80
  puts "Анализ: #{example[:name]}"
  puts "Размер регистра: #{example[:size]}"
  puts "Отводы: #{example[:taps].map { |t| t + 1 }.join(', ')}"
  puts "Начальное состояние: 0b#{example[:initial_state].to_s(2)}"
  
  # Анализ периода
  period_info = lfsr_period(example[:initial_state], example[:taps], example[:size])
  expected_period = (1 << example[:size]) - 1
  puts "Период: #{period_info[:period]}"
  puts "Ожидаемый период (2^#{example[:size]} - 1): #{expected_period}"
  puts "Соответствует ожидаемому: #{period_info[:period] == expected_period}"
  
  # Создаем LFSR для тестов
  lfsr = LFSR.new(example[:initial_state], example[:taps], example[:size])
  
  # Частотный тест
  freq = frequency_test_lfsr(lfsr, 10000, 10)
  puts "Частотный тест: χ²=#{freq[:chi2].round(4)}, прошёл: #{freq[:pass]}"
  
  # Сериальный тест
  serial = serial_test_lfsr(lfsr, 100000, 8)
  puts "Сериальный тест: χ²=#{serial[:chi2].round(4)}, прошёл: #{serial[:pass]}"
  
  # Покер-тест
  poker = poker_test_lfsr(lfsr, 10000, 10)
  puts "Покер-тест: χ²=#{poker[:chi2].round(4)}, прошёл: #{poker[:pass]}"
  
  # Корреляционный тест
  corr = correlation_test_lfsr(lfsr, 10000)
  puts "Корреляционный тест: R=#{corr[:correlation].round(6)}, прошёл: #{corr[:pass]}"
  
  # Интервальный тест
  runs = runs_test_lfsr(lfsr, 10000)
  puts "Интервальный тест: Z=#{runs[:z_score].round(4)}, прошёл: #{runs[:pass]}"
  
  puts
  
  summary << {
    name: example[:name],
    size: example[:size],
    period: period_info[:period],
    expected_period: expected_period,
    period_ok: period_info[:period] == expected_period,
    freq_pass: freq[:pass],
    serial_pass: serial[:pass],
    poker_pass: poker[:pass],
    correlation_pass: corr[:pass],
    runs_pass: runs[:pass]
  }
end

# Сводная таблица
puts "=" * 100
puts "СВОДНАЯ ТАБЛИЦА РЕЗУЛЬТАТОВ LFSR"
puts "=" * 100
headers = ["Полином", "Разм", "Период", "Част", "Сериал", "Покер", "Корр", "Интерв"]
puts "%-30s | %-4s | %-22s | %-5s | %-6s | %-5s | %-4s | %-6s" % headers
puts "-" * 100

summary.each do |s|
  period_display = s[:period_ok] ? "#{s[:period]}/#{s[:expected_period]} ✓" : "#{s[:period]}/#{s[:expected_period]} ✗"
  
  # Обрезаем длинные названия
  name = s[:name].length > 29 ? s[:name][0..26] + "..." : s[:name]
  
  puts "%-30s | %-4s | %-22s | %-5s | %-6s | %-5s | %-4s | %-6s" %
       [ name, 
         s[:size],
         period_display,
         s[:freq_pass] ? "✓" : "✗",
         s[:serial_pass] ? "✓" : "✗",
         s[:poker_pass] ? "✓" : "✗",
         s[:correlation_pass] ? "✓" : "✗",
         s[:runs_pass] ? "✓" : "✗" ]
end

# Итоговая статистика
puts "\n" + "=" * 80
puts "ИТОГОВАЯ СТАТИСТИКА"
puts "=" * 80
total_generators = summary.size
passed_period = summary.count { |s| s[:period_ok] }
passed_freq = summary.count { |s| s[:freq_pass] }
passed_serial = summary.count { |s| s[:serial_pass] }
passed_poker = summary.count { |s| s[:poker_pass] }
passed_corr = summary.count { |s| s[:correlation_pass] }
passed_runs = summary.count { |s| s[:runs_pass] }
passed_all_tests = summary.count { |s| s[:freq_pass] && s[:serial_pass] && s[:poker_pass] && s[:correlation_pass] && s[:runs_pass] }

puts "Всего генераторов: #{total_generators}"
puts "Имеют правильный период: #{passed_period}/#{total_generators}"
puts "Прошли частотный тест: #{passed_freq}/#{total_generators}"
puts "Прошли сериальный тест: #{passed_serial}/#{total_generators}"
puts "Прошли покер-тест: #{passed_poker}/#{total_generators}"
puts "Прошли корреляционный тест: #{passed_corr}/#{total_generators}"
puts "Прошли интервальный тест: #{passed_runs}/#{total_generators}"
puts "Прошли ВСЕ тесты: #{passed_all_tests}/#{total_generators}"

# Лучшие генераторы
good_generators = summary.select { |s| s[:period_ok] && s[:freq_pass] && s[:serial_pass] && s[:poker_pass] }
puts "\nЛучшие генераторы (правильный период + прошли основные тесты):"
good_generators.each do |gen|
  puts "  - #{gen[:name]}"
end

puts "\nГотово!"