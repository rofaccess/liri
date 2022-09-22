# = progressbar.rb
#
# @author Rodrigo Fernández
#
# == Módulo Progressbar
# Este módulo se encarga de mostrar una barra de progreso

require 'ruby-progressbar'

module Liri
  module Common
    module Progressbar
      class << self
        def start(params = {})
          @progressing = true
          progressbar = ProgressBar.create(params)
          Thread.new do
            while @progressing
              progressbar.increment
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