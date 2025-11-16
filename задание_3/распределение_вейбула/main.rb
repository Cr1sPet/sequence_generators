# frozen_string_literal: true

require 'numo/gnuplot'

# -----------------------
# Генерация распределения Вейбулла
# -----------------------
def weibull_random(b, c, n = 10000)
  n.times.map { b * (-Math.log(1 - rand)) ** (1.0 / c) }
end

def weibull_pdf(x, b, c)
  return 0 if x < 0
  (c / b) * (x / b) ** (c - 1) * Math.exp(-(x / b) ** c)
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
# Улучшенные тесты для распределения Вейбулла
# -----------------------
def frequency_test_weibull(data, b, c, n_bins = 20)
  min_val = 0
  max_val = data.max
  bin_width = max_val / n_bins.to_f
  
  counts = Array.new(n_bins + 1, 0)  # +1 для хвоста
  
  data.each do |value|
    if value < max_val
      bin_index = (value / bin_width).to_i
      counts[[bin_index, n_bins - 1].min] += 1
    else
      counts[n_bins] += 1
    end
  end

  # Расчет ожидаемых частот для распределения Вейбулла
  expected = []
  n_bins.times do |i|
    x_low = i * bin_width
    x_high = (i + 1) * bin_width
    # Вероятность попадания в интервал [x_low, x_high]
    prob = Math.exp(-(x_low / b) ** c) - Math.exp(-(x_high / b) ** c)
    expected << data.size * prob
  end
  # Хвост (значения >= max_val)
  prob_tail = Math.exp(-(max_val / b) ** c)
  expected << data.size * prob_tail

  # Объединяем ячейки с малыми ожидаемыми частотами (<5)
  combined_counts = []
  combined_expected = []
  temp_count = 0
  temp_expected = 0
  
  expected.each_with_index do |exp, i|
    temp_count += counts[i]
    temp_expected += exp
    
    if temp_expected >= 5 || i == expected.size - 1
      combined_counts << temp_count
      combined_expected << temp_expected
      temp_count = 0
      temp_expected = 0
    end
  end

  # Вычисляем хи-квадрат
  chi2 = 0.0
  combined_counts.each_with_index do |obs, i|
    if combined_expected[i] > 0
      chi2 += ((obs - combined_expected[i]) ** 2) / combined_expected[i]
    end
  end

  df = [combined_counts.size - 2, 1].max
  
  left = chi2_quantile(0.05, df)
  right = chi2_quantile(0.95, df)

  pass = (chi2 >= left) && (chi2 <= right)

  {
    chi2: chi2,
    df: df,
    pass: pass,
    observed: combined_counts,
    expected: combined_expected.map(&:round),
    n_bins_used: combined_counts.size
  }
end

def correlation_test_weibull(data, n_lags = 5)
  results = {}
  
  (1..n_lags).each do |lag|
    n = data.size - lag
    sum_x = 0.0
    sum_y = 0.0
    sum_xy = 0.0
    sum_x2 = 0.0
    sum_y2 = 0.0

    (0...n).each do |i|
      x_i = data[i]
      y_i = data[i + lag]
      
      sum_x += x_i
      sum_y += y_i
      sum_xy += x_i * y_i
      sum_x2 += x_i * x_i
      sum_y2 += y_i * y_i
    end

    numerator = n * sum_xy - sum_x * sum_y
    denominator = Math.sqrt((n * sum_x2 - sum_x * sum_x) * (n * sum_y2 - sum_y * sum_y))
    
    r = denominator.zero? ? 0.0 : numerator / denominator

    pass = r.abs < 0.05

    results[lag] = {
      correlation: r,
      pass: pass
    }
  end

  results
end

def runs_test_weibull(data, n_thresholds = 3)
  results = {}
  
  # Тестируем на разных квантилях
  [0.25, 0.5, 0.75].each do |quantile|
    threshold = data.sort[(data.size * quantile).to_i]
    
    sequence = data.map { |x| x > threshold ? 1 : 0 }
    
    runs = 1
    (1...data.size).each do |i|
      runs += 1 if sequence[i] != sequence[i-1]
    end

    n1 = sequence.count(1)
    n0 = sequence.count(0)
    
    expected_runs = (2 * n0 * n1).to_f / data.size + 1
    variance_runs = (2 * n0 * n1 * (2 * n0 * n1 - data.size)).to_f / (data.size * data.size * (data.size - 1))
    
    z = (runs - expected_runs) / Math.sqrt(variance_runs)
    
    pass = z.abs < 1.96

    results[quantile] = {
      runs: runs,
      expected_runs: expected_runs.round(2),
      z_score: z,
      pass: pass,
      threshold: threshold.round(4)
    }
  end

  results
