require 'numo/gnuplot'

def generate_normal(n = 12)
  sum = 0.0
  n.times { sum += rand } # rand генерирует число в [0,1)
  sum - n / 2.0
end

# Функция для вычисления плотности нормального распределения
def normal_pdf(x, mu = 0, sigma = 1)
  1.0 / (sigma * Math.sqrt(2 * Math::PI)) * Math.exp(-0.5 * ((x - mu) / sigma) ** 2)
end

# Функция для вычисления функции распределения нормального распределения
def normal_cdf(x, mu = 0, sigma = 1)
  0.5 * (1 + Math.erf((x - mu) / (sigma * Math.sqrt(2))))
end

# Частотный тест для проверки равномерности ГПСЧР
def frequency_test(generator, k: 10, n: 10_000)
  # Правило Кнута: В классической работе Д. Кнута "Искусство программирования" рекомендуется k = 10-20 интервалов
  # Объем выборки: При N=10000, k=10 дает по 1000 ожидаемых наблюдений на интервал - этого достаточно для надежной статистики
  # Степени свободы: k-1=9 степеней свободы - хороший компромисс между чувствительностью и устойчивостью
  
  # Почему не больше?
  # if k > 20:  # Слишком много интервалов
  # - Теоретическая частота N/k становится малой
  # - Увеличивается вероятность случайных отклонений
  # - Требует большего объема данных N
  
  # Почему не меньше?
  # if k < 5:   # Слишком мало интервалов
  # - Низкая чувствительность теста
  # - Может не обнаружить локальные неравномерности
  # - Слишком грубое разбиение
  
  # "Согласно классическим работам по тестированию генераторов (Кнут),
  #  рекомендуется использовать 10-20 интервалов. Мы выбрали k=10 как стандартное значение,
  #  которое обеспечивает хороший баланс между чувствительностью теста и надежностью статистических выводов."

  # 1. Разбиваем интервал (0,1) на k частей
  interval_length = 1.0 / k
  
  # 2. Генерируем N чисел
  numbers = Array.new(n) { generator.call }
  
  # 3. Подсчитываем экспериментальные частоты
  experimental_freq = Array.new(k, 0)
  
  numbers.each do |num|
    interval_index = (num / interval_length).floor
    interval_index = k - 1 if interval_index >= k # На случай, если num == 1.0
    experimental_freq[interval_index] += 1
  end
  
  # 4. Теоретическая частота
  theoretical_freq = n.to_f / k
  
  # 5. Вычисляем статистику χ²
  chi_square = 0.0
  experimental_freq.each do |freq|
    chi_square += ((freq - theoretical_freq) ** 2) / theoretical_freq
  end
  
  # Критические значения для k-1 степеней свободы (из таблицы для k=10)
  # Для α=0.1: χ² = 4.16816, для α=0.9: χ² = 14.6837

  # Эти числа взяты из таблицы распределения χ² для 9 степеней свободы:
  # χ²(0.1; 9) = 4.16816 - это значение, которое превышается с вероятностью 90% (P(χ² > 4.16816) = 0.9)
  # χ²(0.9; 9) = 14.6837 - это значение, которое превышается с вероятностью 10% (P(χ² > 14.6837) = 0.1)

  # Плотность распределения χ² (9 степеней свободы)
  #     |----------------|----------------|----------------|
  #     0               4.16816          14.6837          ∞
  #     |     90%       |      80%       |      10%       |
  #     ↑               ↑                ↑                ↑
  #    α=1.0           α=0.1            α=0.9           α=0.0

  # Согласно методичке:
  # Если χ² < 4.16816 (α > 0.9) - СЛИШКОМ ХОРОШОЕ совпадение (подозрительно!)
  # Если χ² > 14.6837 (α < 0.1) - СЛИШКОМ ПЛОХОЕ совпадение
  # Если 4.16816 < χ² < 14.6837 (0.1 < α < 0.9) - НОРМАЛЬНОЕ совпадение

  # "Эти значения взяты из таблиц распределения χ² для 9 степеней свободы. χ²=4.16816
  # соответствует 10%-ному квантилю (α=0.9), а χ²=14.6837 - 90%-ному квантилю (α=0.1).
  # Согласно методичке, генератор проходит тест, если расчетное значение χ² попадает между этими границами."

  chi_square_01 = 4.16816
  chi_square_09 = 14.6837
  
  # Проверяем условие принятия гипотезы
  passes_test = chi_square_01 < chi_square && chi_square < chi_square_09
  
  {
    chi_square: chi_square,
    critical_low: chi_square_01,
    critical_high: chi_square_09,
    experimental_freq: experimental_freq,
    theoretical_freq: theoretical_freq,
    passes_test: passes_test
  }
