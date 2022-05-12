# = tests_result.rb
#
# @author Rodrigo Fernández
#
# == Clase TestsResult

module Liri
  module Common
    # Esta clase se encarga de guardar y procesar el archivo de resultados
    class TestsResult
      def initialize(folder_path)
        @folder_path = folder_path
      end

      def save(file_name, raw_tests_result)
        file_path = File.join(@folder_path, '/', file_name)
        File.write(file_path, raw_tests_result)
        file_path
      end

      def build_file_name(agent_ip_address, tests_batch_number)
        "batch_#{tests_batch_number}_agent_#{agent_ip_address}_tests_results"
      end
    end
  end
end
