#!/bin/bash
# example_args.sh
$ShouldUseCurl
$ShouldEraseDevice
$SetLocation
$ShouldRestoreDevice
$SetVerbose

while [ $# -gt 0 ] ; do
  case $1 in
    -c | --use-curl) C="$2"
ShouldUseCurl=true
echo use curl
echo ShouldUseCurl = $ShouldUseCurl
;;
    -e | --erase) E="$2"
ShouldEraseDevice=true
echo erase device
echo ShouldEraseDevice = $ShouldEraseDevice
;;
    -h | --help) H="$2"
echo help

;;
    -l | --location) L="$2"
SetLocation=$2
echo file location is  $SetLocation 
;;
    -r | --restore) r="$2" 
ShouldRestoreDevice=true
echo will restore device
echo should restore device is    $ShouldRestoreDevice
;;
    -v | --verbose) V="$2"
SetVerbose=true
echo will be verbose
echo SetVerbose = $SetVerbose 
;;
  esac
  shift
done
#echo $C $E $H $L $R $V