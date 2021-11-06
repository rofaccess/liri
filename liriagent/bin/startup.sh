#!/bin/bash
RUBY_VERSION=2.7.2

source $HOME/.rvm/scripts/rvm

rvm use $RUBY_VERSION

rvm gemset use liri

# Ejecutar el Agent
liri a --trace
