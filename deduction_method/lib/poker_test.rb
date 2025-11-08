# frozen_string_literal: true
require_relative "stat_utils"

def poker_test(samples, digits: 5)
  # безопасно вернуть нейтральный результат для пустого входа
  if samples.empty?
    empty_counts = {
      five: 0, four: 0, full_house: 0, three: 0,
      two_pairs: 0, one_pair: 0, all_diff: 0
    }
    return {
      counts: empty_counts,
      expected: empty_counts.transform_values { 0 },
      chi2: 0.0,
      df: empty_counts.size - 1,
      p_value: 1.0
    }
  end

  counts = Hash.new(0)
  samples.each do |v|
    s = String.new
    x = v
    digits.times do
      x *= 10
      d = x.floor
      s << d.to_s
      x -= d
    end
    freqs = s.chars.each_with_object(Hash.new(0)) { |c, h| h[c] += 1 }.values.sort.reverse
    case freqs
    when [5] then counts[:five] += 1
    when [4, 1] then counts[:four] += 1
    when [3, 2] then counts[:full_house] += 1
    when [3, 1, 1] then counts[:three] += 1
    when [2, 2, 1] then counts[:two_pairs] += 1
    when [2, 1, 1, 1] then counts[:one_pair] += 1
    when [1, 1, 1, 1, 1] then counts[:all_diff] += 1
    end
  end

  n = samples.length

  # вероятности по классической формуле для 5-значных "рук"
  p_all_diff = (10 * 9 * 8 * 7 * 6).to_f / 10**5
  p_one_pair = 10 * (5 * 4 / 2.0) * (9 * 8 * 7).to_f / 10**5
  p_two_pairs = (10 * 9 / 2.0) * (5 * 4 / 2.0) * (3 * 2 / 2.0) * 8.0 / 10**5
  p_three = 10 * (5 * 4 * 3 / 6.0) * (9 * 8).to_f / 10**5
  p_full = 10 * 9 * (5 / 1.0) / 10**5
  p_four = 10 * 5 * 9.0 / 10**5
  p_five = 10.0 / 10**5

  probs = {
    five: p_five, four: p_four, full_house: p_full,
    three: p_three, two_pairs: p_two_pairs,
    one_pair: p_one_pair, all_diff: p_all_diff
  }

  expected = probs.transform_values { |p| p * n }

  # гарантируем, что все ключи есть, даже если их нет в counts
  all_counts = probs.keys.map { |k| counts[k] || 0 }
  expected_values = probs.keys.map { |k| expected[k] }

  chi2 = StatUtils.chi2_stat(all_counts, expected_values)
  df = probs.size - 1
  p_value = StatUtils.chi2_pvalue(chi2, df)
  p_value = p_value.round(6).clamp(0.0, 1.0)

  {
    counts: probs.keys.map { |k| [k, counts[k] || 0] }.to_h,
    expected: expected,
    chi2: chi2,
    df: df,
    p_value: p_value
  }
end