end

# Корреляционный тест для проверки корреляционных свойств ГПСЧР
def correlation_test(generator, n: 10_000)
  # Генерируем последовательность чисел
  numbers = Array.new(n) { generator.call }
  
  # Для автокорреляции: y_i = x_{i+1}
  x = numbers[0..-2]  # все элементы кроме последнего
  y = numbers[1..-1]  # все элементы кроме первого
  
  # Вычисляем необходимые суммы по формулам из методички
  sum_x = x.sum
  sum_y = y.sum
  sum_xy = x.zip(y).map { |a, b| a * b }.sum
  sum_x2 = x.map { |xi| xi ** 2 }.sum
  sum_y2 = y.map { |yi| yi ** 2 }.sum
  
  # Вычисляем коэффициент корреляции R по формуле из методички:
  # R = [N * Σ(x_i * y_i) - Σx_i * Σy_j] / 
  #     sqrt( [N * Σx_i^2 - (Σx_i)^2] * [N * Σy_i^2 - (Σy_i)^2] )
  numerator = n * sum_xy - sum_x * sum_y
  denominator = Math.sqrt((n * sum_x2 - sum_x ** 2) * (n * sum_y2 - sum_y ** 2))
  
  r = numerator / denominator
  
  # Вычисляем критические значения для 5%-ного уровня значимости (α = 0.05)
  # Согласно методичке, R должно лежать в пределах:
  # -1/(N-1) - 2/(N-1) * sqrt(N*(N-3)/(N+1)) ≤ R ≤ -1/(N-1) + 2/(N-1) * sqrt(N*(N-3)/(N+1))
  
  # Обоснование выбора α=0.05:
  # - 5% уровень значимости является стандартным в статистике
  # - Соответствует доверительной вероятности 95%
  # - Широко используется в научных исследованиях и инженерной практике
  # - Рекомендован в методичке для данного теста
  
  term1 = 1.0 / (n - 1)
  term2 = (2.0 / (n - 1)) * Math.sqrt(n * (n - 3) / (n + 1).to_f)
  
  r_lower = -term1 - term2
  r_upper = -term1 + term2
  
  # Проверяем условие принятия гипотезы
  passes_test = r_lower <= r && r <= r_upper
  
  {
    correlation_coefficient: r,
    critical_lower: r_lower,
    critical_upper: r_upper,
    passes_test: passes_test,
    explanation: "Для 5%-ного уровня значимости (α=0.05) значение коэффициента корреляции R должно находиться в указанном интервале"
  }
end

# Демонстрация работы генератора нормального распределения
puts "МОДЕЛИРОВАНИЕ НОРМАЛЬНОГО РАСПРЕДЕЛЕНИЯ"
puts "=" * 50

samples = Array.new(10_000) { generate_normal }

# Вычисление статистик
mean = samples.sum / samples.size
variance = samples.map { |x| (x - mean)**2 }.sum / (samples.size - 1)
std_dev = Math.sqrt(variance)

