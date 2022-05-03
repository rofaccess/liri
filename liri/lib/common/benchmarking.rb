# = benchmarking.rb
#
# @author Rodrigo Fernández
#
# == Módulo Benchmarking
# Este módulo se encarga de medir el tiempo de ejecución de algunos bloques de código

require 'benchmark'
require 'i18n' # requirimiento de la gema to_duration
require 'to_duration'

# Se configura la ubicación del archivo de internacionalización de la gema to_duration
I18n.load_path << Dir[File.join(File.dirname(File.dirname(File.dirname(__FILE__))), 'config/locales') + "/*.yml"]
I18n.default_locale = :es

module Liri
  module Common
    module Benchmarking
      class << self
        def start
          seconds = Benchmark.realtime do
            yield
          end
          print_result(seconds)
        end

        private

        def print_result(seconds)
          puts "Tiempo de ejecución: #{seconds.to_duration}"
        end
      end
    end
  end
end