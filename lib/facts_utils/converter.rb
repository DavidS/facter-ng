# frozen_string_literal: true

module Facter
  module FactsUtils
    class Converter
      class << self
        def to_mb(value_in_bytes)
          (value_in_bytes / (1024.0 * 1024.0)).round(2)
        rescue NoMethodError
          nil
        end

        def to_hz(speed)
          speed = speed.to_i
          return if !speed || speed.zero?

          prefix = { 3 => 'k', 6 => 'M', 9 => 'G', 12 => 'T' }
          power = Math.log10(speed).floor
          validated_speed = power.zero? ? speed.to_f : speed.fdiv(10**power)
          format('%<displayed_speed>.2f', displayed_speed: validated_speed).to_s + ' ' + prefix[power] + 'Hz'
        end

        def bytes_to_human_readable(bytes)
          return unless bytes
          return bytes.to_s + ' bytes' if bytes < 1024

          units = %w[K M G T P E]
          result = determine_exponent(bytes)
          return bytes.to_s + ' bytes' if result[:exp] > units.size

          converted_number = pad_number(result[:converted_number])
          converted_number + " #{units[result[:exp] - 1]}iB"
        end

        private

        def pad_number(number)
          number = number.to_s
          number << '0' if number.split('.').last.length == 1
          number
        end

        def determine_exponent(bytes)
          exp = (Math.log2(bytes) / 10.0).floor
          converted_number = (100.0 * (bytes / 1024.0**exp)).round / 100.0

          if (converted_number - 1024.0).abs < Float::EPSILON
            exp += 1
            converted_number = 1.00
          end
          { exp: exp, converted_number: converted_number }
        end
      end
    end
  end
end
