require 'socket'
#addr = ['<broadcast>', 33333]# broadcast address
addr = ['255.255.255.255', 33333] # broadcast address explicitly [might not work ?]
#addr = ['127.0.0.255', 33333] # ??
UDPSock = UDPSocket.new
UDPSock.setsockopt(Socket::SOL_SOCKET, Socket::SO_BROADCAST, true)
(1..10).each do |i|
  Thread.new do

    data = "I sent this #{i}"
    puts data
    UDPSock.send(data, 0, addr[0], addr[1])
    UDPSock.
  end

  sleep 1
end
UDPSock.close