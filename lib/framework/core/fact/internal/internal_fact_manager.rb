# frozen_string_literal: true

module Facter
  class InternalFactManager
    def initialize
      @log = Log.new(self)
    end

    def resolve_facts(searched_facts)
      searched_facts = filter_internal_facts(searched_facts)

      threads = start_threads(searched_facts)

      join_threads(threads, searched_facts)
    end

    private

    def filter_internal_facts(searched_facts)
      searched_facts.select { |searched_fact| %i[core legacy].include? searched_fact.type }
    end

    def start_threads(searched_facts)
      threads = []

      searched_facts.reject { |elem| elem.fact_class.nil? }.each do |searched_fact|
        threads << Thread.new do
          fact = CoreFact.new(searched_fact)
          fact.create
        rescue StandardError => e
          @log.error("Error while resolving fact: #{searched_fact.name}, #{e.backtrace}")

          nil
        end
      end

      threads
    end

    def join_threads(threads, searched_facts)
      resolved_facts = []

      threads.each do |thread|
        thread.join
        resolved_facts << thread.value if thread.value
      end

      resolved_facts.flatten!

      FactAugmenter.augment_resolved_facts(searched_facts, resolved_facts)
    end
  end
end
