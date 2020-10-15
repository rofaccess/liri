require 'manager/setup/folder'
require 'manager/source_code/compressed_file'

module Liri
  module Manager
    AGENT_ADDRESS = ['255.255.255.255', 33333]

    class << self
      def run
        puts "Starting Testing Process"
        setup_folder = Liri::Manager::Setup::Folder.new
        setup_folder.create unless Dir.exist?(setup_folder.path)

        source_code_folder = Liri::Manager::SourceCode::Folder.new

        compressed_file = Liri::Manager::SourceCode::CompressedFile.new(source_code_folder.path, setup_folder.path)
        compressed_file.create

        all_tests = source_code_folder.all_tests
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

        #compressed_file.delete
        #setup_folder.delete
        #Liri.delete_config
        puts "Finished Testing Process"
      end
    end
  end
end