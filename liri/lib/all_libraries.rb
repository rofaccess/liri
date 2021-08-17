# = all_libraries.rb
#
# Autor::   Rodrigo Fernández
# Web::     http://www.something.com
#
# Este archivo se encarga de importar todas las librerías a utilizar

# Se utiliza la librería *socket* de Ruby para realizar una conexión udp
require 'socket'
require 'net/ssh'
require 'net/scp'

# El archivo *hash_extend* extiende la clase Hash de Ruby para agregarle más funcionalidades
require 'hash_extend'

require 'agent/agent'
require 'agent/runner'
require 'agent/unit_test/rspec'

require 'common/common'
require 'common/compressor/zip'
require 'common/source_code'

require 'manager/manager'
require 'manager/setup'
require 'manager/unit_test/rspec'
