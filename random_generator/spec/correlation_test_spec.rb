# frozen_string_literal: true
require_relative "../lib/correlation_test"
require_relative "../lib/random_generator"

RSpec.describe "Correlation test" do
  let(:rng) { RandomGenerator.new(42) }
  let(:samples) { Array.new(5000) { rng.next_float } }

  it "возвращает среднее, дисперсию и результаты корреляций" do
    result = correlation_test(samples, lags: [1,5,10])
    expect(result).to include(:mean, :var, :results)
    expect(result[:results].keys).to match_array([1,5,10])
    result[:results].each do |lag, data|
      expect(data[:rho]).to be_between(-1.0,1.0)
      expect(data[:p_value]).to be_between(0.0,1.0)
    end
  end

  it "работает с пустым массивом" do
    result = correlation_test([])
    expect(result[:mean]).to eq(0)
    expect(result[:var]).to eq(0)
    expect(result[:results]).to eq({})
  end
end
