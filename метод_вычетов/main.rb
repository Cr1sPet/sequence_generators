# frozen_string_literal: true
# main.rb — анализ LCG + частотный тест + сериальный тест
# Запуск: ruby main.rb

require 'set'

# -----------------------
# КОНСТАНТЫ ДЛЯ УПРАВЛЕНИЯ АНАЛИЗОМ
# -----------------------
# Параметры анализа
DEFAULT_LIMIT = 2000
FREQ_N = 10000
FREQ_K = 10

# Управление расчетом MaxPer
CALCULATE_MAXPER_FOR_LARGE_M = true  # Измени на false чтобы отключить для больших m
MAXPER_SAMPLE_SIZE = 1000            # Можно настроить размер выборки

# -----------------------
# Базовая LCG-логика
# -----------------------
def lcg_next(x, a, c, m)
  (a * x + c) % m
end

def gcd(a, b)
  a, b = b, a % b while b != 0
  a.abs
end

def prime_factors(n)
  n = n.abs
  return [] if n <= 1
  f = []
  d = 2
  while d * d <= n
    while (n % d).zero?
      f << d unless f.include?(d)
      n /= d
    end
    d += 1
  end
  f << n if n > 1
  f
end

def theorem1(a, c, m)
  primes = prime_factors(m)
  cond1 = gcd(c, m) == 1
  cond2 = primes.all? { |p| ((a - 1) % p).zero? }
  cond3 = (m % 4 == 0) ? ((a - 1) % 4 == 0) : true
  { cond1: cond1, cond2: cond2, cond3: cond3, all: cond1 && cond2 && cond3, primes: primes }
end

def period_for_seed(seed, a, c, m)
  seen = {}
  x = seed
  i = 0
  loop do
    return i if seen.key?(x)
    seen[x] = true
    x = lcg_next(x, a, c, m)
    i += 1
  end
end

def analyze_params(a, c, m, seed_limit)
  periods = []
  (0..seed_limit).each do |seed|
    periods << period_for_seed(seed, a, c, m)
  end
  maxp = periods.max
  avgp = periods.sum(0.0) / periods.size
  cnt_max = periods.count { |p| p == maxp }
  { max: maxp, avg: avgp, count_max: cnt_max, periods: periods }
end

def analyze_params_optimized(a, c, m, seed_limit)
  # Определяем сколько сидов реально анализировать
  if m > 10000 && !CALCULATE_MAXPER_FOR_LARGE_M
    puts "    [MaxPer: пропущен (большой m)]"
    return { max: "N/A", avg: "N/A", count_max: "N/A", periods: [] }
  elsif m > 10000
    actual_limit = [MAXPER_SAMPLE_SIZE, seed_limit].min
    puts "    [MaxPer: выборка #{actual_limit} сидов]"
  else
    actual_limit = [m - 1, seed_limit].min
  end

  periods = []
  (0..actual_limit).each do |seed|
    periods << period_for_seed(seed, a, c, m)
  end
  maxp = periods.max
  avgp = periods.sum(0.0) / periods.size
  cnt_max = periods.count { |p| p == maxp }
  { max: maxp, avg: avgp, count_max: cnt_max, periods: periods }
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
# Частотный тест (исправленная версия)
# -----------------------
def frequency_test(a, c, m, seed, n = 1000, k = 10, alpha_lo = 0.1, alpha_hi = 0.9)
  counts = Array.new(k, 0)
  x = seed
  n.times do
    x = lcg_next(x, a, c, m)
    r = x.to_f / m.to_f
    idx = [(r * k).to_i, k - 1].min
    counts[idx] += 1
  end

  expected = n.to_f / k.to_f
  chi2 = counts.reduce(0.0) { |s, obs| s + ((obs - expected) ** 2) / expected }
  df = k - 1

  # ИСПРАВЛЕННЫЕ критические значения
  left = chi2_quantile(alpha_lo, df)   # χ²кр(α=0.1)
  right = chi2_quantile(alpha_hi, df)  # χ²кр(α=0.9)

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

