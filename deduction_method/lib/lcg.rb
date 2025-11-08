# frozen_string_literal: true

class LCG
  attr_accessor :a, :c, :m, :x

  def initialize(seed: 1, a: 1664525, c: 1013904223, m: 2**32)
    @x = seed % m
    @a = a
    @c = c
    @m = m
  end

  def next_int
    @x = (@a * @x + @c) % @m
    @x
  end

  def next_float
    next_int.to_f / @m.to_f
  end

  def generate(n)
    Array.new(n) { next_float }
  end
end
