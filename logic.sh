#!/bin/bash
clear
# shellcheck disable=SC2164
cd chess-logic
if [ "$1" != '' ]; then
    torii --world "$1"
else
  sozo clean
  sozo build
  sozo migrate plan
  sozo migrate apply
fi