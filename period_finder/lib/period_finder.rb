# frozen_string_literal: true

# Определение периода псевдослучайной последовательности
class PeriodFinder
  # Определяет период генератора целых чисел
  # Возвращает хеш: { period: Integer, repeat_value: Integer }
  def self.find_period(generator, max_iterations: 1_000_000)
    seen = {}
    count = 0

    loop do
      value = generator.next_int

      if seen.key?(value)
        return { period: count - seen[value], repeat_value: value }
      end

      seen[value] = count
      count += 1

      break if count >= max_iterations
    end

    # Если не нашли повтор за max_iterations — возвращаем nil
    { period: nil, repeat_value: nil }
  end
end
