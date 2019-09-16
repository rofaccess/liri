require 'bundler/setup'
require 'open3'



module Liri
  class Test
    def self.run(path)

      Open3.popen3('ls') do |stdin, stdout, stderr, wait_thr|
        stdin.puts "This is sent to the command"
        stdin.close                # we're done
        stdout_str = stdout.read   # read stdout to string. note that this will block until the command is done!
        stderr_str = stderr.read   # read stderr to string
        status = wait_thr.value    # will block until the command finishes; returns status that responds to .success? etc
      end

      #system("bundle exec rspec #{path} --format progress --out rspec_result --no-color")
    end
  end
end