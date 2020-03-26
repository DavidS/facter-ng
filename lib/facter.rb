# frozen_string_literal: true

require 'pathname'
require_relative 'util/api_debugger' if ENV['API_DEBUG']

ROOT_DIR = Pathname.new(File.expand_path('..', __dir__)) unless defined?(ROOT_DIR)

require "#{ROOT_DIR}/lib/framework/core/file_loader"
require "#{ROOT_DIR}/lib/framework/core/options/options_validator"
require "#{ROOT_DIR}/lib/api/gem_api"
require "#{ROOT_DIR}/lib/api/cli_api"
require "#{ROOT_DIR}/lib/api/log_api"


module Facter
  @logger = Facter::Log.new(self)
  ConfigReader.init
  Options.init

  extend LogApi
  extend GemApi
  extend CliApi

end
