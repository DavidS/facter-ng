# frozen_string_literal: true

module Facter
  class Options
    class << self
      def cli?
        OptionStore.cli
      end

      def get
        options = {}
        OptionStore.instance_variables.each do |iv|
          variable_name = iv.to_s.delete('@')
          options[variable_name.to_sym] = OptionStore.send(variable_name.to_sym)
        end
        options
      end

      def [](key)
        OptionStore.send(key.to_sym)
      end

      def []=(key, value)
        OptionStore.send("#{key}=".to_sym, value)
      end

      def custom_dir?
        OptionStore.custom_dir && OptionStore.custom_facts
      end

      def custom_dir
        OptionStore.custom_dir.flatten!
      end

      def external_dir?
        OptionStore.external_dir && OptionStore.external_facts
      end

      def external_dir
        OptionStore.external_dir
      end

      def init
        OptionStore.cli = false
        store(ConfigFileOptions.get)
      end

      def init_from_cli(cli_options = {}, user_query = nil)
        Facter::OptionStore.cli = true
        Facter::OptionStore.show_legacy = false
        Facter::OptionStore.user_query = user_query

        ConfigFileOptions.init(cli_options[:config])
        store(ConfigFileOptions.get)
        store(cli_options)

        Facter::OptionsValidator.validate_configs(get)
      end

      def store(options)
        options.each do |key, val|
          val = '' if key == 'log_level' && val == 'log_level'
          OptionStore.send("#{key}=".to_sym, val)
        end
      end
    end
  end
end
