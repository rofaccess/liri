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
          def finish_in_values(finish_in_line)
            values = finish_in_line.to_s.match(/Finished in (.+)\(files took (.+) to load\)/)
            finish_in_text = values[1]
            files_load_text = values[2]
            { finish_in: text_value_to_seconds(finish_in_text), files_load: text_value_to_seconds(files_load_text) }
          end

          def finished_summary_values(finished_summary_line)
            values = finished_summary_line.to_s.match(/(.+) examples*, (.+) failures*,*\s*(\d*)/)
            examples = values[1]
            failures = values[2]
            pending = values[3].empty? ? '0' : values[3]
            { examples: examples.to_i, failures: failures.to_i, pending: pending.to_i }
          end

          # Received string like this "rspec ./spec/failed_spec.rb:4 # Liri debería fallar a propósito" and
          # return string like this "/spec/failed_spec.rb:4"
          def failed_example(failed_example_line)
            values = failed_example_line.to_s.match(/(\/.+.rb:\d+)/)
            failed_example = values[1]
            failed_example
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
