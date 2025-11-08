# frozen_string_literal: true
require_relative "../lib/correlation_test"
require_relative "../lib/lfsr"

RSpec.describe "Correlation test" do
  let(:lfsr) { LFSR.new(seed: 1, taps: [5,3], n_bits: 5) }
  let(:samples) { Array.new(5000) { lfsr.next_float(bits:32) } }

  it "возвращает rho и p_value для лагов" do
    result = correlation_test(samples, lags:[1,2,5])
    expect(result).to include(:mean,:var,:results)
    result[:results].each do |lag, stats|
      expect(stats).to include(:rho,:z,:p_value)
      expect(stats[:p_value]).to be_between(0.0,1.0)
    end
  end

  it "обрабатывает лаг = 0 и слишком большой лаг" do
    result = correlation_test(samples, lags:[0, 6000])
    expect(result[:results][0][:rho]).to eq(0.0)
    expect(result[:results][6000][:rho]).to eq(0.0)
    expect(result[:results][0][:p_value]).to eq(1.0)
  end

  it "работает с пустым массивом" do
    result = correlation_test([], lags:[1,2])
    expect(result[:mean]).to eq(0)
    expect(result[:var]).to eq(0)
    result[:results].each { |_, stats| expect(stats[:p_value]).to eq(1.0) }
  end
end
