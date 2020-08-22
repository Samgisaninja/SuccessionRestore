echo $1
if [[ $1 -eq -h ]]; 
then
echo usage:
echo "-l (location of the ipsw)"
echo "-c (use curl rather than partial zip)"
echo "-v (be verbose)"
echo "-e (erase the device, remove all user data)"
echo "-r (restore the root filesystem (rootfs))" 
fi