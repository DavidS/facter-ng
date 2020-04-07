# frozen_string_literal: true

module Facter
  class OptionStore
    DEFAULT_LOG_LEVEL = :warn

    attr_accessor :debug, :trace, :verbose, :log_level, :show_legacy,
         :block, :custom_dir, :external_dir, :ruby, :cli,
         :custom_facts, :blocked_facts, :ttls, :config, :is_cli

    def initialize
      @debug = false
      @trace = false
      @verbose = false
      @log_level = DEFAULT_LOG_LEVEL
      @show_legacy = true
      @block = true
      @custom_dir = []
      @custom_facts = true
      @external_dir = []
      @external_facts = true
      @ruby = true
    end

    # def ruby
    #   @ruby
    # end
    #
    # def ruby=(bool)
    #   @ruby = bool
    # end
    #
    # def show_legacy=(bool)
    #   if bool == true
    #     @show_legacy = bool
    #     @ruby = true
    #   else
    #     @show_legacy = false
    #     @ruby = Facter::OptionDefaults.ruby
    #   end
    # end
    #
    # def cli=(bool)
    #   @cli = bool
    # end

    def method_missing(method_name, *args, &block)
      property_name = method_name.to_s.delete('=')
      Facter::OptionStore.class_eval do
        attr_accessor property_name
        send("#{method_name}", *args)
      end
    end
  end
end
