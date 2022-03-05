#!/bin/bash
# Volver a la carpeta home
cd ..
 
AGENT_HOME=`pwd`

# Carpetas home
BIN_HOME=$AGENT_HOME/bin
LIBS_HOME=$AGENT_HOME/lib
WORK_HOME=$AGENT_HOME/work

RVM_HOME=$HOME/.rvm/scripts/rvm

RUBY__VERSION=2.7.2

GEMSET_NAME=liri

LIRI_VERSION_FILE_NAME=.liri-version
LIRI_VERSION_FILE_PATH=$BIN_HOME/$LIRI_VERSION_FILE_NAME
# Obtiene la versión actual de Liri del archivo .liri-version
LIRI_VERSION=$(<$LIRI_VERSION_FILE_PATH)

TMP_DIR=`mktemp --directory`
AGENT_SERVICE_NAME=liriagent.service
AGENT_SERVICE_FILE_PATH=$TMP_DIR/$AGENT_SERVICE_NAME

