#!/usr/bin/env ruby

require 'rubygems'
require 'commander/import'

program :name, 'Liri'
program :version, '0.0.1'
program :description, 'Hace algo'

command :run do |c|
  c.syntax = 'Liri run [options]'
  c.summary = ''
  c.description = ''
  c.example 'description', 'command example'
  c.option '--some-switch', 'Some switch that does something'
  c.action do |args, options|
    # Do something or c.when_called Liri::Commands::Run

  end
end

