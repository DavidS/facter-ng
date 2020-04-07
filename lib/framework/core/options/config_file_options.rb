# frozen_string_literal: true

module Facter
  module ConfigFileOptions
    def augment_with_config_file_options!(config_path = nil)
      conf_reader = Facter::ConfigReader.new(config_path)

      augment_config_path(config_path)
      augment_ruby(conf_reader.global)

      augment_custom(conf_reader.global)
      augment_external(conf_reader.global)
      augment_show_legacy(conf_reader.global)
      # augment_facts(conf_reader.ttls)
    end

    def augment_with_config_file_cli_options!(config_path)
      augment_cli(conf_reader.cli)
    end

    private

    def augment_config_path(config_path)
      @option_store.config = config_path
    end

    def augment_cli(file_cli_conf)
      return unless file_cli_conf

      @option_store.debug = file_cli_conf['debug'] unless file_cli_conf['debug'].nil?
      @option_store.trace = file_cli_conf['trace'] unless file_cli_conf['trace'].nil?
      @option_store.verbose = file_cli_conf['verbose'] unless file_cli_conf['verbose'].nil?
      @option_store.log_level = file_cli_conf['log-level'].to_sym unless file_cli_conf['log-level'].nil?
    end

    def augment_custom(file_global_conf)
      return unless file_global_conf

      if @option_store.is_cli
        @option_store.custom_facts = !file_global_conf['no-custom-facts'] unless file_global_conf['no-custom-facts'].nil?
      end
      @option_store.custom_dir = [file_global_conf['custom-dir']].flatten unless file_global_conf['custom-dir'].nil?
    end

    def augment_external(global_conf)
      return unless global_conf

      if @option_store.is_cli
        @option_store.external_facts = !global_conf['no-external-facts'] unless global_conf['no-external-facts'].nil?
      end
      @option_store.external_dir = [global_conf['external-dir']].flatten unless global_conf['external-dir'].nil?
    end

    def augment_ruby(global_conf)
      return unless global_conf

      @option_store.ruby = !global_conf['no-ruby'] unless global_conf['no-ruby'].nil?
    end

    def augment_show_legacy(global_conf)
      return unless global_conf

      @option_store.show_legacy = global_conf['show-legacy'] unless global_conf['show-legacy'].nil?
    end

    # def augment_facts(ttls)
    #   blocked_facts = Facter::BlockList.instance.blocked_facts
    #   @option_store.blocked_facts = blocked_facts unless blocked_facts.nil?
    #
    #   @option_store.ttls = ttls unless ttls.nil?
    # end
  end
end