puts "Теоретические значения: M(ξ) = 0, D(ξ) = 1"
puts "Выборочное среднее: #{mean.round(4)}"
puts "Выборочная дисперсия: #{variance.round(4)}"
puts "Выборочное стандартное отклонение: #{std_dev.round(4)}"

# Гистограмма (группировка данных)
histogram = Hash.new(0)
samples.each do |x|
  bucket = x.round(1)
  histogram[bucket] += 1
end

puts "\nГистограмма (первые 15 значений):"
histogram.sort.first(15).each do |bucket, count|
  puts "#{bucket}: #{'*' * (count / 20)}"
end

# ЧАСТОТНЫЙ ТЕСТ ДЛЯ ПРОВЕРКИ РАВНОМЕРНОСТИ ИСХОДНЫХ ВЕЛИЧИН
puts "\n\nЧАСТОТНЫЙ ТЕСТ ПРОВЕРКИ РАВНОМЕРНОСТИ ГПСЧР"
puts "=" * 50

# Тестируем встроенный генератор Ruby (rand), который используется в generate_normal
test_result = frequency_test(-> { rand })

puts "Параметры теста:"
puts "  k = 10 интервалов"
puts "  N = 10000 чисел"
puts "  Число степеней свободы: 9"

puts "\nРезультаты теста:"
puts "  χ² = #{test_result[:chi_square].round(4)}"
puts "  Критический интервал: (#{test_result[:critical_low]}, #{test_result[:critical_high]})"
puts "  Проходит тест: #{test_result[:passes_test]}"

puts "\nЭкспериментальные частоты по интервалам:"
test_result[:experimental_freq].each_with_index do |freq, i|
  lower_bound = i * 0.1
  upper_bound = (i + 1) * 0.1
  puts "  [#{lower_bound.round(1)}, #{upper_bound.round(1)}): #{freq}"
end

puts "Теоретическая частота для каждого интервала: #{test_result[:theoretical_freq].round(1)}"

# КОРРЕЛЯЦИОННЫЙ ТЕСТ ДЛЯ ПРОВЕРКИ КОРРЕЛЯЦИОННЫХ СВОЙСТВ ГПСЧР
puts "\n\nКОРРЕЛЯЦИОННЫЙ ТЕСТ ПРОВЕРКИ КОРРЕЛЯЦИОННЫХ СВОЙСТВ ГПСЧР"
puts "=" * 50

# Тестируем встроенный генератор Ruby (rand)
corr_test_result = correlation_test(-> { rand })

puts "Параметры теста:"
puts "  N = 10000 чисел"
puts "  Уровень значимости: α = 0.05 (5%)"
puts "  Проверка последовательной автокорреляции: y_i = x_{i+1}"

puts "\nРезультаты теста:"
puts "  Коэффициент корреляции R = #{corr_test_result[:correlation_coefficient].round(6)}"
puts "  Критический интервал: [#{corr_test_result[:critical_lower].round(6)}, #{corr_test_result[:critical_upper].round(6)}]"
puts "  Проходит тест: #{corr_test_result[:passes_test]}"

puts "\nОбъяснение:"
puts "  #{corr_test_result[:explanation]}"
puts "  Для случайной последовательности коэффициент корреляции должен быть близок к 0"
puts "  и находиться в пределах критического интервала"

# Дополнительная проверка: тестируем несколько раз для надежности
puts "\nДополнительная проверка корреляционного теста (5 запусков):"
5.times do |i|
  corr_test_result = correlation_test(-> { rand }, n: 5000)
  status = corr_test_result[:passes_test] ? "ПРОЙДЕН" : "НЕ ПРОЙДЕН"
  puts "  Попытка #{i+1}: R = #{corr_test_result[:correlation_coefficient].round(6)} - #{status}"
end

# Вывод о качестве генератора на основе обоих тестов
puts "\nОБЩАЯ ОЦЕНКА КАЧЕСТВА ГЕНЕРАТОРА:"
frequency_ok = test_result[:passes_test]
correlation_ok = corr_test_result[:passes_test]