# -----------------------
# Улучшенный сериальный тест
# -----------------------
def serial_test(a, c, m, seed, n = 100000, d = 8, alpha_lo = 0.05, alpha_hi = 0.95)
  # Генерируем последовательность u_i = [d * r_i]
  u_sequence = []
  x = seed
  
  n.times do
    x = lcg_next(x, a, c, m)
    r = x.to_f / m.to_f
    u_i = (d * r).to_i  # целое число от 0 до d-1
    u_sequence << u_i
  end

  # Формируем последовательные пары (0,1), (1,2), (2,3)...
  pairs_count = Hash.new(0)
  total_pairs = 0
  
  (0...u_sequence.length - 1).each do |i|
    two_digit_number = u_sequence[i] * d + u_sequence[i + 1]
    pairs_count[two_digit_number] += 1
    total_pairs += 1
  end

  # Проверяем равномерность с помощью критерия χ²
  expected = total_pairs.to_f / (d * d)
  chi2 = 0.0
  
  (0...d*d).each do |pair_value|
    observed = pairs_count[pair_value] || 0
    chi2 += ((observed - expected) ** 2) / expected
  end

  df = d * d - 1

  # Критические значения
  left = chi2_quantile(alpha_lo, df)
  right = chi2_quantile(alpha_hi, df)

  pass = (chi2 > left) && (chi2 < right)

  # Диагностика
  min_count = pairs_count.values.min || 0
  max_count = pairs_count.values.max || 0
  zero_categories = (d * d) - pairs_count.keys.size

  {
    chi2: chi2,
    df: df,
    total_pairs: total_pairs,
    expected_per_pair: expected,
    pairs_count: pairs_count,
    left_crit: left,
    right_crit: right,
    pass: pass,
    d: d,
    min_count: min_count,
    max_count: max_count,
    zero_categories: zero_categories
  }
end


# -----------------------
# Покер-тест
# -----------------------
def poker_test(a, c, m, seed, n = 10000, d = 10)
  # Генерируем последовательность u_i = [d * r_i]
  u_sequence = []
  x = seed
  
  n.times do
    x = lcg_next(x, a, c, m)
    r = x.to_f / m.to_f
    u_i = (d * r).to_i  # целое число от 0 до d-1
    u_sequence << u_i
  end

  # Разбиваем на пятерки
  groups = []
  (0...u_sequence.length).step(5) do |i|
    group = u_sequence[i, 5]
    groups << group if group.length == 5
  end

  # Считаем частоты для 7 классов
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
  
  # Теоретические вероятности по формулам (5.4)-(5.10)
  theoretical_probs = [
    (d-1)*(d-2)*(d-3)*(d-4).to_f / (d**4),  # P1
    10 * (d-1)*(d-2)*(d-3).to_f / (d**4),   # P2  
    15 * (d-1)*(d-2).to_f / (d**4),         # P3
    10 * (d-1)*(d-2).to_f / (d**4),         # P4
    10 * (d-1).to_f / (d**4),               # P5
    5 * (d-1).to_f / (d**4),                # P6
    1.0 / (d**4)                            # P7
  ]

  # Вычисляем χ²
  chi2 = 0.0
  7.times do |i|
    expected = total_groups * theoretical_probs[i]
    observed = class_counts[i]
    chi2 += ((observed - expected) ** 2) / expected if expected > 0
  end

  df = 6  # 7 классов - 1
  
  # Критические значения (α=0.1-0.9 как в частотном тесте)
  left = chi2_quantile(0.1, df)
  right = chi2_quantile(0.9, df)
  
  pass = (chi2 > left) && (chi2 < right)

  {
    chi2: chi2,
    df: df,
    class_counts: class_counts,
    theoretical_probs: theoretical_probs,
    total_groups: total_groups,
    left_crit: left,
    right_crit: right,
    pass: pass
  }
end

