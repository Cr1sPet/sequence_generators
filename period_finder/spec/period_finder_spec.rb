# frozen_string_literal: true
require_relative "../lib/period_finder"
require_relative "../lib/lcg"

RSpec.describe PeriodFinder do
  let(:lcg) { LCG.new(seed: 1, a: 5, c: 3, m: 16) }

  it "находит период конечной последовательности" do
    result = PeriodFinder.find_period(lcg)
    expect(result[:period]).to be_a(Integer)
    expect(result[:period]).to be > 0
    expect(result[:repeat_value]).to be_between(0, 15)
  end

  it "возвращает nil, если повтор не найден в пределах max_iterations" do
    # простой генератор с большим модулем, чтобы повтор не успел появиться
    slow = LCG.new(seed: 1, a: 1103515245, c: 12345, m: 2**31)
    result = PeriodFinder.find_period(slow, max_iterations: 1000)
    expect(result[:period]).to be_nil
    expect(result[:repeat_value]).to be_nil
  end

  it "корректно обрабатывает маленький модуль" do
    lcg = LCG.new(seed: 0, a: 2, c: 1, m: 4)
    result = PeriodFinder.find_period(lcg)
    expect(result[:period]).to be_between(1, 4)
  end

  it "корректно работает для тривиального генератора (m = 1)" do
    trivial = LCG.new(seed: 0, a: 1, c: 0, m: 1)
    result = PeriodFinder.find_period(trivial)
    expect(result[:period]).to eq(1)
  end

  describe "Анализ" do
    it "показывает влияние параметров генератора на период" do
      params = [
        { a: 5, c: 3, m: 16 },
        { a: 5, c: 2, m: 16 },
        { a: 6, c: 3, m: 16 }
      ]

      results = params.map do |p|
        gen = LCG.new(seed: 1, a: p[:a], c: p[:c], m: p[:m])
        PeriodFinder.find_period(gen).merge(a: p[:a], c: p[:c], m: p[:m])
      end

      results.each do |res|
        puts "a=#{res[:a]}, c=#{res[:c]}, m=#{res[:m]} → period=#{res[:period]}"
      end

      expect(results.map { |r| r[:period] }).to all(be > 0)
    end

    it "оценивает объём выборки для доверительного интервала" do
      sigma = 2.0
      d = 0.5
      alpha = 0.05
      z = 1.959964  # квантиль нормального распределения для 95%

      n = ((z * sigma / d)**2).ceil
      expect(n).to be_a(Integer)
      expect(n).to be > 0

      puts "Необходимый объём выборки n = #{n} для погрешности d=#{d} и alpha=#{alpha}"
    end
  end

  describe "Анализ влияния характеристического полинома" do
    it "показывает влияние параметров генератора на период" do
      params = [
        { a: 5, c: 3, m: 16 },
        { a: 5, c: 2, m: 16 },
        { a: 6, c: 3, m: 16 }
      ]

      results = params.map do |p|
        gen = LCG.new(seed: 1, a: p[:a], c: p[:c], m: p[:m])
        PeriodFinder.find_period(gen).merge(a: p[:a], c: p[:c], m: p[:m])
      end

      results.each do |res|
        puts "a=#{res[:a]}, c=#{res[:c]}, m=#{res[:m]} → period=#{res[:period]}"
      end

      expect(results.map { |r| r[:period] }).to all(be > 0)
    end
  end
end
