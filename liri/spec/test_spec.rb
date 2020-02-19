require 'test'
require 'benchmark'

RSpec.describe "Test" do
  context 'run' do
    it "return true" do
      app_root_path = '/home/lesliie/Documentos/TFG/AlchemiTest/alchemy_cms/'
      command = 'bundle exec rspec'
      arg = 'spec/models'

      command = "#{app_root_path} #{command} #{arg}"
      puts command

      time = Benchmark.realtime do
        result = Liri::Test.run(command)
      end
      puts "Time: #{time.round(2)}s"

      expect(result).to eq true
    end
  end
endc