# frozen_string_literal: true

# Обертка над Ruby Random
class RandomGenerator
  def initialize(seed = nil)
    @rng = seed ? Random.new(seed) : Random.new
  end

  def next_float
    @rng.rand
  end

  def next_int(max)
    @rng.rand(max)
  end

  def reset(seed = nil)
    @rng = seed ? Random.new(seed) : Random.new
  end
end
