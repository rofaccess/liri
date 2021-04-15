require 'socket'

addr = ['0.0.0.0', 33333]  # host, port
BasicSocket.do_not_reverse_lookup = true
UDPSock = UDPSocket.new
UDPSock.bind(addr[0], addr[1])

data, addr = UDPSock.recvfrom(1024)
puts "Recibido la ip: '%s'" % [data]
UDPSock.close

#TCP cliente

hostname = data
port = 2000
s = TCPSocket.open(hostname, port)
while line = s.gets     #
  puts line.chop
end
s.close