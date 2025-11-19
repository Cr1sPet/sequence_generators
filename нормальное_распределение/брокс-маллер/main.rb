require 'numo/gnuplot'

# -------------------------
# Box-Muller генерация
# -------------------------

N = (ARGV[0] || 10000).to_i

samples = []
(N/2).times do
  u1 = rand
  u2 = rand
  r = Math.sqrt(-2.0 * Math.log(u1))
  theta = 2.0 * Math::PI * u2
  z1 = r * Math.cos(theta)
  z2 = r * Math.sin(theta)
  samples << z1 << z2
end
samples = samples[0...N] if samples.length > N

# -------------------------
# Основные статистики
# -------------------------

mean = samples.sum / N.to_f
variance = samples.map { |x| (x - mean) ** 2 }.sum / N.to_f
std = Math.sqrt(variance)

puts "Box-Muller method:"
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

edges = Array.new(k_bins + 1) { |i| min_x + i * step }
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

chi2_pass = chi2 < (k_bins - 1) * 2.0  # мягкий критерий

# -------------------------
# Корреляционный тест lag-1
# -------------------------

num = 0.0
(0...(samples.length - 1)).each do |i|
  num += (samples[i] - mean) * (samples[i+1] - mean)
end

den = samples.map { |x| (x - mean)**2 }.sum
r1 = num / den
crit = 1.96 / Math.sqrt(N)

# -------------------------
# Интервальный тест (Чебышёв)
# -------------------------

alpha = 0.05
k_cheb = 1.0 / Math.sqrt(alpha)
count_inside = samples.count { |x| (x - mean).abs <= k_cheb * std }
prop_inside = count_inside.to_f / N
threshold = 1 - alpha

# -------------------------
# Подготовка данных для графика
# -------------------------

bin_centers = []
densities   = []

edges.each_cons(2).each_with_index do |(a,b), i|
  mid = (a + b) / 2.0
  bin_centers << mid
  densities << counts[i].to_f / (n_eff * (b - a))
end

xs = (-60..60).map { |i| i / 10.0 }
pdf = xs.map { |x| 1.0 / Math.sqrt(2*Math::PI) * Math.exp(-0.5 * x*x) }

# -------------------------
# Построение графика через Numo.gnuplot
# -------------------------

Numo.gnuplot do
  set title: "Box-Muller: Нормальное распределение"
  set xlabel: "Значение случайной величины ξ"
  set ylabel: "Плотность вероятности f(ξ)"
  set grid: true
  set key: 'top right'
  set yrange: 0..0.5
  set terminal: 'pngcairo enhanced font "Arial,12"'
  set output: "boxmuller_hist.png"
  
  plot [bin_centers, densities, using: '1:2', with: 'boxes', 
        title: 'Экспериментальные (Box-Muller)', 
        fill: 'solid 0.5', lc: 'rgb "#1E88E5"'],
       [xs, pdf, using: '1:2', with: 'lines', 
        title: 'Теоретическое N(0,1)', lw: 3, lc: 'rgb "#D81B60"']
end

puts "Plot saved to boxmuller_hist.png"

# -------------------------
# Вывод результатов тестов
# -------------------------

puts "\n================= РЕЗУЛЬТАТЫ ТЕСТОВ =================\n\n"

puts "1) Частотный тест (хи-квадрат):"
puts "  χ² = #{chi2.round(4)}, df = #{k_bins - 1}"
puts "  #{chi2_pass ? '✔ Тест пройден' : '✘ Тест НЕ пройден'}\n\n"

puts "2) Корреляционный тест (автокорреляция lag-1):"
puts "  r1 = #{r1.round(6)}, критическое значение ≈ ±#{crit.round(6)}"
puts "  #{r1.abs <= crit ? '✔ Тест пройден' : '✘ Тест НЕ пройден'}\n\n"

puts "3) Интервальный тест (Чебышёв, k=1/√α):"
puts "  k = #{k_cheb.round(4)}"
puts "  Доля значений в интервале ±k·σ = #{prop_inside.round(4)}"
puts "  Требуемая доля = #{threshold}"
puts "  #{prop_inside >= threshold ? '✔ Тест пройден' : '✘ Тест НЕ пройден'}"

puts "\n======================================================\n\n"
