=begin
  Este módulo ejecuta tareas de apoyo
=end

module Liri
  module Task
    class << self
      def tests_count
        source_code = Liri::Common::SourceCode.new('', Liri.compression_class, Liri.unit_test_class)
        source_code.all_tests.size
      end
    end
  end
end

