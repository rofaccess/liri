#!/bin/bash
set_ruby () {
  start_msg "Configurando Ruby"  
  source $RVM_HOME
  
  if rvm use $RUBY__VERSION; then
    success_msg "rvm use $RUBY__VERSION"
  else
    fail_msg "rvm use $RUBY__VERSION"
    exit 1
  fi

  end_msg "Configuracion de Ruby finalizada"    
}

set_gemset () {
  start_msg "Configurando Gemset"
   
  if rvm gemset use $GEMSET_NAME; then
    success_msg "rvm gemset use $GEMSET_NAME"
  else
    fail_msg "rvm gemset use $GEMSET_NAME"
    exit 1
  fi

  end_msg "Configuración de Gemset finalizada"
}

install_liri () {
  start_msg "Instalando Liri"

  if gem install $LIBS_HOME/liri-$LIRI_VERSION.gem; then
    success_msg "gem install $LIBS_HOME/liri-$LIRI_VERSION.gem"
  else
    fail_msg "gem install $LIBS_HOME/liri-$LIRI_VERSION.gem"
    exit 1
  fi

  end_msg "Instalación de Liri finalizada"
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