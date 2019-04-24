require "shlogger/engine"
require "shlogger/configuration"

module Shlogger
  class << self
    attr_reader :config

    def configure
      @config = Configuration.new
      yield config
    end
  end
end
