# frozen_string_literal: true
require_relative "stat_utils"

def frequency_test(samples)
  # Защита от пустого массива
  return { chi2: 0.0, df: 0, p_value: 1.0 } if samples.empty?

  n = samples.size
  ones = samples.count { |v| v >= 0.5 }
  zeros = n - ones

  expected = n / 2.0
  observed = [zeros, ones]
  expected_values = [expected, expected]

  # Защита от нулевых значений (чтобы chi2_stat не ломался)
  if observed.all?(&:zero?) || expected_values.all?(&:zero?)
    return { chi2: 0.0, df: 1, p_value: 1.0 }
  end

  chi2 = StatUtils.chi2_stat(observed, expected_values)
  # Если chi2 вернулся NaN/Infinity — вернуть безопасное значение
  chi2 = 0.0 if chi2.nan? || chi2.infinite?

  p_value = StatUtils.chi2_pvalue(chi2, 1)
  p_value = 1.0 if p_value.nan? || p_value < 0.0

  { chi2: chi2, df: 1, p_value: p_value }
end
