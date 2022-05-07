#!/bin/bash
source messages.sh
source common_functions.sh
source set_variables.sh

########################################################################################################################
# Proceso de instalación del programa Agent
stop_service
set_ruby
set_gemset
install_liri
start_service