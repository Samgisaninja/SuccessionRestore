#!bash
#We are going to create a resources folder in the User’s var directory 
mkdir /var/successioncle/
#We are going to copy and paste these two files into our resources folder so we can identify the device, we do this instead of reading the values directly, just to be safe.  
 cp /System/Library/CoreServices/SystemVersion.plist /var/successioncle/ 
cp /var/containers/Shared/SystemGroup/systemgroup.com.apple.mobilegestaltcache/Library/Caches/com.apple.MobileGestalt.plist /var/successioncle/ 

#We’re now going to read the plist files we just copied, so we can identify and download the correct IPSW for the current device.
  #we are going to get the ProductVersion for example, iOS 13.3 and set it as a variable 

ProductVersion=`plutil -key ProductVersion /var/successioncle/SystemVersion.plist`
#we are now going to get the product buildversion for example, 17c54 and set it as a variable   
ProductBuildVersion=`plutil -key ProductBuildVersion /var/successioncle/SystemVersion.plist`
#we now get the device name for example, if the device is an iPad and set it as a variable   
DeviceName=`plutil -key CacheExtra -key Z/dqyWS6OZTRy10UcmUAhw /var/successioncle/com.apple.MobileGestalt.plist`
DeviceIdentifier=`plutil   -key CacheExtra -key h9jDsbgj7xIVeIQ8S3/X3Q /var/successioncle/com.apple.MobileGestalt.plist`
#We’ll print these values that we have retrieved  
 echo your $DeviceName $DeviceIdentifier is running iOS $ProductVersion $ProductBuildVersion

   
echo succession will download the correct IPSW for your device: press enter to proceed
read varblank2

#print a warning message 

echo once you press enter again, succession will begin the download 
echo  DO NOT LEAVE TERMINAL 
echo   DO NOT POWER OFF YOUR DEVICE 
read varblank2   
#we tell bash where to save the IPSW 
cd /var/successioncle/
echo preparing to download IPSW...
#we now get the FileName of the ipsw from apple’s servers  through ipsw.me’s api 
curl -# -LO  http://api.ipsw.me/v2.1/$DeviceIdentifier/$ProductBuildVersion/filename
echo downloading IPSW...
#we download the ipsw from apple’s servers through ipsw.me’s api    
curl  -# -LO  http://api.ipsw.me/v2.1/$DeviceIdentifier/$ProductBuildVersion/url/dl
#we’re now going to rename our file correctly
#we call the cat command in order to get the contents of /var/successioncle/filename as the downloaded ipsw is just called dl

#we create a variable with the contents of the file
IpswName=`cat /var/successioncle/filename`
#we now use the rename command

mv /var/successioncle/dl $IpswName.zip
#we create a new directory to put the ipsw that is going to be extracted   
mkdir /var/successioncle/ipsw/
echo extracting IPSW...
#we now navigate to the directory that we just created in order to save our extracted ipsw there after unzipping it   
cd /var/successioncle/ipsw/
unzip /var/successioncle/iPad_64bit_TouchID_13.3_17C54_Restore.ipsw.zip
#we create a variable called dmg as we need to find and use the largest dmg later   
 echo moving extracted files... 
 
dmg=`ls -S | head -1`
mv /var/successioncle/ipsw/$dmg /var/successioncle 
#needs completing 
