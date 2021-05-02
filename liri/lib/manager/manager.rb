=begin
  Este modulo es el punto de entrada del programa principal
=end
require 'all_libraries'

module Liri
  module Manager
    class << self
      def run
        puts "Iniciando proceso de Testing"

        source_code = Liri::Manager::SourceCode.new(compression_class, unit_test_class)
        source_code.compress_folder

        all_tests = source_code.all_tests
        samples = all_tests.sample(3)
        puts samples

        agents = Liri::Manager::Agent.load_agents(udp_port, tcp_port)

        # Enviar archivo
        # Enviar pruebas
        # Procesar resultados

        source_code.delete_compressed_folder

        puts "\nProceso de Testing Finalizado"
      end

      private
      def compression_class
        "Liri::Common::Compressor::#{Liri.setup.library.compression}"
      end

      def unit_test_class
        "Liri::Manager::UnitTest::#{Liri.setup.library.unit_test}"
      end

      def udp_port
        Liri.setup.ports.udp
      end

      def tcp_port
        Liri.setup.ports.tcp
      end
    end
  end
end