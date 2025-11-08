# frozen_string_literal: true
require 'rspec'

# Настройки RSpec
RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Чтобы видеть вывод прогресса в терминале
  config.formatter = :documentation

  # Можно отключить monkey patching
  config.disable_monkey_patching!

  # Включаем фильтр по focus
  config.filter_run_when_matching :focus

  # Seed для воспроизводимости случайных тестов
  config.order = :random
  Kernel.srand config.seed
end
