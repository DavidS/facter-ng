# frozen_string_literal: true

module Facter
  module Util
    class FileHelper
      @log = Log.new(self)
      class << self
        DEBUG_MESSAGE = 'File at: %s is not accessible.'

        def safe_read(path, result_if_not_readable = '')
          return File.read(path) if File.readable?(path)

          result_if_not_readable
        end

        def safe_readlines(path, result_if_not_readable = [])
          return File.readlines(path) if File.readable?(path)

          result_if_not_readable
        end
      end
    end
  end
end
