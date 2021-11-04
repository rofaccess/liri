#!/bin/bash

function msg {
  MSG=$1
  SWITCH="\033["
  NORMAL_COLOR="${SWITCH}0m"

   if [ -z "$2" ]
      then
        COLOR='0;30m'
   else
      COLOR=$2
    fi

  SUB_MSG=$3

  CUSTOM_COLOR="${SWITCH}${COLOR}"
  printf "${CUSTOM_COLOR}${SUB_MSG}${NORMAL_COLOR}${MSG}\n"
}

function start_msg {
  MSG=$1
  COLOR="0;35m"
  SUB_MSG="INICIO: "
  printf "+------------------------------------------------------------------------------+\n"	
  msg "$MSG" "$COLOR" "$SUB_MSG"
  printf "+------------------------------------------------------------------------------+\n"
}

function end_msg {
  MSG=$1
  COLOR="0;35m"
  SUB_MSG="FIN: " 
  msg "$MSG" "$COLOR" "$SUB_MSG"
  printf "+------------------------------------------------------------------------------+\n"
}

function info_msg {
  MSG=$1
  COLOR="0;36m"
  SUB_MSG="INFO: "
  msg "$MSG" "$COLOR" "$SUB_MSG"
}

function success_msg {
  MSG=$1
  COLOR="0;32m"
  SUB_MSG="ÉXITO: "
  msg "$MSG" "$COLOR" "$SUB_MSG"
}

function warning_msg {
  MSG=$1
  COLOR="0;33m"
  SUB_MSG="CUIDADO: "
  msg "$MSG" "$COLOR" "$SUB_MSG"
}

function fail_msg {
  MSG=$1
  COLOR="0;31m"
  SUB_MSG="FALLA: "
  msg "$MSG" "$COLOR" "$SUB_MSG"
}

check_command () {
  COMMAND=$1
  
  if ! type $COMMAND > /dev/null; then
    fail_msg "Por favor instale la librería adecuada para ejecutar el comando ${COMMAND} acorde a su distribución Linux."
    exit   
  fi    
}