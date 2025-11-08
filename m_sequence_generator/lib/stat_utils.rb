# frozen_string_literal: true
require 'cmath'

module StatUtils
  def self.chi2_stat(observed, expected)
    raise ArgumentError, "length mismatch" unless observed.length == expected.length
    observed.zip(expected).sum { |o, e| (o - e)**2 / e.to_f }
  end

  def self.chi2_pvalue(chi2, df)
    # аппроксимация через неполную гамму
    1 - gammainc(df / 2.0, chi2 / 2.0)
  end

  def self.gammainc(a, x)
    # простая реализация нижнего интеграла гамма-функции (approx)
    n = 1000
    dx = x.to_f / n
    sum = 0.0
    (0...n).each { |i| sum += (dx * (dx * i)**(a-1) * Math.exp(-dx*i)) }
    sum / Math.gamma(a)
  end

  def self.norm_cdf(z)
    0.5 * (1 + Math.erf(z / Math.sqrt(2)))
  end
end
