# frozen_string_literal: true
require_relative "stat_utils"

def serial_test(samples, d: 2, bins: 10)
  return { chi2: 0.0, df: 0, p_value: 1.0 } if samples.empty?

  n = samples.length
  tuples = (0..(n - d)).map { |i| samples[i, d] }
  tuples_length = tuples.length
  cell_counts = Hash.new(0)
  tuples.each do |t|
    idx = t.map { |v| [(v * bins).floor, bins - 1].min }.join(',')
    cell_counts[idx] += 1
  end

  m_cells = bins**d
  expected = tuples_length.to_f / m_cells
  observed = cell_counts.values + Array.new(m_cells - cell_counts.size, 0)
  chi2 = StatUtils.chi2_stat(observed, Array.new(observed.length, expected))
  df = m_cells - 1
  p_value = StatUtils.chi2_pvalue(chi2, df)
  { d: d, bins: bins, chi2: chi2, df: df, p_value: p_value }
end
