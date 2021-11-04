#!/bin/bash
source messages.sh

cd ..
 
AGENT_HOME=`pwd`
LIBS_HOME=$AGENT_HOME/lib
RUBY_VERSION=2.7.2
GEMSET_NAME=liri
LIRI_VERSION=0.1.1
AGENT_SERVICE_NAME=liriagent.service

check_command () {
  COMMAND=$1
  
  if ! type $COMMAND > /dev/null; then
    fail_msg "Por favor instale la librería adecuada para ejecutar el comando ${COMMAND} acorde a su distribución Linux."
    exit   
  fi    
}

configure_gemset () {
  start_msg "Configurando Gemset"

  source $HOME/.rvm/scripts/rvm
  
  if rvm use $RUBY_VERSION; then
    success_msg "rvm use $RUBY_VERSION"
  else
    fail_msg "rvm use $RUBY_VERSION"
    exit 1
  fi
  
  if rvm gemset use $GEMSET_NAME; then
    success_msg "rvm gemset use $GEMSET_NAME"
  else
    fail_msg "rvm gemset use $GEMSET_NAME"
    exit 1
  fi

  end_msg "Configuración de Gemset finalizada"
}

install_liri () {
  start_msg "Actualizando Liri"

  if gem install $LIBS_HOME/liri-$LIRI_VERSION.gem; then
    success_msg "gem install $LIBS_HOME/liri-$LIRI_VERSION.gem"
  else
    fail_msg "gem install $LIBS_HOME/liri-$LIRI_VERSION.gem"
    exit 1
  fi

  end_msg "Actualización de Liri finalizada"
}

stop_service () {
  start_msg "Apagando Servicio Agent"

  if sudo systemctl stop $AGENT_SERVICE_NAME; then
    success_msg "sudo systemctl stop $AGENT_SERVICE_NAME"
  else
    fail_msg "sudo systemctl stop $AGENT_SERVICE_NAME"
    exit 1
  fi

  end_msg "Apagado de Servicio Agent finalizado"
}

start_service () {
  start_msg "Iniciando Servicio Agent"

  if sudo systemctl start $AGENT_SERVICE_NAME; then
    success_msg "sudo systemctl start $AGENT_SERVICE_NAME"
  else
    fail_msg "sudo systemctl start $AGENT_SERVICE_NAME"
    exit 1
  fi

  info_msg "Para ver estado del Agent utilice: journalctl -e -u $AGENT_SERVICE_NAME"

  end_msg "Inicio de Servicio Agent finalizado"
}


########################################################################################################################
# Proceso de instalación del programa Agent
stop_service
configure_gemset
install_liri
start_service