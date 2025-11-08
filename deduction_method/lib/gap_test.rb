# frozen_string_literal: true
require_relative "stat_utils"

def gap_test(samples, a: 0.2, b: 0.3, max_gap_bin: 10)
  return { interval: [a, b], p_interval: 0.0, n_gaps: 0, chi2: 0.0, df: 0, p_value: 1.0 } if samples.empty?

  p = b - a
  gaps = []
  current = 0

  samples.each do |v|
    if v >= a && v < b
      gaps << current
      current = 0
    else
      current += 1
    end
  end

  n = gaps.size
  # если вообще не встретилось ни одного попадания — корректно обработаем
  if n == 0
    return { interval: [a, b], p_interval: p, n_gaps: 0, chi2: 0.0, df: 0, p_value: 1.0 }
  end

  freqs = Array.new(max_gap_bin + 1, 0)
  gaps.each { |g| g >= max_gap_bin ? freqs[max_gap_bin] += 1 : freqs[g] += 1 }

  expected = (0...max_gap_bin).map { |k| n * ((1 - p)**k) * p }
  expected << n * ((1 - p)**max_gap_bin)

  chi2 = StatUtils.chi2_stat(freqs, expected)
  df = freqs.length - 1
  p_val = StatUtils.chi2_pvalue(chi2, df)

  { interval: [a, b], p_interval: p, n_gaps: n, chi2: chi2.to_f, df: df, p_value: p_val }
end
