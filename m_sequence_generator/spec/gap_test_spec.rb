# frozen_string_literal: true
require_relative "../lib/gap_test"
require_relative "../lib/lfsr"

RSpec.describe "Gap test" do
  let(:lfsr) { LFSR.new(seed: 1, taps: [5,3], n_bits: 5) }
  let(:samples) { Array.new(5000) { lfsr.next_float(bits:32) } }

  it "возвращает chi2 и p_value" do
    result = gap_test(samples, a:0.2, b:0.3)
    expect(result).to include(:chi2,:df,:p_value)
    expect(result[:p_value]).to be_between(0.0,1.0)
  end

  it "обрабатывает все значения в интервале" do
    samples_all = Array.new(1000, 0.25)
    result = gap_test(samples_all, a:0.2,b:0.3)
    expect(result[:chi2]).to be_a(Float)
    expect(result[:p_value]).to be_between(0.0,1.0)
  end

  it "обрабатывает пустой массив" do
    result = gap_test([], a:0.2,b:0.3)
    expect(result[:chi2]).to eq(0)
    expect(result[:p_value]).to eq(1.0)
  end
end
