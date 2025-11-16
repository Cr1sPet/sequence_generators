# frozen_string_literal: true

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
# Тестовые функции для Ruby rand() с адаптивными размерами
# -----------------------
def frequency_test_ruby(n = 10000, k = 10, alpha_lo = 0.1, alpha_hi = 0.9)
  counts = Array.new(k, 0)
  
  n.times do
    r = rand
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
    pass: pass,
    sample_size: n
  }
end

def serial_test_ruby(n = 100000, d = 8, alpha_lo = 0.05, alpha_hi = 0.95)
  # Адаптируем параметры для маленьких выборок
  d = [d, (n / 100).to_i].max  # Уменьшаем d для маленьких выборок
  d = [d, 4].max  # Минимум 4
  
  u_sequence = []
  
  n.times do
    r = rand
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
    pass: pass,
    sample_size: n,
    d_used: d  # Сохраняем использованное значение d
  }
end

def poker_test_ruby(n = 10000, d = 10)
  # Адаптируем размер группы для маленьких выборок
  group_size = n < 5000 ? 3 : 5
  
  u_sequence = []
  
  n.times do
    r = rand
    u_i = (d * r).to_i
    u_sequence << u_i
  end

  groups = []
  (0...u_sequence.length).step(group_size) do |i|
    group = u_sequence[i, group_size]
    groups << group if group.length == group_size
  end

  # Количество классов зависит от размера группы
  num_classes = case group_size
                when 3 then 3  # все разные, 2 одинаковых, все одинаковые
                when 4 then 5  # добавляются дополнительные комбинации
                when 5 then 7  # полный набор
                else 7
                end
                
  class_counts = Array.new(num_classes, 0)
  
  groups.each do |group|
    freq = Hash.new(0)
    group.each { |digit| freq[digit] += 1 }
    frequencies = freq.values.sort.reverse
    
    case group_size
    when 3
      if frequencies == [3]           # a,a,a
        class_counts[2] += 1
      elsif frequencies == [2, 1]     # a,a,b
        class_counts[1] += 1
      elsif frequencies == [1, 1, 1]  # a,b,c
        class_counts[0] += 1
      end
    when 5
      # Оригинальная логика для 5 карт
      case frequencies
      when [5] then class_counts[6] += 1           # a,a,a,a,a
      when [4, 1] then class_counts[5] += 1        # a,a,a,a,b  
      when [3, 2] then class_counts[4] += 1        # a,a,a,b,b
      when [3, 1, 1] then class_counts[3] += 1     # a,a,a,b,c
      when [2, 2, 1] then class_counts[2] += 1     # a,a,b,b,c
      when [2, 1, 1, 1] then class_counts[1] += 1  # a,a,b,c,d
      when [1, 1, 1, 1, 1] then class_counts[0] += 1 # a,b,c,d,e
      end
    end
  end

  total_groups = groups.length
  
  # Теоретические вероятности для разных размеров групп
  theoretical_probs = case group_size
                     when 3
                       [
                         (d-1)*(d-2).to_f / (d**2),  # a,b,c
                         3 * (d-1).to_f / (d**2),    # a,a,b
                         1.0 / (d**2)               # a,a,a
                       ]
                     when 5
                       [
                         (d-1)*(d-2)*(d-3)*(d-4).to_f / (d**4),  # a,b,c,d,e
                         10 * (d-1)*(d-2)*(d-3).to_f / (d**4),   # a,a,b,c,d
                         15 * (d-1)*(d-2).to_f / (d**4),         # a,a,a,b,b
                         10 * (d-1)*(d-2).to_f / (d**4),         # a,a,a,b,c
                         10 * (d-1).to_f / (d**4),               # a,a,a,a,b
                         5 * (d-1).to_f / (d**4),                # a,a,a,a,b (альтернативная)
                         1.0 / (d**4)                            # a,a,a,a,a
                       ]
                     end

  chi2 = 0.0
  num_classes.times do |i|
    expected = total_groups * theoretical_probs[i]
    observed = class_counts[i]
    chi2 += ((observed - expected) ** 2) / expected if expected > 0
  end

  df = num_classes - 1
  
  left = chi2_quantile(0.1, df)
  right = chi2_quantile(0.9, df)
  
  pass = (chi2 > left) && (chi2 < right)

  { 
    chi2: chi2,
    df: df,
    class_counts: class_counts,
    total_groups: total_groups,
    pass: pass,
    sample_size: n,
    group_size_used: group_size
  }
end

def correlation_test_ruby(n = 10000)
  sequence = []
  
  n.times do
    sequence << rand
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
    pass: pass,
    sample_size: n
  }
end

def runs_test_ruby(n = 10000)
  sequence = []
  
  n.times do
    sequence << (rand > 0.5 ? 1 : 0)
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
    pass: pass,
    sample_size: n
  }
end

