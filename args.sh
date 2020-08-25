UseCurl=false
EraseDevice=false
SetLocation=/var/mobile/Media/Succession
RestoreDevice=false
BeVerbose=false

echo $1
if [ "$1" == "-h" ] || [ "$1" == "--help" ]; 
then
echo usage:

echo "-c (--use-curl) (use curl rather than partial zip)"
echo "-e (--erase) (erase the device, remove all user data)"
echo "-l (--location) (specify the location of the ipsw, or dmg) defaults to /var/mobile/Media/Succession)"
echo "-r (--restore) (restore the root filesystem (rootfs, keep user data))"
echo "-v (--verbose) (be verbose)"
exit
elif [ "$1" == "-e" ] || [ "$1" == "--erase" ];
then
e=true
echo will erase the device 
elif [ "$1" == "-c" ] || [ "$1" == "--use-curl" ];
then 
echo will use curl to download the ipsw 
UseCurl=true

elif [ "$1" == "-l" ] || [ "$1" == "--location" ];
then
SetLocation=$2
echo $SetLocation
if [[ -f $SetLocation ]];
then

if [ "${location: -5}" == ".ipsw" ];
then 
mv $location /var/mobile/Media/Succession/ipsw.ipsw
#ShouldDownloadIPSW=false
#ShouldExtractIPSW=true
echo the ipsw has been moved successfully
elif [ "${location: -4}" == ".dmg" ];
then 
mv $location /var/mobile/Media/Succession/rfs.dmg
#ShouldDownloadIPSW=false
#ShouldExtractIPSW=false
echo the dmg  has been moved successfully 
else
echo this is not a valid file format
exit
fi
fi
fi
if [ "$1" == "-r" ] || [ "$1" == "--restore" ];
then
 echo will keep user data

elif [ "$1" == "-v" ] || [ "$1" == "--verbose" ];
then
echo will be verbose

elif [ "$1" == "" ] || [ "$1" == "" ];
then
echo will use succession as normal
elif [ "$1" != "-c" ] || [ "$1" != "--use-curl" ] || [ "$1" != "-e" ] || [ "$1" != "--erase" ] || [ "$1" != "-h" ] || [ "$1" != "--help" ] || [ "$1" != "-l" ] || [ "$1" != "--location" ] || [ "$1" != "-r" ] || [ "$1" != "--restore" ] || [ "$1" != "-v" ] || [ "$1" != "--verbose" ] || [ "$1" != "" ];
then 
echo invalid command!        
fi