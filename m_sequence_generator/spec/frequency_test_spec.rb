# frozen_string_literal: true
require_relative "../lib/frequency_test"
require_relative "../lib/lfsr"

RSpec.describe "Frequency test" do
  let(:lfsr) { LFSR.new(seed: 1, taps: [5,3], n_bits: 5) }
  let(:samples) { Array.new(5000) { lfsr.next_float(bits:32) } }

  it "возвращает chi2 и p_value в диапазоне" do
    result = frequency_test(samples)
    expect(result).to include(:chi2, :df, :p_value)
    expect(result[:chi2]).to be_a(Float)
    expect(result[:p_value]).to be_between(0.0, 1.0)
  end

  it "работает с пустым массивом" do
    result = frequency_test([])
    expect(result[:chi2]).to eq(0.0)
    expect(result[:p_value]).to eq(1.0)
  end
end
