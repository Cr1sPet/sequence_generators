require "spec_helper"
require_relative "../lib/poker_test"
require_relative "../lib/lcg"

RSpec.describe "Poker test" do
  let(:rng) { LCG.new(seed: 12345, a: 1103515245, c: 12345, m: 2**31) }

  it "returns expected keys" do
    samples = Array.new(2000) { rng.next_float }
    result = poker_test(samples, digits: 5)
    expect(result.keys).to include(:counts, :expected, :chi2, :df, :p_value)
    expect(result[:counts].keys).to include(:five, :four, :three, :all_diff)
    expect(result[:p_value]).to be_between(0.0, 1.0)
  end

  it "handles smaller number of digits" do
    samples = Array.new(1000) { rng.next_float }
    result = poker_test(samples, digits: 3)
    expect(result[:p_value]).to be_between(0.0, 1.0)
  end

  it "handles edge case: all identical values" do
    samples = Array.new(1000, 0.12345)
    result = poker_test(samples, digits: 5)
    expect(result[:counts].values.sum).to eq(1000)
    expect(result[:p_value]).to be_between(0.0, 1.0)
  end

  it "handles empty input safely" do
    result = poker_test([])
    expect(result[:chi2]).to eq(0)
    expect(result[:p_value]).to eq(1.0)
  end
end
