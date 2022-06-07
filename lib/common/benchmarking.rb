# frozen_string_literal: true

# = benchmarking.rb
#
# @author Rodrigo Fernández

require "benchmark"

module Liri
  module Common
    # == Módulo Benchmarking
    # Este módulo se encarga de medir el tiempo de ejecución de algunos bloques de código
    module Benchmarking
      class << self
        def start(start_msg: nil, end_msg: 'Duration: ', stdout: true, &block)
          Liri.logger.info(start_msg, stdout)

          seconds = Benchmark.realtime(&block)

          Liri.logger.info("#{end_msg}#{Duration.humanize(seconds, times_round: Liri.times_round, times_round_type: Liri.times_round_type)}", stdout)
          seconds
        end
      end
    end
  end
end
