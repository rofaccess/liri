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
        Liri::Manager::UnitTest::Rspec.all
      end
    end
  end
end