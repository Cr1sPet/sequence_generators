
require 'set'
require 'numo/gnuplot'

# Генератор псевдослучайных чисел методом серединных квадратов
# Берем изначальный seed, возводим его в квадрат
# Берем из результата средние цифры - это новое число
# Повторяем процесс, пока не получим число, которое уже было

# middle_square_correct.rb
# Метод срединных квадратов: d цифр (по умолчанию d=4)

def middle_square_next(x, d = 4)
  sq = (x ** 2).to_s.rjust(2 * d, '0')
  start = (sq.length - d) / 2
  sq[start, d].to_i
end

# Возвращает число членов последовательности до вырождения:
# т.е. количество уникальных значений, пока не встретится 0 или пока не произойдёт повтор.
def middle_square_period_until_degenerate(seed, d = 4)
  raise ArgumentError, "seed must be between 0 and #{10**d - 1}" if seed < 0 || seed >= 10**d
  seen = {}
  x = seed
  idx = 0
  loop do
    return idx if x == 0           # вырождение в 0 — возвращаем, сколько уникальных уже было
    return idx if seen.key?(x)     # встречаем повтор — возвращаем количество уникальных членов
    seen[x] = idx
    x = middle_square_next(x, d)
    idx += 1
  end
end

# Находим в диапазоне 1..9999 числа, дающие максимальный период
def find_max_period_seeds(range = 1..9999, d = 4)
  max_period = -1
  max_seeds = []
  range.each do |seed|
    p = middle_square_period_until_degenerate(seed, d)
    if p > max_period
      max_period = p
      max_seeds = [seed]
    elsif p == max_period
      max_seeds << seed
    end
  end
  { max_period: max_period, max_seeds: max_seeds }
end

def period_distribution(range = 0..9999, d = 4)
  dist = Hash.new(0)
  range.each do |seed|
    p = middle_square_period_until_degenerate(seed, d)
    dist[p] += 1
  end
  dist
end

def plot_distribution(dist, filename = "period_distribution.png")
  periods = dist.keys.sort
  counts = periods.map { |p| dist[p] }
  
  Numo.gnuplot do
    set terminal: 'png', size: [1000, 600]
    set output: filename
    set title: "Распределение длины периода (middle-square, d=4)"
    set xlabel: "Длина периода"
    set ylabel: "Количество сидов"
    set grid: true
    set style: 'fill solid 0.5'
    set xtics: 'auto'  # Пусть gnuplot сам решит как расставить подписи
    plot [periods, counts, with: 'boxes', notitle: true]
  end
  
  puts "Гистограмма сохранена в #{filename}"
end

if __FILE__ == $0
  result = find_max_period_seeds(1..9999, 4)
  puts "Максимальный период (число членов до вырождения): #{result[:max_period]}"
  puts "Числа в этом периоде: #{result[:max_seeds]}"
  dist = period_distribution(0..9999, 4)
  plot_distribution(dist)
end
