#!/bin/bash
source messages.sh

cd ..
 
AGENT_HOME=`pwd`
LIBS_HOME=$AGENT_HOME/lib
BIN_HOME=$AGENT_HOME/bin
RUBY__VERSION=2.7.2 # Se usa doble guión bajo porque en algunos sistemas, RUBY_VERSION es una variable de entorno con valor propio y se termina usando el valor de esa variable en esta instalación
AGENT_USER_NAME=liri 
GEMSET_NAME=liri
LIRI_VERSION=0.1.1

TMP_DIR=`mktemp --directory`
AGENT_SERVICE_NAME=liriagent.service
SERVICE_FILE=$TMP_DIR/$AGENT_SERVICE_NAME
WORK_HOME=$AGENT_HOME/work

check_command () {
  COMMAND=$1
  
  if [ -z "$2" ]
    then
      MSG="Por favor instale la librería adecuada para ejecutar el comando ${COMMAND} acorde a su distribución Linux."
  else
    MSG=$2
  fi

  if ! type $COMMAND > /dev/null; then
    fail_msg "$MSG" # La variable debe pasarse entre comillas osino no imprime todo el mensaje
    exit   
  fi    
}

check_command_gpg () {
  OS_NAME=$(os_name)

  # En Ubuntu se usa gpg porque gpg2 por algún motivo falla en obtener las claves
  if [ "$OS_NAME" == "Ubuntu" ]; then
    check_command gpg
  else
    check_command gpg2
  fi  
}

function press_key {
  msg "\nPresione Enter para continuar o la tecla 's' + Enter para salir "
  read option
  if [ "$option" == "s" ]; then
    exit
  fi
}

check_c_compilers () {
  if ! type gcc > /dev/null; then
    warning_msg "No se encuentra el comando gcc"

    if ! type cc > /dev/null; then
      warning_msg "No se encuentra el comando cc"
      fail_msg "Para realizar la instalación se requiere un compilador para el lenguaje C, como gcc o cc"
      exit   
    fi    
  fi     
}

