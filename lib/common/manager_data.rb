# = manager_data.rb
#
# @author Rodrigo Fernández
#
# == Clase ManagerData

module Liri
  module Common
    # Esta clase guarda los datos del Manager
    class ManagerData
      attr_accessor :tests_results_folder_path, :compressed_file_path, :user, :password

      def initialize(tests_results_folder_path:, compressed_file_path:, user:, password:)
        @tests_results_folder_path = tests_results_folder_path
        @compressed_file_path = compressed_file_path
        @user = user
        @password = password
      end

      def to_h
        {
          tests_results_folder_path: @tests_results_folder_path,
          compressed_file_path: @compressed_file_path,
          user: @user,
          password: @password
        }
      end
    end
  end
end
