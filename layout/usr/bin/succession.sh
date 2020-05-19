#!/bin/bash
echo "Welcome to SuccessionCLI! Written by Samg_is_a_Ninja and demhademha"
echo "Special thanks to pwn20wnd (mountpoint and rsync args) and wh0ba (storage space utils)"
sleep 3
checkRoot=`whoami`
if [ $checkRoot != "root" ]; then
    echo "SuccessionCLI needs to be run as root. Please su and try again."
    exit
fi

#Contact helper tool to get iOS version and device model
ProductVersion=`SuccessionCLIhelper --deviceVersion`
#we are now going to get the product buildversion for example, 17c54 and set it as a variable   
ProductBuildVersion=`SuccessionCLIhelper --deviceBuildNumber`
#we now get the machine ID, (for example iPhone9,4), and store it as a variable
DeviceIdentifier=`SuccessionCLIhelper --deviceModel`
#we now need to get the actual device identifier for example, iPad 7,11 is iPad 7th generation 
DeviceName=`plutil -key $DeviceIdentifier /var/mobile/Media/Succession`
#We’ll print these values that we have retrieved  
echo Your $DeviceIdentifier $DeviceName is running iOS version $ProductVersion build $ProductBuildVersion
echo "Please make sure this information is accurate before continuing. Press enter to confirm or exit if inaccurate."
read varblank
shouldExtractIPSW=true
shouldDownloadIPSW=true
if [ -f /private/var/mobile/Media/Succession/rfs.dmg ]; then
    while true; do
        read -p "Detected provided rootfilesystem disk image, would you like to use it? (y/n) " yn
        case $yn in
            [Yy]* ) shouldExtractIPSW=false; break;;
            [Nn]* ) shouldExtractIPSW=true; break;;
            * ) echo "Please answer yes or no.";;
        esac
    done
fi
if ! $shouldExtractIPSW; then
    rm -rf /private/var/mobile/Media/Succession/ipsw*
    shouldDownloadIPSW=false
fi
if [ -f /private/var/mobile/Media/Succession/ipsw.ipsw ]; then
    while true; do
        read -p "Detected provided ipsw, would you like to use it? (y/n) " yn
        case $yn in
            [Yy]* ) shouldDownloadIPSW=false; break;;
            [Nn]* ) shouldDownloadIPSW=true; break;;
            * ) echo "Please answer yes or no.";;
        esac
    done
fi

