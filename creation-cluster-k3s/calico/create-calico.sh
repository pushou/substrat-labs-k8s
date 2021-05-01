#!/bin/bash
shopt -s expand_aliases
alias k='kubectl'
k apply -f $(pwd)/calico/calico.yaml
