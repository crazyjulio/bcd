require 'active_support/configurable'

module PaypalConfig
  def self.configure(&block)
    yield @config ||= PaypalConfig::Configuration.new
  end

  def self.config
    @config ||= {}
  end

  def self.config=(hash)
    @config=hash
  end

  class Configuration
    include ActiveSupport::Configurable
    config_accessor :business_email
    config_accessor :return_url
    config_accessor :host
    config_accessor :notify_url
  end
end