os_name () {
  OS_NAME=$(cat /etc/*-release | grep -w NAME | cut -d= -f2 | tr -d '"')
  echo "$OS_NAME"
}

check_requeriments () {
  OS_NAME=$(os_name)

  info_msg "Distribución detectada: $OS_NAME"
  echo ""
  info_msg "Para finalizar satisfactoriamente la instalación debe tener actualizada el sistema operativo y tener instalado los programas necesarios"

  if [ "$OS_NAME" == "Manjaro Linuxx" ]; then
    echo "      > sudo pacman -Syu"
    echo "      > sudo pacman -S curl gcc make"
    info_msg "Comandos probados en Manjaro 21.2.3 (Qonos)"

  elif [ "$OS_NAME" == "Ubuntu" ]; then
    echo "        > sudo apt-get update"
    echo "        > sudo apt update"
    echo "        > sudo apt install openssh-server curl gcc make"
    info_msg "Comandos probados en Ubuntu 21.10 (Impish Indri)"

  elif [ "$OS_NAME" == "Debian GNU/Linux" ]; then
    info_msg "Antes de actualizar Debian debe agregar su usuario al grupo sudo agregando whoami ALL=(ALL) NOPASSWD:ALL al final del archivo sudoers. Reemplace whoami por su nombre de usuario"
    echo "        > su"
    echo "        > nano /etc/sudoers"
    echo "        > sudo apt-get update"
    echo "        > sudo apt update"
    echo "        > sudo apt install gnupg2 curl gcc make"
    info_msg "Comandos probados en Debian 11.1 (Bullseye)"
  elif [ "$OS_NAME" == "Fedora Linux" ]; then
    info_msg "Fedora 35 ya tiene instalado todos los programas necesarios"
    info_msg "Para poder activar e iniciar el Agente Liri se debe configurar selinux especificando SELINUX=permissive en /etc/selinux/config y reiniciando el sistema"
    echo "        > nano /etc/selinux/config"
    info_msg "Comandos probados en Fedora 35"

  else
    info_msg "- gpg: para instalar las claves gpg de RVM"
    info_msg "- curl: para descargar RVM"
    info_msg "- gcc y make: para instalar Ruby"

  fi  

  info_msg "En algunos momentos se requerirá el ingreso de la contraseña sudo o root"
  info_msg "Asegurese de que el servicio ssh esté instalado y ejecutandose"
  echo "      > sudo systemctl status sshd"
  echo "      > sudo systemctl enable sshd"
  echo "      > sudo systemctl start sshd" 

  check_command_gpg
  check_command curl
  check_c_compilers
  check_command make
}

install_gpg_keys () {
  start_msg "Instalando claves"
  OS_NAME=$(os_name)

  # En Ubuntu se usa gpg porque gpg2 por algún motivo falla en obtener las claves
  if [ "$OS_NAME" == "Ubuntu" ]; then
    if curl -sSL https://rvm.io/mpapis.asc | gpg --import -; then
      success_msg "curl -sSL https://rvm.io/mpapis.asc | gpg --import -"
    else
      fail_msg "curl -sSL https://rvm.io/mpapis.asc | gpg --import -"
      exit 1
    fi    

    if curl -sSL https://rvm.io/pkuczynski.asc | gpg --import -; then
      success_msg "curl -sSL https://rvm.io/pkuczynski.asc | gpg --import -"
    else
      fail_msg "curl -sSL https://rvm.io/pkuczynski.asc | gpg --import -"
      exit 1
    fi    

  else
    if gpg2 --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB; then
      success_msg "gpg2 --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB"
    else
      fail_msg "gpg2 --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB"
      exit 1
    fi    

  fi  

  end_msg "Instalación de claves finalizada"
}

install_rvm () {
  start_msg "Instalando RVM"

  # Descargar e instalar RVM
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

  if rvm install $RUBY__VERSION; then
    success_msg "rvm install $RUBY__VERSION"
  else
    fail_msg "rvm install $RUBY__VERSION"
    exit 1
  fi

  
  if rvm use $RUBY__VERSION; then
    success_msg "rvm use $RUBY__VERSION"
  else
    fail_msg "rvm use $RUBY__VERSION"
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
  start_msg "Instalando Liri"

  if gem install $LIBS_HOME/liri-$LIRI_VERSION.gem; then
    success_msg "gem install $LIBS_HOME/liri-$LIRI_VERSION.gem"
  else
    fail_msg "gem install $LIBS_HOME/liri-$LIRI_VERSION.gem"
    exit 1
  fi

  end_msg "Instalación de Liri finalizada"
}

create_service () { 
  start_msg "Creando servicio"

cat << EOF > $SERVICE_FILE
  [Unit]
  Description=Liri Agent
  After=network.target

  [Service]
  Type=simple

  User=$(whoami)
  Group=$(whoami)

  WorkingDirectory=$WORK_HOME

  ExecStart=$BIN_HOME/startup.sh
  ExecStop=$BIN_HOME/shutdown.sh

  [Install]
  WantedBy=multi-user.target
EOF

  if sudo mv $SERVICE_FILE /etc/systemd/system/; then
    success_msg "sudo mv $SERVICE_FILE /etc/systemd/system/"
  else
    fail_msg "sudo mv $SERVICE_FILE /etc/systemd/system/-"
    exit 1
  fi   

  if sudo systemctl daemon-reload; then
    success_msg "sudo systemctl daemon-reload"
  else
    fail_msg "sudo systemctl daemon-reload"
    exit 1
  fi  

  end_msg "Creación de servicio finalizada"
}

enable_service () {
  start_msg "Activando Servicio Agent"

  if sudo systemctl enable $AGENT_SERVICE_NAME; then
    success_msg "sudo systemctl enable $AGENT_SERVICE_NAME"
  else
    fail_msg "sudo systemctl enable $AGENT_SERVICE_NAME"
    exit 1
  fi

  end_msg "Activación de Servicio Agent finalizado"
}


start_service () {
  start_msg "Iniciando Servicio Agent"

  if sudo systemctl stop $AGENT_SERVICE_NAME; then
    success_msg "sudo systemctl stop $AGENT_SERVICE_NAME"
  else
    fail_msg "sudo systemctl stop $AGENT_SERVICE_NAME"
    exit 1
  fi

  if sudo systemctl start $AGENT_SERVICE_NAME; then
    success_msg "sudo systemctl start $AGENT_SERVICE_NAME"
  else
    fail_msg "sudo systemctl start $AGENT_SERVICE_NAME"
    exit 1
  fi

  info_msg "Para ver estado del Agent utilice: journalctl -e -u $AGENT_SERVICE_NAME o sudo systemctl status $AGENT_SERVICE_NAME"

  end_msg "Inicio de Servicio Agent finalizado"
}


########################################################################################################################
start_msg "Proceso de instalación del programa Agent"
check_requeriments
press_key
install_gpg_keys
install_rvm
install_ruby
create_gemset
install_liri
create_service
enable_service
start_service