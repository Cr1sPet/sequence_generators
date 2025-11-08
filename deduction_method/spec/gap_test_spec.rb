require "spec_helper"
require_relative "../lib/gap_test"
require_relative "../lib/lcg"

RSpec.describe "Gap test" do
  let(:rng) { LCG.new(seed: 777, a: 1103515245, c: 12345, m: 2**31) }

  it "computes chi2 and p_value for uniform samples" do
    samples = Array.new(5000) { rng.next_float }
    result = gap_test(samples, a: 0.3, b: 0.7)
    expect(result).to include(:chi2, :df, :p_value)
    expect(result[:p_value]).to be_between(0.0, 1.0)
  end

  it "handles very narrow range" do
    samples = Array.new(5000) { rng.next_float }
    result = gap_test(samples, a: 0.49, b: 0.5)
    expect(result[:p_value]).to be_between(0.0, 1.0)
  end

  it "handles edge case: all values in the gap" do
    samples = Array.new(1000, 0.9)
    result = gap_test(samples, a: 0.1, b: 0.8)
    expect(result[:chi2]).to be_a(Float)
    expect(result[:p_value]).to be_between(0.0, 1.0)
  end

  it "handles empty input safely" do
    result = gap_test([], a: 0.2, b: 0.8)
    expect(result[:chi2]).to eq(0)
    expect(result[:p_value]).to eq(1.0)
  end
end
