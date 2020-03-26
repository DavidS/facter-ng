# frozen_string_literal: true

module GemApi
  class ResolveCustomFactError < StandardError; end

  def clear_messages
    @logger.debug('clear_messages is not implemented')
  end

  # Alias method for Facter.fact()
  # @param name [string] fact name
  #
  # @return [Facter::Util::Fact, nil] The fact object, or nil if no fact
  #   is found.
  #
  # @api public
  def [](name)
    fact(name)
  end

  # Add custom facts to fact collection
  # @param name [String] Custom fact name
  # @param options = {} [Hash] optional parameters for the fact - attributes
  #   of {Facter::Util::Fact} and {Facter::Util::Resolution} can be
  #   supplied here
  # @param block [Proc] a block defining a fact resolution
  #
  # @return [Facter::Util::Fact] the fact object, which includes any previously
  #   defined resolutions
  #
  # @api public
  def add(name, options = {}, &block)
    options[:fact_type] = :custom
    Facter::LegacyFacter.add(name, options, &block)
    Facter::LegacyFacter.collection.invalidate_custom_facts
  end

  # Clears all cached values and removes all facts from memory.
  #
  # @return [nil]
  #
  # @api public
  def clear
    @already_searched = {}
    Facter::LegacyFacter.clear
    Facter::LegacyFacter.collection.invalidate_custom_facts
    Facter::LegacyFacter.collection.reload_custom_facts
  end

  def core_value(user_query)
    user_query = user_query.to_s
    resolved_facts = Facter::FactManager.instance.resolve_core([user_query])
    fact_collection = Facter::FactCollection.new.build_fact_collection!(resolved_facts)
    splitted_user_query = Facter::Utils.split_user_query(user_query)
    fact_collection.dig(*splitted_user_query)
  end

  # Returns a fact object by name.  If you use this, you still have to
  # call {Facter::Util::Fact#value `value`} on it to retrieve the actual
  # value.
  #
  # @param name [String] the name of the fact
  #
  # @return [Facter::Util::Fact, nil] The fact object, or nil if no fact
  #   is found.
  #
  # @api public
  def fact(user_query)
    user_query = user_query.to_s
    resolve_fact(user_query)

    @already_searched[user_query]
  end

  # Reset search paths for custom and external facts
  # If config file is set custom and external facts will be reloaded
  #
  # @return [nil]
  #
  # @api public
  def reset
    Facter::LegacyFacter.reset
    Facter::LegacyFacter.search(*Options.custom_dir)
    Facter::LegacyFacter.search_external(Options.external_dir)
    nil
  end

  # Register directories to be searched for custom facts. The registered directories
  # must be absolute paths or they will be ignored.
  #
  # @param dirs [Array<String>] An array of searched directories
  #
  # @return [void]
  #
  # @api public
  def search(*dirs)
    Facter::LegacyFacter.search(*dirs)
  end

  # Registers directories to be searched for external facts.
  #
  # @param dirs [Array<String>] An array of searched directories
  #
  # @return [void]
  #
  # @api public
  def search_external(dirs)
    Facter::LegacyFacter.search_external(dirs)
  end

  # Returns the registered search directories.for external facts.
  #
  # @return [Array<String>] An array of searched directories
  #
  # @api public
  def search_external_path
    Facter::LegacyFacter.search_external_path
  end

  # Returns the registered search directories for custom facts.
  #
  # @return [Array<String>] An array of the directories searched
  #
  # @api public
  def search_path
    Facter::LegacyFacter.search_path
  end

  # Gets a hash mapping fact names to their values
  # The hash contains core facts, legacy facts, custom facts and external facts (all facts that can be resolved).
  #
  # @return [Facter::FactCollection] the hash of fact names and values
  #
  # @api public
  def to_hash
    log_blocked_facts

    # Options.init_from_api
    reset
    resolved_facts = Facter::FactManager.instance.resolve_facts
    Facter::SessionCache.invalidate_all_caches
    Facter::FactCollection.new.build_fact_collection!(resolved_facts)
  end

  # Gets the value for a fact. Returns `nil` if no such fact exists.
  #
  # @param name [String] the fact name
  # @return [String] the value of the fact, or nil if no fact is found
  #
  # @api public
  def value(user_query)
    user_query = user_query.to_s
    resolve_fact(user_query)
    @already_searched[user_query]&.value
  end

  # Returns Facter version
  #
  # @return [String] Current version
  #
  # @api public
  def version
    version_file = ::File.join(ROOT_DIR, 'VERSION')
    ::File.read(version_file).strip
  end

  private

  def add_fact_to_searched_facts(user_query, value)
    @already_searched[user_query] ||= ResolvedFact.new(user_query, value)
    @already_searched[user_query].value = value
  end

  # Returns a ResolvedFact and saves the result in @already_searched array that is used as a global collection.
  # @param user_query [String] Fact that needs resolution
  #
  # @return [ResolvedFact]
  def resolve_fact(user_query)
    user_query = user_query.to_s
    resolved_facts = Facter::FactManager.instance.resolve_facts([user_query])
    Facter::SessionCache.invalidate_all_caches
    fact_collection = Facter::FactCollection.new.build_fact_collection!(resolved_facts)
    splitted_user_query = Facter::Utils.split_user_query(user_query)

    begin
      value = fact_collection.value(*splitted_user_query)
      add_fact_to_searched_facts(user_query, value)
    rescue KeyError
      nil
    end
  end

  # Proxy method that catches not yet implemented method calls
  #
  # @param name [type] [description]
  # @param *args [type] [description]
  # @param &block [type] [description]
  #
  # @return [type] [description]
  #
  # @api private
  def method_missing(name, *args, &block)
    @logger.error(
      "--#{name}-- not implemented but required \n" \
      'with params: ' \
      "#{args.inspect} \n" \
      'with block: ' \
      "#{block.inspect}  \n" \
      "called by:  \n" \
      "#{caller} \n"
    )
    nil
  end

  prepend ApiDebugger if ENV['API_DEBUG']
end
