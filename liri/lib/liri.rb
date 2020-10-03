require 'compressor/zip'

module Liri
  class << self
    def run
      puts "Starting Testing Process"
      #compressor = Compressor::Zip.new(input_dir, output_file)
      #compressor.compress

      # sender = Sender::Ftp.new
      # sender.send

      # runner = Runner::Rspec.new
      # runner.run
      puts "Finished Testing Process"
    end

    private
    def input_dir
      File.dirname(__dir__)
    end

    def output_file
      File.join(input_dir, '.liri', "#{input_dir.split('/').last}.zip")
    end
  end
end
