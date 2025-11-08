
require 'spec_helper'

RSpec.describe 'main' do
  describe '#find_max_period_seeds' do
    subject(:result) { find_max_period_seeds(1..9999, 4) }

    describe 'максимальный период (число членов до вырождения)' do
      let(:expected_max_period) { 111 }

      it 'подсчитывается верно' do
        expect(result[:max_period]).to eq(expected_max_period)
      end
    end

    describe 'числа, по которым максимальный период' do
      let(:expected_max_seeds) { [6_239] }

      it 'подсчитывается верно' do
        expect(result[:max_seeds]).to eq(expected_max_seeds)
      end
    end
  end
end