if $shouldDownloadIPSW; then
    echo succession will download the correct IPSW for your device: press enter to proceed
    #print a warning message 
    echo once you press enter again, succession will begin the download 
    echo DO NOT LEAVE TERMINAL 
    echo DO NOT POWER OFF YOUR DEVICE 
    read varblank2   
    #we tell bash where to save the IPSW 
    echo preparing to download IPSW...
    echo downloading IPSW...
    # Clean up any files from previous runs
    rm -rf /private/var/mobile/Media/Succession/*
    #we download the ipsw from apple’s servers through ipsw.me’s api
    #TODO: add pzb to just download what we need instead of the entire IPSW
    curl  -# -L -o /private/var/mobile/Media/Succession/partial.ipsw http://api.ipsw.me/v2.1/$DeviceIdentifier/$ProductBuildVersion/url/dl
    #now that the download is complete, rename "partial.ipsw" to "ipsw.ipsw"
    mv /private/var/mobile/Media/Succession/partial.ipsw /private/var/mobile/Media/Succession/ipsw.ipsw
fi
if $shouldExtractIPSW; then
    #we create a new directory to put the ipsw that is going to be extracted   
    # Clean up partially extracted ipsws from previous runs
    rm -rf /private/var/mobile/Media/Succession/ipsw/*
    # If this is the first run, we need a destination folder to dump to
    mkdir /private/var/mobile/Media/Succession/ipsw/
    # 7z is a much faster and more advanced zip tool, and most devices will have it.
    pathToSevenZ=`which 7z`
    if [ -x $pathToSevenZ ]; then
        echo "Verifying IPSW..."
        7z x -o/private/var/mobile/Media/Succession/ipsw /private/var/mobile/Media/Succession/ipsw.ipsw BuildManifest.plist
        buildManifestString=$(</private/var/mobile/Media/Succession/ipsw/BuildManifest.plist)
        if [[ $buildManifestString = *$deviceBuildNumber* ]]; then
            echo "IPSW verified, extracting root filesystem..."
            nameOfDMG=`7z l /private/var/mobile/Media/Succession/ipsw.ipsw | grep "dmg" | sort -k 4 | awk 'END {print $NF}'`
            7z x -o/private/var/mobile/Media/Succession/ipsw /private/var/mobile/Media/Succession/ipsw.ipsw $nameOfDMG
            echo moving extracted files...
            mv /private/var/mobile/Media/Succession/ipsw/$nameOfDMG /private/var/mobile/Media/Succession/rfs.dmg
        else
            versionCheckOverride=false
            echo "**********WARNING!**********"
            echo "The IPSW provided does not appear to match the iOS version of this device"
            echo "ATTEMPTING TO CHANGE YOUR iOS VERSION USING THIS TOOL WILL RESULT IN A BOOTLOOP"
            while true; do
                read -p "Would you like to override this check and continue anyway? (y/n)" yn
                case $yn in
                    [Yy]* ) versionCheckOverride=true; break;;
                    [Nn]* ) versionCheckOverride=false; break;;
                    * ) echo "Please answer yes or no.";;
                esac
            done
            if $versionCheckOverride; then
                    nameOfDMG=`7z l /private/var/mobile/Media/Succession/ipsw.ipsw | grep "dmg" | sort -k 4 | awk 'END {print $NF}'`
                    7z x -o/private/var/mobile/Media/Succession/ipsw /private/var/mobile/Media/Succession/ipsw.ipsw $nameOfDMG
                    echo moving extracted files...
                    mv /private/var/mobile/Media/Succession/ipsw/$nameOfDMG /private/var/mobile/Media/Succession/rfs.dmg
            else
                    echo "Good choice. Succession will now quit."
                    exit
            fi
        fi
    else 
        #we now navigate to the directory that we just created in order to save our extracted ipsw there after unzipping it 
        echo "Extracting IPSW..."  
        cd /private/var/mobile/Media/Succession/ipsw/
        unzip /private/var/mobile/Media/Succession/ipsw.ipsw
        cd ~
        echo "Verifying IPSW..."
        buildManifestString=$(</private/var/mobile/Media/Succession/ipsw/BuildManifest.plist)
        if [[ $buildManifestString = *$deviceBuildNumber* ]]; then
            echo "IPSW verified, moving files..."
            dmg=`ls -S /private/var/mobile/Media/Succession/ipsw/ | head -1`
            mv /private/var/mobile/Media/Succession/ipsw/$dmg /private/var/mobile/Media/Succession/rfs.dmg
        else
            versionCheckOverride=false
            echo "**********WARNING!**********"
            echo "The IPSW provided does not appear to match the iOS version of this device"
            echo "ATTEMPTING TO CHANGE YOUR iOS VERSION USING THIS TOOL WILL RESULT IN A BOOTLOOP"
            while true; do
                read -p "Would you like to override this check and continue anyway? (y/n)" yn
                case $yn in
                    [Yy]* ) versionCheckOverride=true; break;;
                    [Nn]* ) versionCheckOverride=false; break;;
                    * ) echo "Please answer yes or no.";;
                esac
            done
            if $versionCheckOverride; then
                    echo "IPSW verified, moving files..."
                    dmg=`ls -S /private/var/mobile/Media/Succession/ipsw/ | head -1`
                    mv /private/var/mobile/Media/Succession/ipsw/$dmg /private/var/mobile/Media/Succession/rfs.dmg
            else
                    echo "Good choice. Succession will now quit."
                    exit
            fi
        fi
    fi 
    # Clean up
    rm -rf /private/var/mobile/Media/Succession/ipsw/
    rm /private/var/mobile/Media/Succession/ipsw.ipsw
fi
echo "Rootfilesystem dmg successfully extracted!"
#needs completing 
