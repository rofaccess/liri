# = manager_data.rb
#
# @author Rodrigo Fernández
#
# == Clase ManagerData

module Liri
  module Common
    # Esta clase guarda los datos del Manager
    class ManagerData
      attr_accessor :folder_path, :compressed_file_path, :user, :password

      def initialize(folder_path:, compressed_file_path:, user:, password:)
        @folder_path = folder_path
        @compressed_file_path = compressed_file_path
        @user = user
        @password = password
      end

      def to_h
        {
          folder_path: @folder_path,
          compressed_file_path: @compressed_file_path,
          user: @user,
          password: @password
        }
      end
    end
  end
end
