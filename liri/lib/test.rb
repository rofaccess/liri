require 'bundler/setup'
require 'open3'

module Liri
  class Test
    def self.run(command)
      Open3.popen3(command) do |stdin, stdout, stderr, wait_thr|
        while line = stdout.gets do
          puts(line)
        end
      end
    end
  end
end