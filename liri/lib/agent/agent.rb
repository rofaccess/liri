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
        # tests = receiver.tests_received
        # runner = Liri::Agent::Runner::Rspec.new
        # tests_result = runner.run_tests(tests)
        # receiver.send_tests_results(tests_result)
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