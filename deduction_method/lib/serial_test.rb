# frozen_string_literal: true
require_relative "stat_utils"

def serial_test(samples, d: 2, bins: nil, m: 10)
  # поддержка обоих параметров: bins и m
  bins ||= m

  n = samples.length
  return { d: d, bins: bins, cells: bins**d, tuples_length: 0, chi2: 0.0, df: bins**d - 1, p_value: 1.0 } if n == 0

  # если данных меньше, чем размер окна, возвращаем безопасный результат
  if n < d
    return { d: d, bins: bins, cells: bins**d, tuples_length: 0, chi2: 0.0, df: bins**d - 1, p_value: 1.0 }
  end

  tuples = (0..(n - d)).map { |i| samples[i, d] }
  tuples_length = tuples.length
  cell_counts = Hash.new(0)

  tuples.each do |t|
    idx = t.map { |v| [(v * bins).floor, bins - 1].min }.join(',')
    cell_counts[idx] += 1
  end

  m_cells = bins**d
  expected = tuples_length.to_f / m_cells.to_f

  observed = cell_counts.values + Array.new(m_cells - cell_counts.size, 0)

  chi2 = StatUtils.chi2_stat(observed, Array.new(observed.length, expected))
  df = m_cells - 1
  p = StatUtils.chi2_pvalue(chi2, df)
  p = p.round(6).clamp(0.0, 1.0)

  {
    d: d,
    bins: bins,
    cells: m_cells,
    tuples_length: tuples_length,
    chi2: chi2,
    df: df,
    p_value: p
  }
end
