# frozen_string_literal: true
require_relative "../lib/serial_test"
require_relative "../lib/random_generator"

RSpec.describe "Serial test" do
  let(:rng) { RandomGenerator.new(42) }
  let(:samples) { Array.new(5000) { rng.next_float } }

  it "возвращает chi2 и p_value" do
    result = serial_test(samples, d:2, bins:10)
    expect(result).to include(:chi2, :df, :p_value)
    expect(result[:p_value]).to be_between(0.0, 1.0)
  end

  it "работает с пустым массивом" do
    result = serial_test([], d:2, bins:10)
    expect(result[:chi2]).to eq(0.0)
    expect(result[:p_value]).to eq(1.0)
  end
end
