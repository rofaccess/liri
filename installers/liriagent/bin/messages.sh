#!/bin/bash

msg () {
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

start_msg () {
  MSG=$1
  COLOR="0;35m"
  SUB_MSG="INICIO: "
  printf "+------------------------------------------------------------------------------+\n" 
  msg "$MSG" "$COLOR" "$SUB_MSG"
  printf "+------------------------------------------------------------------------------+\n"
}

end_msg () {
  MSG=$1
  COLOR="0;35m"
  SUB_MSG="FIN: " 
  msg "$MSG" "$COLOR" "$SUB_MSG"
  printf "+------------------------------------------------------------------------------+\n"
}

info_msg () {
  MSG=$1
  COLOR="0;36m"
  SUB_MSG="INFO: "
  msg "$MSG" "$COLOR" "$SUB_MSG"
}

success_msg () {
  MSG=$1
  COLOR="0;32m"
  SUB_MSG="ÉXITO: "
  msg "$MSG" "$COLOR" "$SUB_MSG"
}

warning_msg () {
  MSG=$1
  COLOR="0;33m"
  SUB_MSG="CUIDADO: "
  msg "$MSG" "$COLOR" "$SUB_MSG"
}

fail_msg () {
  MSG=$1
  COLOR="0;31m"
  SUB_MSG="FALLA: "
  msg "$MSG" "$COLOR" "$SUB_MSG"
}