if frequency_ok && correlation_ok
  puts "  ✓ Генератор удовлетворяет ЧАСТОТНОМУ тесту"
  puts "  ✓ Генератор удовлетворяет КОРРЕЛЯЦИОННОМУ тесту"
  puts "  ✓ Генератор считается КАЧЕСТВЕННЫМ по обоим критериям"
elsif frequency_ok && !correlation_ok
  puts "  ✓ Генератор удовлетворяет ЧАСТОТНОМУ тесту"
  puts "  ✗ Генератор НЕ удовлетворяет КОРРЕЛЯЦИОННОМУ тесту"
  puts "  ⚠ Генератор требует дополнительной проверки"
elsif !frequency_ok && correlation_ok
  puts "  ✗ Генератор НЕ удовлетворяет ЧАСТОТНОМУ тесту"
  puts "  ✓ Генератор удовлетворяет КОРРЕЛЯЦИОННОМУ тесту"
  puts "  ⚠ Генератор требует дополнительной проверки"
else
  puts "  ✗ Генератор НЕ удовлетворяет ЧАСТОТНОМУ тесту"
  puts "  ✗ Генератор НЕ удовлетворяет КОРРЕЛЯЦИОННОМУ тесту"
  puts "  ✗ Генератор считается НЕКАЧЕСТВЕННЫМ"
end

# ВИЗУАЛИЗАЦИЯ РЕЗУЛЬТАТОВ МОДЕЛИРОВАНИЯ С ИСПОЛЬЗОВАНИЕМ NUMO.GNUPLOT
puts "\n\nВИЗУАЛИЗАЦИЯ РЕЗУЛЬТАТОВ МОДЕЛИРОВАНИЯ"
puts "=" * 50

puts "Подготовка данных для визуализации..."

# Создаем нормализованную гистограмму для графика
histogram_data = Hash.new(0)
bin_width = 0.3
samples.each do |x|
  bucket = (x / bin_width).round * bin_width
  histogram_data[bucket] += 1
end

# Нормализуем гистограмму (преобразуем в плотность вероятности)
total_area = histogram_data.values.sum * bin_width
normalized_histogram = {}
histogram_data.each do |bucket, count|
  normalized_histogram[bucket] = count.to_f / total_area
end

# Подготовка данных для графика
buckets = normalized_histogram.keys.sort
frequencies = buckets.map { |bucket| normalized_histogram[bucket] }

# Теоретическая кривая нормального распределения
x_theoretical = (-4.0).step(4.0, 0.04).to_a
y_theoretical = x_theoretical.map { |x| normal_pdf(x) }

# Построение графика гистограммы с теоретической кривой
puts "Построение гистограммы с теоретической кривой..."
Numo.gnuplot do
  set title: "Моделирование нормального распределения"
  set xlabel: "Значение случайной величины ξ"
  set ylabel: "Плотность вероятности f(ξ)"
  set grid: true
  set key: 'top right'
  set yrange: 0..0.5
  set terminal: 'pngcairo enhanced font "Arial,12"'
  set output: "normal_distribution.png"
  
  plot [buckets, frequencies, using: '1:2', with: 'boxes', 
        title: 'Экспериментальные данные', fill: 'solid 0.5', lc: 'rgb "#1E88E5"'],
       [x_theoretical, y_theoretical, using: '1:2', with: 'lines', 
        title: 'Теоретическое N(0,1)', lw: 3, lc: 'rgb "#D81B60"']
end

puts "Гистограмма сохранена в файл: normal_distribution.png"

# Построение графика функции распределения
puts "Построение графика функции распределения..."

# Экспериментальная функция распределения
sorted_samples = samples.sort
empirical_cdf = sorted_samples.map.with_index { |x, i| i.to_f / sorted_samples.size }

