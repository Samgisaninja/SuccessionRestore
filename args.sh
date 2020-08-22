echo $1
if [[ $1 -eq -h ]]; 
then
echo usage:
echo "-l (specify the location of the ipsw, defaults to /var/mobile/Media/Succession)"
echo "-c (use curl rather than partial zip)"
echo "-v (be verbose)"
echo "-e (erase the device, remove all user data)"
echo "-r (restore the root filesystem (rootfs, keep user data))"
exit
fi
fi