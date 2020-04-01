# frozen_string_literal: true

module Facter
  class CacheManager
    def initialize
      @groups = {}
      @log = Log.new(self)
      @fact_groups = Facter::FactGroups.new
    end

    def cache_dir
      LegacyFacter::Util::Config.facts_cache_dir
    end

    def resolve_facts(searched_facts)
      return searched_facts, [] if File.directory?(cache_dir) == false || Options[:cache] == false

      facts = []
      searched_facts.each do |fact|
        res = resolve_fact(fact)
        facts << res unless res.nil?
      end
      facts.each do |fact|
        searched_facts.delete_if { |f| f.name == fact.name }
      end
      [searched_facts, facts]
    end

    def cache_facts(resolved_facts)
      return if Options[:cache] == false

      resolved_facts.each do |fact|
        cache_fact(fact)
      end

      write_cache unless @groups.empty?
    end

    private

    def resolve_fact(searched_fact)
      group_name = @fact_groups.get_fact_group(searched_fact.name)
      return unless group_name

      return unless group_cached?(group_name)

      return if check_ttls(group_name).zero?

      data = read_group_json(group_name)
      return unless data

      @log.debug("loading cached values for #{group_name} facts")
      create_fact(searched_fact, data[searched_fact.name])
    end

    def create_fact(searched_fact, value)
      resolved_fact = Facter::ResolvedFact.new(searched_fact.name, value, searched_fact.type)
      resolved_fact.user_query = searched_fact.user_query
      resolved_fact.filter_tokens = searched_fact.filter_tokens
      resolved_fact
    end

    def cache_fact(fact)
      group_name = @fact_groups.get_fact_group(fact.name)
      return if group_name.nil? || fact.value.nil?

      return unless group_cached?(group_name)

      @groups[group_name] ||= {}
      @groups[group_name][fact.name] = fact.value
    end

    def write_cache
      unless File.directory?(cache_dir)
        require 'fileutils'
        FileUtils.mkdir_p(cache_dir)
      end

      @groups.each do |group_name, data|
        next if check_ttls(group_name).zero?

        @log.debug("caching values for #{group_name} facts")
        cache_file_name = File.join(cache_dir, group_name)
        File.write(cache_file_name, JSON.pretty_generate(data))
      end
    end

    def read_group_json(group_name)
      return @groups[group_name] if @groups.key?(group_name)

      cache_file_name = File.join(cache_dir, group_name)
      data = nil
      if File.readable?(cache_file_name)
        file = File.read(cache_file_name)
        begin
          data = JSON.parse(file)
        rescue JSON::ParserError
          delete_cache(group_name)
        end
      end
      @groups[group_name] = data
      data
    end

    def group_cached?(group_name)
      cached = @fact_groups.get_group_ttls(group_name) ? true : false
      delete_cache(group_name) unless cached
      cached
    end

    def check_ttls(group_name)
      ttls = @fact_groups.get_group_ttls(group_name)
      return 0 unless ttls

      cache_file_name = File.join(cache_dir, group_name)
      return ttls unless File.readable?(cache_file_name)

      file_time = File.mtime(cache_file_name)
      expire_date = file_time + ttls
      if expire_date < Time.now
        File.delete(cache_file_name)
        return ttls
      end
      expire_date.to_i
    end

    def delete_cache(group_name)
      cache_file_name = File.join(cache_dir, group_name)
      File.delete(cache_file_name) if File.readable?(cache_file_name)
    end
  end
end
