# frozen_string_literal: true

module Facts
  module Solaris
    module Processors
      class Speed
        FACT_NAME = 'processors.speed'

        def call_the_resolver
          fact_value = Facter::Resolvers::Solaris::Processors.resolve(:speed)
          speed = Facter::FactsUtils::Converter.to_hz(fact_value)
          Facter::ResolvedFact.new(FACT_NAME, speed)
        end
      end
    end
  end
end