# -----------------------
# Корреляционный тест (автокорреляция)
# -----------------------
def correlation_test(a, c, m, seed, n = 10000)
  # Генерируем последовательность
  sequence = []
  x = seed
  
  n.times do
    x = lcg_next(x, a, c, m)
    sequence << x.to_f / m.to_f  # нормализуем к [0,1)
  end

  # Вычисляем коэффициент автокорреляции R₁ (y_i = x_{i+1})
  sum_x = 0.0
  sum_y = 0.0
  sum_xy = 0.0
  sum_x2 = 0.0
  sum_y2 = 0.0

  (0...n-1).each do |i|
    x_i = sequence[i]
    y_i = sequence[i + 1]  # x_{i+1}
    
    sum_x += x_i
    sum_y += y_i
    sum_xy += x_i * y_i
    sum_x2 += x_i * x_i
    sum_y2 += y_i * y_i
  end

  # Формула (5.12)
  numerator = n * sum_xy - sum_x * sum_y
  denominator = Math.sqrt((n * sum_x2 - sum_x * sum_x) * (n * sum_y2 - sum_y * sum_y))
  
  r = denominator.zero? ? 0.0 : numerator / denominator

  # Критические границы для α=0.05
  term = (2.0 / (n - 1)) * Math.sqrt(n * (n - 3).to_f / (n + 1))
  lower_bound = (1.0 / (n - 1)) - term
  upper_bound = (1.0 / (n - 1)) + term

  pass = (r >= lower_bound) && (r <= upper_bound)

  {
    correlation: r,
    lower_bound: lower_bound,
    upper_bound: upper_bound,
    pass: pass,
    n: n
  }
end

# -----------------------
# Интервальный тест (дополнительный)
# -----------------------
def runs_test(a, c, m, seed, n = 10000)
  # Генерируем последовательность
  sequence = []
  x = seed
  
  n.times do
    x = lcg_next(x, a, c, m)
    sequence << (x.to_f / m.to_f > 0.5 ? 1 : 0)  # бинаризуем
  end

  # Считаем серии (runs)
  runs = 1
  current = sequence[0]
  
  (1...n).each do |i|
    runs += 1 if sequence[i] != sequence[i-1]
  end

  # Теоретическое ожидание и дисперсия для серий
  n1 = sequence.count(1)  # количество единиц
  n0 = sequence.count(0)  # количество нулей
  
  expected_runs = (2 * n0 * n1).to_f / n + 1
  variance_runs = (2 * n0 * n1 * (2 * n0 * n1 - n)).to_f / (n * n * (n - 1))
  
  # Z-статистика
  z = (runs - expected_runs) / Math.sqrt(variance_runs)
  
  # Проверка на нормальность (|Z| < 1.96 для α=0.05)
  pass = z.abs < 1.96

  {
    runs: runs,
    expected_runs: expected_runs,
    z_score: z,
    pass: pass,
    n0: n0,
    n1: n1
  }
end

# -----------------------
# Комплексный сериальный тест с разными параметрами
# -----------------------
def comprehensive_serial_test(a, c, m, seed)
  results = []
  
  # Тест 1: Больше данных, меньше категорий
  st1 = serial_test(a, c, m, seed, 100000, 8, 0.05, 0.95)
  results << {test: "N=100000, d=8", pass: st1[:pass], chi2: st1[:chi2]}
  
  # Тест 2: Стандартные параметры но больше данных
  st2 = serial_test(a, c, m, seed, 200000, 10, 0.05, 0.95)
  results << {test: "N=200000, d=10", pass: st2[:pass], chi2: st2[:chi2]}
  
  # Тест 3: Либеральные границы
  st3 = serial_test(a, c, m, seed, 100000, 8, 0.01, 0.99)
  results << {test: "N=100000, d=8, alpha=0.01-0.99", pass: st3[:pass], chi2: st3[:chi2]}
  
  # Возвращаем true если хотя бы один тест прошел
  any_pass = results.any? { |r| r[:pass] }
  
  {results: results, any_pass: any_pass, best_chi2: results.map { |r| r[:chi2] }.min}
end