end

# -----------------------
# Множественное тестирование с разными параметрами
# -----------------------
def run_comprehensive_weibull_tests
  test_configs = [
    {b: 1.0, c: 0.5, n_samples: 5000, name: "b=1.0, c=0.5 (убывающая)"},
    {b: 1.0, c: 1.0, n_samples: 10000, name: "b=1.0, c=1.0 (экспоненциальная)"},
    {b: 1.0, c: 1.5, n_samples: 15000, name: "b=1.0, c=1.5 (стандартная)"},
    {b: 1.0, c: 3.0, n_samples: 8000, name: "b=1.0, c=3.0 (нормальноподобная)"},
    {b: 2.0, c: 2.0, n_samples: 10000, name: "b=2.0, c=2.0 (масштабированная)"}
  ]
  
  all_results = {}
  
  test_configs.each do |config|
    puts "\n" + "="*70
    puts "ТЕСТИРОВАНИЕ: #{config[:name]}"
    puts "Объем выборки: #{config[:n_samples]}"
    puts "="*70
    
    # Генерация данных
    data = weibull_random(config[:b], config[:c], config[:n_samples])
    
    # Основные статистики
    mean = data.sum / data.size
    variance = data.map { |x| (x - mean) ** 2 }.sum / data.size
    
    # Теоретические моменты (через гамма-функцию)
    theoretical_mean = config[:b] * Math.gamma(1 + 1.0 / config[:c])
    theoretical_variance = config[:b] ** 2 * (Math.gamma(1 + 2.0 / config[:c]) - Math.gamma(1 + 1.0 / config[:c]) ** 2)
    
    puts "ОСНОВНЫЕ СТАТИСТИКИ:"
    puts "  Выборочное среднее: #{mean.round(4)} (теоретическое: #{theoretical_mean.round(4)})"
    puts "  Выборочная дисперсия: #{variance.round(4)} (теоретическая: #{theoretical_variance.round(4)})"
    
    # Тестирование
    results = {}
    
    # ТЕСТ 1: Частотный тест с разными настройками
    puts "\nТЕСТ 1: ЧАСТОТНЫЙ ТЕСТ"
    puts "-" * 50
    freq_results = {}
    [10, 15, 20].each do |bins|
      test_result = frequency_test_weibull(data, config[:b], config[:c], bins)
      freq_results[bins] = test_result
      puts "  #{bins} интервалов: χ²=#{test_result[:chi2].round(4)}, df=#{test_result[:df]}, #{test_result[:pass] ? 'ПРОШЕЛ ✓' : 'НЕ ПРОШЕЛ ✗'}"
    end
    results[:frequency] = freq_results
    
    # ТЕСТ 2: Корреляционный тест с разными лагами
    puts "\nТЕСТ 2: КОРРЕЛЯЦИОННЫЙ ТЕСТ"
    puts "-" * 50
    corr_results = correlation_test_weibull(data, 5)
    corr_results.each do |lag, result|
      puts "  Лаг #{lag}: r=#{result[:correlation].round(6)}, #{result[:pass] ? 'ПРОШЕЛ ✓' : 'НЕ ПРОШЕЛ ✗'}"
    end
    results[:correlation] = corr_results
    
    # ТЕСТ 3: Интервальный тест с разными порогами
    puts "\nТЕСТ 3: ИНТЕРВАЛЬНЫЙ ТЕСТ"
    puts "-" * 50
    runs_results = runs_test_weibull(data, 3)
    runs_results.each do |quantile, result|
      puts "  Квантиль #{quantile}: Z=#{result[:z_score].round(4)}, #{result[:pass] ? 'ПРОШЕЛ ✓' : 'НЕ ПРОШЕЛ ✗'}"
    end
    results[:runs] = runs_results
    
    # Сводка
    freq_passed = freq_results.values.count { |r| r[:pass] }
    corr_passed = corr_results.values.count { |r| r[:pass] }
    runs_passed = runs_results.values.count { |r| r[:pass] }
    
    total_freq_tests = freq_results.size
    total_corr_tests = corr_results.size
    total_runs_tests = runs_results.size
    
    puts "\nСВОДКА ДЛЯ #{config[:name]}:"
    puts "  Частотный тест: #{freq_passed}/#{total_freq_tests}"
    puts "  Корреляционный тест: #{corr_passed}/#{total_corr_tests}"
    puts "  Интервальный тест: #{runs_passed}/#{total_runs_tests}"
    
    all_results[config[:name]] = {
      data: data,
      results: results,
      stats: {mean: mean, variance: variance},
      params: {b: config[:b], c: config[:c]}
    }
  end
  
  all_results
