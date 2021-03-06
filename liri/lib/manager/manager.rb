require 'manager/setup/folder'
require 'manager/source_code/compressed_file'

module Liri
  module Manager
    AGENT_ADDRESS = ['255.255.255.255', 33333]

    class << self
      def run
        puts "Iniciando proceso de Testing"

        source_code = Liri::Manager::SourceCode.new(compressor_class)
        source_code.compress_folder

        all_tests = source_code.all_tests

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
        puts "Proceso de Testing Finalizado"
      end

      private
      def compressor_class
        "Liri::Common::Compressor::#{Liri.setup.implementation.compressor}"
      end
    end
  end
end