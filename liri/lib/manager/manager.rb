=begin
  Este modulo es el punto de entrada del programa principal
=end
require 'all_libraries'

module Liri
  module Manager
    class << self
      def run
        puts "Iniciando proceso de Testing"

        source_code = Liri::Manager::SourceCode.new(compressor_class)
        source_code.compress_folder

        all_tests = source_code.all_tests
        samples = all_tests.sample(3)

        sender = Liri::Manager::Sender.new(udp_port, tcp_port)
        sender.load_agents_addresses


        source_code.delete_compressed_folder
=begin
        sender = Common::Connection::Client::Udp.new(agent_address)
        sender.open
        puts "Enviando Hola..."
        response = sender.send("Hola")
        if response == "Hola"
          puts "Recibiendo Hola..."
          puts "Enviando Chau..."
          response = sender.send("Chau")
          if response == "Chau"
            puts "Recibiendo Chau..."
            sender.close
          end
        end

        # runner = Runner::Rspec.new
        # runner.run
=end
        puts "\nProceso de Testing Finalizado"
      end

      private
      def compressor_class
        "Liri::Common::Compressor::#{Liri.setup.implementation.compressor}"
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