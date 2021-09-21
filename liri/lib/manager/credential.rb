require 'highline/import'

module Liri
  class Manager
    class Credential
      # Obtiene ususario y contraseña del sistema en el que se ejecuta el programa
      def get
        local_user = get_local_user
        password = ask("Ingrese contraseña del usuario #{local_user}: ") { |q| q.echo = "*" }
        return local_user, password
      end

      private
      def get_local_user
        %x[whoami].delete!("\n")
      end
    end
  end
end
