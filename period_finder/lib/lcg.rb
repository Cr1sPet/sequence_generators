# frozen_string_literal: true

# Линейный конгруэнтный генератор (LCG)
class LCG
  attr_reader :a, :c, :m
  attr_accessor :seed

  def initialize(seed:, a:, c:, m:)
    @seed = seed
    @a = a
    @c = c
    @m = m
  end

  def next_int
    @seed = (a * @seed + c) % m
  end

  def next_float
    next_int.to_f / m
  end

  def reset(seed)
    @seed = seed
  end
end
