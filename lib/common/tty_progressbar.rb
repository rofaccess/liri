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
      ANIMATION = [
          "=---=---=---=---=---=---=---=---=---=---=---=---=---=---=---=---=---=---=---=---",
          "-=---=---=---=---=---=---=---=---=---=---=---=---=---=---=---=---=---=---=---=--",
          "--=---=---=---=---=---=---=---=---=---=---=---=---=---=---=---=---=---=---=---=-",
          "---=---=---=---=---=---=---=---=---=---=---=---=---=---=---=---=---=---=---=---=",
      ]

      ANIMATION2 = [
          "=---=---=---=---=---",
          "-=---=---=---=---=--",
          "--=---=---=---=---=-",
          "---=---=---=---=---=",
      ]
      class << self
        # Example:
        #   Common::TtyProgressbar.start("Compressing source code |:bar| Time: :elapsed", total: nil, width: 80) do
        #     ...code
        #   end
        def start(format, params = {})
          @progressing = true # posiblemente no debiera ser una variable global, tal vez meter dentro del thread
          progressbar = TTY::ProgressBar.new(format, params)
          Thread.new do
            animation_count = 0
            while @progressing
              progressbar.advance

              progressbar.update(unknown: ANIMATION[animation_count])
              animation_count += 1
              animation_count = 0 if animation_count == 3

              sleep(0.1)
            end
          end
          yield
          @progressing = false
        end
      end
    end
  end
end