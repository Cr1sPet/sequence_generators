# frozen_string_literal: true
require_relative "stat_utils"

def frequency_test(samples)
  # Обрабатываем пустой массив
  return { chi2: 0.0, df: 0, p_value: 1.0 } if samples.empty?

  n = samples.size
  ones = samples.count { |v| v >= 0.5 }
  zeros = n - ones
  expected = n / 2.0

  chi2 = StatUtils.chi2_stat([zeros, ones], [expected, expected])
  p_value = StatUtils.chi2_pvalue(chi2, 1)

  { chi2: chi2, df: 1, p_value: p_value }
end
