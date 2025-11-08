# frozen_string_literal: true
require_relative "../lib/random_generator"

RSpec.describe RandomGenerator do
  it "возвращает значения от 0 до 1" do
    rng = RandomGenerator.new(42)
    100.times do
      expect(rng.next_float).to be_between(0.0,1.0)
    end
  end

  it "генератор с одинаковым сидом повторяет последовательность" do
    r1 = RandomGenerator.new(42)
    r2 = RandomGenerator.new(42)
    seq1 = Array.new(10) { r1.next_float }
    seq2 = Array.new(10) { r2.next_float }
    expect(seq1).to eq(seq2)
  end

  it "метод reset изменяет последовательность" do
    rng = RandomGenerator.new(42)
    first = rng.next_float
    rng.reset(42)
    expect(rng.next_float).to eq(first)
  end
end
