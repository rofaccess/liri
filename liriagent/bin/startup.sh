#!/bin/bash

source messages.sh

if [ -z "$1" ]
  then
	RUBY__VERSION=2.7.2
    info_msg "No se especificó una versión de Ruby. Ej.: ./install 2.7.2"
    info_msg "Se usa por defecto Ruby ${RUBY__VERSION}"
else
  # Se usa doble guión bajo porque en algunos sistemas, RUBY_VERSION es una variable de entorno con valor propio y se termina usando el valor de esa variable en esta instalación
  RUBY__VERSION=$1
fi

# Se carga rvm en el contexto actual. RVM se instaló con el script install.sh
source $HOME/.rvm/scripts/rvm

# Se establece la versión de Ruby a utilizar. Esta versión de Ruby se instaló con el script install.sh
rvm use $RUBY__VERSION

# Se establece el gemset a utilizar. Este gemset se creó con el script install.sh
rvm gemset use liri

# Ejecutar el Agent
liri a --trace