# -----------------------
# Параметры примеров - улучшенные варианты
# -----------------------
examples = [
  # Хорошие LCG с большими модулями
  { a: 1664525, c: 1013904223, m: 2**32, label: "MMIX LCG (a=1664525, c=1013904223, m=2^32)" },
  { a: 1103515245, c: 12345, m: 2**31, label: "GLIBC LCG (a=1103515245, c=12345, m=2^31)" },
  { a: 16807, c: 0, m: 2147483647, label: "MINSTD (a=16807, c=0, m=2^31-1)" },
  { a: 48271, c: 0, m: 2147483647, label: "MINSTD улучшенный (a=48271, c=0, m=2^31-1)" },
  
  # Оригинальные примеры для сравнения
  { a: 5,  c: 1,   m: 16,  label: "Пример 1 (a=5, c=1, m=16)" },
  { a: 21, c: 1,   m: 32,  label: "Пример 2 (a=21, c=1, m=32)" },
  { a: 13, c: 7,   m: 100, label: "Пример 4 (a=13, c=7, m=100)" }
]

DEFAULT_LIMIT = 2000
FREQ_N = 10000
FREQ_K = 10

puts "\n=== АНАЛИЗ ПАРАМЕТРОВ LCG + ЧАСТОТНЫЙ ТЕСТ + СЕРИАЛЬНЫЙ ТЕСТ ===\n\n"

summary = []

examples.each do |ex|
  a = ex[:a]; c = ex[:c]; m = ex[:m]
  seed_limit = [m - 1, DEFAULT_LIMIT].min

  puts "=" * 80
  puts "Параметры: #{ex[:label]}"
  puts "Параметры: a=#{a}, c=#{c}, m=#{m}"
  puts "Анализ сидов: 0..#{seed_limit}"

  cond = theorem1(a, c, m)
  puts "Условия теоремы 1:"
  puts "  c и m взаимно просты?  #{cond[:cond1]}"
  puts "  a-1 кратно всем простым делителям m? #{cond[:cond2]}  (простые делители m: #{cond[:primes].join(',')})"
  puts "  a-1 кратно 4 при m%4==0?  #{cond[:cond3]}"
  puts "→ ВСЕ условия выполняются? #{cond[:all]}"

  # Для больших m ограничим анализ
  if m > 10000
    puts "Анализ периодов: пропущено (слишком большой m)"
    res = { max: "N/A", avg: "N/A", count_max: "N/A" }
  else
    res = analyze_params_optimized(a, c, m, seed_limit)
    puts "Максимальный период среди проверенных сидов: #{res[:max]}"
    puts "Средний период (AvgPer): #{res[:avg].round(3)}"
    puts "Кол-во сидов с максимальным периодом: #{res[:count_max]}"
  end

  # Частотный тест
  ft = frequency_test(a, c, m, 1, FREQ_N, FREQ_K)
  puts "Частотный тест (χ²) для seed=1, N=#{FREQ_N}, k=#{FREQ_K}:"
  puts "  χ² = #{ft[:chi2].round(4)}, df=#{ft[:df]}"
  puts "  критические границы (alpha_lo=0.1, alpha_hi=0.9): left=#{ft[:left_crit].round(4)}, right=#{ft[:right_crit].round(4)}"
  puts "  Прошёл ли частотный тест? #{ft[:pass]}"

  # Комплексный сериальный тест
  puts "Сериальный тест (комплексный):"
  cst = comprehensive_serial_test(a, c, m, 1)
  
  cst[:results].each do |test_result|
    puts "  #{test_result[:test]}: χ²=#{test_result[:chi2].round(4)}, pass=#{test_result[:pass]}"
  end
  puts "  Лучший χ²: #{cst[:best_chi2].round(4)}"
  puts "  Прошёл ли хотя бы один сериальный тест? #{cst[:any_pass]}"
  
  puts

  # В основном блоке после сериального теста добавляем:
  # Покер-тест
  poker = poker_test(a, c, m, 1, 10000, 10)
  puts "Покер-тест для seed=1, N=10000, d=10:"
  puts "  χ² = #{poker[:chi2].round(4)}, df=#{poker[:df]}"
  puts "  классы: #{poker[:class_counts].inspect}"
  puts "  Прошёл покер-тест? #{poker[:pass]}"

  puts

  # Корреляционный тест  
  corr = correlation_test(a, c, m, 1, 10000)
  puts "Корреляционный тест для seed=1, N=10000:"
  puts "  R = #{corr[:correlation].round(6)}"
  puts "  границы: [#{corr[:lower_bound].round(6)}, #{corr[:upper_bound].round(6)}]"
  puts "  Прошёл корреляционный тест? #{corr[:pass]}"

  puts

  # Интервальный тест
  runs = runs_test(a, c, m, 1, 10000)
  puts "Интервальный тест для seed=1, N=10000:"
  puts "  серии: #{runs[:runs]}, ожидалось: #{runs[:expected_runs].round(2)}"
  puts "  Z = #{runs[:z_score].round(4)}"
  puts "  Прошёл интервальный тест? #{runs[:pass]}"

  puts

  summary << {
  label: ex[:label],
  a: a, c: c, m: m, 
  theorem_ok: cond[:all],
  max: res[:max], 
  avg: res[:avg], 
  count_max: res[:count_max],
  freq_pass: ft[:pass],
  serial_pass: cst[:any_pass],
  best_chi2_serial: cst[:best_chi2],
  # Новые тесты - инициализируем значениями по умолчанию
  poker_pass: poker ? poker[:pass] : false,
  correlation_pass: corr ? corr[:pass] : false,
  runs_pass: runs ? runs[:pass] : false
}
end


