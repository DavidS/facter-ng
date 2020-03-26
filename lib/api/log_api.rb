# frozen_string_literal: true

module LogApi
  # Prints out a debug message when debug option is set to true
  # @param msg [String] Message to be printed out
  #
  # @return [nil]
  #
  # @api public
  def debug(msg)
    return unless debugging?

    @logger.debug(msg)
    nil
  end

  # Check whether printing stack trace is enabled
  #
  # @return [bool]
  #
  # @api public
  def trace?
    @trace
  end

  # Enable or disable trace
  # @param debug_bool [bool] Set trace on debug state
  #
  # @return [type] [description]
  #
  # @api public
  def trace(bool)
    @trace = bool
  end

  def on_message(&block)
    Facter::Log.on_message(&block)
  end

  # Check whether debuging is enabled
  #
  # @return [bool]
  #
  # @api public
  def debugging?
    Facter::Options[:debug]
  end

  # Enable or disable debugging
  # @param debug_bool [bool] State which debugging should have
  #
  # @return [type] [description]
  #
  # @api public
  def debugging(debug_bool)
    Facter::Options[:debug] = debug_bool

    debug_bool
  end

  def log_exception(exception, message = :default)
    arr = []
    if message == :default
      arr << exception.message
    elsif message
      arr << message
    end
    if @trace
      arr << 'backtrace:'
      arr.concat(exception.backtrace)
    end

    @logger.error(arr.flatten.join("\n"))
  end
end
