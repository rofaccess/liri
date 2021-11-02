#!/bin/bash
source messages.sh

cd ..
 
AGENT_HOME=`pwd`
LIBS_HOME=$AGENT_HOME/lib
BIN_HOME=$AGENT_HOME/bin
RUBY_VERSION=2.7.2
AGENT_USER_NAME=liri 
GEMSET_NAME=liri
LIRI_VERSION=0.1.1

check_command () {
  COMMAND=$1
  
  if ! type $COMMAND > /dev/null; then
    fail_msg "Por favor instale la librería adecuada para ejecutar el comando ${COMMAND} acorde a su distribución Linux."
    exit   
  fi    
}

install_rvm () {
  start_msg "Instalando RVM"
 
  # Instalar claves gpg
  check_command gpg2
 
  if gpg2 --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB; then
    success_msg "gpg2 --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB"
  else
    fail_msg "gpg2 --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB"
    exit 1
  fi

  # Descargar e instalar RVM
  check_command curl

  if \curl -sSL https://get.rvm.io | bash -s stable; then
    success_msg "\curl -sSL https://get.rvm.io | sudo bash -s stable"
  else
    fail_msg "\curl -sSL https://get.rvm.io | sudo bash -s stable"
    exit 1
  fi   
  
  source $HOME/.rvm/scripts/rvm

  end_msg "Instalación de RVM finalizada"
}

install_ruby () {
  start_msg "Instalando Ruby"

  if rvm install $RUBY_VERSION; then
    success_msg "rvm install $RUBY_VERSION"
  else
    fail_msg "rvm install $RUBY_VERSION"
    exit 1
  fi

  
  if rvm use $RUBY_VERSION; then
    success_msg "rvm use $RUBY_VERSION"
  else
    fail_msg "rvm use $RUBY_VERSION"
    exit 1
  fi

  end_msg "Instalación de Ruby finalizada"
}

create_gemset () {
  start_msg "Configurando Gemset"
  
  if rvm gemset create $GEMSET_NAME; then
    success_msg "rvm gemset create $GEMSET_NAME"
  else
    fail_msg "rvm gemset create $GEMSET_NAME"
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
  start_msg "Înstalando Liri"

  if gem install $LIBS_HOME/liri-$LIRI_VERSION.gem; then
    success_msg "gem install $LIBS_HOME/liri-$LIRI_VERSION.gem"
  else
    fail_msg "gem install $LIBS_HOME/liri-$LIRI_VERSION.gem"
    exit 1
  fi

  end_msg "Instalación de Liri finalizada"
}


########################################################################################################################
# Proceso de instalación del programa Agent
install_rvm
install_ruby
create_gemset
install_liri
