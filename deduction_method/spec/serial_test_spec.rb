require "spec_helper"
require_relative "../lib/serial_test"
require_relative "../lib/lcg"

RSpec.describe "Serial test" do
  let(:rng) { LCG.new(seed: 42, a: 1103515245, c: 12345, m: 2**31) }

  it "returns chi2 and p-value for valid samples" do
    samples = Array.new(5000) { rng.next_float }
    result = serial_test(samples, m: 10)
    expect(result).to include(:chi2, :df, :p_value)
    expect(result[:chi2]).to be_a(Float)
    expect(result[:p_value]).to be_between(0.0, 1.0)
  end

  it "handles small sample sets gracefully" do
    samples = [0.1, 0.2, 0.3]
    result = serial_test(samples, m: 5)
    expect(result[:p_value]).to be_between(0.0, 1.0)
  end

  it "handles empty samples safely" do
    result = serial_test([], m: 5)
    expect(result[:chi2]).to eq(0)
    expect(result[:p_value]).to eq(1.0)
  end
end
