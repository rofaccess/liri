# frozen_string_literal: true

# = duration.rb
#
# @author Rodrigo Fernández

require "chronic_duration"

module Liri
  module Common
    # == Módulo Duration
    # Este módulo se encarga de convertir el tiempo en segundos a un formato legible
    module Duration
      class << self
        def humanize(time, times_round:, times_round_type:)
          # El time puede ser un BigDecimal y aunque se redondee puede responder con un formato 0.744e2, por eso
          # es imporantes hacerle un to_f para convertirlo a 74.4 antes de proceder a humanizarlo
          time = time.to_f
          case times_round_type
          when :floor then ChronicDuration.output(time.truncate(times_round), format: :short, keep_zero: true)
          when :roof then ChronicDuration.output(time.round(times_round), format: :short, keep_zero: true)
          else raise "Invalid times_round_type. Expected: floor or roof. Received: #{times_round_type}"
          end
        end
      end
    end
  end
end