end

# -----------------------
# Визуализация результатов
# -----------------------
def plot_weibull_results(results, b, c)
  data = results[:data]
  
  # Ограничим данные для визуализации
  max_visual = b * 3.0  # Адаптируем под параметры
  data_visual = data.select { |x| x <= max_visual }
  
  # Гистограмма
  n_bins = 50
  histogram = Array.new(n_bins, 0)
  bin_width = max_visual / n_bins

  data_visual.each do |x|
    bin = (x / bin_width).to_i
    bin = n_bins - 1 if bin >= n_bins
    histogram[bin] += 1
  end

  # Нормализация гистограммы
  total = data_visual.size.to_f
  histogram_normalized = histogram.map { |count| count / (total * bin_width) }

  # Теоретическая кривая
  x_theoretical = (0..500).map { |i| i * max_visual / 500.0 }
  y_theoretical = x_theoretical.map { |x| weibull_pdf(x, b, c) }

  # Данные для гистограммы
  x_hist = (0...n_bins).map { |i| (i + 0.5) * bin_width }
  y_hist = histogram_normalized

  begin
    Numo.gnuplot do
      set title: "Распределение Вейбулла (b=#{b}, c=#{c})"
      set xlabel: 'x'
      set ylabel: 'Плотность вероятности f(x)'
      set xrange: 0..max_visual
      set style: 'fill solid 0.5'
      set terminal: 'pngcairo enhanced font "Arial,12"'
      set output: "weibull_b_#{b}_c_#{c}.png"
      
      plot [x_hist, y_hist, using: '1:2', with: 'boxes', 
            title: 'Эмпирическое распределение', lc: 'rgb "#1E88E5"'],
           [x_theoretical, y_theoretical, using: '1:2', with: 'lines', 
            title: 'Теоретическое распределение', lw: 3, lc: 'rgb "#D81B60"']
    end
  rescue => e
    puts "Ошибка при построении графика: #{e.message}"
  end
end

# -----------------------
# Основная программа
# -----------------------
puts "=" * 70
puts "КОМПЛЕКСНОЕ ТЕСТИРОВАНИЕ РАСПРЕДЕЛЕНИЯ ВЕЙБУЛЛА"
puts "=" * 70
puts "Множественное тестирование с разными параметрами b и c"
puts

# Запуск всестороннего тестирования
results = run_comprehensive_weibull_tests

# Визуализация результатов
puts "\nПостроение графиков распределения..."
results.each do |name, config|
  params = config[:params]
  plot_weibull_results(config, params[:b], params[:c])
  puts "  График для #{name} сохранен"
end

# Итоговая статистика
puts "\n" + "=" * 70
puts "ИТОГОВАЯ СТАТИСТИКА ПО ВСЕМ ТЕСТАМ"
puts "=" * 70

results.each do |name, config|
  freq_tests = config[:results][:frequency]
  corr_tests = config[:results][:correlation]
  runs_tests = config[:results][:runs]
  
  freq_passed = freq_tests.values.count { |r| r[:pass] }
  corr_passed = corr_tests.values.count { |r| r[:pass] }
  runs_passed = runs_tests.values.count { |r| r[:pass] }
  
  total_passed = freq_passed + corr_passed + runs_passed
  total_tests = freq_tests.size + corr_tests.size + runs_tests.size
  
  puts "#{name}:"
  puts "  Пройдено тестов: #{total_passed}/#{total_tests} (#{(total_passed.to_f/total_tests*100).round(1)}%)"
  puts "  Детали: частотный #{freq_passed}/#{freq_tests.size}, " +
       "корреляционный #{corr_passed}/#{corr_tests.size}, " +
       "интервальный #{runs_passed}/#{runs_tests.size}"
end

puts "\nТестирование завершено!"