#!/bin/bash
# example_args.sh

while [ $# -gt 0 ] ; do
  case $1 in
    -c | --use-curl) C="$2" ;;
    -e | --erase) E="$2" ;;
    -h | --help) H="$2" 
echo help 
;;
    -l | --location) L="$2" ;;

    -r | --restore) r="$2" ;;

    -v | --verbose) L="$2" ;;

  esac
  shift
done
echo $C $E $H $L $R $V