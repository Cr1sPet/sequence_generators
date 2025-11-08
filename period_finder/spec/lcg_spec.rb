# frozen_string_literal: true
require_relative "../lib/lcg"

RSpec.describe LCG do
  let(:lcg) { LCG.new(seed: 1, a: 5, c: 3, m: 16) }

  it "генерирует значения в диапазоне [0, m)" do
    50.times do
      val = lcg.next_int
      expect(val).to be_between(0, 15)
    end
  end

  it "возвращает float в диапазоне [0, 1)" do
    expect(lcg.next_float).to be_between(0.0, 1.0)
  end

  it "сбрасывает seed корректно" do
    lcg.reset(10)
    expect(lcg.seed).to eq(10)
  end
end
