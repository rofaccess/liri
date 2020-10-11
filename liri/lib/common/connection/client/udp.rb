require 'socket'

module Common
  module Connection
    module Client
      class Udp
        def initialize(address)
          @address = address
          @socket = UDPSocket.new
        end

        def open
          @socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_BROADCAST, true)
        end

        def send(data)
          @socket.send(data, 0, @address[0], @address[1])
          @socket.recvfrom(16)[0]
        end

        def close
          @socket.close
        end
      end
    end
  end
end