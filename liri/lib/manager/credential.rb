module Liri
  class Manager
    class Credential
      #obtiene ususario y contraseña del sistema en el que se ejecuta
      def get
        liri_setup = Liri::Manager::Setup.new
        liri_setup.create unless File.exist?(liri_setup.path)
        temp= %x[whoami]
        user_manager = temp.delete!("\n")
        liri_setup.update_value_two_level('manager_user', 'user', user_manager)
        puts "Escribir contraseña del usuario #{user_manager}:"
        pass = STDIN.gets.chomp
        puts "#{pass} es la contraseña de "
        liri_setup.update_value_two_level('manager_user', 'password', pass)
      end
    end
  end
end
