# spec/frequency_test_spec.rb
require_relative "../lib/frequency_test"
require_relative "../lib/random_generator"

RSpec.describe "Frequency test" do
  let(:rng) { RandomGenerator.new(42) }
  let(:samples) { Array.new(5000) { rng.next_float } }

  it "возвращает chi2 и p_value в диапазоне" do
    result = frequency_test(samples)
    expect(result).to include(:chi2, :df, :p_value)
    expect(result[:p_value]).to be_between(0.0, 1.0)
  end

  it "работает с пустым массивом" do
    result = frequency_test([])
    expect(result[:chi2]).to eq(0.0)
    expect(result[:p_value]).to eq(1.0)
  end
end
