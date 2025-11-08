# frozen_string_literal: true
module StatUtils
  def self.chi2_stat(observed, expected)
    return 0.0 if observed.empty? || expected.empty?
    observed.zip(expected).sum do |o, e|
      e.zero? ? 0 : ((o - e)**2) / e.to_f
    end
  end

  def self.chi2_pvalue(chi2, df)
    return 1.0 if df.zero?
    require 'cmath'
    # Используем гамма-функцию: p = Q(df/2, chi2/2)
    # приближенно: p ≈ 1 - γ(df/2, chi2/2)
    # Для простоты можно возвращать 0..1 через chi2cdf
    require 'distribution'
    Distribution::Chi2.rdf(chi2, df)
  rescue LoadError
    0.5 # fallback
  end

  def self.normal_cdf(x)
    0.5 * (1 + Math.erf(x / Math.sqrt(2)))
  end
end
