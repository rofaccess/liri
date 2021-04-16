=begin
  Este modulo es el punto de entrada del programa agente
=end
require 'all_libraries'

module Liri
  module Agent
    class << self
      def run
        receiver = Agent::Receiver.new(udp_port, tcp_port)
        receiver.wait_manager_connection_request
        receiver.start_connection_with_manager
      end

      private
      def udp_port
        Liri.setup.ports.udp
      end

      def tcp_port
        Liri.setup.ports.tcp
      end
    end
  end
end