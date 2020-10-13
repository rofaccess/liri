require 'manager/source_code'

module Liri
  module Manager
    AGENT_ADDRESS = ['255.255.255.255', 33333]

    class << self
      def run
        puts "Starting Testing Process"
        Liri::Manager::Folder.create
        Liri::Manager::SourceCode.compress

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
        puts "Finished Testing Process"
      end
    end
  end
end