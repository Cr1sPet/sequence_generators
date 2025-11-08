# frozen_string_literal: true
require_relative "spec_helper"

RSpec.describe LCG do
  it "generates reproducible sequence" do
    g1 = LCG.new(seed: 1)
    g2 = LCG.new(seed: 1)
    expect(g1.generate(10)).to eq(g2.generate(10))
  end

  it "produces values in (0,1)" do
    g = LCG.new
    arr = g.generate(100)
    expect(arr.all? { |x| x >= 0 && x < 1 }).to be true
  end
end
