# frozen_string_literal: true

require 'pathname'
require_relative 'util/api_debugger' if ENV['API_DEBUG']

ROOT_DIR = Pathname.new(File.expand_path('..', __dir__)) unless defined?(ROOT_DIR)

require "#{ROOT_DIR}/lib/framework/core/file_loader"
require "#{ROOT_DIR}/lib/framework/core/options/options_validator"

module CliApi
  # Gets a hash mapping fact names to their values
  #
  # @return [Array] the hash of fact names and values
  #
  # @api private
  def to_user_output(cli_options, *args)
    cli_options = cli_options.map { |(k, v)| [k.to_sym, v] }.to_h
    Facter::Options.init_from_cli(cli_options, args)
    @logger.info("executed with command line: #{ARGV.drop(1).join(' ')}")
    log_blocked_facts

    resolved_facts = Facter::FactManager.instance.resolve_facts(args)

    fact_formatter = Facter::FormatterFactory.build(Facter::Options.get)

    status = error_check(args, resolved_facts)

    [fact_formatter.format(resolved_facts), status || 0]
  end

  # Returns exit status when user query contains facts that do
  #   not exist
  #
  # @param dirs [Array] Arguments sent to CLI
  # @param dirs [Array] List of resolved facts
  #
  # @return [Integer, nil] Will return status 1 if user query contains
  #  facts that are not found or resolved, otherwise it will return nil
  #
  # @api private
  def error_check(args, resolved_facts)
    if Facter::Options[:strict]
      missing_names = args - resolved_facts.map(&:user_query).uniq
      if missing_names.count.positive?
        status = 1
        log_errors(missing_names)
      else
        status = nil
      end
    end

    status
  end

  # Prints out blocked facts before to_hash or to_user_output is called
  #
  # @return [nil]
  #
  # @api private
  def log_blocked_facts
    block_list = Facter::BlockList.new(Facter::Options[:config]).block_list
    @logger.debug("blocking collection of #{block_list.join("\s")} facts") if block_list.any? && Facter::Options[:block]
  end

  # Used for printing errors regarding CLI user input validation
  #
  # @param missing_names [Array] List of facts that were requested
  #  but not found
  #
  # @return [nil]
  #
  # @api private
  def log_errors(missing_names)
    missing_names.each do |missing_name|
      @logger.error("fact \"#{missing_name}\" does not exist.", true)
    end
  end
end
