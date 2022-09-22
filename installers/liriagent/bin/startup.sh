#!/bin/bash
RVM_HOME=$HOME/.rvm/scripts/rvm
RUBY__VERSION=2.7.2

# Se carga rvm en el contexto actual. RVM se instaló con el script install.sh
source $RVM_HOME

# Se establece la versión de Ruby a utilizar. Esta versión de Ruby se instaló con el script install.sh
rvm use $RUBY__VERSION

# Se establece el gemset a utilizar. Este gemset se creó con el script install.sh
rvm gemset use liri

# Ejecutar el Agent
liri a --trace