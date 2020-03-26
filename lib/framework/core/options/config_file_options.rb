# frozen_string_literal: true

module Facter
  class ConfigFileOptions
    class << self
      def init(config_path = nil)
        @options = {}
        conf_reader = Facter::ConfigReader.init(config_path)

        augment_config_path(config_path)

        if Options.cli?
          augment_cli(conf_reader.cli)
          augment_ruby(conf_reader.global)
        end
        augment_custom(conf_reader.global)
        augment_external(conf_reader.global)
        augment_show_legacy(conf_reader.global)
        augment_facts(conf_reader.ttls, config_path)
      end

      def get
        @options || {}
      end

      private

      def augment_config_path(config_path)
        @options[:config] = config_path
      end

      def augment_cli(file_cli_conf)
        return unless file_cli_conf

        @options[:debug] = file_cli_conf['debug'] unless file_cli_conf['debug'].nil?
        @options[:trace] = file_cli_conf['trace'] unless file_cli_conf['trace'].nil?
        @options[:verbose] = file_cli_conf['verbose'] unless file_cli_conf['verbose'].nil?
        @options[:log_level] = file_cli_conf['log-level'].to_sym unless file_cli_conf['log-level'].nil?
      end

      def augment_custom(file_global_conf)
        return unless file_global_conf

        if Options.cli?
          @options[:custom_facts] = !file_global_conf['no-custom-facts'] unless file_global_conf['no-custom-facts'].nil?
        end

        @options[:custom_dir] = file_global_conf['custom-dir'] unless file_global_conf['custom-dir'].nil?
      end

      def augment_external(global_conf)
        return unless global_conf

        if Options.cli?
          @options[:external_facts] = !global_conf['no-external-facts'] unless global_conf['no-external-facts'].nil?
        end

        @options[:external_dir] = [global_conf['external-dir']].flatten unless global_conf['external-dir'].nil?
      end

      def augment_ruby(global_conf)
        return unless global_conf

        @options[:ruby] = global_conf['no-ruby'].nil? ? true : !global_conf['no-ruby']
      end

      def augment_show_legacy(global_conf)
        return unless global_conf

        @options[:show_legacy] = global_conf['show-legacy'] unless global_conf['show-legacy'].nil?
      end

      def augment_facts(ttls, config_path)
        blocked_facts = Facter::BlockList.new(config_path).blocked_facts
        @options[:blocked_facts] = blocked_facts unless blocked_facts.nil?

        @options[:ttls] = ttls unless ttls.nil?
      end
    end
  end
end
