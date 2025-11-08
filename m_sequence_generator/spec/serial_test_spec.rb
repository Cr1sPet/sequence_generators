# frozen_string_literal: true
require_relative "../lib/serial_test"
require_relative "../lib/lfsr"

RSpec.describe "Serial test" do
  let(:lfsr) { LFSR.new(seed: 1, taps: [5,3], n_bits: 5) }
  let(:samples) { Array.new(5000) { lfsr.next_float(bits:32) } }

  it "возвращает chi2 и p_value" do
    result = serial_test(samples, d:2, bins:10)
    expect(result).to include(:chi2, :df, :p_value)
    expect(result[:chi2]).to be_a(Float)
    expect(result[:p_value]).to be_between(0.0, 1.0)
  end

  it "работает с маленькой выборкой" do
    result = serial_test([0.1,0.2,0.3], d:2, bins:2)
    expect(result[:p_value]).to be_between(0.0,1.0)
  end

  it "работает с пустой выборкой" do
    result = serial_test([], d:2, bins:2)
    expect(result[:chi2]).to eq(0)
    expect(result[:p_value]).to eq(1.0)
  end
end
