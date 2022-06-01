# = tty_progressbar.rb
#
# @author Rodrigo Fernández
#
# == Módulo TtyProgressbar
require "tty-progressbar"

module Liri
  module Common
    # Este módulo se encarga de mostrar una barra de progreso
    module TtyProgressbar
      ANIMATION = [
        "■□□□■□□□■□□□■□□□■□□□■□□□■□□□■□□□■□□□■□□□■□□□■□□□■□□□■□□□■□□□■□□□■□□□■□□□■□□□■□",
        "□■□□□■□□□■□□□■□□□■□□□■□□□■□□□■□□□■□□□■□□□■□□□■□□□■□□□■□□□■□□□■□□□■□□□■□□□■□□□■",
        "□□■□□□■□□□■□□□■□□□■□□□■□□□■□□□■□□□■□□□■□□□■□□□■□□□■□□□■□□□■□□□■□□□■□□□■□□□■□□□",
        "□□□■□□□■□□□■□□□■□□□■□□□■□□□■□□□■□□□■□□□■□□□■□□□■□□□■□□□■□□□■□□□■□□□■□□□■□□□■□□",
      ]

      ANIMATION2 = [
          "■□□□■□□□■□□□■□□□■□□",
          "□■□□□■□□□■□□□■□□□■□",
          "□□■□□□■□□□■□□□■□□□■",
          "□□□■□□□■□□□■□□□■□□□",
      ]
      class << self
        # Example:
        #   Common::TtyProgressbar.start("Compressing source code |:bar| Time: :elapsed", total: nil, width: 80) do
        #     ...code
        #   end
        def start(format, params = {})
          params[:unknown] = ANIMATION[0]
          progressbar = TTY::ProgressBar.new(format, params)
          # Es importante iniciar la barra porque TimeFormatter.call accede a su start_time y si no se inició la barra
          # entonces ocurre un error
          progressbar.start
          progressbar.use(Common::TtyProgressbar::TimeFormatter)

          Thread.new do
            animation_count = 0
            while !progressbar.stopped?
              progressbar.advance

              progressbar.update(unknown: ANIMATION[animation_count])
              animation_count += 1
              animation_count = 0 if animation_count == 3

              sleep(0.1)
            end
          end
          yield
          progressbar.update(total: 1) # Esto hace que la barra cambie a al estilo completado con un porcentaje del 100%
          progressbar.stop
        rescue TypeError
          # Se captura la excepción solo para evitar un error en start_time mas abajo
        end
      end

      # From
      class TimeFormatter
        include TTY::ProgressBar::Formatter[/:time/i]

        def call(value) # specify how display string is formatted
          # access current progress bar instance to read start time
          elapsed = Duration.humanize(Time.now - progress.start_time, times_round: Liri.times_round, times_round_type: Liri.times_round_type)
          value.gsub(matcher, elapsed)   # replace :time token with a value
        end
      end
    end
  end
end