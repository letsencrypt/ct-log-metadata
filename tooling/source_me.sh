#!/bin/bash

# I am only meant to be sourced by other scripts

RED="$(tput setaf 1)"
BLU="$(tput setaf 4)"
RST="$(tput sgr0)"

function prettyRed() {
  echo "${RED}==> ${1}${RST}"
}

function pretty() {
  echo "${BLU}==> ${1}${RST}"
}
