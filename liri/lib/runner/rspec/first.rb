require 'bundler/setup'
require 'open3'

class Runner
  class First
    def run
      app_root_path = '/home/suc/bin/alchemy_cms/'
      command = 'bundle exec rspec'
      arg = 'spec/models'

      command = "#{app_root_path} #{command} #{arg}"
      puts command

      Open3.popen3(command) do |stdin, stdout, stderr, wait_thr|
        while line = stdout.gets do
          puts(line)
        end
      end
    end

    true
  end
end