require 'manager/source_code/source_code'
require 'manager/unit_test/rspec'

module Liri
  module Manager
    class SourceCode::Folder
      attr_reader :path

      def initialize
        @path = Dir.pwd
        @name = @path.split('/').last
      end

      def all_tests
        unit_test = Liri::Manager::UnitTest::Rspec.new(@path)
        unit_test.all_test
      end
    end
  end
end