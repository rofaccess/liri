# = rspec_result_parser.rb
#
# @author Rodrigo Fernández
#
# == Clase RspecResultParser

module Liri
  module Common
    module UnitTest
      # Esta clase parsea texto de resultado en rspec a volores numéricos
      class RspecResultParser
        class << self
          def finished_in_values(finished_in_line)
            values = finished_in_line.to_s.match(/Finished in (.+)\(files took (.+) to load\)/)
            finished_in_text = values[1]
            files_took_to_load_text = values[2]
            { finished_in: text_value_to_seconds(finished_in_text), files_took_to_load: text_value_to_seconds(files_took_to_load_text) }
          end

          def finished_summary_values(finished_summary_line)
            values = finished_summary_line.to_s.match(/(.+) examples*, (.+) failures*,*\s*(\d*)/)
            examples = values[1]
            failures = values[2]
            pending = values[3].empty? ? '0' : values[3]
            { examples: examples.to_i, failures: failures.to_i, pending: pending.to_i }
          end

          private

          def text_value_to_seconds(text)
            TextTimeParser.to_seconds(text)
          end
        end
      end
    end
  end
end
