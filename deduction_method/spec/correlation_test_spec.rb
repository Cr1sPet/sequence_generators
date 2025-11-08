require "spec_helper"
require_relative "../lib/correlation_test"
require_relative "../lib/lcg"

RSpec.describe "Correlation test" do
  let(:rng) { LCG.new(seed: 100, a: 1664525, c: 1013904223, m: 2**32) }

  it "computes correlation and p-value for several lags" do
    samples = Array.new(5000) { rng.next_float }
    [1, 2, 5].each do |lag|
      result = correlation_test(samples, lags: [lag])
      expect(result).to include(:mean, :var, :results)
      expect(result[:results]).to have_key(lag)
      lag_res = result[:results][lag]
      expect(lag_res).to include(:rho, :p_value)
      expect(lag_res[:p_value]).to be_between(0.0, 1.0)
    end
  end

  it "handles minimal lag" do
    samples = Array.new(100) { rng.next_float }
    result = correlation_test(samples, lags: [1])
    lag_res = result[:results][1]
    expect(lag_res[:rho].abs).to be < 1
  end

  it "handles zero or too-large lag gracefully" do
    samples = Array.new(100) { rng.next_float }
    result_zero = correlation_test(samples, lags: [0])
    result_large = correlation_test(samples, lags: [200])
    expect(result_zero[:results][0][:rho]).to eq(0)
    expect(result_large[:results][200][:rho]).to eq(0)
  end

  it "handles empty input safely" do
    result = correlation_test([], lags: [1])
    expect(result[:results][1][:rho]).to eq(0)
    expect(result[:results][1][:p_value]).to eq(1.0)
  end
end
