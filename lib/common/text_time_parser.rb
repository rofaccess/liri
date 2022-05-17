# = text_time_parser.rb
#
# @author Rodrigo Fernández
#
# == Clase TextTimeParser

require 'bigdecimal'

module Liri
  module Common
    # Esta clase parsea texto en horas, minutos y segundos a un valor decimal en segundos
    class TextTimeParser
      class << self
        def to_seconds(text_time)
          values = text_time.split(' ')
          case values.size
          when 2 # cuando se tiene por ejemplo '15 minutes'
            text_time_to_seconds(values[0], values[1])
          when 4 # cuando se tiene por ejemplo '1 minute 5 seconds'
            text_time_to_seconds(values[0], values[1]) + text_time_to_seconds(values[2], values[3])
          when 6 # cuando se tiene por ejemplo '1 hour 30 minutes 25 seconds'
            text_time_to_seconds(values[0], values[1]) +
              text_time_to_seconds(values[2], values[3]) +
              text_time_to_seconds(values[4], values[5])
          end
          # queda pendiente agregar el caso de dias, horas, minutos y segundos, además hace falta verificar como lo muestra Rspec
        end

        private

        def text_time_to_seconds(number, text)
          # Se usa BigDecimal porque
          # En una multiplicación normal: (203.033*3600).to_f = 730918.7999999999
          # Con BigDecimal: (BigDecimal('203.033') * 3600).to_f = 730918.8
          time = BigDecimal(number)
          time_in_seconds = case text
          when 'second', 'seconds' then time
          when 'minute', 'minutes' then time * 60
          when 'hour', 'hours' then time * 3600
          when 'day', 'days' then time * 86_400
                            end
          time_in_seconds.to_f
        end
      end
    end
  end
end
