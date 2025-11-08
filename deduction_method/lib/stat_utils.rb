# frozen_string_literal: true

module StatUtils
  def self.chi2_stat(observed, expected)
    raise ArgumentError, "length mismatch" unless observed.length == expected.length
    observed.zip(expected).sum { |o, e| e.zero? ? 0 : ((o - e)**2) / e.to_f }
  end

  def self.erf(x)
    a1, a2, a3, a4, a5, p = 0.254829592, -0.284496736, 1.421413741, -1.453152027, 1.061405429, 0.3275911
    sign = x.negative? ? -1 : 1
    x = x.abs
    t = 1.0 / (1.0 + p * x)
    y = 1.0 - (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t * Math.exp(-x * x)
    sign * y
  end

  def self.norm_cdf(z)
    0.5 * (1 + erf(z / Math.sqrt(2)))
  end

  def self.chi2_pvalue(stat, df)
    return 1.0 if df.zero?
    if df > 50
      z = (stat - df) / Math.sqrt(2.0 * df)
      1.0 - 0.5 * (1 + erf(z / Math.sqrt(2)))
    else
      t = (stat / df)**(1.0 / 3.0)
      mu = 1.0 - 2.0 / (9.0 * df)
      sigma = Math.sqrt(2.0 / (9.0 * df))
      z = (t - mu) / sigma
      1.0 - 0.5 * (1 + erf(z / Math.sqrt(2)))
    end
  end
end