# В основном блоке ДО вывода сводной таблицы добавим отладку:
puts "\n=== ОТЛАДКА ДАННЫХ ==="
summary.each_with_index do |s, i|
  puts "Запись #{i}: #{s.inspect}"
end

# И исправим вывод таблицы - добавим проверки на nil:
puts "\n" + "=" * 120
puts "ПОЛНАЯ СВОДНАЯ ТАБЛИЦА ВСЕХ ТЕСТОВ"
puts "=" * 120
headers = ["Название", "Th1", "MaxPer", "Частот", "Сериал", "Покер", "Коррел", "Интерв", "χ² сер"]
puts "%-25s | %-3s | %-7s | %-6s | %-6s | %-5s | %-6s | %-6s | %-8s" % headers
puts "-" * 120

summary.each do |s|
  max_per_display = s[:max].is_a?(String) ? s[:max] : s[:max].to_s
  best_chi2_display = s[:best_chi2_serial] ? s[:best_chi2_serial].round(1) : "N/A"
  
  row = [
    s[:label][0..24],
    s[:theorem_ok] ? "Да" : "Нет",
    max_per_display,
    s[:freq_pass] ? "✓" : "✗",
    s[:serial_pass] ? "✓" : "✗", 
    s[:poker_pass] ? "✓" : "✗",
    s[:correlation_pass] ? "✓" : "✗",
    s[:runs_pass] ? "✓" : "✗",
    best_chi2_display
  ]
  
  puts "%-25s | %-3s | %-7s | %-6s | %-6s | %-5s | %-6s | %-6s | %-8s" % row
end

# Итоговая статистика
puts "\n" + "=" * 80
puts "ИТОГОВАЯ СТАТИСТИКА"
puts "=" * 80
total_generators = summary.size
passed_freq = summary.count { |s| s[:freq_pass] }
passed_serial = summary.count { |s| s[:serial_pass] }
passed_poker = summary.count { |s| s[:poker_pass] }
passed_corr = summary.count { |s| s[:correlation_pass] }
passed_runs = summary.count { |s| s[:runs_pass] }
passed_all = summary.count { |s| s[:freq_pass] && s[:serial_pass] && s[:poker_pass] && s[:correlation_pass] && s[:runs_pass] }

puts "Всего генераторов: #{total_generators}"
puts "Прошли частотный тест: #{passed_freq}/#{total_generators}"
puts "Прошли сериальный тест: #{passed_serial}/#{total_generators}" 
puts "Прошли покер-тест: #{passed_poker}/#{total_generators}"
puts "Прошли корреляционный тест: #{passed_corr}/#{total_generators}"
puts "Прошли интервальный тест: #{passed_runs}/#{total_generators}"
puts "Прошли ВСЕ тесты: #{passed_all}/#{total_generators}"

# Лучшие генераторы
good_generators = summary.select { |s| s[:freq_pass] && s[:serial_pass] && s[:poker_pass] }
puts "\nЛучшие генераторы (прошли основные тесты):"
good_generators.each do |gen|
  puts "  - #{gen[:label]}"
end

puts "\nГотово!"