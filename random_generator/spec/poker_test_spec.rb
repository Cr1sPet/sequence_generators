# frozen_string_literal: true
require_relative "../lib/poker_test"
require_relative "../lib/random_generator"

RSpec.describe "Poker test" do
  let(:rng) { RandomGenerator.new(42) }
  let(:samples) { Array.new(2000) { rng.next_float } }

  it "возвращает ключи и p_value" do
    result = poker_test(samples, digits:5)
    expect(result).to include(:counts, :expected, :chi2, :df, :p_value)
    expect(result[:counts].keys).to all(be_a(Symbol))
    expect(result[:p_value]).to be_between(0.0, 1.0)
  end

  it "работает с пустым массивом" do
    result = poker_test([])
    expect(result[:chi2]).to eq(0.0)
    expect(result[:p_value]).to eq(1.0)
  end
end
