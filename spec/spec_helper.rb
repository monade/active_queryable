require 'active_support'
require 'rspec'

I18n.enforce_available_locales = false
RSpec::Expectations.configuration.warn_about_potential_false_positives = false

RSpec.configure do |config|

  config.around(:each) do |example|
    ActiveRecord::Base.transaction do
      example.run
      raise ActiveRecord::Rollback
    end
  end
end


