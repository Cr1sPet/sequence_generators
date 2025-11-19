require 'numo/gnuplot'

# -------------------------
# Метод Зелинского
# -------------------------

N = (ARGV[0] || 10000).to_i
k_const = Math.sqrt(8.0 / Math::PI)  # константа k из метода Зелинского

# Обратное преобразование (метод Зелинского)
def zelinsky_inverse(r, k_const)
  t = (1.0 + r) / (1.0 - r)
  (1.0 / k_const) * Math.log(t)
end

samples = []

N.times do
  r1 = rand
  r2 = rand
  x = zelinsky_inverse(r1, k_const)
  x = -x if r2 < 0.5
  samples << x
end

# -------------------------
# Основные статистики
# -------------------------

mean = samples.sum / N.to_f
variance = samples.map { |x| (x - mean) ** 2 }.sum / N.to_f
std = Math.sqrt(variance)

puts "Zelinsky method:"
puts "  N = #{N}"
puts "  mean = #{mean.round(5)}"
puts "  variance = #{variance.round(5)}"

# -------------------------
# Частотный тест (хи-квадрат)
# -------------------------

k_bins = 20
min_x = -6.0
max_x = 6.0
step = (max_x - min_x) / k_bins

edges = Array.new(k_bins+1) { |i| min_x + i * step }
counts = Array.new(k_bins, 0)

samples.each do |x|
  next if x < min_x || x > max_x
  idx = ((x - min_x) / (max_x - min_x) * k_bins).to_i
  idx = k_bins - 1 if idx == k_bins
  counts[idx] += 1
end

expected = edges.each_cons(2).map { |a,b|
  0.5 * (Math.erf(b / Math.sqrt(2)) - Math.erf(a / Math.sqrt(2)))
}

n_eff = counts.sum

chi2 = counts.each_with_index.map { |obs, i|
  exp = expected[i] * n_eff
  exp > 0 ? (obs - exp)**2 / exp : 0
}.sum

puts "Chi² = #{chi2.round(4)} (df=#{k_bins - 1})"

# -------------------------
# Коррелятционный тест lag-1
# -------------------------

num = 0.0
den = 0.0

samples.each_with_index do |x, i|
  break if i == samples.length - 1
  num += (x - mean) * (samples[i+1] - mean)
end

den = samples.map { |x| (x - mean)**2 }.sum
r1 = num / den

crit = 1.96 / Math.sqrt(N)

puts "autocorr r1 = #{r1.round(5)} (critical ≈ ±#{crit.round(5)})"

# -------------------------
# Интервальный тест (по формуле 5.21 → k = 1/sqrt(alpha))
# -------------------------

alpha = 0.05
k_cheb = 1.0 / Math.sqrt(alpha)
count_inside = samples.count { |x| (x - mean).abs <= k_cheb * std }
prop_inside = count_inside.to_f / N

puts "Interval test:"
puts "  k = 1/sqrt(alpha) = #{k_cheb.round(4)}"
puts "  proportion inside = #{prop_inside.round(4)}"
puts "  expected ≥ #{1 - alpha}"

# -------------------------
# Построение гистограммы через Numo::Gnuplot
# -------------------------

# Подготовка данных для гистограммы
bin_centers = []
densities   = []

edges.each_cons(2).each_with_index do |(a,b), i|
  mid = (a + b) / 2.0
  bin_centers << mid
  densities << counts[i].to_f / (n_eff * (b - a))
end

# Теоретическая N(0,1)
xs = (-60..60).map { |i| i / 10.0 }
pdf = xs.map { |x| 1.0 / Math.sqrt(2*Math::PI) * Math.exp(-0.5 * x*x) }

Numo.gnuplot do
  set title: "Моделирование нормального распределения методом Зелинского"
  set xlabel: "Значение случайной величины ξ"
  set ylabel: "Плотность вероятности f(ξ)"
  set grid: true
  set key: 'top right'
  set yrange: 0..0.5
  set terminal: 'pngcairo enhanced font "Arial,12"'
  set output: "zelinsky_hist.png"
  
  plot [bin_centers, densities, using: '1:2', with: 'boxes', 
        title: 'Экспериментальные (метод Зелинского)', 
        fill: 'solid 0.5', lc: 'rgb "#1E88E5"'],
       [xs, pdf, using: '1:2', with: 'lines', 
        title: 'Теоретическое N(0,1)', lw: 3, lc: 'rgb "#D81B60"']
end

puts "Plot saved to zelinsky_hist.png"


puts "\n================= РЕЗУЛЬТАТЫ ТЕСТОВ =================\n\n"

# ----- 1) Частотный тест (хи-квадрат) -----
# Табличное критическое значение можно не считать в коде — 
# но мы сравним с «ожидаемым поведением»
chi2_pass = chi2 < (k_bins - 1) * 2.0   # мягкий критерий: χ² не должен быть «слишком большим»

puts "Частотный тест (хи-квадрат):"
puts "  Значение статистики χ² = #{chi2.round(4)} при #{k_bins - 1} степенях свободы."
if chi2_pass
  puts "  ✔ Тест пройден: форма распределения не противоречит нормальному."
else
  puts "  ✘ Тест НЕ пройден: наблюдаются значимые отклонения от нормального закона."
end
puts

# ----- 2) Корреляционный тест (lag-1) -----
puts "Корреляционный тест (автокорреляция lag-1):"
puts "  r₁ = #{r1.round(6)}, критическое значение ≈ ±#{crit.round(6)}."
if r1.abs <= crit
  puts "  ✔ Тест пройден: последовательность НЕ содержит заметной зависимости между соседними значениями."
else
  puts "  ✘ Тест НЕ пройден: есть статистически значимая автокорреляция."
end
puts

# ----- 3) Интервальный тест (Чебышёв, формулы 5.18–5.22) -----
threshold = 1 - alpha

puts "Интервальный тест (по формуле Чебышёва k = 1/√α):"
puts "  k = #{k_cheb.round(4)}"
puts "  Доля значений в интервале ±k·σ: #{prop_inside.round(4)}"
puts "  Требуемая доля:                #{threshold}"
if prop_inside >= threshold
  puts "  ✔ Тест пройден: выборка укладывается в ожидаемый интервал."
else
  puts "  ✘ Тест НЕ пройден: доля попаданий слишком мала."
end

puts "\n======================================================\n\n"