# -----------------------
# Многоуровневое тестирование на разных размерах выборок
# -----------------------
def run_comprehensive_tests
  puts "=== КОМПЛЕКСНЫЙ АНАЛИЗ ГЕНЕРАТОРА RUBY RAND() ==="
  puts "Тестирование на разных объемах данных для проверки стабильности"
  puts "ВСЕ тесты запускаются на ВСЕХ размерах выборок"
  puts
  
  # Разные размеры выборок для тестирования
  sample_sizes = [1000, 5000, 10000, 50000, 100000]
  
  all_results = {}
  
  sample_sizes.each do |size|
    puts "=" * 70
    puts "РАЗМЕР ВЫБОРКИ: #{size}"
    puts "=" * 70
    
    results = {}
    
    # Запускаем ВСЕ тесты для текущего размера выборки
    puts "Запуск всех тестов..."
    
    # Частотный тест
    freq_n = size
    freq = frequency_test_ruby(freq_n)
    results[:frequency] = freq
    puts "✓ Частотный тест (#{freq_n} samples): #{freq[:pass] ? 'ПРОШЕЛ' : 'НЕ ПРОШЕЛ'}"
    
    # Сериальный тест - ЗАПУСКАЕМ ДЛЯ ВСЕХ РАЗМЕРОВ
    serial_n = size
    serial = serial_test_ruby(serial_n)
    results[:serial] = serial
    puts "✓ Сериальный тест (#{serial_n} samples, d=#{serial[:d_used]}): #{serial[:pass] ? 'ПРОШЕЛ' : 'НЕ ПРОШЕЛ'}"
    
    # Покер-тест
    poker_n = size
    poker = poker_test_ruby(poker_n)
    results[:poker] = poker
    puts "✓ Покер-тест (#{poker_n} samples, группа=#{poker[:group_size_used]}): #{poker[:pass] ? 'ПРОШЕЛ' : 'НЕ ПРОШЕЛ'}"
    
    # Корреляционный тест
    corr_n = size
    corr = correlation_test_ruby(corr_n)
    results[:correlation] = corr
    puts "✓ Корреляционный тест (#{corr_n} samples): #{corr[:pass] ? 'ПРОШЕЛ' : 'НЕ ПРОШЕЛ'}"
    
    # Интервальный тест
    runs_n = size
    runs = runs_test_ruby(runs_n)
    results[:runs] = runs
    puts "✓ Интервальный тест (#{runs_n} samples): #{runs[:pass] ? 'ПРОШЕЛ' : 'НЕ ПРОШЕЛ'}"
    
    all_results[size] = results
    puts
  end
  
  all_results
end

# -----------------------
# Анализ и вывод результатов
# -----------------------
def analyze_results(all_results)
  puts "=" * 80
  puts "АНАЛИЗ РЕЗУЛЬТАТОВ ПО РАЗМЕРАМ ВЫБОРОК"
  puts "=" * 80
  
  # Сводная таблица
  headers = ["Размер выборки", "Частотный", "Сериальный", "Покер", "Корреляция", "Интервальный", "Успешность"]
  puts "| %-15s | %-9s | %-9s | %-5s | %-11s | %-11s | %-10s |" % headers
  puts "| " + "-" * 15 + " | " + "-" * 9 + " | " + "-" * 9 + " | " + "-" * 5 + " | " + "-" * 11 + " | " + "-" * 11 + " | " + "-" * 10 + " |"
  
  all_results.each do |size, tests|
    freq_pass = tests[:frequency][:pass] ? "✓" : "✗"
    serial_pass = tests[:serial][:pass] ? "✓" : "✗"
    poker_pass = tests[:poker][:pass] ? "✓" : "✗"
    corr_pass = tests[:correlation][:pass] ? "✓" : "✗"
    runs_pass = tests[:runs][:pass] ? "✓" : "✗"
    
    # Подсчет успешности
    total_tests = 5
    passed_tests = [freq_pass, serial_pass, poker_pass, corr_pass, runs_pass].count { |x| x == "✓" }
    success_rate = (passed_tests.to_f / total_tests * 100).round(1)
    
    puts "| %-15s | %-9s | %-9s | %-5s | %-11s | %-11s | %-10s |" % 
         [size.to_s, freq_pass, serial_pass, poker_pass, corr_pass, runs_pass, "#{success_rate}%"]
  end
  
  # Статистика стабильности
  puts "\n" + "=" * 60
  puts "СТАТИСТИКА СТАБИЛЬНОСТИ ГЕНЕРАТОРА"
  puts "=" * 60
  
  total_runs = 0
  total_passed = 0
  stability_by_test = Hash.new { |h, k| h[k] = { total: 0, passed: 0 } }
  
  all_results.each do |size, tests|
    tests.each do |test_name, result|
      stability_by_test[test_name][:total] += 1
      stability_by_test[test_name][:passed] += 1 if result[:pass]
      total_runs += 1
      total_passed += 1 if result[:pass]
    end
  end
  
  puts "Общая успешность: #{(total_passed.to_f / total_runs * 100).round(1)}% (#{total_passed}/#{total_runs} тестов)"
  puts "\nУспешность по тестам:"
  
  stability_by_test.each do |test_name, stats|
    success_rate = (stats[:passed].to_f / stats[:total] * 100).round(1)
    puts "  #{test_name.to_s.capitalize}: #{success_rate}% (#{stats[:passed]}/#{stats[:total]})"
  end
  
end

# -----------------------
# Основная программа
# -----------------------
puts "=== КОМПЛЕКСНОЕ ТЕСТИРОВАНИЕ ГЕНЕРАТОРА RUBY RAND() ==="
puts "Алгоритм: Mersenne Twister (MT19937)"
puts "Теоретический период: 2^19937-1"
puts "Цель: проверка стабильности на разных объемах данных"
puts "ВАЖНО: Все тесты адаптированы для работы с маленькими выборками"
puts

# Запускаем комплексное тестирование
all_results = run_comprehensive_tests

# Анализируем результаты
analyze_results(all_results)

puts "\n" + "=" * 60