# Теоретическая функция распределения
x_cdf = (-4.0).step(4.0, 0.04).to_a
y_cdf_theoretical = x_cdf.map { |x| normal_cdf(x) }

Numo.gnuplot do
  set title: "Функция распределения нормального распределения"
  set xlabel: "Значение случайной величины ξ"
  set ylabel: "Вероятность F(ξ)"
  set grid: true
  set key: 'bottom right'
  set xrange: -4..4
  set yrange: 0..1
  set terminal: 'pngcairo enhanced font "Arial,12"'
  set output: "normal_cdf.png"
  
  plot [sorted_samples, empirical_cdf, using: '1:2', with: 'lines', 
        title: 'Экспериментальная CDF', lw: 2, lc: 'rgb "#1E88E5"'],
       [x_cdf, y_cdf_theoretical, using: '1:2', with: 'lines', 
        title: 'Теоретическая CDF N(0,1)', lw: 2, lc: 'rgb "#D81B60"']
end

puts "Функция распределения сохранена в файл: normal_cdf.png"

# Проверка по правилу 3-х сигм
puts "\nПРОВЕРКА ПО ПРАВИЛУ 3-Х СИГМ:"
puts "Теоретическое распределение N(0,1) должно удовлетворять:"
puts "- 68.27% значений в интервале [-1, 1]"
puts "- 95.45% значений в интервале [-2, 2]" 
puts "- 99.73% значений в интервале [-3, 3]"

ranges = [
  { range: "(-∞, -3σ)", theoretical: 0.00135, actual: samples.count { |x| x < -3 } / samples.size.to_f },
  { range: "[-3σ, -2σ)", theoretical: 0.0214, actual: samples.count { |x| x >= -3 && x < -2 } / samples.size.to_f },
  { range: "[-2σ, -1σ)", theoretical: 0.1359, actual: samples.count { |x| x >= -2 && x < -1 } / samples.size.to_f },
  { range: "[-1σ, 1σ)", theoretical: 0.6827, actual: samples.count { |x| x >= -1 && x < 1 } / samples.size.to_f },
  { range: "[1σ, 2σ)", theoretical: 0.1359, actual: samples.count { |x| x >= 1 && x < 2 } / samples.size.to_f },
  { range: "[2σ, 3σ)", theoretical: 0.0214, actual: samples.count { |x| x >= 2 && x < 3 } / samples.size.to_f },
  { range: "[3σ, ∞)", theoretical: 0.00135, actual: samples.count { |x| x >= 3 } / samples.size.to_f }
]

puts "\nИнтервал      | Теоретическая | Фактическая | Отклонение"
puts "--------------|---------------|-------------|------------"
ranges.each do |r|
  deviation = (r[:actual] - r[:theoretical]).abs
  puts "%-13s | %-13.4f | %-11.4f | %-10.4f" % [r[:range], r[:theoretical], r[:actual], deviation]
end

puts "\nИТОГОВЫЙ ВЫВОД ПО МОДЕЛИРОВАНИЮ:"
if (0.65..0.70).include?(ranges[3][:actual])
  puts "✓ Центральная предельная теорема подтверждена экспериментально"
  puts "✓ Распределение близко к теоретическому N(0,1)"
  puts "✓ Генератор нормального распределения работает КОРРЕКТНО"
else
  puts "✗ Требуется дополнительная проверка генератора нормального распределения"
end

puts "\nТеоретическое обоснование:"
puts "- Центральная предельная теорема утверждает, что сумма независимых"
puts "  одинаково распределенных случайных величин стремится к нормальному"
puts "  распределению при увеличении их количества."
puts "- В нашем случае: ξ = Σr_i - 6, где r_i ~ U(0,1)"
puts "- M(ξ) = 12*0.5 - 6 = 0, D(ξ) = 12*(1/12) = 1"
puts "- Результаты подтверждают теоретические расчеты."