# = log.rb
#
# @author Rodrigo Fernández
#
# == Clase Log
# Esta clase se encarga de manejar el logging

require 'logger'
module Liri
  class Log
    def initialize(log_file_name, shift_age, stdout: true)
      @stdout = stdout
      if @stdout
        @stdout_log = Logger.new(STDOUT, shift_age)
        @stdout_log.datetime_format = "%d-%m-%Y %H:%M"
      end

      @file_log = Logger.new(log_file_name, shift_age)
      @file_log.datetime_format = "%d-%m-%Y %H:%M"
    end

    def debug(text)
      @stdout_log.debug(text) if @stdout
      @file_log.debug(text)
    end

    def info(text)
      @stdout_log.info(text) if @stdout
      @file_log.info(text)
    end

    def warn(text)
      @stdout_log.warn(text) if @stdout
      @file_log.warn(text)
    end

    def error(text)
      @stdout_log.error(text) if @stdout
      @file_log.error(text)
    end

    def fatal(text)
      @stdout_log.fatal(text) if @stdout
      @file_log.fatal(text)
    end

    def unknown(text)
      @stdout_log.unknown(text) if @stdout
      @file_log.unknown(text)
    end
  end
end
