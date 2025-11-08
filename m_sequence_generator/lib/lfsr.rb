# frozen_string_literal: true

# Генератор М-последовательностей (LFSR)
class LFSR
  attr_reader :state, :taps, :n_bits

  def initialize(seed:, taps:, n_bits:)
    raise ArgumentError, "seed must be >0" if seed <= 0
    @state = seed
    @taps = taps
    @n_bits = n_bits
  end

  # возвращает следующий бит последовательности
  def next_bit
    bit = @state & 1
    feedback = @taps.reduce(0) { |acc, t| acc ^ ((@state >> (t - 1)) & 1) }
    @state = (@state >> 1) | (feedback << (@n_bits - 1))
    bit
  end

  # возвращает float в [0,1)
  def next_float(bits: 32)
    val = 0
    bits.times do
      val = (val << 1) | next_bit
    end
    val.to_f / (2**bits)
  end
end
