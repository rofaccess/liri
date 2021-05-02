=begin
  Esta clase se encarga de lidiar con los agentes
=end
require 'all_libraries'

module Liri
  module Manager
    class Agent
      class << self
        def load_agents(udp_port, tcp_port)
          sender = Liri::Manager::Sender.new(udp_port, tcp_port)
          agent_addresses = sender.load_agents_addresses
        end
      end

      # ip_address: dirección ip donde se estan ejecutando el agente
      # status: puede ser waiting o running
      def initialize(status, ip_address, tcp_port)
        @ip_address = ip_address
        @status = status
      end
    end
  end
end