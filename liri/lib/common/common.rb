module Liri
  module Common
    class << self
      def current_host_ip_address
        addr = Socket.ip_address_list.select(&:ipv4?).detect{|addr| addr.ip_address != '127.0.0.1'}
        addr.ip_address
      end
    end
  end
end