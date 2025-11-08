# frozen_string_literal: true
require_relative "stat_utils"

def correlation_test(samples, lags: [1,2,5,10])
  n = samples.length
  return { mean: 0, var: 0, results: {} } if n.zero?

  mean = samples.sum / n.to_f
  var = samples.sum { |x| (x - mean)**2 } / n
  res = {}

  lags.each do |lag|
    if lag <= 0 || lag >= n || var.zero?
      res[lag] = { rho: 0.0, z: 0.0, p_value: 1.0 }
      next
    end

    acov = (0...(n - lag)).sum { |i| (samples[i]-mean)*(samples[i+lag]-mean) } / (n-lag).to_f
    rho = acov / var
    z = rho * Math.sqrt(n)
    p_value = 2 * (1 - StatUtils.normal_cdf(z.abs))
    res[lag] = { rho: rho, z: z, p_value: p_value }
  end

  { mean: mean, var: var, results: res }
end
