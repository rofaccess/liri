require 'highline/import'

module Liri
  class Manager
    class Credential
      FILE_NAME = 'liri-credentials.yml'
      def initialize(folder_path)
        @folder_path = folder_path
        @file_path = File.join(@folder_path, '/', FILE_NAME)
      end

      # Obtiene ususario y contraseña del sistema en el que se ejecuta el programa
      def get
        user, password = get_credentials
        unless user || password
          user, password = ask_credentials
          save_credentials(user, password)
        end
        return user, password
      end

      private
      def get_local_user
        %x[whoami].delete!("\n")
      end

      def get_credentials
        if File.exist?(@file_path)
          data = YAML.load(File.read(@file_path))
          return data['user'], data['password']
        else
          return nil, nil
        end
      rescue Psych::SyntaxError
        # Este error ocurre cuando se guardan caracteres raros en el archivo liri-credentials.yml
        # en este caso se borra el archivo y se pide de nuevo la contraseña
        delete_credentials
        return nil, nil
      end

      def ask_credentials
        local_user = get_local_user
        password = ask("Enter password for user #{local_user}: ") { |q| q.echo = "*" }
        return local_user, password
      end

      def save_credentials(user, password)
        File.write(@file_path, "user: #{user}\npassword: #{password}")
      end

      def delete_credentials
        if File.exist?(@file_path)
          File.delete(@file_path)
          File.exist?(@file_path) ? false : true
        else
          false
        end
      end
    end
  end
end
