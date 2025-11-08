# frozen_string_literal: true
require "rspec"
require_relative "../lib/lcg"
require_relative "../lib/frequency_test"

RSpec.describe "Frequency test" do
  let(:lcg) { LCG.new(seed: 12345) }
  let(:samples) { lcg.generate(10_000) }

  it "возвращает chi2 и p_value в корректном диапазоне" do
    result = frequency_test(samples)
    expect(result).to include(:chi2, :df, :p_value)
    expect(result[:chi2]).to be_a(Float)
    expect(result[:p_value]).to be_between(0.0, 1.0)
  end

  it "обрабатывает пустой массив" do
    result = frequency_test([])
    expect(result[:chi2]).to eq(0.0)
    expect(result[:p_value]).to eq(1.0)
    expect(result[:df]).to eq(0)
  end

  it "корректно считает примерно равное количество 0 и 1 для большого генератора" do
    zeros = samples.count { |v| v < 0.5 }
    ones = samples.count { |v| v >= 0.5 }
    expect((zeros - ones).abs.to_f / samples.size).to be < 0.05
  end
end
