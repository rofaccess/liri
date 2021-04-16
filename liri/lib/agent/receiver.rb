require 'socket'

module Liri
  module Agent
    class Receiver
      def initialize(udp_port, tcp_port)
        @udp_port = udp_port
        @udp_socket = UDPSocket.new
        @tcp_port = tcp_port
      end

      def wait_manager_connection_request
        puts "LiriAgent(#{Liri::Common.current_host_ip_address}): ¿Algún LiriManager que me dé trabajo?"

        BasicSocket.do_not_reverse_lookup = true
        @udp_socket.bind('0.0.0.0', @udp_port)
        @manager_request = @udp_socket.recvfrom(1024)

        puts "LiriManager(#{manager_ip_address}): #{manager_message}"
      end

      def start_connection_with_manager
        request_msg = "¿Que trabajo tienes para mi LiriManager(#{manager_ip_address})?"
        puts "LiriAgent(#{Liri::Common.current_host_ip_address}): #{request_msg}"

        @tcp_socket = TCPSocket.open(manager_ip_address, @tcp_port)
        @tcp_socket.print(request_msg)
        while line = @tcp_socket.gets
          response_msg = line.chop
          puts "LiriManager(#{manager_ip_address}): #{response_msg}"
        end
        @tcp_socket.close
      end

      private
      def manager_ip_address
        @manager_request.last.last
      end

      def manager_message
        @manager_request.first
      end
    end
  end
end