# = benchmarking.rb
#
# @author Rodrigo Fernández
#
# == Módulo Benchmarking
# Este módulo se encarga de medir el tiempo de ejecución de algunos bloques de código

require 'benchmark'
require 'i18n' # requerimiento de la gema to_duration
require 'to_duration'

# Se configura la ubicación del archivo de internacionalización de la gema to_duration
I18n.load_path << Dir[File.join(File.dirname(File.dirname(File.dirname(__FILE__))), 'config/locales') + "/*.yml"]
I18n.default_locale = :es

module Liri
  module Common
    module Benchmarking
      class << self
        def start(start_msg: nil, end_msg: 'Duración: ', stdout: true)
          Liri.logger.info(start_msg, stdout)
          start_time = Time.now
          seconds = Benchmark.realtime do
            yield
          end
          end_time = Time.now - start_time
          Liri.logger.info("#{end_msg}#{seconds.to_duration}", stdout)
          Liri.logger.info("#{end_msg}#{seconds}", stdout)
          Liri.logger.info("#{end_msg}#{end_time.to_duration}", stdout)
          Liri.logger.info("#{end_msg}#{end_time}", stdout)
          seconds
        end
      end
    end
  end
end