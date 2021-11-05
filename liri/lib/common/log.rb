# = log.rb
#
# @author Rodrigo Fernández
#
# == Clase Log
# Esta clase se encarga de manejar el logging

require 'logger'
require 'colorized_string'

module Liri
  module Common
    class Log
      FOLDER_NAME = 'logs'
      FOLDER_PATH = File.join(Dir.pwd, "/#{FOLDER_NAME}")
      FILE_NAME = 'liri.log'

      def initialize(shift_age, folder_path:, file_name:, stdout: true)
        @stdout = stdout
        @shift_age = shift_age
        @folder_path = folder_path || FOLDER_PATH
        @file_name = file_name || FILE_NAME
        @file_path = File.join(@folder_path, '/', @file_name)

        create_stdout_logger if @stdout
        create_log_folder
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
        @stdout_logger.formatter = Liri::Common::LogFormatter.colorize(Liri.setup.log.stdout.colorize)
      end

      def create_file_logger
        @file_logger = Logger.new(@file_path, @shift_age)
        @file_logger.formatter = Liri::Common::LogFormatter.colorize(Liri.setup.log.file.colorize)
      end

      def create_log_folder
        Dir.mkdir(@folder_path) unless Dir.exist?(@folder_path)
      end
    end

    class LogFormatter
      DATETIME_FORMAT = "%d-%m-%Y %H:%M"

      SEVERITY_COLORS = {
          DEBUG: :black,
          INFO: :green,
          WARN: :orange,
          ERROR: :light_red,
          FATAL: :red,
          UNKNOWN: :purple
      }

      class << self
        def colorize(type)
          proc do |severity, datetime, progname, msg|
            formatted_date = datetime.strftime(DATETIME_FORMAT)
            severity_abb_block = "#{severity.slice(0)}"
            date_block = "[#{formatted_date}##{Process.pid}]"
            severity_block = "#{severity} -- :"
            msg_block = "#{msg}\n"

            case type
            when 'severity' then
              info_block = "#{colorize_according_severity(severity, severity_abb_block)} #{date_block} #{colorize_according_severity(severity, severity_block)}"
            when 'severity_date' then
              info_block = colorize_according_severity(severity, "#{severity_abb_block} #{date_block} #{severity_block}")
            when 'full' then
              info_block = colorize_according_severity(severity, "#{severity_abb_block} #{date_block} #{severity_block}")
              msg_block = colorize_according_severity(severity, msg_block)
            else
              info_block = "#{severity_abb_block} #{date_block} #{severity_block}"
            end

            "#{info_block} #{msg_block}"
          end
        end

        private
        def colorize_according_severity(severity, line)
          color = SEVERITY_COLORS[severity.to_sym] || :black
          ColorizedString.new(line).public_send(color)
        end
      end
    end
  end
end
