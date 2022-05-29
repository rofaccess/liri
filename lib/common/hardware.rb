# = hardware.rb
#
# @author Rodrigo Fernández

module Liri
  module Common
    # == Módulo Hardware
    # Este módulo se encarga de obtener información del hardware
    module Hardware
      class << self
        def cpu
          cpu = %x|inxi -C|
          cpu = cpu.to_s.match(/model(.+)bits/)
          cpu = cpu[1].gsub("  12", "")
          cpu = cpu.gsub(": ", "")
          cpu
        rescue Errno::ENOENT
          raise InxiCommandNotFoundError.new
        end

        def memory
          memory = %x|grep MemTotal /proc/meminfo|
          memory = memory.to_s.match(/(\d+)/)
          (memory[1].to_i * 0.000001).to_i
        end
      end
    end
  end
end
