# = log.rb
#
# @author Rodrigo Fernández
#
# == Clase Log
# Esta clase se encarga de manejar el logging

require 'logger'
module Liri
  module Common
    class Log
      FOLDER_PATH = File.join(Dir.pwd, '/log')
      FILE_NAME = 'liri.log'
      FILE_PATH = File.join(FOLDER_PATH, '/', FILE_NAME)

      def initialize(shift_age, stdout=true)
        @stdout = stdout
        @datetime_format = "%d-%m-%Y %H:%M"
        @shift_age = shift_age

        create_stdout_logger if @stdout
        create_file_logger
      end

      def debug(text)
        @stdout_logger.debug(text) if @stdout
        @file_logger.debug(text)
      end

      def info(text)
        @stdout_logger.info(text) if @stdout
        @file_logger.info(text)
      end

      def warn(text)
        @stdout_logger.warn(text) if @stdout
        @file_logger.warn(text)
      end

      def error(text)
        @stdout_logger.error(text) if @stdout
        @file_logger.error(text)
      end

      def fatal(text)
        @stdout_logger.fatal(text) if @stdout
        @file_logger.fatal(text)
      end

      def unknown(text)
        @stdout_logger.unknown(text) if @stdout
        @file_logger.unknown(text)
      end

      private
      def create_stdout_logger
        @stdout_logger = Logger.new(STDOUT, @shift_age)
        @stdout_logger.datetime_format = @datetime_format
      end

      def create_file_logger
        create_log_folder unless Dir.exist?(FOLDER_PATH)
        @file_logger = Logger.new(FILE_PATH, @shift_age)
        @file_logger.datetime_format = @datetime_format
      end

      def create_log_folder
        Dir.mkdir(FOLDER_PATH)
      end
    end
  end
end
