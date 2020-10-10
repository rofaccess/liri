require 'compressor/zip'
require 'config'

module Liri
  class << self
    def run
      puts "Starting Testing Process"
      # TODO Warning: The source code can be contains logs files and temporal files that
      # are unnecessary for testing process and will increase the compressed file size
      # In future will be necessary ignore some folders before compress source file
      compressor = Compressor::Zip.new(source_code_dir, compressed_file)
      compressor.compress

      sender = Sender::Udp.new(agent_address)
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
      puts "Finished Testing Process"
    end

    private

    def source_code_dir
      Config::SOURCE_CODE_DIR
    end

    def compressed_file
      Config::COMPRESSED_FILE
    end

    def agent_address
      Config::AGENT_ADDRESS
    end
  end
end
