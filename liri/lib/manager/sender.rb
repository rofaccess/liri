require 'socket'


server = TCPServer.open(2000)

addr = ['<broadcast>', 33333]

UDPSock = UDPSocket.new
UDPSock.setsockopt(Socket::SOL_SOCKET, Socket::SO_BROADCAST, true)
addrr = Socket.ip_address_list.select(&:ipv4?).detect{|addr| addr.ip_address != '127.0.0.1'}
data2= addrr.ip_address
UDPSock.send(data2, 0, addr[0], addr[1])
UDPSock.close

loop {                           # el servidor corre infinitamente
  Thread.start(server.accept) do |client|
    client.puts(Time.now.ctime)
    client.puts "terminó la conexión!"
    client.close                  # se desconecta el cliente
  end
}