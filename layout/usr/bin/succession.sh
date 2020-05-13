#!/bin/bash
#We are going to create a resources folder in the User’s var directory 
mkdir -p /private/var/mobile/Media/Succession/
#Contact helper tool to get iOS version and device model
ProductVersion=`SuccessionCLIhelper --deviceVersion`
#we are now going to get the product buildversion for example, 17c54 and set it as a variable   
ProductBuildVersion=`SuccessionCLIhelper --deviceBuildNumber`
#we now get the machine ID, (for example iPhone9,4), and store it as a variable
DeviceIdentifier=`SuccessionCLIhelper --deviceModel`
#We’ll print these values that we have retrieved  
echo your $DeviceIdentifier is running iOS version $ProductVersion build $ProductBuildVersion
echo please make sure this information is accurate before continuing
shouldDownloadIPSW=true
if [ -f /private/var/mobile/Media/Succession/ipsw.ipsw ]; then
    read -p "Detected provided ipsw, would you like to use it? (y/n)" $wantsToUseProvidedIPSW
    case $wantsToUseProvidedIPSW in
        [Yy]* ) shouldDownloadIPSW=false;;
        [Nn]* ) shouldDownloadIPSW=true;;
        * ) echo "Please answer yes or no.";;
    esac
fi

if $shouldDownloadIPSW; then
    echo succession will download the correct IPSW for your device: press enter to proceed
    read varblank2

    #print a warning message 

    echo once you press enter again, succession will begin the download 
    echo  DO NOT LEAVE TERMINAL 
    echo  DO NOT POWER OFF YOUR DEVICE 
    read varblank2   
    #we tell bash where to save the IPSW 
    echo preparing to download IPSW...
    echo downloading IPSW...
    #we download the ipsw from apple’s servers through ipsw.me’s api    
    curl  -# -L -o partial.ipsw http://api.ipsw.me/v2.1/$DeviceIdentifier/$ProductBuildVersion/url/dl
    #now that the download is complete, rename "partial.ipsw" to "ipsw.ipsw"
    mv partial.ipsw ipsw.ipsw

#we create a new directory to put the ipsw that is going to be extracted   
mkdir /private/var/mobile/Media/Succession/ipsw/
echo extracting IPSW...
#we now navigate to the directory that we just created in order to save our extracted ipsw there after unzipping it   
cd /private/var/mobile/Media/Succession/ipsw/
unzip /private/var/mobile/Media/Succession/ipsw.ipsw
#we create a variable called dmg as we need to find and use the largest dmg later   
echo moving extracted files... 
 
dmg=`ls -S | head -1`
mv /private/var/mobile/Media/Succession/ipsw/$dmg /var/mobile/Media/Succession/rfs.dmg
#needs completing 
