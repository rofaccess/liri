# = tty_progressbar.rb
#
# @author Rodrigo Fernández
#
# == Módulo TtyProgressbar
# Este módulo se encarga de mostrar una barra de progreso

require "tty-progressbar"

module Liri
  module Common
    module TtyProgressbar
      class << self
        # Example:
        #   Common::TtyProgressbar.start("Compressing source code [:bar]", total: nil, width: 100, bar_format: :asterisk) do
        #     ...code
        #   end
        def start(format, params = {})
          @compressing = true
          progressbar = TTY::ProgressBar.new(format, params)
          Thread.new do
            while @compressing
              progressbar.advance
              sleep(0.1)
            end
          end
          yield
          @compressing = false
        end
      end
    end
  end
end