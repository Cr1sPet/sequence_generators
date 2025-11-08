# frozen_string_literal: true
require_relative "../lib/lfsr"

RSpec.describe LFSR do
  let(:lfsr) { LFSR.new(seed: 1, taps: [5,3], n_bits: 5) }

  it "возвращает биты 0 или 1" do
    100.times { expect([0,1]).to include(lfsr.next_bit) }
  end

  it "возвращает float в диапазоне [0,1)" do
    10.times do
      f = lfsr.next_float(bits: 16)
      expect(f).to be >= 0.0
      expect(f).to be < 1.0
    end
  end

  it "инициализация с seed <=0 выбрасывает ошибку" do
    expect { LFSR.new(seed: 0, taps: [1], n_bits: 1) }.to raise_error(ArgumentError)
  end
end
