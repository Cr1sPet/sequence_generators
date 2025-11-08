# frozen_string_literal: true
require_relative "../lib/poker_test"
require_relative "../lib/lfsr"

RSpec.describe "Poker test" do
  let(:lfsr) { LFSR.new(seed: 1, taps: [5,3], n_bits: 5) }
  let(:samples) { Array.new(2000) { lfsr.next_float(bits:32) } }

  it "возвращает ключи и p_value" do
    result = poker_test(samples, digits:5)
    expect(result).to include(:counts, :expected, :chi2, :df, :p_value)
    expect(result[:counts].keys).to include(:five,:four,:three,:all_diff)
    expect(result[:p_value]).to be_between(0.0,1.0)
  end

  it "работает с пустым массивом" do
    result = poker_test([])
    expect(result[:chi2]).to eq(0)
    expect(result[:p_value]).to eq(1.0)
  end
end
